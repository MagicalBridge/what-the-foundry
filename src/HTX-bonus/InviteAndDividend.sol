// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDexRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract InviteAndDividend is Ownable, ReentrancyGuard {
    IERC20 public BSC_USDT_Token;
    IERC20 public BSC_HTX_Token;
    IDexRouter public dexRouter;

    uint256 public constant DEPOSIT_AMOUNT = 100 * 1e18; // 用户每次入金的金额是固定的, 为 100 USDT
    uint256 public constant DIRECT_REWARD_AMOUNT = 38 * 1e18; // 入金的用户，其直接推荐他的上级获得 38 USDT
    uint256 public constant INDIRECT_REWARD_AMOUNT = 2 * 1e18; // 上级的上级, 获取的推荐奖励为 2 USDT
    uint256 public constant SWAP_USDT_TO_HTX_AMOUNT = 30 * 1e18; // 用户每入金100 USDT, 将其中的30 USDT通过 Dex 兑换成 HTX Token
    uint256 public constant SWAP_THRESHOLD = 300 * 1e18;
    uint256 public constant MAX_TOTAL_REWARD_PER_DEPOSIT = 500 * 1e18; // 单次投注，用户总收益上限为500 USDT
    uint256 public one_time_dividend; // 用户入金HTX分红
    uint256 public dividend_amount_per_second; // 分红的速率，表示是已经入金的用户每秒的HTX代币的分红金额，是个币本位的数字，根据用户入金的时间算起动态更新
    uint256 public accumulatedUSDTForSwap;
    bool public paused = false; // 系统是否暂停投注, 默认为否

    mapping(address => User) public users;

    struct User {
        address referrer; // 用户的推荐人，即推荐他的上级用户
        address[] referrals; // 用户所推荐的下级, 这是直接推荐的, 不含所有间接推荐用户
        uint256 directReward; // 直接推荐奖励
        uint256 indirectReward; // 间接推荐奖励
        uint256 totalReward; // 总计推荐奖励, 包含直接推荐和间接推荐
        bool isBound; // 是否与上级绑过, 同一个地址只允许与一位用户绑定, 作为他/她的上级
        bool hasDeposited; // 是否有过投注行为, 是否已入金
        uint8 depositCount; // 投注次数
        uint256 lastUpdateTime; // 最后一次更新分红时间戳
        uint256 unclaimedDividends; // 还没有提取的分红金额
    }

    constructor(
        address _usdtToken,
        address _htxToken,
        address _dexRouter,
        uint256 _one_time_dividend,
        uint256 _dividend_amount_per_second
    ) Ownable(msg.sender) {
        BSC_USDT_Token = IERC20(_usdtToken);
        BSC_HTX_Token = IERC20(_htxToken);
        dexRouter = IDexRouter(_dexRouter);
        one_time_dividend = _one_time_dividend;
        dividend_amount_per_second = _dividend_amount_per_second;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function bindUser(address _referrer) external nonReentrant whenNotPaused {
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

    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        // 用户需要通过绑定操作来绑定上级用户, 且只允许绑定一次, 否则不能进行入金操作
        require(users[msg.sender].isBound, "Must be bound to a referrer");
        require(amount == DEPOSIT_AMOUNT, "Deposit amount must be equal to 100 USDT");

        // 检查用户是否满足复投条件
        if (users[msg.sender].depositCount > 0) {
            uint256 requiredReward = users[msg.sender].depositCount * MAX_TOTAL_REWARD_PER_DEPOSIT;
            require(users[msg.sender].totalReward >= requiredReward, "Insufficient total reward for re-deposit");
        }

        // 增加投注次数
        users[msg.sender].depositCount++;

        // Transfer 100 USDT from user to contract
        require(BSC_USDT_Token.transferFrom(msg.sender, address(this), DEPOSIT_AMOUNT), "Transfer failed");

        users[msg.sender].hasDeposited = true;

        // Initialize or update the last update time for dividends
        if (users[msg.sender].lastUpdateTime == 0) {
            users[msg.sender].lastUpdateTime = block.timestamp;
        } else {
            updateUnclaimedDividends(msg.sender);
        }

        emit Deposit(msg.sender, DEPOSIT_AMOUNT, users[msg.sender].depositCount);

        // 累加USDT用于兑换
        accumulatedUSDTForSwap += SWAP_USDT_TO_HTX_AMOUNT;

        // 检查是否达到兑换阈值
        if (accumulatedUSDTForSwap >= SWAP_THRESHOLD) {
            swapUSDTToHTX();
        }

        // 用户成功入金100usdt, 直接给用户打 one_time_dividend 数量的HTX Token
        require(
            BSC_HTX_Token.transferFrom(address(this), msg.sender, one_time_dividend),
            "One time dividend transfer failed"
        );

        distributeBonuses(msg.sender);
    }

    function swapUSDTToHTX() internal {
        require(BSC_USDT_Token.approve(address(dexRouter), accumulatedUSDTForSwap), "Approval failed");

        address[] memory path = new address[](2);
        path[0] = address(BSC_USDT_Token);
        path[1] = address(BSC_HTX_Token);

        uint256 deadline = block.timestamp + 300; // 5 minutes

        uint256[] memory amounts = dexRouter.swapExactTokensForTokens(
            accumulatedUSDTForSwap,
            0, // 设置为0表示接受任何数量的HTX代币，请根据需要调整
            path,
            address(this),
            deadline
        );

        accumulatedUSDTForSwap = 0; // 重置累积的USDT数量

        emit USDTSwappedToHTX(amounts[0], amounts[1]);
    }

    function distributeBonuses(address _user) internal {
        address current = users[_user].referrer;
        uint8 level = 1;

        while (current != address(0) && level <= 17) {
            uint256 rewardAmount = 0;
            uint256 directReferrals = users[current].referrals.length;

            if (level == 1) {
                rewardAmount = DIRECT_REWARD_AMOUNT;
            } else if (
                (directReferrals >= 1 && level <= 3) || (directReferrals >= 2 && level <= 6)
                    || (directReferrals >= 3 && level <= 17)
            ) {
                rewardAmount = INDIRECT_REWARD_AMOUNT;
            }

            if (rewardAmount > 0) {
                uint256 currentMaxTotalReward = users[current].depositCount * MAX_TOTAL_REWARD_PER_DEPOSIT;
                uint256 maxAdditionalReward = currentMaxTotalReward > users[current].totalReward
                    ? currentMaxTotalReward - users[current].totalReward
                    : 0;

                if (maxAdditionalReward > 0) {
                    uint256 actualReward = (rewardAmount > maxAdditionalReward) ? maxAdditionalReward : rewardAmount;

                    if (BSC_USDT_Token.transferFrom(address(this), current, actualReward)) {
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

    function updateUnclaimedDividends(address _user) internal {
        uint256 timePassed = block.timestamp - users[_user].lastUpdateTime;
        uint256 newDividends = timePassed * dividend_amount_per_second;
        users[_user].unclaimedDividends += newDividends;
        users[_user].lastUpdateTime = block.timestamp;
    }

    function claimDividends() external nonReentrant whenNotPaused {
        require(users[msg.sender].hasDeposited, "User has not deposited");
        updateUnclaimedDividends(msg.sender);

        uint256 amountToClaim = users[msg.sender].unclaimedDividends;
        require(amountToClaim > 0, "No dividends to claim");

        // 尝试执行USDT到HTX的兑换，但不影响分红提取
        if (accumulatedUSDTForSwap >= SWAP_THRESHOLD) {
            swapUSDTToHTX();
        }

        // 一次性地将分红转给用户，避免多次转给单个用户，提高效率
        users[msg.sender].unclaimedDividends = 0;

        require(BSC_HTX_Token.transferFrom(address(this), msg.sender, amountToClaim), "Dividend transfer failed");

        emit DividendsClaimed(msg.sender, amountToClaim);
    }

    function getUnclaimedDividends(address _user) public view returns (uint256) {
        if (!users[_user].hasDeposited) {
            return 0;
        }
        uint256 timePassed = block.timestamp - users[_user].lastUpdateTime;
        return users[_user].unclaimedDividends + (timePassed * dividend_amount_per_second);
    }

    function setOneTimeDividend(uint256 _amount) external onlyOwner {
        one_time_dividend = _amount * 1e18;
    }

    function setDividendAmountPerSecond(uint256 _amount) external onlyOwner {
        dividend_amount_per_second = _amount;
    }

    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    event UserBound(address indexed user, address indexed referrer);
    event Deposit(address indexed user, uint256 amount, uint256 depositCount);
    event RewardPaid(address indexed user, uint256 amount);
    event RewardTransferFailed(address indexed user, uint256 amount);
    event DividendsClaimed(address indexed user, uint256 amount);
    event USDTSwappedToHTX(uint256 usdtAmount, uint256 htxAmount);
    event ContractPaused(address by);
    event ContractUnpaused(address by);
}
