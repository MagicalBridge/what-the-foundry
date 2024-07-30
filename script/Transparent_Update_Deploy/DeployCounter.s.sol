// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {CounterUpgradeable} from "../../src/Transparent_Proxy/CounterUpgradeable.sol";

contract DeployCounter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        // 部署实现合约
        CounterUpgradeable counter = new CounterUpgradeable();

        // 部署代理管理合约
        ProxyAdmin proxyAdmin = new ProxyAdmin(deployer);

        // 部署代理合约
        bytes memory initializeData = abi.encodeWithSignature("initialize()");
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(counter), address(proxyAdmin), initializeData);

        vm.stopBroadcast();

        console.log("Proxy deployed to:", address(proxy)); // 0x9955cd930B1DB572Ac9e3Cd9D80919DB1C58C174
        console.log("ProxyAdmin deployed to:", address(proxyAdmin)); // 0xAf3c0dfA4949c720638F95ad8AB75d861641F005
        console.log("CounterV1 deployed to:", address(counter)); // 0xD694053aB8a9d281A5170b88Ff56955502682531
    }
}
