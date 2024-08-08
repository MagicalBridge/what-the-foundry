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

    function testGetOwners() public view {
        assertEq(address(wallet).balance, 2 ether);
        assertEq(wallet.getOwners(), owners);
    }
}
