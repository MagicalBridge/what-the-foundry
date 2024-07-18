#!/bin/bash

# Decode ABI-encoded calldata using https://openchain.xyz [aliases: 4d, 4bd]
# 给定一笔交易数据，分别解出函数签名和参数分别是什么

# "transfer(address,uint256)"
# 0x5494befe3CE72A2CA0001fE0Ed0C55B42F8c358f
# 137811276 [1.378e8]
cast 4byte-decode "0xa9059cbb0000000000000000000000005494befe3ce72a2ca0001fe0ed0c55b42f8c358f000000000000000000000000000000000000000000000000000000000836d54c"