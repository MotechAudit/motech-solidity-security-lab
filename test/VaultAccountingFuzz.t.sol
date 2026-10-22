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

    function testFuzzDepositKeepsVaultBalanceAndAccountingConsistent(
        uint96 rawAmount
    ) public {
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
        assertEq(
            vault.balances(depositor),
            recordedBalanceBefore + amount
        );
    }

    function testFuzzWithdrawalClearsAccountingAndReturnsRecordedAmount(
        uint96 rawAmount
    ) public {
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
        assertEq(
            depositor.balance,
            depositorBalanceBeforeWithdrawal + amount
        );
        assertEq(address(vault).balance, vaultBalanceBeforeWithdrawal - amount);
        assertEq(vault.balances(depositor), 0);
    }
}
