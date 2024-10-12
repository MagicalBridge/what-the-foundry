// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../src/HTX-bonus/InviteAndDividendUpgradeable.sol";

contract DeployInviteAndDividendUpgradeable is Script {
    function run() external {
        // 从环境变量中获取私钥或在此处定义私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // 根据私钥生成部署者的地址
        address deployerAddress = vm.addr(deployerPrivateKey);

        // 启动广播以启用交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署合约逻辑
        InviteAndDividendUpgradeable logic = new InviteAndDividendUpgradeable();

        // 部署 Proxy 管理合约
        ProxyAdmin proxyAdmin = new ProxyAdmin(deployerAddress);

        // 初始化参数
        address usdtToken = 0x55d398326f99059fF775485246999027B3197955; // USDT 代币地址
        address htxToken = 0x61EC85aB89377db65762E234C946b5c25A56E99e; // HTX 代币地址
        address trxToken = 0xCE7de646e7208a4Ef112cb6ed5038FA6cC6b12e3; // TRX 代币地址
        address dexRouter = 0xd0F08FE0B691C6a7b280c8DD5C7bC6D44Ad35e35; // DEX 路由合约地址
        uint256 oneTimeDividend = 100; // 一次性分红金额

        // 编码初始化函数数据
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,address,address,address,uint256)",
            usdtToken,
            htxToken,
            trxToken,
            dexRouter,
            oneTimeDividend
        );

        // 部署 TransparentUpgradeableProxy 并通过 ProxyAdmin 进行管理
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(logic), address(proxyAdmin), data);

        // 停止广播
        vm.stopBroadcast();

        console.log("Logic contract deployed at:", address(logic));
        console.log("Proxy contract deployed at:", address(proxy));
        console.log("Proxy Admin deployed at:", address(proxyAdmin));
        console.log("ProxyAdmin owner:", proxyAdmin.owner());
    }
}
