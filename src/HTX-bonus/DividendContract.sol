// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    event testEvent(address indexed user);
    event testAction(address indexed user);

    function callTestEvent() external {
        emit testEvent(msg.sender);
    }

    address[] public allUsers1;

    // 给某个地址转 CAKE
    function callTestAction() external {
        allUsers1.push(msg.sender);
        emit testAction(msg.sender);
    }

    // 合约接受 BNB
    receive() external payable {}
}
