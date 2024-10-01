// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract PackDexWrapETHToToken {
    receive() external payable {}

    function generateSignature(uint256 amount, uint256 deadline) external payable returns (bytes memory signature) {
        address user = 0x2b754dEF498d4B6ADada538F01727Ddf67D91A7D;
        address[] memory path = new address[](2);
        path[0] = 0xf46F9847a153480C85BDa37251170f2A3C5A87a8; // WETH address
        path[1] = 0xA6f1076DdAfCD7DebdCeA36918C2E7C42dDd9b86; // Token address

        bytes memory data = abi.encodeWithSignature(
            "swapExactETHForTokens(uint256,address[],address,uint256)", amount, path, user, deadline
        );

        return data;
    }
}
