// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AdderUpgradeable is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public total;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        total = 0;
    }

    function add(uint256 i) public {
        total += i;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
