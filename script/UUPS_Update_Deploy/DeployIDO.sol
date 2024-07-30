// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IDOlounchUpgradeable} from "../src/UUPS_Proxy/IDOlounchUpgradeable.sol";

contract DeployIDO is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address rntTokenAddress = vm.envAddress("RNT_TOKEN_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 部署实现合约
        IDOlounchUpgradeable implementation = new IDOlounchUpgradeable();

        // 编码初始化调用
        bytes memory data = abi.encodeWithSelector(IDOlounchUpgradeable.initialize.selector, rntTokenAddress);

        // 部署代理合约
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);

        console.log("IDO Contract deployed at:", address(proxy)); // 0xDB2685d0bA01D6BC9e888357013A89400153576F
        console.log("Implementation deployed at:", address(implementation)); // 0x26873FD54A4C5bC7f73BbF8571786649D9fDe808
        console.log("Current isIDOActive:", IDOlounchUpgradeable(payable(proxy)).isIDOActive());
        console.log("Current totalFundsRaised:", IDOlounchUpgradeable(payable(proxy)).totalFundsRaised());

        vm.stopBroadcast();
    }
}
