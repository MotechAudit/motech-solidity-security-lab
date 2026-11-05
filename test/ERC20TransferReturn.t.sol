// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {VulnerableTokenPayout} from "../src/erc20/VulnerableTokenPayout.sol";
import {FixedTokenPayout} from "../src/erc20/FixedTokenPayout.sol";
import {StandardMockToken, FalseReturnMockToken} from "./mocks/MockReturnTokens.sol";

contract ERC20TransferReturnTest is Test {
    address private constant RECIPIENT = address(0xBEEF);
    uint256 private constant AMOUNT = 100 ether;

    function testVulnerablePayoutRecordsPaymentWhenTokenReturnsFalse() public {
        FalseReturnMockToken token = new FalseReturnMockToken();
        VulnerableTokenPayout payout = new VulnerableTokenPayout();
        token.mint(address(payout), AMOUNT);

        payout.payout(token, RECIPIENT, AMOUNT);

        // The call did not revert, but the mock moved no tokens.
        assertEq(token.balanceOf(address(payout)), AMOUNT, "vault should still hold tokens");
        assertEq(token.balanceOf(RECIPIENT), 0, "recipient should receive no tokens");
        assertEq(payout.paidOut(RECIPIENT), AMOUNT, "vulnerable accounting falsely records payment");
    }

    function testFixedPayoutRevertsWhenTokenReturnsFalse() public {
        FalseReturnMockToken token = new FalseReturnMockToken();
        FixedTokenPayout payout = new FixedTokenPayout();
        token.mint(address(payout), AMOUNT);

        vm.expectRevert(
            abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(token))
        );
        payout.payout(token, RECIPIENT, AMOUNT);

        assertEq(token.balanceOf(address(payout)), AMOUNT, "vault tokens should remain");
        assertEq(token.balanceOf(RECIPIENT), 0, "recipient should receive no tokens");
        assertEq(payout.paidOut(RECIPIENT), 0, "accounting must remain unchanged");
    }

    function testFixedPayoutTransfersStandardTokenAndRecordsPayment() public {
        StandardMockToken token = new StandardMockToken();
        FixedTokenPayout payout = new FixedTokenPayout();
        token.mint(address(payout), AMOUNT);

        payout.payout(token, RECIPIENT, AMOUNT);

        assertEq(token.balanceOf(address(payout)), 0, "vault should send its tokens");
        assertEq(token.balanceOf(RECIPIENT), AMOUNT, "recipient should receive tokens");
        assertEq(payout.paidOut(RECIPIENT), AMOUNT, "successful payout should be recorded");
    }

    function testVulnerablePayoutWorksWithStandardToken() public {
        StandardMockToken token = new StandardMockToken();
        VulnerableTokenPayout payout = new VulnerableTokenPayout();
        token.mint(address(payout), AMOUNT);

        payout.payout(token, RECIPIENT, AMOUNT);

        assertEq(token.balanceOf(address(payout)), 0);
        assertEq(token.balanceOf(RECIPIENT), AMOUNT);
        assertEq(payout.paidOut(RECIPIENT), AMOUNT);
    }
}
