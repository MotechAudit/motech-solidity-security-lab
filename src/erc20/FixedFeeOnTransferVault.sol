// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20Minimal} from "./IERC20Minimal.sol";

/// @notice Educational example that credits the amount an ERC-20 vault actually receives.
/// @dev This addresses fee-on-transfer accounting; it is not a complete production vault.
contract FixedFeeOnTransferVault {
    IERC20Minimal public immutable token;

    mapping(address => uint256) public credits;
    uint256 public totalCredits;

    error ZeroAmount();
    error TransferFailed();

    constructor(IERC20Minimal token_) {
        token = token_;
    }

    function deposit(uint256 requestedAmount) external {
        if (requestedAmount == 0) revert ZeroAmount();

        uint256 balanceBefore = token.balanceOf(address(this));
        if (!token.transferFrom(msg.sender, address(this), requestedAmount)) {
            revert TransferFailed();
        }
        uint256 balanceAfter = token.balanceOf(address(this));

        // Account for the amount delivered, not the nominal transfer request.
        uint256 received = balanceAfter - balanceBefore;
        if (received == 0) revert ZeroAmount();

        credits[msg.sender] += received;
        totalCredits += received;
    }

    function withdraw() external {
        uint256 amount = credits[msg.sender];
        if (amount == 0) revert ZeroAmount();

        // Update accounting before the external token transfer.
        credits[msg.sender] = 0;
        totalCredits -= amount;

        if (!token.transfer(msg.sender, amount)) revert TransferFailed();
    }
}
