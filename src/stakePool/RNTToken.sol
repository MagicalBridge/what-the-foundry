// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RNTToken is ERC20 {
    constructor() ERC20("RNTToken", "RNT") {
        _mint(msg.sender, 1e10 * 1e18);
    }
}
