// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../../src/Bank.sol";
import {Handler} from "./Handler.sol";

/// @notice The invariant suite. Foundry will call random sequences of the handler's functions, and
///         after every sequence it checks that every `invariant_*` function still holds. If one
///         ever fails, Foundry shrinks the sequence down to the shortest reproduction and prints it.
contract BankInvariantTest is Test {
    Bank internal bank;
    Handler internal handler;

    function setUp() public {
        bank = new Bank();
        handler = new Handler(bank);

        // Point the fuzzer at the HANDLER, not the bank. This is the line that makes the whole
        // thing work: it drives the bank only through the safe, bounded actions we defined.
        targetContract(address(handler));
    }

    /// The bank must physically hold exactly the ETH it has accounted for. If this ever breaks,
    /// the contract has either lost or invented money.
    function invariant_bankIsSolvent() public view {
        assertEq(address(bank).balance, bank.totalDeposited(), "bank ETH must equal its accounting");
    }

    /// The bank's own total must match our independent ghost tally of every deposit and withdrawal.
    /// This catches accounting drift the contract alone could never notice.
    function invariant_accountingMatchesGhost() public view {
        assertEq(bank.totalDeposited(), handler.ghost_sumDeposits(), "totalDeposited must match the ghost tally");
    }
}
