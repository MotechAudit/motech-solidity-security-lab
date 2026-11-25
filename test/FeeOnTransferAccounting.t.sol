// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {IERC20Minimal} from "../src/erc20/IERC20Minimal.sol";
import {VulnerableFeeOnTransferVault} from "../src/erc20/VulnerableFeeOnTransferVault.sol";
import {FixedFeeOnTransferVault} from "../src/erc20/FixedFeeOnTransferVault.sol";

/// @dev Test token that burns 10% of every transfer to model a fee-on-transfer ERC-20.
contract MockFeeOnTransferToken is IERC20Minimal {
    uint256 public constant FEE_BPS = 1_000;
    uint256 public constant BPS = 10_000;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    error InsufficientBalance();
    error InsufficientAllowance();

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 approved = allowance[from][msg.sender];
        if (approved < amount) revert InsufficientAllowance();
        allowance[from][msg.sender] = approved - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (balanceOf[from] < amount) revert InsufficientBalance();

        uint256 fee = (amount * FEE_BPS) / BPS;
        balanceOf[from] -= amount;
        balanceOf[to] += amount - fee;
        // The fee is burned, so the vault receives less than the requested amount.
    }
}

contract FeeOnTransferAccountingTest is Test {
    address private constant ALICE = address(0xA11CE);
    address private constant BOB = address(0xB0B);

    function testVulnerableVaultOverCreditsAndBecomesInsolvent() public {
        MockFeeOnTransferToken token = new MockFeeOnTransferToken();
        VulnerableFeeOnTransferVault vault = new VulnerableFeeOnTransferVault(IERC20Minimal(address(token)));

        _fundAndApprove(token, address(vault), ALICE, 100);
        _fundAndApprove(token, address(vault), BOB, 100);

        vm.prank(ALICE);
        vault.deposit(100);
        vm.prank(BOB);
        vault.deposit(100);

        // Each 100-token deposit delivers only 90, but each depositor is credited 100.
        assertEq(vault.totalCredits(), 200, "nominal credits should total 200");
        assertEq(token.balanceOf(address(vault)), 180, "vault receives only 180");

        // The first withdrawal is paid, leaving fewer tokens than the second user's credit.
        vm.prank(ALICE);
        vault.withdraw();

        assertEq(token.balanceOf(address(vault)), 80, "only 80 tokens remain");
        vm.expectRevert(MockFeeOnTransferToken.InsufficientBalance.selector);
        vm.prank(BOB);
        vault.withdraw();

        // The failed withdrawal rolls back, leaving Bob's unbacked credit recorded.
        assertEq(vault.credits(BOB), 100, "Bob still has an unbacked 100-token credit");
    }

    function testFixedVaultCreditsOnlyTheAmountActuallyReceived() public {
        MockFeeOnTransferToken token = new MockFeeOnTransferToken();
        FixedFeeOnTransferVault vault = new FixedFeeOnTransferVault(IERC20Minimal(address(token)));

        _fundAndApprove(token, address(vault), ALICE, 100);
        _fundAndApprove(token, address(vault), BOB, 100);

        vm.prank(ALICE);
        vault.deposit(100);
        vm.prank(BOB);
        vault.deposit(100);

        assertEq(vault.credits(ALICE), 90, "Alice is credited the 90 received");
        assertEq(vault.credits(BOB), 90, "Bob is credited the 90 received");
        assertEq(vault.totalCredits(), 180, "total credits match received assets");
        assertEq(token.balanceOf(address(vault)), 180, "vault assets back all credits");

        vm.prank(ALICE);
        vault.withdraw();
        vm.prank(BOB);
        vault.withdraw();

        assertEq(vault.totalCredits(), 0, "all credits are cleared");
        assertEq(token.balanceOf(address(vault)), 0, "both withdrawals are fully backed");
        assertEq(token.balanceOf(ALICE), 81, "outgoing transfer fee is borne by recipient");
        assertEq(token.balanceOf(BOB), 81, "outgoing transfer fee is borne by recipient");
    }

    function testFuzzFixedVaultCreditsTheBalanceDelta(uint96 requestedAmount) public {
        vm.assume(requestedAmount > 0);

        MockFeeOnTransferToken token = new MockFeeOnTransferToken();
        FixedFeeOnTransferVault vault = new FixedFeeOnTransferVault(IERC20Minimal(address(token)));

        token.mint(ALICE, requestedAmount);
        vm.prank(ALICE);
        token.approve(address(vault), requestedAmount);

        vm.prank(ALICE);
        vault.deposit(requestedAmount);

        uint256 expectedReceived = requestedAmount - ((uint256(requestedAmount) * token.FEE_BPS()) / token.BPS());
        assertEq(vault.credits(ALICE), expectedReceived);
        assertEq(token.balanceOf(address(vault)), expectedReceived);
    }

    function _fundAndApprove(
        MockFeeOnTransferToken token,
        address spender,
        address account,
        uint256 amount
    ) internal {
        token.mint(account, amount);
        vm.prank(account);
        token.approve(spender, amount);
    }
}
