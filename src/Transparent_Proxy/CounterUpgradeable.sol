// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CounterUpgradeable is Initializable {
    uint256 public count;

    function initialize() public initializer {
        count = 0;
    }

    function increment() public {
        count += 1;
    }
}
