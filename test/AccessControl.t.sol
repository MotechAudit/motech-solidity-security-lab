// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/access-control/VulnerableFeeVault.sol";
import "../src/access-control/FixedFeeVault.sol";

contract AccessControlTest is Test {
    receive() external payable {}

    address private constant ATTACKER = address(0xBEEF);
    uint256 private constant FEES = 10 ether;

    function testAnyoneCanRedirectFeesInVulnerableVault() public {
        vm.deal(address(this), FEES);
        vm.deal(ATTACKER, 1 ether);

        VulnerableFeeVault vault = new VulnerableFeeVault(address(this));
        vault.fund{value: FEES}();

        uint256 attackerBalanceBefore = ATTACKER.balance;

        // The missing onlyOwner check lets an arbitrary caller redirect the fees.
        vm.prank(ATTACKER);
        vault.setFeeRecipient(ATTACKER);

        assertEq(vault.feeRecipient(), ATTACKER);

        // The owner performs the normal withdrawal, but funds now go to the attacker.
        vault.withdrawFees();

        assertEq(ATTACKER.balance, attackerBalanceBefore + FEES);
        assertEq(vault.accruedFees(), 0);
    }

    function testNonOwnerCannotRedirectFeesInFixedVault() public {
        vm.deal(address(this), FEES);
        vm.deal(ATTACKER, 1 ether);

        FixedFeeVault vault = new FixedFeeVault(address(this));
        vault.fund{value: FEES}();

        uint256 attackerBalanceBefore = ATTACKER.balance;
        uint256 ownerBalanceBeforeWithdrawal = address(this).balance;

        vm.expectRevert(FixedFeeVault.Unauthorized.selector);
        vm.prank(ATTACKER);
        vault.setFeeRecipient(ATTACKER);

        assertEq(vault.feeRecipient(), address(this));

        vault.withdrawFees();

        assertEq(address(this).balance, ownerBalanceBeforeWithdrawal + FEES);
        assertEq(ATTACKER.balance, attackerBalanceBefore);
        assertEq(vault.accruedFees(), 0);
    }
}
