// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @notice Educational example of an ERC-20 integration that ignores transfer's return value.
/// @dev A token may return false without reverting. This contract can then record a payout
///      that never happened. Do not use this example in production.
contract VulnerableTokenPayout {
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
        // BUG: The returned bool is ignored. A false-return token can make this look successful.
        token.transfer(recipient, amount);
        paidOut[recipient] += amount;
    }
}
