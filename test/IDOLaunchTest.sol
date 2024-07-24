// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {IDOContract} from "../src/IDOLaunch.sol";

contract RNTToken is ERC20 {
    constructor() ERC20("RNTToken", "RNT") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}

contract IDOLaunchTest is Test {
    IDOContract public idoContract;
    RNTToken public rntToken;
    address public owner;
    address public alice;
    address public bob;
    address public carol;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        // 部署RNT代币
        vm.prank(owner);
        rntToken = new RNTToken();

        console.log("balance of owner ", rntToken.balanceOf(owner));
        // 部署IDO合约
        vm.startPrank(owner);

        idoContract = new IDOContract(rntToken);
        rntToken.transfer(address(idoContract), 1000000 * 10 ** rntToken.decimals());

        console.log("balance of idoContract ", rntToken.balanceOf(address(idoContract)));

        vm.stopPrank();

        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);
        vm.deal(carol, 1000 ether);
    }

    function testPreSale() public {
        vm.startPrank(alice);
        // 向idoContract合约中转钱
        idoContract.preSale{value: 10 ether}();
        assertEq(idoContract.contributions(alice), 10 ether);
        assertEq(idoContract.totalFundsRaised(), 10 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        // 向idoContract合约中转钱
        idoContract.preSale{value: 20 ether}();
        assertEq(idoContract.contributions(bob), 20 ether);
        assertEq(idoContract.totalFundsRaised(), 30 ether);
        vm.stopPrank();

        vm.startPrank(carol);
        vm.expectRevert("Hard cap reached");
        idoContract.preSale{value: 180 ether}();
        console.log(idoContract.totalFundsRaised());
        vm.stopPrank();
    }

    function testClaimTokens() public {
        vm.prank(alice);
        idoContract.preSale{value: 10 ether}();
        assertEq(idoContract.contributions(alice), 10 ether);
        assertEq(idoContract.totalFundsRaised(), 10 ether);

        vm.prank(bob);
        idoContract.preSale{value: 90 ether}();
        assertEq(idoContract.contributions(bob), 90 ether);
        assertEq(idoContract.totalFundsRaised(), 100 ether);

        vm.prank(owner);
        idoContract.endIDO();
        assertEq(idoContract.isIDOActive(), false);
        assertEq(idoContract.isIDOSuccess(), true);

        vm.prank(alice);
        idoContract.claimTokens();
        console.log("balance of alice ", rntToken.balanceOf(alice));
        assertEq(rntToken.balanceOf(alice), 100);

        vm.prank(bob);
        idoContract.claimTokens();
        console.log("balance of bob ", rntToken.balanceOf(alice));
        assertEq(rntToken.balanceOf(bob), 900);
    }

    // 测试withdraw函数
    function testWithdraw() public {}
}
