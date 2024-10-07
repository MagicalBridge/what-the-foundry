const ethers = require("ethers");
const Event = require("./models/Event");
const LastProcessedBlock = require("./models/LastProcessedBlock");
const PendingEvent = require("./models/PendingEvent");
const { getProvider } = require("./utils/ethersProvider");

// 配置
const REQUIRED_CONFIRMATIONS = 12;
const PENDING_EVENT_CHECK_INTERVAL = 5 * 60 * 1000; // 5分钟
const ABI_UPDATE_INTERVAL = 24 * 60 * 60 * 1000; // 24小时

// 合约 ABI 和地址
const contractABI = `
  event testAction(address indexed user);
  event UserBound(address indexed user, address indexed referrer);
  event Deposit(address indexed user, uint256 amount, uint256 depositCount);
  event RewardPaid(address indexed user, uint256 amount);
  event RewardTransferFailed(address indexed user, uint256 amount);
  event DividendsClaimed(address indexed user, uint256 usdtAmount, uint256 amount);
  event USDTSwappedToHTX(uint256 usdtAmount, uint256 htxAmount);
  event ContractPaused(address by);
  event ContractUnpaused(address by);`
  .split(";")
  .map((item) => item.trim())
  .filter((item) => item);
const contractAddress = process.env.CONTRACT_ADDRESS;

// 解析 ABI 字符串为 JSON 对象
const parsedABI = contractABI
  .map((item) => {
    const match = item.match(/event\s+(\w+)\((.*?)\)/);
    if (match) {
      const [, name, params] = match;
      return {
        type: "event",
        name,
        inputs: params.split(",").map((param) => {
          const parts = param.trim().split(" ");
          let type, name, indexed;
          if (parts.length === 3) {
            [indexed, type, name] = parts;
            indexed = indexed === "indexed";
          } else if (parts.length === 2) {
            if (parts[0] === "indexed") {
              [indexed, type] = parts;
              indexed = true;
            } else {
              [type, name] = parts;
              indexed = false;
            }
          } else {
            [type] = parts;
            name = null;
            indexed = false;
          }
          return { type, name, indexed };
        }),
      };
    }
    return null;
  })
  .filter(Boolean);

console.log(123123, parsedABI);

// 创建合约实例
let contract = new ethers.Contract(contractAddress, contractABI, getProvider());

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
async function processEvent(event, currentBlockNumber) {
  try {
    const eventName = event?.fragment?.name || event?.event; // 兼容 PendingEvent 模型
    const confirmations = currentBlockNumber - event.blockNumber + 1;

    // 解析事件参数
    const eventABI = parsedABI.find((abi) => abi.name === eventName);
    let parsedArgs = {};
    if (eventABI && event.args) {
      eventABI.inputs.forEach((input, index) => {
        if (input.name) {
          parsedArgs[input.name] = event.args[input.name] || event.args[index];
        }
      });
    }

    let eventData = {
      blockNumber: event.blockNumber,
      transactionHash: event.transactionHash,
      transactionIndex: event.transactionIndex,
      index: event.index,
      address: event.address,
      event: eventName, // 兼容 PendingEvent 模型
      args: parsedArgs, // 使用解析后的参数
    };
    if (event.log) {
      eventData.address = event.log?.address;
      eventData.transactionIndex = event.log?.transactionIndex;
      eventData.index = event.log?.logIndex;
      eventData.blockNumber = event.log?.blockNumber;
      eventData.transactionHash = event.log?.transactionHash;
    }
    if (confirmations < REQUIRED_CONFIRMATIONS) {
      console.log(
        `事件 ${eventData.transactionHash} 尚未得到足够确认,稍后处理`
      );
      await PendingEvent.findOneAndUpdate(
        { transactionHash: eventData.transactionHash, index: eventData.index },
        eventData,
        { upsert: true, new: true }
      );
      return;
    }
    const existingEvent = await Event.findOne({
      transactionHash: eventData.transactionHash,
      index: eventData.index,
    });
    if (existingEvent) {
      if (existingEvent.blockNumber !== eventData.blockNumber) {
        console.log(`检测到重组,更新事件 ${eventData.transactionHash}`);
        existingEvent.blockNumber = eventData.blockNumber;
        await existingEvent.save();
      } else {
        console.log(`事件已存在，跳过处理`);
      }
      return;
    }
    if (!eventName) {
      console.log(
        `收到未知事件类型: ${event.topics ? event.topics[0] : "未知"}`,
        eventData.transactionHash
      );
      return;
    }
    const newEvent = new Event(eventData);

    await newEvent.save();
    console.log(`事件已保存: ${eventData.transactionHash}`);

    await PendingEvent.deleteOne({
      transactionHash: eventData.transactionHash,
      index: eventData.index,
    });
  } catch (error) {
    console.error(`处理事件时出错: ${error}`);
    throw error;
  }
}

// 获取历史事件
async function getHistoricalEvents(fromBlock, toBlock) {
  let batchSize = 1000;
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
      const currentBlockNumber = await getProvider().getBlockNumber();
      for (const event of events) {
        await processEvent(event, currentBlockNumber);
      }
      await updateLastProcessedBlock(currentToBlock);
      currentFromBlock = currentToBlock + 1;
    } catch (error) {
      console.error(`获取历史事件时出错: ${error}`);
      batchSize = Math.max(Math.floor(batchSize / 2), 1);
    }
  }
}

// 检查待处理事件
async function checkPendingEvents() {
  console.log("开始检查待处理事件...");
  const currentBlockNumber = await getProvider().getBlockNumber();
  const pendingEvents = await PendingEvent.find({}).sort({ blockNumber: 1 });

  for (const pendingEvent of pendingEvents) {
    const confirmations = currentBlockNumber - pendingEvent.blockNumber + 1;
    if (confirmations >= REQUIRED_CONFIRMATIONS) {
      console.log(`处理之前待确认的事件: ${pendingEvent.transactionHash}`);
      try {
        const block = await getProvider().getBlock(pendingEvent.blockNumber);
        if (block && block.hash) {
          const tx = await getProvider().getTransactionReceipt(
            pendingEvent.transactionHash
          );
          if (tx && tx.blockNumber === pendingEvent.blockNumber) {
            const event = {
              ...pendingEvent.toObject(),
              getBlock: () => Promise.resolve(block),
              getTransaction: () => Promise.resolve(tx),
              getTransactionReceipt: () => Promise.resolve(tx),
            };
            await processEvent(event, currentBlockNumber);
          } else {
            console.log(
              `事件 ${pendingEvent.transactionHash} 可能已被重组，删除待处理记录`
            );
            await PendingEvent.deleteOne({ _id: pendingEvent._id });
          }
        } else {
          console.log(`无法获取区块 ${pendingEvent.blockNumber}，稍后重试`);
        }
      } catch (error) {
        console.error(`处理待确认事件时出错: ${error}`);
      }
    }
  }
  console.log("待处理事件检查完成");
}

// 监听新事件
function listenToNewEvents(fromBlock) {
  console.log(`开始监听新事件,从区块 ${fromBlock}`);
  contract.on("*", async (event) => {
    try {
      const currentBlockNumber = await getProvider().getBlockNumber();
      await processEvent(event, currentBlockNumber);
      await updateLastProcessedBlock(event.blockNumber);
      updateLastProcessedBlock(currentBlockNumber);
    } catch (error) {
      console.error(`处理新事件时出错: ${error}`);
    }
  });
}

// 获取最新的 ABI
async function getLatestABI() {
  // 这里应该实现从某个 API 或数据库获取最新 ABI 的逻辑
  // 暂时返回当前的 ABI
  return contractABI;
}

// 主函数
async function main() {
  let pendingEventCheckInterval;

  try {
    const lastProcessedBlock = await getLastProcessedBlock();
    const currentBlock = await getProvider().getBlockNumber();

    // 处理历史事件
    await getHistoricalEvents(lastProcessedBlock + 1, currentBlock);

    // 更新最后处理的区块
    await updateLastProcessedBlock(currentBlock);

    // 监听新事件
    listenToNewEvents(currentBlock + 1);

    // 立即检查一次待处理事件
    await checkPendingEvents();

    // 设置定期检查待处理事件的定时器
    pendingEventCheckInterval = setInterval(async () => {
      try {
        await checkPendingEvents();
      } catch (error) {
        console.error("检查待处理事件时出错:", error);
      }
    }, PENDING_EVENT_CHECK_INTERVAL);

    // 定期更新 ABI
    setInterval(async () => {
      try {
        const latestABI = await getLatestABI();
        contract = new ethers.Contract(
          contractAddress,
          latestABI,
          getProvider()
        );
        console.log("合约 ABI 已更新");
      } catch (error) {
        console.error("更新 ABI 时出错:", error);
      }
    }, ABI_UPDATE_INTERVAL);

    // 保持程序运行
    await new Promise(() => {});
  } catch (error) {
    console.error(`主函数出错: ${error}`);
    if (pendingEventCheckInterval) {
      clearInterval(pendingEventCheckInterval);
    }
    console.log("5秒后重试...");
    await new Promise((resolve) => setTimeout(resolve, 5000));
    main(); // 重新启动主函数
  }
}

// 启动主函数
main().catch((error) => {
  console.error("程序出错:", error);
  process.exit(1);
});
