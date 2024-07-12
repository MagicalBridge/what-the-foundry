#!/bin/bash

# deploy the project using  the following command
#forge create src/LouisToken.sol:MyToken --account mainTestAccount --rpc-url sepolia --constructor-args "My Test Token" "MTT"

# 部署你的合约到测试网
# forge create src/LouisToken.sol:MyToken --rpc-url sepolia --account mainTestAccount --constructor-args "My Test Token" "MTT" --etherscan-api-key MTPWKWF5E99E1P5C6GH4BIJ69XF8AMEI83

# forge verify-contract 0x0937a7bE8817cbcfF6e83F2F5e4EA188E14Dfd32 src/LouisToken.sol:MyToken --chain 11155111 --rpc-url sepolia --num-of-optimizations 200 --compiler-version v0.8.25+commit.9ef177df --etherscan-api-key MTPWKWF5E99E1P5C6GH4BIJ69XF8AMEI83 --constructor-args $(cast abi-encode "constructor(string,string)" "My Test Token" "MTT")