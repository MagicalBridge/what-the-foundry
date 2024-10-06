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

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}

contract InviteAndDividend is Ownable, ReentrancyGuard {
    IERC20 public BSC_USDT_Token; // 0x55d398326f99059fF775485246999027B3197955
    IERC20 public BSC_HTX_Token; // 0x61EC85aB89377db65762E234C946b5c25A56E99e
    IERC20 public BSC_TXR_Token; // 0xCE7de646e7208a4Ef112cb6ed5038FA6cC6b12e3
    IDexRouter public dexRouter;

    uint256 public constant DEPOSIT_AMOUNT = 100 * 1e18; // 用户每次入金的金额是固定的, 为 100 USDT
    uint256 public constant DIRECT_REWARD_AMOUNT = 38 * 1e18; // 入金的用户，其直接推荐他的上级获得 38 USDT
    uint256 public constant INDIRECT_REWARD_AMOUNT = 2 * 1e18; // 上级的上级, 获取的推荐奖励为 2 USDT
    uint256 public constant SWAP_USDT_TO_HTX_AMOUNT = 30 * 1e18; // 用户每入金100 USDT, 将其中的30 USDT通过 Dex 兑换成 HTX Token
    uint256 public constant SWAP_THRESHOLD = 300 * 1e18;
    uint256 public constant MAX_TOTAL_REWARD_PER_DEPOSIT = 500 * 1e18; // 单次投注，用户总收益上限为500 USDT
    uint256 public constant EVERY_DAY_DIVIDEND = 11 * 1e17; // 每天分给用户的分红（以1.1 USDT代币数量计）
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
        address _trxToken,
        address _dexRouter,
        uint256 _one_time_dividend,
        uint256 _dividend_amount_per_second
    ) Ownable(msg.sender) {
        BSC_USDT_Token = IERC20(_usdtToken);
        BSC_HTX_Token = IERC20(_htxToken);
        BSC_TXR_Token = IERC20(_trxToken);
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

        // 用户入金成功, 设置他的最后更新时间, 以便于计算分红
        users[msg.sender].lastUpdateTime = getNextDayTimestamp();

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

        address[] memory path = new address[](3);
        path[0] = address(BSC_USDT_Token);
        path[0] = address(BSC_TXR_Token);
        path[2] = address(BSC_HTX_Token);

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
        User storage user = users[_user];
        // 确保用户已经存款
        require(user.hasDeposited, "User has not deposited");
        uint256 currentTime = block.timestamp;
        uint256 lastUpdate = user.lastUpdateTime;

        // 如果最近更新时间大于当前时间戳, 跳过操作
        if (lastUpdate >= currentTime) {
            return;
        }

        // 计算从上次更新到现在经过的完整天数
        uint256 daysPassed = (currentTime - lastUpdate) / 1 days;

        // 如果经过的天数大于等于1，才开始计算分红
        if (daysPassed >= 1) {
            // 计算分红总额（每天1.1 USDT等值的HTX）
            uint256 dailyDividend = EVERY_DAY_DIVIDEND; // 1.1 USDT in wei
            uint256 totalDividend = dailyDividend * daysPassed;

            // 将计算得到的分红添加到未领取分红中
            user.unclaimedDividends += totalDividend;

            // 更新最后更新时间，向前推进整天数
            user.lastUpdateTime += daysPassed * 1 days;
        }
    }

    function claimDividends() external nonReentrant whenNotPaused {
        require(users[msg.sender].hasDeposited, "User has not deposited");
        updateUnclaimedDividends(msg.sender);

        uint256 amountToClaim = users[msg.sender].unclaimedDividends;
        require(amountToClaim > 0, "No dividends to claim");

        // 尝试执行USDT到HTX的兑换
        if (accumulatedUSDTForSwap >= SWAP_THRESHOLD) {
            swapUSDTToHTX();
        }

        // 一次性地将分红转给用户，避免多次转给单个用户，提高效率
        users[msg.sender].unclaimedDividends = 0;

        // 计算等值的HTX数量
        address[] memory path = new address[](2);
        path[0] = address(BSC_USDT_Token);
        path[1] = address(BSC_HTX_Token);

        uint256[] memory amounts = dexRouter.getAmountsOut(amountToClaim, path);

        uint256 htxAmount = amounts[1];

        // 确保合约有足够的HTX余额
        require(BSC_HTX_Token.balanceOf(address(this)) >= htxAmount, "Insufficient HTX balance in contract");

        require(BSC_HTX_Token.transferFrom(address(this), msg.sender, htxAmount), "Dividend transfer failed");

        emit DividendsClaimed(msg.sender, amountToClaim, htxAmount);
    }

    function getUnclaimedDividends(address _user) public view returns (uint256) {
        User storage user = users[_user];
        if (!user.hasDeposited || user.lastUpdateTime > block.timestamp) {
            return user.unclaimedDividends;
        }

        uint256 currentTime = block.timestamp;
        uint256 lastUpdate = user.lastUpdateTime;
        uint256 daysPassed = (currentTime - lastUpdate) / 1 days;

        uint256 dailyDividend = EVERY_DAY_DIVIDEND;
        uint256 additionalDividends = dailyDividend * daysPassed;

        return user.unclaimedDividends + additionalDividends;
    }

    function getNextDayTimestamp() internal view returns (uint256) {
        // 获取当前时间戳
        uint256 currentTimestamp = block.timestamp;

        // 计算下一天开始的时间戳
        uint256 nextDayTimestamp = ((currentTimestamp / 1 days) + 1) * 1 days;

        return nextDayTimestamp;
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
    event DividendsClaimed(address indexed user, uint256 usdtAmount, uint256 amount);
    event USDTSwappedToHTX(uint256 usdtAmount, uint256 htxAmount);
    event ContractPaused(address by);
    event ContractUnpaused(address by);
}
