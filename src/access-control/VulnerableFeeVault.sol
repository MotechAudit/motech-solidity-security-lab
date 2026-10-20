// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Educational example of a missing access-control check.
/// @dev DO NOT deploy. setFeeRecipient() intentionally lacks onlyOwner.
contract VulnerableFeeVault {
    address public immutable owner;
    address public feeRecipient;
    uint256 public accruedFees;

    error InvalidRecipient();
    error NothingToWithdraw();
    error TransferFailed();
    error Unauthorized();

    constructor(address initialFeeRecipient) {
        if (initialFeeRecipient == address(0)) revert InvalidRecipient();
        owner = msg.sender;
        feeRecipient = initialFeeRecipient;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function fund() external payable {
        accruedFees += msg.value;
    }

    /// @notice Intentionally vulnerable: any caller can redirect future fee withdrawals.
    function setFeeRecipient(address newRecipient) external {
        if (newRecipient == address(0)) revert InvalidRecipient();
        feeRecipient = newRecipient;
    }

    function withdrawFees() external onlyOwner {
        uint256 amount = accruedFees;
        if (amount == 0) revert NothingToWithdraw();

        accruedFees = 0;
        (bool success, ) = payable(feeRecipient).call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}
