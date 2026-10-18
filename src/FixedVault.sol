// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Educational example of a basic reentrancy mitigation pattern.
/// @dev This is not a production-ready vault or a complete audit.
contract FixedVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // Effect: update accounting before transferring control externally.
        balances[msg.sender] = 0;

        // Interaction: make the external call only after state is updated.
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
