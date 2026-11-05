// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @dev Conventional ERC-20 mock used to demonstrate a successful transfer.
contract StandardMockToken is ERC20 {
    constructor() ERC20("Standard Mock Token", "SMT") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

/// @dev Non-standard mock that explicitly returns false and moves no tokens.
contract FalseReturnMockToken is ERC20 {
    constructor() ERC20("False Return Mock Token", "FRT") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function transfer(address, uint256) public pure override returns (bool) {
        return false;
    }
}
