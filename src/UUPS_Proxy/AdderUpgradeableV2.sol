// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AdderUpgradeableV2 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public total;
    uint256 public timesAdded; // 新增的状态变量

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        total = 0;
        timesAdded = 0;
    }

    function add(uint256 i) public {
        total += i;
        timesAdded += 1; // 新增的功能
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
