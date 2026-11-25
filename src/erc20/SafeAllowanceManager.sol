// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Educational example of setting token allowances for a designated spender.
/// @dev Uses OpenZeppelin forceApprove for tokens that require a zero allowance before a non-zero update.
contract SafeAllowanceManager {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address public immutable owner;

    error Unauthorized();

    constructor(IERC20 token_, address owner_) {
        token = token_;
        owner = owner_;
    }

    function setSpenderAllowance(address spender, uint256 amount) external {
        if (msg.sender != owner) revert Unauthorized();
        token.forceApprove(spender, amount);
    }
}
