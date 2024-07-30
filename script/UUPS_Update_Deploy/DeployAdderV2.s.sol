// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {console, Script} from "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import {AdderUpgradeableV2} from "../../src/UUPS_Proxy/AdderUpgradeableV2.sol";

contract DeployAdderV2 is Script {
    function setUp() public {}

    // 第一种方案：使用底层方法进行升级
    // function run() external {
    //     uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    //     address proxyAddress = vm.envAddress("PROXY_ADDRESS");

    //     vm.startBroadcast(deployerPrivateKey);

    //     // 部署新的实现合约
    //     AdderUpgradeableV2 newImplementation = new AdderUpgradeableV2();

    //     // 获取代理合约的实例，但将其视为 UUPSUpgradeable
    //     UUPSUpgradeable proxy = UUPSUpgradeable(proxyAddress);

    //     // 执行升级
    //     proxy.upgradeToAndCall(address(newImplementation), "");

    //     // 验证升级
    //     AdderUpgradeableV2 upgradedProxy = AdderUpgradeableV2(proxyAddress);

    //     console.log("Upgrade completed");
    //     console.log("New implementation address:", address(newImplementation));
    //     console.log("Proxy address:", proxyAddress);
    //     console.log("Current total:", upgradedProxy.total());
    //     console.log("Times added:", upgradedProxy.timesAdded());

    //     vm.stopBroadcast();
    // }

    // 第二种方案：使用现成的Upgrades方法来实现
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployerAddress);

        vm.startBroadcast(deployerPrivateKey);

        Options memory opts;

        opts.unsafeSkipAllChecks = true;
        opts.referenceContract = "AdderUpgradeable.sol";

        Upgrades.upgradeProxy(proxyAddress, "AdderUpgradeableV2.sol", "", opts, deployerAddress);

        vm.stopBroadcast();
    }
}
