import React, { useState } from 'react';
import { ethers } from 'ethers';

const cakeTokenAddress = "0xFa60D973F7642B748046464e165A65B7323b0DEE"; // CAKE 代币地址
const contractAddress = "0xc33804d4c3f1a90B56912048Ef78ff2CC21E29C0"; // 你的合约地址
const cakeABI = [ 
    "function approve(address spender, uint256 amount) public returns (bool)"
]; // 仅包含 approve 函数的 CAKE 代币 ABI

const AuthorizeCake = () => {
  const [amount, setAmount] = useState('');
  const [status, setStatus] = useState('');

  // 切换到 BSC 测试网
  const switchToBscTestnet = async () => {
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0x61' }], // 0x61 是 BSC 测试网的 Chain ID
      });
      setStatus('Switched to BSC Testnet');
    } catch (switchError) {
      // 如果用户没有该网络，则添加网络
      if (switchError.code === 4902) {
        try {
          await window.ethereum.request({
            method: 'wallet_addEthereumChain',
            params: [
              {
                chainId: '0x61',
                chainName: 'Binance Smart Chain Testnet',
                rpcUrls: ['https://data-seed-prebsc-1-s1.binance.org:8545/'],
                nativeCurrency: {
                  name: 'Binance Coin',
                  symbol: 'BNB',
                  decimals: 18,
                },
                blockExplorerUrls: ['https://testnet.bscscan.com'],
              },
            ],
          });
          setStatus('BSC Testnet added and switched');
        } catch (addError) {
          setStatus('Failed to add or switch to BSC Testnet');
        }
      } else {
        setStatus('Failed to switch to BSC Testnet');
      }
    }
  };

  // 连接 MetaMask
  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        setStatus(`Wallet connected: ${accounts[0]}`);
        await switchToBscTestnet(); // 尝试切换到 BSC 测试网
      } catch (error) {
        setStatus('Failed to connect wallet.');
      }
    } else {
      setStatus('Please install MetaMask!');
    }
  };

  // 授权合约转移用户 CAKE 代币
  const approveCAKE = async () => {
    if (!window.ethereum) {
      setStatus('MetaMask is required');
      return;
    }
  
    if (!amount || isNaN(amount) || parseFloat(amount) <= 0) {
      setStatus('Please enter a valid amount of CAKE');
      return;
    }
  
    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
  
      const cakeTokenContract = new ethers.Contract(cakeTokenAddress, cakeABI, signer);
  
      const amountInWei = ethers.utils.parseUnits(amount, 18);
      const tx = await cakeTokenContract.approve(contractAddress, amountInWei);
  
      console.log('Transaction sent:', tx); // Debugging: log the transaction object
  
      setStatus('Waiting for transaction confirmation...');
      const receipt = await tx.wait(); // 等待交易完成
      console.log('Transaction receipt:', receipt); // Debugging: log the transaction receipt
      setStatus('Authorization successful!');
    } catch (error) {
      console.error('Error occurred:', error); // Debugging: log the error
      setStatus(`Failed: ${error.message}`);
    }
  };

  return (
    <div>
      <h1>Authorize CAKE Transfer</h1>
      <button onClick={connectWallet}>Connect Wallet</button>
      <p>{status}</p>

      <input
        type="text"
        placeholder="Enter amount of CAKE"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
      />

      <button onClick={approveCAKE}>Approve CAKE Transfer</button>
    </div>
  );
};

export default AuthorizeCake;