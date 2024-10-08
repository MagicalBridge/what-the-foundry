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
    address pancakeRouter;

    function setUp() public {
        // 设置合约部署者（owner）、推荐人 referrer 和用户 user
        owner = makeAddr("owner");
        referrer = makeAddr("referrer");
        user = makeAddr("user");
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
        console.log("balance of owner htx", usdtToken.balanceOf(owner));
        console.log("balance of owner trx", usdtToken.balanceOf(owner));

        // owner用户将100usdt转给user用户
        usdtToken.transfer(user, 100 * 1e18);

        console.log("balance of user usdt", usdtToken.balanceOf(user));

        vm.stopPrank();

        inviteAndDividend =
            new InviteAndDividend(address(usdtToken), address(htxToken), address(trxToken), pancakeRouter, 7000000);

        // owner用户将htxtoken转给合约
        vm.startPrank(owner);
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

    // 测试只能绑定一个推荐人
    function testUserCanBindReferrerOnce() public {
        vm.startPrank(user);
        inviteAndDividend.bindUser(referrer);

        // 验证绑定成功，通过读取用户结构体来检查推荐人地址
        (address actualReferrer,,,,,,,,) = inviteAndDividend.users(user);
        assertEq(actualReferrer, referrer, "Referrer should be bound successfully");

        // 再次尝试绑定上级，应该失败
        vm.expectRevert("Already bound to a referrer");
        inviteAndDividend.bindUser(address(0x999));
        vm.stopPrank();
    }

    // 测试无法将用户绑定到零地址
    function testCannotBindToZeroAddress() public {
        vm.startPrank(user);
        vm.expectRevert("Cannot bind a referrer that is the zero address");
        inviteAndDividend.bindUser(address(0));
        vm.stopPrank();
    }

    // 测试无法将自己绑定为推荐人
    function testCannotBindToSelf() public {
        vm.startPrank(user);
        vm.expectRevert("Cannot refer yourself");
        inviteAndDividend.bindUser(user);
        vm.stopPrank();
    }

    // 测试用户没有绑定推荐用户就来存款
    function testDepositWithoutBindingReferrer() public {
        // 用户将自己的usdt授权给分红合约
        vm.startPrank(user);
        usdtToken.approve(address(inviteAndDividend), 100 * 1e18);

        // 尝试存入100usdt, 没有绑定推荐人, 应触发 revert
        vm.expectRevert("Must be bound to a referrer");
        inviteAndDividend.deposit(100 * 1e18);

        vm.stopPrank();
    }

    // 用户存入错误金额, 应触发 revert
    function testDepositErrorAmount() public {
        // 绑定推荐人
        vm.startPrank(user);
        inviteAndDividend.bindUser(referrer);
        vm.stopPrank();

        // 用户将自己的usdt授权给分红合约
        vm.startPrank(user);
        usdtToken.approve(address(inviteAndDividend), 100 * 1e18);

        // 4. 尝试存入错误金额
        vm.expectRevert("Deposit amount must be equal to 100 USDT");
        inviteAndDividend.deposit(50 * 1e18);

        vm.stopPrank();
    }

    // 测试存入正确的金额, 用户的对应状态应该发生改变
    function testDepositCorrectAmount() public {
        // 绑定推荐人
        vm.startPrank(user);

        console.log("referrer", referrer);

        inviteAndDividend.bindUser(referrer);
        vm.stopPrank();

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

        // 用户存入100usdt，一次性分红7000000 htx token,
        console.log("balance of user", htxToken.balanceOf(address(user)));
        uint256 oneTimeDividend = inviteAndDividend.one_time_dividend();
        assertEq(htxToken.balanceOf(address(user)), oneTimeDividend, "User should receive one time dividend in HTX");

        // 验证推荐人的奖励分发情况

        (
            , // 用户的推荐人，即推荐他的上级用户
            uint256 referrerdirectReward, // 直接推荐奖励
            , // 间接推荐奖励
            uint256 referrertotalReward, // 总计推荐奖励, 包含直接推荐和间接推荐
            , // 是否与上级绑过, 同一个地址只允许与一位用户绑定, 作为他/她的上级
            , // 是否有过投注行为, 是否已入金
            , // 投注次数
            , // 最后一次更新分红时间戳
                // 还没有提取的分红金额
        ) = inviteAndDividend.users(referrer);
        // assertEq(referrerdirectReward, 38 * 1e18, "Referrer should receive direct reward");
        // assertEq(referrertotalReward, 38 * 1e18, "Referrer should receive total reward");
    }
}
