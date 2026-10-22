// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FixedVault.sol";
import "../src/access-control/FixedFeeVault.sol";

/// @dev Test helper that records a vault balance but refuses incoming ETH.
contract RejectingEthReceiver {
    receive() external payable {
        revert("Reject ETH");
    }

    function depositToVault(FixedVault vault) external payable {
        vault.deposit{value: msg.value}();
    }

    function withdrawFromVault(FixedVault vault) external {
        vault.withdraw();
    }
}

contract TransferFailureTest is Test {
    uint256 private constant AMOUNT = 2 ether;

    function testFixedVaultWithdrawalRollsBackWhenReceiverRejectsEth() public {
        FixedVault vault = new FixedVault();
        RejectingEthReceiver receiver = new RejectingEthReceiver();

        vm.deal(address(this), AMOUNT);
        receiver.depositToVault{value: AMOUNT}(vault);

        uint256 vaultBalanceBefore = address(vault).balance;
        uint256 recordedBalanceBefore = vault.balances(address(receiver));
        uint256 receiverBalanceBefore = address(receiver).balance;

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Transfer failed"));
        receiver.withdrawFromVault(vault);

        // The external call failed, so the whole withdrawal transaction reverted.
        // The earlier effects in withdraw() must not leave stale accounting behind.
        assertEq(address(vault).balance, vaultBalanceBefore, "vault ETH should remain");
        assertEq(vault.balances(address(receiver)), recordedBalanceBefore, "deposit accounting should roll back");
        assertEq(address(receiver).balance, receiverBalanceBefore, "rejecting receiver should get no ETH");
    }

    function testFixedFeeVaultWithdrawalRollsBackWhenRecipientRejectsEth() public {
        RejectingEthReceiver receiver = new RejectingEthReceiver();
        FixedFeeVault vault = new FixedFeeVault(address(receiver));

        vm.deal(address(this), AMOUNT);
        vault.fund{value: AMOUNT}();

        uint256 vaultBalanceBefore = address(vault).balance;
        uint256 accruedFeesBefore = vault.accruedFees();
        uint256 ownerBalanceBefore = address(this).balance;
        uint256 recipientBalanceBefore = address(receiver).balance;

        vm.expectRevert(FixedFeeVault.TransferFailed.selector);
        vault.withdrawFees();

        // Resetting accruedFees happens before the external call, but must roll back
        // if the recipient rejects ETH and TransferFailed is raised.
        assertEq(address(vault).balance, vaultBalanceBefore, "fee ETH should remain");
        assertEq(vault.accruedFees(), accruedFeesBefore, "accrued fees should roll back");
        assertEq(address(this).balance, ownerBalanceBefore, "owner balance should not change");
        assertEq(address(receiver).balance, recipientBalanceBefore, "recipient should receive no ETH");
    }
}
