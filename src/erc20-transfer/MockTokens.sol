// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Mock tokens used only by the unchecked ERC-20 return-value example.
/// @dev Test doubles, not production tokens. All three expose the same
/// `transfer(address,uint256)` selector (0xa9059cbb) with different behavior:
/// standard success, silent `false`, and legacy no-return-data.
contract StandardToken {
    string public name = "Standard Mock Token";
    string public symbol = "STD";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}

/// @notice Non-standard token that reports failure by returning `false`
/// instead of reverting, and moves no tokens at all.
contract FalseReturnToken {
    string public name = "False Return Mock Token";
    string public symbol = "FLS";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address, uint256) external pure returns (bool) {
        // Non-standard behavior: silently reports failure instead of reverting,
        // and moves no tokens. A caller that ignores this return value believes
        // the transfer succeeded.
        return false;
    }
}

/// @notice Legacy-style token whose `transfer` returns no data at all,
/// like some tokens deployed before the ERC-20 return value was standard.
/// @dev The function has the same selector as ERC-20 `transfer`, but a
/// high-level call through the `IERC20` interface reverts on the empty
/// returndata, while OpenZeppelin `SafeERC20` tolerates it.
contract NoReturnToken {
    string public name = "No Return Mock Token";
    string public symbol = "NRT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        // No return value.
    }
}
