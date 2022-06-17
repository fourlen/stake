// SPDX-License-Identifier: MIT


pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract testERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("testToken", "TEST") {
        _mint(msg.sender, initialSupply);
    }
}