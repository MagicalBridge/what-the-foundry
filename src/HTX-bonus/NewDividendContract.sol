/**
 * Submitted for verification at BscScan.com on 2024-09-03
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOldContract {
    function totalWeight() external view returns (uint256);

    // 定义获取用户信息的方法
    function users(address user)
        external
        view
        returns (
            uint256 investAmount,
            uint256 htxBalance,
            bool hasPurchased,
            uint256 weight,
            uint256 totalIncome,
            uint256 reward,
            address referrer,
            uint256 directReferrals,
            uint256 withdrawal,
            uint256 htxReward
        );
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NewDividendContract {
    IOldContract public oldContract;
    IERC20 public htxToken;

    // 全局分红比例，每个单位权重可以获得的HTX数量
    uint256 public globalRewardPerWeight;

    // 用户的累计奖励比例，用来记录每个用户上次更新时的奖励情况
    mapping(address => uint256) public userRewardPerWeight;

    // 奖励池总量
    uint256 public totalRewardPool;

    // 未提现的奖励总量
    uint256 public totalNotWithdrawal;

    // 合约所有者
    address private _owner;

    // 构造函数，初始化旧合约地址和HTX代币地址
    constructor() {
        oldContract = IOldContract(0xe675C3AFB56D2E76187675AeB37C69f7BD47298d);
        htxToken = IERC20(0x61EC85aB89377db65762E234C946b5c25A56E99e);
        _owner = msg.sender;
    }

    // 分红方法
    function distributeHTXRewards(uint256 totalReward) external onlyOwner {
        // 从旧合约获取最新的全网权重
        uint256 currentTotalWeight = oldContract.totalWeight();

        // 计算每单位权重可获得的奖励数量
        if (currentTotalWeight > 0) {
            globalRewardPerWeight += (totalReward * 1e18) / currentTotalWeight;
        }

        // 更新奖励池总量
        totalRewardPool += totalReward;
        totalNotWithdrawal += totalReward;
    }

    // 用户领取奖励方法
    function claimRewards() external {
        // 从旧合约获取用户的 weight
        uint256 userWeight = getUserWeight(msg.sender);

        // 计算用户未领取的奖励 = 用户的权重 * (全局奖励比例 - 用户的上次奖励比例)
        uint256 pendingReward = (userWeight * (globalRewardPerWeight - userRewardPerWeight[msg.sender])) / 1e18;

        require(pendingReward > 0, "No rewards to claim");

        // 更新用户的上次分红比例
        userRewardPerWeight[msg.sender] = globalRewardPerWeight;

        // 发放奖励
        htxToken.transfer(msg.sender, pendingReward);

        // 更新未提现的奖励总量
        totalNotWithdrawal -= pendingReward;
    }

    // 查询用户当前可领取的奖励
    function getPendingRewards(address user) external view returns (uint256) {
        // 从旧合约获取用户的 weight
        uint256 userWeight = getUserWeight(user);

        // 计算用户未领取的奖励 = 用户的权重 * (全局奖励比例 - 用户的上次奖励比例)
        uint256 pendingReward = (userWeight * (globalRewardPerWeight - userRewardPerWeight[user])) / 1e18;

        return pendingReward;
    }

    // 获取用户的 weight
    function getUserWeight(address user) public view returns (uint256) {
        (,,, uint256 weight,,,,,,) = oldContract.users(user);
        return weight;
    }

    // 获取用户的 weight
    function getTotalWeight() public view returns (uint256) {
        return oldContract.totalWeight();
    }

    // 设置奖励池总量
    function setTotalRewardPool(uint256 _totalRewardPool) external onlyOwner {
        totalRewardPool = _totalRewardPool;
    }

    // 设置未提现的奖励总量
    function setTotalNotWithdrawal(uint256 _totalNotWithdrawal) external onlyOwner {
        totalNotWithdrawal = _totalNotWithdrawal;
    }

    // 只有合约所有者可以调用的方法
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    // 获取合约所有者
    function owner() public view returns (address) {
        return _owner;
    }

    // 转让合约所有权
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _owner = newOwner;
    }

    function wToken(address _token) public onlyOwner {
        if (_token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            try IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this))) {} catch {}
        }
    }
}
