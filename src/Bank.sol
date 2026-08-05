// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice A deliberately tiny ETH bank. Users deposit their own ETH and withdraw it again.
///         It exists only to demonstrate invariant testing on something small enough to hold in
///         your head, while still having real properties that must never break.
///
///         Two things must ALWAYS be true, no matter what sequence of deposits and withdrawals
///         happens, and in what order, and by whom:
///           1. The contract physically holds exactly the ETH it has accounted for.
///           2. Its running total equals every deposit made, minus every withdrawal made.
///
///         `test/invariant/` proves both hold across thousands of random sequences.
contract Bank {
    mapping(address => uint256) public balanceOf;
    uint256 public totalDeposited;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        totalDeposited += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalDeposited -= amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
