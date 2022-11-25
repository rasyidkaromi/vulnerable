// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/ERC20.sol";
import "../lib/ReentrancyGuard.sol";

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}

contract UnstoppableLender is ReentrancyGuard {

    IERC20 public immutable damnValuableToken;
    uint256 public poolBalance;

    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        damnValuableToken = IERC20(tokenAddress);
    }

    function depositTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Must deposit at least one token");
        damnValuableToken.transferFrom(msg.sender, address(this), amount);
        poolBalance = poolBalance + amount;
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
        require(borrowAmount > 0, "Must borrow at least one token");

        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        assert(poolBalance == balanceBefore);
        damnValuableToken.transfer(msg.sender, borrowAmount);
        IReceiver(msg.sender).receiveTokens(address(damnValuableToken), borrowAmount);
        
        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }
}
