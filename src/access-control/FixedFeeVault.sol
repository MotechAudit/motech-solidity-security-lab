// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Educational example demonstrating an owner-only privileged setter.
/// @dev Illustrates one access-control fix; this is not a production-ready vault.
contract FixedFeeVault {
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

    /// @notice Only the owner can change where accrued fees will be sent.
    function setFeeRecipient(address newRecipient) external onlyOwner {
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
