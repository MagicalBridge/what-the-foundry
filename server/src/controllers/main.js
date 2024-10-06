const { ethers } = require("ethers");

// 连接到区块链
const provider = new ethers.providers.JsonRpcProvider(
  "https://bsc-dataseed.binance.org/"
);

// 合约地址和ABI
const contractAddress = "你的合约地址";
const contractABI = [
  /* 合约 ABI */
];

// 创建合约实例
const contract = new ethers.Contract(contractAddress, contractABI, provider);

// 监听 DividendDistributed 事件
contract.on(
  "DividendDistributed",
  (amountBNB, amountCake, timestamp, event) => {
    console.log(
      `Dividend distributed: ${amountBNB} BNB, ${amountCake} CAKE at ${new Date(
        timestamp * 1000
      )}`
    );

    // 将记录存入数据库（伪代码）
    saveToDatabase({
      amountBNB: amountBNB.toString(),
      amountCake: amountCake.toString(),
      timestamp: new Date(timestamp * 1000),
      transactionHash: event.transactionHash,
    });
  }
);
module.exports = { applyToken };
