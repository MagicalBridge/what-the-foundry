// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CounterUpgradeableV2 is Initializable {
    uint256 public count;
    bool public flag;

    function initialize() public initializer {
        count = 0;
    }

    function increment() public {
        count += 1;
    }

    function getFlagStatus() public view returns (bool) {
        return flag;
    }
}
