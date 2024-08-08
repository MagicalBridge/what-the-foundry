// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {MultisignatureWallet} from "../src/MultisignatureWallet/MultisignatureWallet.sol";

contract MultisignatureWalletTest is Test {
    address public signer1;
    address public signer2;
    address public signer3;
    address[] public owners;

    address public recipient;
    MultisignatureWallet wallet;

    event SubmitTransaction(
        address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    function setUp() public {
        signer1 = makeAddr("signer1");
        signer2 = makeAddr("signer2");
        signer3 = makeAddr("signer3");

        // Create wallet and set its first owner.
        owners.push(signer1);
        owners.push(signer2);
        owners.push(signer3);

        vm.deal(signer1, 10 ether);
        vm.deal(signer2, 10 ether);
        vm.deal(signer3, 10 ether);

        uint8 required = 2;
        wallet = new MultisignatureWallet(owners, required);
        // Transfer some Ether to wallet
        vm.deal(address(wallet), 2 ether);

        console.log(address(wallet).balance);
    }

    function testSubmitTransaction() public {
        // prepare transaction
        recipient = makeAddr("recipient");
        uint256 value = 1 ether;
        bytes memory data = "0x1234";

        vm.expectEmit(true, true, true, true);
        emit SubmitTransaction(signer1, 0, recipient, value, data);
        // signer1 submits transaction
        vm.prank(signer1);
        wallet.submitTransaction(recipient, value, data);

        // verify transaction was submitted
        assertEq(wallet.getTransactionCount(), 1);

        // get transaction details
        (address toAddress, uint256 txValue, bytes memory txData, bool executed, uint256 numConfirmations) =
            wallet.getTransaction(0);

        assertEq(toAddress, recipient);
        assertEq(txValue, value);
        assertEq(txData, data);
        assertEq(executed, false);
        assertEq(numConfirmations, 0);
    }

    function testConfirmTransaction() public {
        // Assume that a transaction has been successfully submitted
        // prepare transaction
        recipient = makeAddr("recipient");
        uint256 value = 1 ether;
        bytes memory data = "0x1234";

        // signer1 submits transaction
        vm.prank(signer1);
        wallet.submitTransaction(recipient, value, data);

        uint256 txIndex = 0;

        // signer2 confirms transaction
        vm.expectEmit(true, true, true, true);
        emit ConfirmTransaction(signer2, txIndex);

        vm.prank(signer2);
        wallet.confirmTransaction(txIndex);

        // verify number of confirmations for the transaction
        (address toAddress, uint256 txValue, bytes memory txData, bool executed, uint256 numConfirmations) =
            wallet.getTransaction(txIndex);

        assertEq(toAddress, recipient);
        assertEq(txValue, value);
        assertEq(txData, data);
        assertEq(executed, false);
        assertEq(numConfirmations, 1);

        // verify tx is confirmed for signer2
        assertTrue(wallet.isConfirmed(txIndex, signer2));

        // make sure that signer2 cannot confirm twice
        vm.expectRevert("tx already confirmed");
        vm.prank(signer2);
        wallet.confirmTransaction(txIndex);

        // make sure that owner can confirm transaction
        address nonOwner = makeAddr("nonOwner");
        vm.expectRevert("not owner");
        vm.prank(nonOwner);
        wallet.confirmTransaction(txIndex);
    }

    function testRevokeConfirmation() public {
        address to = makeAddr("recipient");
        uint256 value = 1 ether;
        bytes memory data = "0x1234";

        // signer1 submits transaction
        vm.prank(signer1);
        wallet.submitTransaction(to, value, data);

        uint256 txIndex = 0;

        // signer2 confirms transaction
        vm.prank(signer2);
        wallet.confirmTransaction(txIndex);

        vm.expectEmit(true, true, true, true);
        emit RevokeConfirmation(signer2, txIndex);

        vm.prank(signer2);
        wallet.revokeConfirmation(txIndex);

        // verify number of confirmations for the transaction
        (address toAddress, uint256 txValue, bytes memory txData, bool executed, uint256 numConfirmations) =
            wallet.getTransaction(txIndex);

        // verify transaction details
        assertEq(toAddress, to);
        assertEq(txValue, value);
        assertEq(txData, data);
        assertEq(executed, false);
        assertEq(numConfirmations, 0);

        // verify confirmations
        // revoke before executing
        assertFalse(wallet.isConfirmed(txIndex, signer2));

        // make sure that signer2 cannot revoke non-existent confirmation
        vm.expectRevert("tx not confirmed");
        vm.prank(signer2);
        wallet.revokeConfirmation(txIndex);

        // make sure that non-owner cannot revoke confirmations
        address nonOwner = makeAddr("nonOwner");
        vm.expectRevert("not owner");
        vm.prank(nonOwner);
        wallet.revokeConfirmation(txIndex);
    }

    function testExecuteTransaction() public {
        recipient = makeAddr("recipient");
        uint256 value = 1 ether;
        bytes memory data = "0x1234";

        // signer1 submits transaction
        vm.prank(signer1);
        wallet.submitTransaction(recipient, value, data);

        uint256 txIndex = 0;

        // signer2 and signer3 confirm transaction
        vm.prank(signer2);
        wallet.confirmTransaction(txIndex);

        vm.prank(signer3);
        wallet.confirmTransaction(txIndex);

        // signer1 executes transaction
        vm.expectEmit(true, true, true, true);
        emit ExecuteTransaction(signer1, txIndex);

        vm.prank(signer1);
        wallet.executeTransaction(txIndex);

        // verify transaction execution
        (address toAddress, uint256 txValue, bytes memory txData, bool executed, uint256 numConfirmations) =
            wallet.getTransaction(txIndex);

        // verify transaction details
        assertEq(toAddress, recipient);
        assertEq(txValue, value);
        assertEq(txData, data);
        assertEq(executed, true); // 执行状态应为 true
        assertEq(numConfirmations, 2); // 确认次数应为 2

        address nonOwner = makeAddr("nonOwner");
        vm.expectRevert("not owner");
        vm.prank(nonOwner);
        wallet.executeTransaction(txIndex);

        // make sure that it cannot be executed twice
        vm.expectRevert("tx already executed");
        vm.prank(signer1);
        wallet.executeTransaction(txIndex);

        uint256 insufficientTxIndex = 1;

        vm.prank(signer1);
        wallet.submitTransaction(recipient, value, data);

        vm.prank(signer2);
        wallet.confirmTransaction(insufficientTxIndex);

        vm.expectRevert("cannot execute tx");
        vm.prank(signer1);
        wallet.executeTransaction(insufficientTxIndex);
    }

    function testGetOwners() public view {
        assertEq(address(wallet).balance, 2 ether);
        assertEq(wallet.getOwners(), owners);
    }
}
