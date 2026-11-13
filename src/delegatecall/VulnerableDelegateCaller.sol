// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Educational example of an unsafe `delegatecall` into a contract
///         whose storage layout does not match the caller's.
/// @dev DO NOT deploy. `delegatecall` runs the implementation's code in the
///      CALLER's storage context, so a layout mismatch silently overwrites
///      the caller's own variables.
///
///      Storage layout of this caller:
///        slot 0: address owner
///        slot 1: uint256 value
///        slot 2: address implementation
///
///      Storage layout of VulnerableLibrary (the implementation):
///        slot 0: uint256 storedValue
///
///      Calling `setValue` delegatecalls `VulnerableLibrary.setValue`,
///      which writes to slot 0. In this caller, slot 0 holds `owner`,
///      so the owner is replaced by the supplied number and `value`
///      (slot 1) is never updated.
contract VulnerableDelegateCaller {
    address public owner;
    uint256 public value;
    address public implementation;

    constructor(address _implementation) {
        owner = msg.sender;
        implementation = _implementation;
    }

    function setValue(uint256 _value) external {
        // Vulnerability: the implementation's slot 0 is a uint256, while
        // this caller's slot 0 is the owner address. The write lands on
        // the wrong variable.
        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        require(success, "delegatecall failed");
    }
}
