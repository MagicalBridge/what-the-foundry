// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {console, Script} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AdderUpgradeableV2} from "../src/UUPS_Proxy/AdderUpgradeableV2.sol";

contract DeployAdderV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 部署新的实现合约
        AdderUpgradeableV2 newImplementation = new AdderUpgradeableV2();

        // 获取代理合约的实例，但将其视为 UUPSUpgradeable
        UUPSUpgradeable proxy = UUPSUpgradeable(proxyAddress);

        // 执行升级
        proxy.upgradeToAndCall(address(newImplementation), "");

        // 验证升级
        AdderUpgradeableV2 upgradedProxy = AdderUpgradeableV2(proxyAddress);

        console.log("Upgrade completed");
        console.log("New implementation address:", address(newImplementation));
        console.log("Proxy address:", proxyAddress);
        console.log("Current total:", upgradedProxy.total());
        console.log("Times added:", upgradedProxy.timesAdded());

        vm.stopBroadcast();
    }
}
