// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Educational module whose first state variable occupies storage slot 0.
/// @dev Its layout is intentionally incompatible with VulnerableDelegateCaller.
contract StorageCollisionModule {
    uint256 public value;

    function setValue(uint256 newValue) external {
        value = newValue;
    }
}
