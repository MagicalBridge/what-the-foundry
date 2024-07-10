// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;

    event Deposit(address indexed user, uint amount);

    function setUp() public {
      // 新建bank合约实例
      bank = new Bank();
    }

    function testDepositEvent() public {
        address user = address(0x2b754dEF498d4B6ADada538F01727Ddf67D91A7D);
        uint depositAmount = 1 ether;

        // 为用户提供足够的以太币
        vm.deal(user, depositAmount);

        vm.prank(user); // 设置 msg.sender 为 user
        // 配置期望的事件参数
        vm.expectEmit(true, false, false, true); 
        emit Deposit(user, depositAmount); // 期望的事件
        bank.depositETH{value: depositAmount}(); // 调用 depositETH 函数
    }

    function test_BalanceUpdate() public {
        // 声明一个用户地址：这是使用我自己的测试账号 
        address myMockUser = address(0x2b754dEF498d4B6ADada538F01727Ddf67D91A7D);

        console.log(myMockUser); // forge test -vvv 才能打印输出
        
        // 从合约中取出用户的余额
        uint initialBalance = bank.balanceOf(myMockUser);
        
        // 声明一个变量：用 10 ether 进行测试 
        uint depositAmount = 10 ether;

        // 为用户提供足够的以太币
        vm.deal(myMockUser, depositAmount);

        // 断言初始化的时候用户地址的ETH余额为0
        assertEq(initialBalance, 0, "Initial balance should be 0");

        // 默认msg.sender是当前部署的测试合约的地址，这里重置为我们的mock账户
        vm.prank(myMockUser); // 设置 msg.sender 为 myMockUser
        
        // 触发bank的存款方法 
        bank.depositETH{value: depositAmount}();

        // 取出新的用户余额
        uint updatedBalance = bank.balanceOf(myMockUser);

        // 断言用户的余额等于 初始余额 + 存入的余额 
        assertEq(updatedBalance, initialBalance + depositAmount, "Balance should be updated correctly");
    }

    function test_DepositZero() public {
        // mock 地址
        address user = address(0x2b754dEF498d4B6ADada538F01727Ddf67D91A7D);

        // 设置 msg.sender 为 user
        vm.prank(user);
        
        // 确保交易回滚并触发错误信息
        vm.expectRevert(bytes("Deposit amount must be greater than 0"));
        
        // 尝试存款 0
        bank.depositETH{value: 0}(); 
    }
}
