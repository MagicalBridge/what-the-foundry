// const { ethers } = require("ethers");

// // 初始化 ethers.js Provider 和 Wallet
// const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
// const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// // 获取合约地址和 ABI
// const contractAddress = process.env.CONTRACT_ADDRESS;
// const contractABI = [
//   "function callTestAction() external",
//   "event testEvent(address indexed user)",
//   "event testAction(address indexed user)",
// ];
// const contract = new ethers.Contract(contractAddress, contractABI, wallet);

// // 定时调用 callTestAction
// const callContractAction = async () => {
//   try {
//     const tx = await contract.callTestAction();
//     console.log(`Transaction sent: ${tx.hash}`);
//     await tx.wait();
//     console.log("Transaction confirmed");
//   } catch (error) {
//     console.error("Failed to call contract function:", error);
//   }
// };

// // 每24小时调用一次（86400000ms）
// // setInterval(callContractAction, 5000);

// // 监听事件并存储到 MongoDB
// contract.on("testEvent", async (user, event) => {
//   console.log(`testEvent 触发 (使用过滤器): ${user}`);
//   console.log("事件详情:", event);
// });

// // 设置事件过滤器
// const filter = contract.filters.testAction();

// // 监听从最新区块开始的事件
// contract.on(filter, (user, event) => {
//   console.log(`testAction 触发: ${user}`);
//   console.log("事件详情:", event);
// });

// // 启动脚本时调用一次
// // callContractAction();
require("../eventIndexer");

// // async function cleanupPendingTransactions() {
// //   try {
// //     const pendingNonce = await provider.getTransactionCount(
// //       wallet.address,
// //       "pending"
// //     );
// //     const confirmedNonce = await provider.getTransactionCount(
// //       wallet.address,
// //       "latest"
// //     );

// //     console.log(
// //       `清理前 - 待处理的nonce: ${pendingNonce}, 已确认的nonce: ${confirmedNonce}`
// //     );

// //     if (pendingNonce === confirmedNonce) {
// //       console.log("没有待处理的交易需要清理。");
// //       return;
// //     }

// //     for (let nonce = confirmedNonce; nonce < pendingNonce; nonce++) {
// //       const cleanupTransaction = {
// //         to: wallet.address,
// //         value: 0,
// //         nonce: nonce,
// //         gasPrice: ethers.utils.parseUnits("20", "gwei"), // 根据实际网络情况调整
// //         gasLimit: 21000,
// //       };

// //       const signedTx = await wallet.signTransaction(cleanupTransaction);
// //       const txResponse = await provider.sendTransaction(signedTx);

// //       console.log(
// //         `清理交易已发送，nonce: ${nonce}, 交易哈希: ${txResponse.hash}`
// //       );
// //       await txResponse.wait();
// //       console.log(`nonce ${nonce} 的清理交易已确认`);
// //     }

// //     const newPendingNonce = await provider.getTransactionCount(
// //       wallet.address,
// //       "pending"
// //     );
// //     const newConfirmedNonce = await provider.getTransactionCount(
// //       wallet.address,
// //       "latest"
// //     );

// //     console.log(
// //       `清理后 - 新的待处理nonce: ${newPendingNonce}, 新的已确认nonce: ${newConfirmedNonce}`
// //     );

// //     if (newPendingNonce === newConfirmedNonce) {
// //       console.log("所有���处理的交易已成功清理。");
// //     } else {
// //       console.log(
// //         "清理过程完成，但仍有一些待处理的交易。可能需要再次运行清理或检查网络状况。"
// //       );
// //     }
// //   } catch (error) {
// //     console.error("清理过程中出错:", error);
// //   }
// // }

// // // 清理待交易的阻塞订单
// // cleanupPendingTransactions();
