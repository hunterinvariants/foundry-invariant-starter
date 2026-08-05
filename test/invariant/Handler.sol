// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../../src/Bank.sol";

/// @notice THE HANDLER is the single most important, and most skipped, piece of invariant testing.
///
///         If you point the fuzzer straight at your contract, it calls functions with random
///         garbage arguments, almost every call reverts, and it explores nothing. The handler is a
///         thin wrapper that exposes only SAFE, BOUNDED versions of your actions, so every call the
///         fuzzer makes is a valid operation. That is what lets it explore deep, realistic states.
///
///         The handler also holds GHOST VARIABLES: an independent tally of what the state should be,
///         computed here, in the test, separately from the contract. The invariants then check the
///         contract against this independent source of truth. If the contract and the ghost ever
///         disagree, you have found a bug.
contract Handler is Test {
    Bank public bank;

    // A fixed cast of users, so deposits and withdrawals happen across several accounts.
    address[] internal actors;
    address internal currentActor;

    // GHOST VARIABLE: our own tally of the ETH that should be in the bank, tracked independently.
    uint256 public ghost_sumDeposits;

    constructor(Bank bank_) {
        bank = bank_;
        for (uint256 i = 0; i < 5; i++) {
            actors.push(makeAddr(string(abi.encodePacked("actor", vm.toString(i)))));
        }
    }

    // Pick one of the actors based on a fuzzed seed, and run the action as that account.
    modifier useActor(uint256 seed) {
        currentActor = actors[seed % actors.length];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    function deposit(uint256 actorSeed, uint256 amount) external useActor(actorSeed) {
        // BOUND the fuzzed amount into a sane range. Without this the fuzzer wastes runs on
        // absurd values, and here it would try to deposit more ETH than exists.
        amount = bound(amount, 0, 100 ether);
        vm.deal(currentActor, amount); // fund the actor so the deposit cannot revert
        bank.deposit{value: amount}();
        ghost_sumDeposits += amount; // keep our independent tally in step
    }

    function withdraw(uint256 actorSeed, uint256 amount) external useActor(actorSeed) {
        // Bound the withdrawal to what this actor actually has, so the call is always valid and
        // never reverts. Reverts here would trip fail_on_revert and stop the run.
        uint256 bal = bank.balanceOf(currentActor);
        amount = bound(amount, 0, bal);
        bank.withdraw(amount);
        ghost_sumDeposits -= amount;
    }
}
