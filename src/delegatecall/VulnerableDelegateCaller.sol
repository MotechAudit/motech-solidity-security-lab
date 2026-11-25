// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Educational demonstration of delegatecall storage-layout collision.
/// @dev DO NOT deploy. The owner is in slot 0, while the module's value is also in slot 0.
contract VulnerableDelegateCaller {
    address public owner;

    error Unauthorized();
    error DelegateCallFailed(bytes reason);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function delegateSetValue(address module, uint256 newValue) external onlyOwner {
        (bool success, bytes memory result) =
            module.delegatecall(abi.encodeWithSignature("setValue(uint256)", newValue));
        if (!success) revert DelegateCallFailed(result);
    }
}
