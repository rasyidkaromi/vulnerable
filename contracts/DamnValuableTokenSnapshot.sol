// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/ERC20.sol";

contract DamnValuableTokenSnapshot is ERC20Snapshot {
    uint256 private lastSnapshotId;

    constructor(uint256 initialSupply) ERC20("DamnValuableToken", "DVT") {
        _mint(msg.sender, initialSupply);
    }

    function snapshot() public returns (uint256) {
        lastSnapshotId = _snapshot();
        return lastSnapshotId;
    }

    function getBalanceAtLastSnapshot(address account) external view returns (uint256) {
        return balanceOfAt(account, lastSnapshotId);
    }

    function getTotalSupplyAtLastSnapshot() external view returns (uint256) {
        return totalSupplyAt(lastSnapshotId);
    }
}
