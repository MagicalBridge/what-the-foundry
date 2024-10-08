// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {InviteAndDividend} from "../src/HTX-bonus/InviteAndDividend.sol";

contract USDT_Token is ERC20 {
    constructor() ERC20("USDT_Token", "USDT") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}

contract HTX_Token is ERC20 {
    constructor() ERC20("HTX_Token", "HTX") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}

contract TXR_Token is ERC20 {
    constructor() ERC20("TXR_Token", "TXR") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}

contract InviteAndDividendTest is Test {
    InviteAndDividend inviteAndDividend;
    USDT_Token usdtToken;
    HTX_Token htxToken;
    TXR_Token trxToken;

    address owner;
    address referrer;
    address user;
    address user2;
    address pancakeRouter;

    function setUp() public {
        // 设置合约部署者（owner）、推荐人 referrer 和用户 user
        owner = address(0x2b754dEF498d4B6ADada538F01727Ddf67D91A7D);
        // referrer = makeAddr("referrer");
        referrer = address(0x2b754dEF498d4B6ADada538F01727Ddf67D91A7D);
        user = makeAddr("user");
        user2 = makeAddr("user2");
        pancakeRouter = address(0x1b81D678ffb9C0263b24A97847620C99d213eB14);

        // 部署USDT，HTX，TXR代币
        vm.startPrank(owner);
        usdtToken = new USDT_Token();
        htxToken = new HTX_Token();
        trxToken = new TXR_Token();

        console.log("usdtToken", address(usdtToken));
        console.log("htxToken", address(htxToken));
        console.log("trxToken", address(trxToken));

        console.log("balance of owner usdt", usdtToken.balanceOf(owner));
        console.log("balance of owner htx ", usdtToken.balanceOf(owner));
        console.log("balance of owner trx ", usdtToken.balanceOf(owner));

        // owner用户将100usdt转给user用户
        usdtToken.transfer(user, 100 * 1e18);

        // owner用户将100usdt转给user2用户
        usdtToken.transfer(user2, 100 * 1e18);

        console.log("balance of user usdt ", usdtToken.balanceOf(user));
        console.log("balance of user2 usdt", usdtToken.balanceOf(user2));

        inviteAndDividend =
            new InviteAndDividend(address(usdtToken), address(htxToken), address(trxToken), pancakeRouter, 7000000);

        // owner用户将htxtoken转给合约
        htxToken.transfer(address(inviteAndDividend), 10000000 * 1e18);
        vm.stopPrank();

        console.log("balance of InviteAndDividend", htxToken.balanceOf(address(inviteAndDividend))); // 10000000,000,000,000,000,000,000
        console.log("balance of owner", htxToken.balanceOf(owner));

        // uint256 initialBalance = 1000 * 1e18; // 1000 USDT
        // deal(address(USDT), user, initialBalance);
        // deal(address(HTX), address(inviteAndDividend), 1000 * 1e18); // 确保合约有足够的 HTX

        // 设置交易的初始权限
        // vm.prank(address(this));
        // inviteAndDividend.transferOwnership(owner);
    }

    // 测试存入正确的金额, 用户的对应状态应该发生改变
    function testDepositCorrectAmount() public {
        // 绑定推荐人
        vm.startPrank(user);

        console.log("referrer", referrer);

        inviteAndDividend.bindUser(referrer);
        vm.stopPrank();

        // 记录推荐人初始 USDT 余额
        uint256 initialReferrerBalance = usdtToken.balanceOf(referrer);

        // 用户将自己的usdt授权给分红合约
        vm.startPrank(user);
        usdtToken.approve(address(inviteAndDividend), 100 * 1e18);

        // 尝试存入100usdt
        inviteAndDividend.deposit(100 * 1e18);
        vm.stopPrank();

        // 验证用户存入100usdt后, 对应的状态发生改变
        (
            address referrerParams, // 用户的推荐人，即推荐他的上级用户
            uint256 directReward, // 直接推荐奖励
            uint256 indirectReward, // 间接推荐奖励
            uint256 totalReward, // 总计推荐奖励, 包含直接推荐和间接推荐
            uint8 depositCount, // 投注次数
            uint256 lastUpdateTime, // 最后一次更新分红时间戳
            uint256 unclaimedDividends, // 还没有提取的分红金额
            bool isBound, // 是否与上级绑过, 同一个地址只允许与一位用户绑定, 作为他/她的上级
            bool hasDeposited // 是否有过投注行为, 是否已入金
        ) = inviteAndDividend.users(user);

        console.log("referrerParams", referrerParams);
        console.log("directReward", directReward);
        console.log("indirectReward", indirectReward);
        console.log("totalReward", totalReward);
        console.log("depositCount", depositCount);
        console.log("lastUpdateTime", lastUpdateTime);
        console.log("unclaimedDividends", unclaimedDividends);
        console.log("isBound", isBound);
        console.log("hasDeposited", hasDeposited);

        assertEq(hasDeposited, true, "User deposited money. Should be true.");
        assertEq(isBound, true, "User is bound. Should be true.");
        assertEq(depositCount, 1, "User deposited once. Should be 1.");
        assertEq(referrerParams, referrer, "Referrer should match.");

        // 用户存入100usdt，一次性分红7000000 htx token,
        console.log("balance of user", htxToken.balanceOf(address(user)));
        uint256 oneTimeDividend = inviteAndDividend.one_time_dividend();
        assertEq(htxToken.balanceOf(address(user)), oneTimeDividend, "User should receive one time dividend in HTX");

        // 验证 referrer 应该收到的直接奖励
        uint256 expectedDirectReward = 38 * 1e18; // 38 USDT
        uint256 newReferrerBalance = usdtToken.balanceOf(referrer);
        assertEq(
            newReferrerBalance,
            initialReferrerBalance + expectedDirectReward,
            "Referrer should receive 38 USDT as direct reward"
        );

        console.log("contract balance of usdtToken ---- ", usdtToken.balanceOf(address(inviteAndDividend)));

        // user2 绑定推荐人，user
        vm.startPrank(user2);
        inviteAndDividend.bindUser(user);
        vm.stopPrank();
    }
}
