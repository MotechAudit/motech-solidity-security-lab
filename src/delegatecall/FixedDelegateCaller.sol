// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Educational example of a `delegatecall` whose implementation
///         storage layout is explicitly aligned with the caller's.
/// @dev This is not a production-ready proxy. It shows only the alignment
///      rule: the implementation must declare the same variables, in the
///      same order and with the same types, as the caller.
///
///      Storage layout (identical in FixedDelegateCaller and
///      FixedLibrary):
///        slot 0: address owner
///        slot 1: uint256 value
///
///      This caller additionally stores `implementation` in slot 2.
///      FixedLibrary never writes to slot 2, so that variable is safe,
///      but the alignment must be re-checked every time either contract
///      changes. For real proxies, prefer an established pattern such as
///      EIP-1967 / UUPS, and never delegatecall into untrusted code.
contract FixedDelegateCaller {
    address public owner;
    uint256 public value;
    address public implementation;

    constructor(address _implementation) {
        owner = msg.sender;
        implementation = _implementation;
    }

    function setValue(uint256 _value) external {
        // Safe here only because FixedLibrary's slot 0 is `owner` and
        // slot 1 is `value`, exactly like this caller.
        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        require(success, "delegatecall failed");
    }
}
