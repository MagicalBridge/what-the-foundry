// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AdderUpgradeable} from "../src/AdderUpgradeable.sol";

contract DeployAdder is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 部署一个新的AdderUpgradeable合约
        AdderUpgradeable implementation = new AdderUpgradeable();
        bytes memory initializeData = abi.encodeWithSelector(AdderUpgradeable.initialize.selector);
        // 部署一个新的ERC1967Proxy，指向AdderUpgradeable合约
        // 并初始化AdderUpgradeable的initialize函数
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initializeData);

        AdderUpgradeable(address(proxy)).add(10);

        console.log("Adder deployed at:", address(proxy));
        console.log("Implementation deployed at:", address(implementation));
        console.log("Current total:", AdderUpgradeable(address(proxy)).total());

        vm.stopBroadcast();
    }
}
