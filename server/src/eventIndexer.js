const ethers = require("ethers");
const mongoose = require("mongoose");
const Event = require("./models/Event");
const LastProcessedBlock = require("./models/LastProcessedBlock");
const { provider } = require("./utils/ethersProvider");

// 合约 ABI 和地址
const contractABI = [
  /* 你的合约 ABI */
];
const contractAddress = process.env.CONTRACT_ADDRESS;

// 创建合约实例
let contract = new ethers.Contract(contractAddress, contractABI, provider);

// 定义所需的确认数
const REQUIRED_CONFIRMATIONS = 12;

// 获取最后处理的区块
async function getLastProcessedBlock() {
  const lastBlock = await LastProcessedBlock.findOne({ contractAddress });
  return lastBlock
    ? lastBlock.blockNumber
    : parseInt(process.env.START_BLOCK || "0");
}

// 更新最后处理的区块
async function updateLastProcessedBlock(blockNumber) {
  await LastProcessedBlock.findOneAndUpdate(
    { contractAddress },
    { blockNumber },
    { upsert: true }
  );
}

// 处理单个事件
async function processEvent(event) {
  try {
    // 检查事件是否来自已确认的区块
    const confirmations =
      (await provider.getBlockNumber()) - event.blockNumber + 1;
    if (confirmations < REQUIRED_CONFIRMATIONS) {
      console.log(`事件 ${event.transactionHash} 尚未得到足够确认,稍后处理`);
      return;
    }

    // 检查事件是否已经存在于数据库中
    const existingEvent = await Event.findOne({
      transactionHash: event.transactionHash,
      logIndex: event.logIndex,
    });

    if (existingEvent) {
      // 检查区块号是否发生变化(可能是由于重组)
      if (existingEvent.blockNumber !== event.blockNumber) {
        console.log(`检测到重组,更新事件 ${event.transactionHash}`);
        existingEvent.blockNumber = event.blockNumber;
        await existingEvent.save();
      }
      return;
    }

    if (!event.event) {
      console.log(`收到未知事件类型: ${event.topics[0]}`);
      return;
    }

    const newEvent = new Event({
      blockNumber: event.blockNumber,
      transactionHash: event.transactionHash,
      logIndex: event.logIndex,
      address: event.address,
      event: event.event,
      returnValues: event.args,
    });

    await newEvent.save();
    console.log(`事件已保存: ${event.transactionHash}`);
  } catch (error) {
    console.error(`处理事件时出错: ${error}`);
    throw error;
  }
}

// 获取历史事件
async function getHistoricalEvents(fromBlock, toBlock) {
  const batchSize = 1000; // 每批处理的区块数
  let currentFromBlock = fromBlock;

  while (currentFromBlock <= toBlock) {
    const currentToBlock = Math.min(currentFromBlock + batchSize - 1, toBlock);
    console.log(`获取历史事件: 从 ${currentFromBlock} 到 ${currentToBlock}`);

    try {
      const events = await contract.queryFilter(
        "*",
        currentFromBlock,
        currentToBlock
      );
      for (const event of events) {
        await processEvent(event);
      }
      await updateLastProcessedBlock(currentToBlock);
    } catch (error) {
      console.error(`获取历史事件时出错: ${error}`);
      // 如果出错,减小批次大小并重试
      batchSize = Math.max(Math.floor(batchSize / 2), 1);
      continue;
    }

    currentFromBlock = currentToBlock + 1;
  }
}

// 监听新事件
function listenToNewEvents(fromBlock) {
  console.log(`开始监听新事件,从区块 ${fromBlock}`);
  contract.on("*", async (event) => {
    try {
      await processEvent(event);
      await updateLastProcessedBlock(event.blockNumber);
    } catch (error) {
      console.error(`处理新事件时出错: ${error}`);
    }
  });
}

// 获取最新的 ABI
async function getLatestABI() {
  // 这里可以实现从某个 API 或数据库获取最新 ABI 的逻辑
  // 例如:
  // const response = await fetch('https://api.example.com/latest-abi');
  // return await response.json();
}

// 主函数
async function main() {
  while (true) {
    try {
      const lastProcessedBlock = await getLastProcessedBlock();
      const currentBlock = await provider.getBlockNumber();

      // 处理历史事件
      await getHistoricalEvents(lastProcessedBlock, currentBlock);

      // 更新最后处理的区块
      await updateLastProcessedBlock(currentBlock);

      // 监听新事件
      listenToNewEvents(currentBlock + 1);

      // 定期更新 ABI
      setInterval(async () => {
        try {
          const latestABI = await getLatestABI();
          contract = new ethers.Contract(contractAddress, latestABI, provider);
          console.log("合约 ABI 已更新");
        } catch (error) {
          console.error("更新 ABI 时出错:", error);
        }
      }, 24 * 60 * 60 * 1000); // 每24小时检查一次

      // 如果成功,退出循环
      break;
    } catch (error) {
      console.error(`主函数出错: ${error}`);
      console.log("5秒后重试...");
      await new Promise((resolve) => setTimeout(resolve, 5000));
    }
  }
}

// 连接到 MongoDB
mongoose
  .connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => {
    console.log("MongoDB connected");
    main();
  })
  .catch((err) => console.error("MongoDB connection error:", err));

mongoose.connection.on("disconnected", async () => {
  console.log("MongoDB 连接断开,尝试重新连接...");
  await mongoose.connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });
});
