#!/bin/bash

# deploy the project using  the following command
#forge create src/LouisToken.sol:MyToken --account mainTestAccount --rpc-url sepolia --constructor-args "My Test Token" "MTT"

# 部署你的合约到测试网
# forge create src/LouisToken.sol:MyToken --rpc-url sepolia --account mainTestAccount --constructor-args "My Test Token" "MTT" --etherscan-api-key MTPWKWF5E99E1P5C6GH4BIJ69XF8AMEI83

forge script --chain sepolia script/LouisToken.s.sol:MyTokenScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv