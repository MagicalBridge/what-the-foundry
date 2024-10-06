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

        vm.stopPrank();

        inviteAndDividend =
            new InviteAndDividend(address(usdtToken), address(htxToken), address(trxToken), pancakeRouter, 700);

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

    function testDeposit() public {
        // 1. 设置初始状态
        // uint256 initialBalance = 1000 * 1e18; // 1000 USDT
        // deal(address(USDT), user, initialBalance);
        // deal(address(HTX), address(inviteAndDividend), 1000 * 1e18); // 确保合约有足够的 HTX

        // 2. 绑定推荐人
        vm.startPrank(user);
        inviteAndDividend.bindUser(referrer);

        // 验证绑定成功，通过读取用户结构体来检查推荐人地址
        (address actualReferrer,,,,,,,,) = inviteAndDividend.users(user);
        assertEq(actualReferrer, referrer, "Referrer should be bound successfully");

        // 再次尝试绑定上级，应该失败
        vm.expectRevert("Already bound to a referrer");
        inviteAndDividend.bindUser(address(0x999));
        vm.stopPrank();

        //     // 3. 授权 USDT
        //     // vm.startPrank(user);
        //     // USDT.approve(address(inviteAndDividend), initialBalance);

        //     // 4. 尝试存入错误金额
        //     // vm.expectRevert("Deposit amount must be equal to 100 USDT");
        //     // inviteAndDividend.deposit(50 * 1e18);
        //     // vm.stopPrank();
    }
}
