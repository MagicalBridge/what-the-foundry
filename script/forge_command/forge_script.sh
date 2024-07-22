#!/bin/bash

# 部署指定文件
forge script --chain sepolia script/LouisToken.s.sol:MyTokenScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv