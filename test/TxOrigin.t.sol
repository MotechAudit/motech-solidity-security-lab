// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tx-origin/VulnerableTxOriginWallet.sol";
import "../src/tx-origin/FixedOwnerWallet.sol";

contract TxOriginForwarder {
    function forwardToVulnerable(
        VulnerableTxOriginWallet wallet,
        address payable recipient,
        uint256 amount
    ) external {
        wallet.withdrawTo(recipient, amount);
    }

    function forwardToFixed(
        FixedOwnerWallet wallet,
        address payable recipient,
        uint256 amount
    ) external {
        wallet.withdrawTo(recipient, amount);
    }
}

contract TxOriginTest is Test {
    address private constant ATTACKER = address(0xBEEF);
    uint256 private constant FUNDS = 5 ether;

    function testTxOriginAuthorizationCanBeAbusedThroughForwarder() public {
        VulnerableTxOriginWallet wallet = new VulnerableTxOriginWallet();
        TxOriginForwarder forwarder = new TxOriginForwarder();

        vm.deal(address(wallet), FUNDS);
        vm.deal(ATTACKER, 1 ether);
        uint256 attackerBalanceBefore = ATTACKER.balance;

        // Simulate the owner initiating a call to a malicious intermediary.
        vm.prank(address(this), address(this));
        forwarder.forwardToVulnerable(wallet, payable(ATTACKER), FUNDS);

        assertEq(address(wallet).balance, 0, "wallet should be drained in this demo");
        assertEq(ATTACKER.balance, attackerBalanceBefore + FUNDS, "recipient gets wallet funds");
    }

    function testMsgSenderAuthorizationBlocksForwarder() public {
        FixedOwnerWallet wallet = new FixedOwnerWallet();
        TxOriginForwarder forwarder = new TxOriginForwarder();

        vm.deal(address(wallet), FUNDS);
        vm.deal(ATTACKER, 1 ether);
        uint256 attackerBalanceBefore = ATTACKER.balance;

        vm.expectRevert(FixedOwnerWallet.Unauthorized.selector);
        vm.prank(address(this), address(this));
        forwarder.forwardToFixed(wallet, payable(ATTACKER), FUNDS);

        assertEq(address(wallet).balance, FUNDS, "wallet funds should remain");
        assertEq(ATTACKER.balance, attackerBalanceBefore, "attacker should receive nothing");
    }
}
