const { ethers } = require("ethers");
const { getProvider } = require("../utils/ethersProvider");
const Event = require("../models/Event");

// 初始化 ethers.js Provider 和 Wallet
const provider = getProvider();
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// 获取合约地址和 ABI
const contractAddress = process.env.CONTRACT_ADDRESS;
const contractABI = [
  "function callTestAction() external",
  "event testEvent(address indexed user)",
  "event testAction(address indexed user)",
];
const contract = new ethers.Contract(contractAddress, contractABI, wallet);

// 定时调用 callTestAction
const callContractAction = async () => {
  try {
    const tx = await contract.callTestAction();
    console.log(`Transaction sent: ${tx.hash}`);
    await tx.wait();
    console.log("Transaction confirmed");
  } catch (error) {
    console.error("Failed to call contract function:", error);
  }
};

// 每24小时调用一次（86400000ms）
// setInterval(callContractAction, 5000);

// 启动脚本时调用一次
callContractAction();

async function getWithdrawalRecords(ctx) {
  const { userAddress } = ctx.request.body;
  // 查询事件表event=RewardPaid, args.user=userAddress
  const records = await Event.find({
    event: "RewardPaid",
    "args.user": userAddress,
  });
  ctx.body = {
    list: records,
  };
}

async function getInvitationRewards(ctx) {
  const { userAddress } = ctx.request.body;
  // 查询事件表event=RewardPaid, args.user=userAddress
  const records = await Event.find({
    event: "RewardPaid",
    "args.user": userAddress,
  });
  ctx.body = {
    list: records,
  };
}

async function getDividendRecords(ctx) {
  const { userAddress } = ctx.request.body;
  // 查询事件表event=RewardPaid, args.user=userAddress
  const records = await Event.find({
    event: "RewardPaid",
    "args.user": userAddress,
  });
  ctx.body = {
    list: records,
  };
}
async function getTotalAmount(ctx) {
  const { userAddress } = ctx.request.body;
  // 查询amount总额, 事件表event=DividendsClaimed
  // 查询amount总额, 事件表event=RewardPaid
  const totalAmount = await Event.aggregate([
    { $match: { event: "DividendsClaimed", "args.user": userAddress } },
    { $group: { _id: null, totalAmount: { $sum: "$amount" } } },
  ]);
  const totalAmount2 = await Event.aggregate([
    { $match: { event: "RewardPaid", "args.user": userAddress } },
    { $group: { _id: null, totalAmount: { $sum: "$amount" } } },
  ]);
  ctx.body = {
    dividendTotalAmount: totalAmount[0].totalAmount,
    invitationTotalAmount: totalAmount2[0].totalAmount,
  };
}
module.exports = {
  getWithdrawalRecords,
  getInvitationRewards,
  getDividendRecords,
  getTotalAmount,
};
