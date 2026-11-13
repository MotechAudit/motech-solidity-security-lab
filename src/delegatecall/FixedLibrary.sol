// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Implementation contract whose storage layout is deliberately
///         aligned with FixedDelegateCaller, slot for slot.
/// @dev This is a teaching example, not a production-ready proxy
///      implementation. The alignment below is the whole point: the
///      implementation must declare the caller's variables in the same
///      order and with the same types, so a `delegatecall` write lands on
///      the variable it was meant for.
///
///      Storage layout (identical in FixedLibrary and
///      FixedDelegateCaller):
///        slot 0: address owner
///        slot 1: uint256 value
///
///      FixedDelegateCaller additionally stores `implementation` in
///      slot 2, which this contract never writes to. Any future variable
///      added to the implementation must keep the shared slots aligned,
///      or the collision returns.
contract FixedLibrary {
    address public owner;
    uint256 public value;

    function setValue(uint256 _value) external {
        value = _value;
    }
}
