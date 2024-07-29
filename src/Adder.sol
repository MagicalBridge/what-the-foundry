// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract Adder {
    uint256 public total;

    constructor() {
        total = 0;
    }

    function add(uint256 i) public {
        total += i;
    }
}
