// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Educational vault showing safe calls to ERC-20 tokens with optional return data.
/// @dev Balance-delta accounting is included for fee-on-transfer behavior; this is not production-ready.
contract SafeERC20CompatibilityVault {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    mapping(address => uint256) public credits;
    uint256 public totalCredits;

    error ZeroReceived();

    constructor(IERC20 token_) {
        token = token_;
    }

    function deposit(uint256 requestedAmount) external {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), requestedAmount);
        uint256 received = token.balanceOf(address(this)) - balanceBefore;

        if (received == 0) revert ZeroReceived();

        credits[msg.sender] += received;
        totalCredits += received;
    }

    function withdraw() external {
        uint256 amount = credits[msg.sender];
        if (amount == 0) revert ZeroReceived();

        credits[msg.sender] = 0;
        totalCredits -= amount;

        token.safeTransfer(msg.sender, amount);
    }
}
