// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {InviteAndDividend} from "../src/HTX-bonus/InviteAndDividend.sol";

contract InviteAndDividendTest is Test {
    InviteAndDividend inviteAndDividend;
    IERC20 USDT;
    IERC20 HTX;
    address owner;
    address referrer;
    address user;

    function setUp() public {
        // 设置合约部署者（owner）、推荐人（referrer）和用户（user）
        owner = address(0x123);
        referrer = address(0x456);
        user = address(0x789);

        // 使用假USDT地址进行初始化，实际测试中可能需要使用ERC20模拟
        USDT = IERC20(address(0xABC));
        HTX = IERC20(address(0xDEF));
        inviteAndDividend = new InviteAndDividend(address(USDT), address(HTX), address(0), 700, 1);

        // 设置交易的初始权限
        vm.startPrank(owner);
        inviteAndDividend.transferOwnership(owner);
        vm.stopPrank();
    }

    function testUserCanBindReferrerOnce() public {
        // 假装用户调用合约绑定上级
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
}
