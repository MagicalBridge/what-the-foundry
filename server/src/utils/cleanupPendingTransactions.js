async function cleanupPendingTransactions() {
  try {
    const pendingNonce = await provider.getTransactionCount(
      wallet.address,
      "pending"
    );
    const confirmedNonce = await provider.getTransactionCount(
      wallet.address,
      "latest"
    );

    console.log(
      `清理前 - 待处理的nonce: ${pendingNonce}, 已确认的nonce: ${confirmedNonce}`
    );

    if (pendingNonce === confirmedNonce) {
      console.log("没有待处理的交易需要清理。");
      return;
    }

    for (let nonce = confirmedNonce; nonce < pendingNonce; nonce++) {
      const cleanupTransaction = {
        to: wallet.address,
        value: 0,
        nonce: nonce,
        gasPrice: ethers.utils.parseUnits("20", "gwei"), // 根据实际网络情况调整
        gasLimit: 21000,
      };

      const signedTx = await wallet.signTransaction(cleanupTransaction);
      const txResponse = await provider.sendTransaction(signedTx);

      console.log(
        `清理交易已发送，nonce: ${nonce}, 交易哈希: ${txResponse.hash}`
      );
      await txResponse.wait();
      console.log(`nonce ${nonce} 的清理交易已确认`);
    }

    const newPendingNonce = await provider.getTransactionCount(
      wallet.address,
      "pending"
    );
    const newConfirmedNonce = await provider.getTransactionCount(
      wallet.address,
      "latest"
    );

    console.log(
      `清理后 - 新的待处理nonce: ${newPendingNonce}, 新的已确认nonce: ${newConfirmedNonce}`
    );

    if (newPendingNonce === newConfirmedNonce) {
      console.log("所有���处理的交易已成功清理。");
    } else {
      console.log(
        "清理过程完成，但仍有一些待处理的交易。可能需要再次运行清理或检查网络状况。"
      );
    }
  } catch (error) {
    console.error("清理过程中出错:", error);
  }
}

// 清理待交易的阻塞订单
cleanupPendingTransactions();
