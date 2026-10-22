// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Educational example using the immediate caller for owner authorization.
/// @dev Not a production-ready wallet or a complete security audit.
contract FixedOwnerWallet {
    address public immutable owner;

    error Unauthorized();
    error InvalidRecipient();
    error TransferFailed();

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function withdrawTo(address payable recipient, uint256 amount) external {
        if (msg.sender != owner) revert Unauthorized();
        if (recipient == address(0)) revert InvalidRecipient();

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}
