// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Library/implementation contract with a storage layout that does
///         NOT match the caller that delegatecalls into it.
/// @dev DO NOT deploy or use in production. This contract is only safe to
///      call directly; when it is reached through `delegatecall`, its writes
///      land on the CALLER's storage slots, not on its own storage.
///
///      Storage layout of THIS contract (its own view):
///        slot 0: uint256 storedValue
///
///      Storage layout of VulnerableDelegateCaller (the contract that
///      delegatecalls into this one):
///        slot 0: address owner
///        slot 1: uint256 value
///        slot 2: address implementation
///
///      `setValue` writes to slot 0. In the caller's storage, slot 0 is
///      `owner`, so the call overwrites the caller owner instead of
///      updating any value.
contract VulnerableLibrary {
    uint256 public storedValue;

    function setValue(uint256 _value) external {
        storedValue = _value;
    }
}
