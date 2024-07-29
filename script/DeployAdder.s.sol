// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Adder} from "../src/Adder.sol";

contract DeployAdder is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address admin = msg.sender;
        // 部署逻辑合约
        Adder adder = new Adder();

        // 输出代理合约地址
        console.log("TransparentProxy deployed to:");

        vm.stopBroadcast();
    }
}
