// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ERC20.sol";

contract KingToken is ERC20 {
    uint256 public _totalSupply;
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {
        _mint(msg.sender, initialSupply * 10 ** uint256(decimals));
        _totalSupply = initialSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return 0;
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return 0;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        return false;
    }
}
