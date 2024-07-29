// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script, console} from "forge-std/Script.sol";
import {IDOlounchUpgradeableV2} from "../src/UUPS_Proxy/IDOlounchUpgradeableV2.sol";

contract DeployIDOV2 is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("IDO_PROXY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 部署新的【实现合约】
        IDOlounchUpgradeableV2 newImplementation = new IDOlounchUpgradeableV2();

        // 获取代理合约的实现
        UUPSUpgradeable proxy = UUPSUpgradeable(proxyAddress);

        // 执行升级操作
        proxy.upgradeToAndCall(address(newImplementation), "");

        // 调用新的函数, 获取maxContribution值
        uint256 newValue = IDOlounchUpgradeableV2(payable(proxyAddress)).get_MAX_CONTRIBUTION();

        console.log("MAX_CONTRIBUTION:", newValue);
        console.log("IDO Contract deployed at:", address(proxy)); // 0xDB2685d0bA01D6BC9e888357013A89400153576F
        console.log("Implementation deployed at:", address(newImplementation)); // 0x0301e38a6f67dB83c84db4b67748a9142D120B77

        vm.stopBroadcast();
    }
}
