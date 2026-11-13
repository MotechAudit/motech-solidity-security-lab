// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Educational example of the same payout guarded by OpenZeppelin SafeERC20.
/// @dev Not a production-ready distributor or a complete security audit.
/// Uses OpenZeppelin Contracts v5.0.2 (`SafeERC20`): the low-level call reverts
/// when a token returns `false`, and tolerates legacy tokens that return no data.
contract FixedTokenPayout {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    mapping(address => uint256) public earned;
    mapping(address => uint256) public paid;

    constructor(IERC20 _token) {
        token = _token;
    }

    /// @notice Credit `amount` of reward tokens to `user`.
    /// @dev No access control on purpose: this is a minimal teaching fixture,
    /// not a production distributor.
    function credit(address user, uint256 amount) external {
        earned[user] += amount;
    }

    /// @notice Pay out the caller's full earned balance.
    function claim() external {
        uint256 amount = earned[msg.sender];
        require(amount > 0, "Nothing to claim");

        // SafeERC20 performs a low-level call and checks the result: a `false`
        // return reverts with `SafeERC20FailedOperation`, and an empty return
        // (legacy no-return tokens) is accepted as success.
        token.safeTransfer(msg.sender, amount);

        paid[msg.sender] += amount;
        earned[msg.sender] = 0;
    }
}
