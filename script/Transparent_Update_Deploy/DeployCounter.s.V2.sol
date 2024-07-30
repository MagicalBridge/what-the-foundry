// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {CounterUpgradeableV2} from "../../src/Transparent_Proxy/CounterUpgradeableV2.sol";

contract DeployCounterV2 is Script {
    // 这些地址应该是之前部署时记录的地址
    address constant PROXY_ADDRESS = 0x9955cd930B1DB572Ac9e3Cd9D80919DB1C58C174; // 填入您的代理合约地址
    address constant PROXY_ADMIN_ADDRESS = 0xAf3c0dfA4949c720638F95ad8AB75d861641F005; // 填入您的 ProxyAdmin 地址

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        // 部署新版本的实现合约
        CounterUpgradeableV2 newImplementation = new CounterUpgradeableV2();
        console.log("New implementation deployed at:", address(newImplementation));

        // 假设已经有 ProxyAdmin 和 TransparentUpgradeableProxy 部署
        // 你需要用对应的地址替换下面的地址
        address proxyAdminAddress = 0xAf3c0dfA4949c720638F95ad8AB75d861641F005; // 替换为实际的 ProxyAdmin 地址
        address proxyAddress = 0x9955cd930B1DB572Ac9e3Cd9D80919DB1C58C174; // 替换为实际的 TransparentUpgradeableProxy 地址

        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        TransparentUpgradeableProxy proxy = TransparentUpgradeableProxy(payable(proxyAddress));

        // 升级代理合约到新的实现合约
        proxyAdmin.upgrade(proxy, address(newImplementation));

        vm.stopBroadcast();
    }
}
