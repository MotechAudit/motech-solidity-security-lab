// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FixedVault.sol";

/// @dev Fuzz tests for the vault's balance/accounting relationship.
contract VaultAccountingFuzzTest is Test {
    FixedVault private vault;

    function setUp() public {
        vault = new FixedVault();
    }

    function testFuzzDepositKeepsVaultBalanceAndAccountingConsistent(uint96 rawAmount) public {
        uint256 amount = bound(uint256(rawAmount), 1, 100 ether);
        address depositor = makeAddr("fuzz-depositor");
        vm.deal(depositor, amount);

        uint256 vaultBalanceBefore = address(vault).balance;
        uint256 recordedBalanceBefore = vault.balances(depositor);

        vm.prank(depositor);
        vault.deposit{value: amount}();

        // A successful deposit must increase on-chain ETH and recorded
        // accounting by exactly the same amount.
        assertEq(address(vault).balance, vaultBalanceBefore + amount);
        assertEq(vault.balances(depositor), recordedBalanceBefore + amount);
    }

    function testFuzzWithdrawalClearsAccountingAndReturnsRecordedAmount(uint96 rawAmount) public {
        uint256 amount = bound(uint256(rawAmount), 1, 100 ether);
        address depositor = makeAddr("fuzz-withdrawer");
        vm.deal(depositor, amount);

        vm.prank(depositor);
        vault.deposit{value: amount}();

        uint256 depositorBalanceBeforeWithdrawal = depositor.balance;
        uint256 vaultBalanceBeforeWithdrawal = address(vault).balance;
        uint256 recordedBalanceBeforeWithdrawal = vault.balances(depositor);

        assertEq(vaultBalanceBeforeWithdrawal, amount);
        assertEq(recordedBalanceBeforeWithdrawal, amount);

        vm.prank(depositor);
        vault.withdraw();

        // A successful withdrawal must pay exactly the recorded amount,
        // clear the caller's credit, and reduce the vault's ETH by that amount.
        assertEq(depositor.balance, depositorBalanceBeforeWithdrawal + amount);
        assertEq(address(vault).balance, vaultBalanceBeforeWithdrawal - amount);
        assertEq(vault.balances(depositor), 0);
    }

    /// @dev Invariant: Multiple deposits from a single depositor must accumulate
    ///      additively, keeping the vault ETH balance and user balance synchronized.
    function testFuzzMultipleDepositsAccumulateCorrectly(uint96 rawA, uint96 rawB, uint96 rawC) public {
        uint256 a = bound(uint256(rawA), 1, 50 ether);
        uint256 b = bound(uint256(rawB), 1, 50 ether);
        uint256 c = bound(uint256(rawC), 1, 50 ether);
        uint256 total = a + b + c;

        address depositor = makeAddr("multi-depositor");
        vm.deal(depositor, total);

        uint256 vaultBalanceBefore = address(vault).balance;
        uint256 recordedBalanceBefore = vault.balances(depositor);

        vm.startPrank(depositor);
        vault.deposit{value: a}();
        vault.deposit{value: b}();
        vault.deposit{value: c}();
        vm.stopPrank();

        // Recorded balance must strictly match the sum of individual deposits
        assertEq(vault.balances(depositor), recordedBalanceBefore + total);
        assertEq(address(vault).balance, vaultBalanceBefore + total);
    }

    /// @dev Invariant: Deposits from distinct users must maintain strict state isolation;
    ///      one user's deposit must not mutate another user's recorded balance.
    function testFuzzMultiUserDepositsMaintainIndependentAccounting(uint96 rawAmountA, uint96 rawAmountB) public {
        uint256 amountA = bound(uint256(rawAmountA), 1, 100 ether);
        uint256 amountB = bound(uint256(rawAmountB), 1, 100 ether);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        vm.deal(alice, amountA);
        vm.deal(bob, amountB);

        // Alice deposits
        vm.prank(alice);
        vault.deposit{value: amountA}();

        assertEq(vault.balances(alice), amountA);
        assertEq(vault.balances(bob), 0);
        assertEq(address(vault).balance, amountA);

        // Bob deposits
        vm.prank(bob);
        vault.deposit{value: amountB}();

        // Invariant: Alice's balance remains unchanged after Bob's deposit
        assertEq(vault.balances(alice), amountA);
        assertEq(vault.balances(bob), amountB);
        assertEq(address(vault).balance, amountA + amountB);
    }

    /// @dev Invariant: One user withdrawing cannot withdraw or drain another user's funds;
    ///      remaining depositor's balance must stay strictly solvent and intact.
    function testFuzzUserCannotWithdrawAnotherUsersFunds(uint96 rawAmountA, uint96 rawAmountB) public {
        uint256 amountA = bound(uint256(rawAmountA), 1, 100 ether);
        uint256 amountB = bound(uint256(rawAmountB), 1, 100 ether);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        vm.deal(alice, amountA);
        vm.deal(bob, amountB);

        vm.prank(alice);
        vault.deposit{value: amountA}();

        vm.prank(bob);
        vault.deposit{value: amountB}();

        uint256 aliceBalBeforeWithdraw = alice.balance;
        uint256 bobBalBeforeWithdraw = bob.balance;

        // Alice withdraws her entire balance
        vm.prank(alice);
        vault.withdraw();

        // Alice receives only amountA and her vault balance clears to 0
        assertEq(alice.balance, aliceBalBeforeWithdraw + amountA);
        assertEq(vault.balances(alice), 0);

        // Invariant: Bob's funds remain completely untouched and solvent in the vault
        assertEq(bob.balance, bobBalBeforeWithdraw);
        assertEq(vault.balances(bob), amountB);
        assertEq(address(vault).balance, amountB);

        // Bob can now also withdraw his funds cleanly
        vm.prank(bob);
        vault.withdraw();

        assertEq(bob.balance, bobBalBeforeWithdraw + amountB);
        assertEq(vault.balances(bob), 0);
        assertEq(address(vault).balance, 0);
    }
}
