// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20Minimal} from "./IERC20Minimal.sol";

/// @notice Educational example of incorrect ERC-20 deposit accounting.
/// @dev DO NOT deploy. It credits the requested amount rather than the amount received.
contract VulnerableFeeOnTransferVault {
    IERC20Minimal public immutable token;

    mapping(address => uint256) public credits;
    uint256 public totalCredits;

    constructor(IERC20Minimal token_) {
        token = token_;
    }

    function deposit(uint256 requestedAmount) external {
        require(requestedAmount > 0, "Zero amount");
        require(token.transferFrom(msg.sender, address(this), requestedAmount), "Transfer failed");

        // Vulnerability: fee-on-transfer tokens may deliver less than requestedAmount.
        // The vault nevertheless creates a full-value credit for the depositor.
        credits[msg.sender] += requestedAmount;
        totalCredits += requestedAmount;
    }

    function withdraw() external {
        uint256 amount = credits[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        credits[msg.sender] = 0;
        totalCredits -= amount;

        require(token.transfer(msg.sender, amount), "Transfer failed");
    }
}
