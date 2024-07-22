// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {LouisToken} from "../src/LouisToken.sol";

contract MyTokenScript is Script {
    LouisToken public louistoken;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        louistoken = new LouisToken("LouisTestToken", "LTT");

        console.log("MyToken deployed to:", address(louistoken));

        vm.stopBroadcast();
    }
}
