// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/ERC20.sol";

contract DamnValuableToken is ERC20 {
    constructor() ERC20("DamnValuableToken", "DVT") {
        _mint(msg.sender, type(uint256).max);
    }
}