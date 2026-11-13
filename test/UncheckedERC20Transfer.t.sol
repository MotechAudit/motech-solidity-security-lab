// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../src/erc20-transfer/MockTokens.sol";
import "../src/erc20-transfer/VulnerableTokenPayout.sol";
import "../src/erc20-transfer/FixedTokenPayout.sol";

/// @notice Tests prove whether token balances actually moved, not only whether
/// a payout function returned. The vulnerable payout silently records a
/// payment for a token that returned `false`; the SafeERC20 payout reverts
/// instead and leaves accounting untouched.
contract UncheckedERC20TransferTest is Test {
    address private constant USER = address(0xA11CE);
    uint256 private constant REWARD = 100 ether;

    function testVulnerablePayoutSilentlyMarksFalseReturnTokenAsPaid() public {
        FalseReturnToken token = new FalseReturnToken();
        VulnerableTokenPayout payout = new VulnerableTokenPayout(IERC20(address(token)));

        token.mint(address(payout), REWARD);
        payout.credit(USER, REWARD);

        vm.prank(USER);
        payout.claim();

        // Accounting says the user was paid in full...
        assertEq(payout.paid(USER), REWARD, "vulnerable payout records full payment");
        assertEq(payout.earned(USER), 0, "vulnerable payout clears earned balance");
        // ...but no tokens ever moved. The reward is now unclaimable: earned is
        // zero, yet the user received nothing.
        assertEq(token.balanceOf(USER), 0, "user received no tokens");
        assertEq(token.balanceOf(address(payout)), REWARD, "payout still holds the tokens");
    }

    function testVulnerablePayoutPaysStandardToken() public {
        StandardToken token = new StandardToken();
        VulnerableTokenPayout payout = new VulnerableTokenPayout(IERC20(address(token)));

        token.mint(address(payout), REWARD);
        payout.credit(USER, REWARD);

        vm.prank(USER);
        payout.claim();

        // With a well-behaved token the vulnerable code happens to work: the
        // bug only manifests with non-standard return behavior.
        assertEq(token.balanceOf(USER), REWARD, "user receives the reward");
        assertEq(token.balanceOf(address(payout)), 0, "payout is drained");
        assertEq(payout.paid(USER), REWARD, "payment is recorded");
    }

    function testFixedPayoutRevertsOnFalseReturnToken() public {
        FalseReturnToken token = new FalseReturnToken();
        FixedTokenPayout payout = new FixedTokenPayout(IERC20(address(token)));

        token.mint(address(payout), REWARD);
        payout.credit(USER, REWARD);

        vm.expectRevert(
            abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(token))
        );
        vm.prank(USER);
        payout.claim();

        // The whole claim reverted, so accounting is untouched and the user can
        // still claim once the payout is funded with a working token.
        assertEq(payout.earned(USER), REWARD, "earned balance must survive the revert");
        assertEq(payout.paid(USER), 0, "nothing is recorded as paid");
        assertEq(token.balanceOf(USER), 0, "user received no tokens");
        assertEq(token.balanceOf(address(payout)), REWARD, "payout still holds the tokens");
    }

    function testFixedPayoutPaysStandardToken() public {
        StandardToken token = new StandardToken();
        FixedTokenPayout payout = new FixedTokenPayout(IERC20(address(token)));

        token.mint(address(payout), REWARD);
        payout.credit(USER, REWARD);

        vm.prank(USER);
        payout.claim();

        assertEq(token.balanceOf(USER), REWARD, "user receives the reward");
        assertEq(token.balanceOf(address(payout)), 0, "payout is drained");
        assertEq(payout.paid(USER), REWARD, "payment is recorded");
    }

    function testFixedPayoutPaysLegacyNoReturnToken() public {
        NoReturnToken token = new NoReturnToken();
        FixedTokenPayout payout = new FixedTokenPayout(IERC20(address(token)));

        token.mint(address(payout), REWARD);
        payout.credit(USER, REWARD);

        vm.prank(USER);
        payout.claim();

        // SafeERC20 tolerates the empty returndata of legacy tokens.
        assertEq(token.balanceOf(USER), REWARD, "user receives the reward");
        assertEq(token.balanceOf(address(payout)), 0, "payout is drained");
        assertEq(payout.paid(USER), REWARD, "payment is recorded");
    }

    function testVulnerablePayoutRevertsOnLegacyNoReturnToken() public {
        NoReturnToken token = new NoReturnToken();
        VulnerableTokenPayout payout = new VulnerableTokenPayout(IERC20(address(token)));

        token.mint(address(payout), REWARD);
        payout.credit(USER, REWARD);

        // The naive call goes through the IERC20 interface, which expects a
        // 32-byte bool return. Empty returndata makes the ABI decoding revert,
        // so this failure is loud, not silent — but the payout still cannot
        // serve legacy tokens at all.
        vm.expectRevert();
        vm.prank(USER);
        payout.claim();

        assertEq(payout.earned(USER), REWARD, "earned balance must survive the revert");
        assertEq(payout.paid(USER), 0, "nothing is recorded as paid");
        assertEq(token.balanceOf(USER), 0, "user received no tokens");
    }
}
