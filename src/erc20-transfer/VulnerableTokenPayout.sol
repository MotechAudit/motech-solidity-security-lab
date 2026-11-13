// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Educational example of an unchecked ERC-20 transfer return value.
/// @dev DO NOT deploy. `claim()` trusts that `transfer` moved the tokens and
/// updates accounting either way, so a token that returns `false` can make the
/// payout look paid while no tokens moved.
contract VulnerableTokenPayout {
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

        // Vulnerability: the bool returned by `transfer` is ignored. Some
        // tokens return `false` instead of reverting, so this line can
        // "succeed" while moving no tokens — yet the accounting below still
        // records a payment.
        token.transfer(msg.sender, amount);

        paid[msg.sender] += amount;
        earned[msg.sender] = 0;
    }
}
