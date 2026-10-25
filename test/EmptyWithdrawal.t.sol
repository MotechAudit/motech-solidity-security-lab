// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FixedVault.sol";

/// @dev Regression tests for withdrawals when the caller has no recorded balance.
contract EmptyWithdrawalTest is Test {
    FixedVault private vault;

    function setUp() public {
        vault = new FixedVault();
    }

    function testEmptyVaultWithdrawalRevertsWithoutChangingBalances() public {
        address caller = makeAddr("empty-caller");
        vm.deal(caller, 1 ether);

        uint256 callerBalanceBefore = caller.balance;
        uint256 vaultBalanceBefore = address(vault).balance;

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Nothing to withdraw"));
        vm.prank(caller);
        vault.withdraw();

        // A failed withdrawal must not transfer ETH or create a balance entry.
        assertEq(caller.balance, callerBalanceBefore, "caller balance should remain");
        assertEq(address(vault).balance, vaultBalanceBefore, "vault balance should remain");
        assertEq(vault.balances(caller), 0, "caller must have no recorded balance");
    }

    function testCallerWithoutDepositCannotWithdrawAnotherUsersFunds() public {
        address depositor = makeAddr("funded-depositor");
        address caller = makeAddr("non-depositor");
        uint256 depositAmount = 2 ether;

        vm.deal(depositor, depositAmount);
        vm.deal(caller, 1 ether);

        vm.prank(depositor);
        vault.deposit{value: depositAmount}();

        uint256 callerBalanceBefore = caller.balance;
        uint256 vaultBalanceBefore = address(vault).balance;
        uint256 depositorBalanceBefore = vault.balances(depositor);

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Nothing to withdraw"));
        vm.prank(caller);
        vault.withdraw();

        // One user's lack of credit must not affect another user's deposit.
        assertEq(caller.balance, callerBalanceBefore, "caller balance should remain");
        assertEq(vault.balances(caller), 0, "caller must have no recorded balance");
        assertEq(vault.balances(depositor), depositorBalanceBefore, "depositor accounting should remain");
        assertEq(address(vault).balance, vaultBalanceBefore, "depositor funds should remain in vault");
    }
}
