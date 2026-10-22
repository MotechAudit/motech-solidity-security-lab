// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Educational example of unsafe tx.origin authorization.
/// @dev DO NOT deploy. An owner can be tricked into calling a malicious forwarder.
contract VulnerableTxOriginWallet {
    address public immutable owner;

    error Unauthorized();
    error TransferFailed();

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function withdrawTo(address payable recipient, uint256 amount) external {
        // Vulnerability: tx.origin is the transaction initiator, not the immediate caller.
        if (tx.origin != owner) revert Unauthorized();

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}
