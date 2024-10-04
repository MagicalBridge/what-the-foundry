// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InviteContract is Ownable, ReentrancyGuard {
    IERC20 public BSC_USDT_Token;
    IERC20 public BSC_HTX_Token;

    uint256 public constant DEPOSIT_AMOUNT = 100 * 1e18; // 用户每次入金的金额是固定的, 为 100 USDT
    uint256 public constant DIRECT_REWARD_AMOUNT = 38 * 1e18; // 入金的用户，其直接推荐他的上级获得 38 USDT
    uint256 public constant INDIRECT_REWARD_AMOUNT = 2 * 1e18; // 上级的上级, 获取的推荐奖励为 2 USDT
    uint256 public constant MAX_TOTAL_REWARD_PER_DEPOSIT = 500 * 1e18; // 单次投注，用户总收益上限为500 USDT
    mapping(address => User) users;

    event UserBound(address indexed user, address indexed referrer);
    event Deposit(address indexed user, uint256 amount, uint256 depositCount);
    event RewardPaid(address indexed user, uint256 amount);
    event RewardTransferFailed(address indexed user, uint256 amount);

    struct User {
        address referrer; // 用户的推荐人，即推荐他的上级用户
        address[] referrals; // 用户所推荐的下级, 这是直接推荐的, 不含所有间接推荐用户
        uint256 directReward; // 直接推荐奖励
        uint256 indirectReward; // 间接推荐奖励
        uint256 totalReward; // 总计推荐奖励, 包含直接推荐和间接推荐
        bool isBound; // 是否与上级绑过, 同一个地址只允许与一位用户绑定, 作为他/她的上级
        bool hasDeposited; // 是否有过投注行为, 是否已入金
        uint8 depositCount; // 投注次数
    }

    constructor(address _usdtToken, address _htxToken) Ownable(msg.sender) {
        BSC_USDT_Token = IERC20(_usdtToken);
        BSC_HTX_Token = IERC20(_htxToken);
    }

    function bindUser(address _referrer) external nonReentrant {
        // 用户的推荐人必须是有效地址, 不能是0地址
        require(_referrer != address(0), "Cannot bind a referrer that is the zero address");
        // 用户的推荐人不能是自己
        require(_referrer != msg.sender, "Cannot refer yourself");
        // 用户不能重复绑定上级
        require(!users[msg.sender].isBound, "Already bound to a referrer");
        users[msg.sender].referrer = _referrer;
        users[msg.sender].isBound = true;
        // 设置用户的层级关系, 把当前用户添加到他的上级的referrals数组中
        users[_referrer].referrals.push(msg.sender);

        emit UserBound(msg.sender, _referrer);
    }

    function deposit(uint256 amount) external nonReentrant {
        // 用户需要通过绑定操作来绑定上级用户, 且只允许绑定一次, 否则不能进行入金操作
        require(users[msg.sender].isBound, "Must be bound to a referrer");
        require(amount == DEPOSIT_AMOUNT, "Deposit amount must be equal to 100 USDT");
        // 增加投注次数
        users[msg.sender].depositCount++;

        // Transfer 100 USDT from user to contract
        require(BSC_USDT_Token.transferFrom(msg.sender, address(this), DEPOSIT_AMOUNT), "Transfer failed");

        users[msg.sender].hasDeposited = true;

        emit Deposit(msg.sender, DEPOSIT_AMOUNT, users[msg.sender].depositCount);

        address current = users[msg.sender].referrer;

        uint8 level = 1;

        while (current != address(0) && level <= 17) {
            uint256 rewardAmount = 0;
            uint256 directReferrals = users[current].referrals.length;

            if (level == 1) {
                // Direct referrer gets 38 USDT
                rewardAmount = DIRECT_REWARD_AMOUNT;
            } else if (
                (directReferrals >= 1 && level <= 3) || (directReferrals >= 2 && level <= 6)
                    || (directReferrals >= 3 && level <= 17)
            ) {
                // 2 USDT for upper levels
                rewardAmount = INDIRECT_REWARD_AMOUNT;
            }

            if (rewardAmount > 0) {
                // 计算当前投注的最大总收益上限
                uint256 currentMaxTotalReward = users[current].depositCount * MAX_TOTAL_REWARD_PER_DEPOSIT;

                // 计算还可以获得的最大奖励金额
                uint256 maxAdditionalReward = currentMaxTotalReward > users[current].totalReward
                    ? currentMaxTotalReward - users[current].totalReward
                    : 0;

                if (maxAdditionalReward > 0) {
                    uint256 actualReward = (rewardAmount > maxAdditionalReward) ? maxAdditionalReward : rewardAmount;

                    if (BSC_USDT_Token.transfer(current, actualReward)) {
                        if (level == 1) {
                            users[current].directReward += actualReward;
                        } else {
                            users[current].indirectReward += actualReward;
                        }
                        users[current].totalReward += actualReward;
                        emit RewardPaid(current, actualReward);
                    } else {
                        emit RewardTransferFailed(current, actualReward);
                    }
                }
            }

            current = users[current].referrer;
            level++;
        }
    }
}
