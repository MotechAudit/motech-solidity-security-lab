// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20CompatibilityVault} from "../src/erc20/SafeERC20CompatibilityVault.sol";
import {SafeAllowanceManager} from "../src/erc20/SafeAllowanceManager.sol";

/// @dev ERC-20-like token whose state-changing methods intentionally return no data.
contract MockNoReturnToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    error InsufficientBalance();
    error InsufficientAllowance();

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external {
        allowance[msg.sender][spender] = amount;
    }

    function transfer(address to, uint256 amount) external {
        _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external {
        uint256 approved = allowance[from][msg.sender];
        if (approved < amount) revert InsufficientAllowance();
        allowance[from][msg.sender] = approved - amount;
        _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (balanceOf[from] < amount) revert InsufficientBalance();
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}

/// @dev ERC-20 token that explicitly returns false from transfer and transferFrom.
contract MockFalseReturnToken is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address, uint256) external pure override returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) external pure override returns (bool) {
        return false;
    }
}

/// @dev Token that rejects changing a non-zero allowance directly to another non-zero value.
contract MockZeroFirstApprovalToken is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;

    error InsufficientBalance();
    error InsufficientAllowance();
    error MustResetAllowanceFirst();

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        if (allowance[msg.sender][spender] != 0 && amount != 0) {
            revert MustResetAllowanceFirst();
        }
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
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}

contract ERC20CompatibilityTest is Test {
    address private constant ALICE = address(0xA11CE);
    address private constant SPENDER = address(0xBEEF);
    address private constant STRANGER = address(0xBAD);

    function testSafeERC20SupportsTokenMethodsWithNoReturnData() public {
        MockNoReturnToken token = new MockNoReturnToken();
        SafeERC20CompatibilityVault vault =
            new SafeERC20CompatibilityVault(IERC20(address(token)));

        token.mint(ALICE, 100);
        vm.prank(ALICE);
        token.approve(address(vault), 100);

        vm.prank(ALICE);
        vault.deposit(100);

        assertEq(vault.credits(ALICE), 100);
        assertEq(vault.totalCredits(), 100);
        assertEq(token.balanceOf(address(vault)), 100);

        vm.prank(ALICE);
        vault.withdraw();

        assertEq(token.balanceOf(ALICE), 100);
        assertEq(vault.totalCredits(), 0);
        assertEq(token.balanceOf(address(vault)), 0);
    }

    function testSafeERC20RejectsExplicitFalseReturn() public {
        MockFalseReturnToken token = new MockFalseReturnToken();
        SafeERC20CompatibilityVault vault =
            new SafeERC20CompatibilityVault(IERC20(address(token)));

        token.mint(ALICE, 100);
        vm.prank(ALICE);
        token.approve(address(vault), 100);

        vm.expectRevert();
        vm.prank(ALICE);
        vault.deposit(100);

        assertEq(vault.credits(ALICE), 0);
        assertEq(vault.totalCredits(), 0);
        assertEq(token.balanceOf(address(vault)), 0);
    }

    function testForceApproveSupportsZeroFirstApprovalTokens() public {
        MockZeroFirstApprovalToken token = new MockZeroFirstApprovalToken();
        SafeAllowanceManager manager =
            new SafeAllowanceManager(IERC20(address(token)), address(this));

        manager.setSpenderAllowance(SPENDER, 100);
        assertEq(token.allowance(address(manager), SPENDER), 100);

        // A direct non-zero-to-non-zero approve would revert for this token.
        // forceApprove resets to zero and retries the requested allowance.
        manager.setSpenderAllowance(SPENDER, 250);
        assertEq(token.allowance(address(manager), SPENDER), 250);
    }

    function testOnlyOwnerCanChangeManagedAllowance() public {
        MockZeroFirstApprovalToken token = new MockZeroFirstApprovalToken();
        SafeAllowanceManager manager =
            new SafeAllowanceManager(IERC20(address(token)), address(this));

        vm.expectRevert(SafeAllowanceManager.Unauthorized.selector);
        vm.prank(STRANGER);
        manager.setSpenderAllowance(SPENDER, 100);

        assertEq(token.allowance(address(manager), SPENDER), 0);
    }
}
