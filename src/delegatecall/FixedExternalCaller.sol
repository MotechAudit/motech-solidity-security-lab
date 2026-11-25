// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Safer comparison: invoke the module with a normal external call.
/// @dev The module writes to its own storage; this is not a general-purpose proxy design.
contract FixedExternalCaller {
    address public owner;

    error Unauthorized();
    error ExternalCallFailed(bytes reason);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function callModule(address module, uint256 newValue) external onlyOwner {
        (bool success, bytes memory result) =
            module.call(abi.encodeWithSignature("setValue(uint256)", newValue));
        if (!success) revert ExternalCallFailed(result);
    }
}
