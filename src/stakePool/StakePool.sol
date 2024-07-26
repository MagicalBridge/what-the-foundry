// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {RNTToken} from "./RNTToken.sol";
import {EsRNTToken} from "./EsRNTToken.sol";

contract StakePool {
    using SafeERC20 for RNTToken;

    RNTToken public rntToken;
    EsRNTToken public esrntToken;

    // 记录用户质押信息
    struct UserStakeInfo {
        uint256 stakedAmount;
        uint256 updateTime;
        uint256 unclaimedAmount;
    }

    // 设置一个mapping来存储指定Token每个用户的质押数量。
    mapping(address => mapping(address => uint256)) private stakes;

    // 用户地址对于质押信息的映射
    mapping(address => UserStakeInfo) public userStakeInfo;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event RewardUpdated(address indexed user, uint256 newUnclaimedAmount);

    constructor(RNTToken _rntToken, EsRNTToken _esrntToken) {
        rntToken = _rntToken;
        esrntToken = _esrntToken;
    }

    function stake(uint256 amount) public {
        // 从结构体中获取到当前操作用户的质押信息
        UserStakeInfo storage user = userStakeInfo[msg.sender];

        // 更新用户未提取的收益信息
        // 我的质押奖励计算需要精确到秒级别，根据规则每质押一个RNT,一天可以获得一个esRNT
        // 一天换算成秒数为 86400
        // 当前的时间戳 - 用户上次更新的时间戳 就是需要累加的秒数
        // 累加的秒数 * 用户当前质押的RNT数量 / 86400 = 需要累加的esRNT数量
        if (user.stakedAmount > 0) {
            uint256 newUnclaimedAmount = (block.timestamp - user.updateTime) * user.stakedAmount / 86400;
            user.unclaimedAmount += newUnclaimedAmount;

            if (newUnclaimedAmount > 0) {
                emit RewardUpdated(msg.sender, user.unclaimedAmount);
            }
        } else {
            // 将用户第一次的质押时间记录更新
            user.updateTime = block.timestamp;
        }

        // 更新用户的质押数量和更新时间
        user.stakedAmount += amount;

        // 将用户rntToken转移到当前的StakePool合约
        // transferFrom需要先在rntToken的approve方法中设置允许StakePool合约从用户地址中转出rntToken
        rntToken.transferFrom(msg.sender, address(this), amount);

        // 更新用户在StakePool合约中的质押的RNT的代币数量
        stakes[address(rntToken)][msg.sender] += amount;

        emit Staked(msg.sender, amount);
    }

    function unStake(uint256 amount) public {
        // 从结构体中获取到用户的质押信息
        UserStakeInfo storage user = userStakeInfo[msg.sender];
        // 用户提取的RNT数量不能超过用户当前未提取的RNT数量
        require(user.stakedAmount >= amount, "Insufficient staked amount");

        // 解除质押的时候也需要更新用户未提取的RNT的数量
        uint256 newUnclaimedAmount = (block.timestamp - user.updateTime) * user.stakedAmount / 86400;
        user.unclaimedAmount += newUnclaimedAmount;

        if (newUnclaimedAmount > 0) {
            emit RewardUpdated(msg.sender, user.unclaimedAmount);
        }

        // 更新用户质押的数量和更新时间
        user.stakedAmount -= amount;
        user.updateTime = block.timestamp;

        // 将用户的RNTToken转移到用户地址
        rntToken.transfer(msg.sender, amount);

        // 更新用户在StakePool合约中的质押的RNT的代币数量
        stakes[address(rntToken)][msg.sender] -= amount;

        emit Unstaked(msg.sender, amount);
    }

    function claim() public {
        // 取出当前用户的质押信息
        UserStakeInfo storage user = userStakeInfo[msg.sender];

        // 计算用户在claim瞬间的汇总的收益
        uint256 reward = user.unclaimedAmount + (block.timestamp - user.updateTime) * user.stakedAmount / 86400;

        // 重置用户的未提取收益和最后操作时间
        user.unclaimedAmount = 0;
        user.updateTime = block.timestamp;

        // 将等值的RNT从质押池转移到esRNT合约
        rntToken.safeTransfer(address(esrntToken), reward);

        // 将奖励的esRNT mint 给用户
        esrntToken.mint(msg.sender, reward);

        emit Claimed(msg.sender, reward);
    }
}
