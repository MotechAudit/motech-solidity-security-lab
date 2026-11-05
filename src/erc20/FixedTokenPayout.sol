// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Educational example that safely handles ERC-20 transfer return values.
/// @dev SafeERC20 reverts when a token explicitly returns false and supports tokens that
///      return no data, provided the call itself does not revert. It cannot make a malicious
///      or economically unusual token trustworthy; token behavior still needs review.
contract FixedTokenPayout {
    using SafeERC20 for IERC20;

    address public immutable owner;
    mapping(address => uint256) public paidOut;

    error Unauthorized();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function payout(IERC20 token, address recipient, uint256 amount) external onlyOwner {
        // Transfer first. If it fails, SafeERC20 reverts and accounting is not updated.
        token.safeTransfer(recipient, amount);
        paidOut[recipient] += amount;
    }
}
