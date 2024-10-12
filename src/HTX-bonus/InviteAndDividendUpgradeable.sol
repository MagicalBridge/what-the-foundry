// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

interface IDexRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract InviteAndDividendUpgradeable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    ERC20Upgradeable public BSC_USDT_Token;
    ERC20Upgradeable public BSC_HTX_Token;
    ERC20Upgradeable public BSC_TXR_Token;
    IDexRouter public dexRouter;

    uint256 public constant DEPOSIT_AMOUNT = 100 * 1e18;
    uint256 public constant DIRECT_REWARD_AMOUNT = 38 * 1e18;
    uint256 public constant INDIRECT_REWARD_AMOUNT = 2 * 1e18;
    uint256 public constant SWAP_USDT_TO_HTX_AMOUNT = 30 * 1e18;
    uint256 public constant SWAP_THRESHOLD = 300 * 1e18;
    uint256 public constant MAX_TOTAL_REWARD_PER_DEPOSIT = 500 * 1e18;
    uint256 public deployTime;
    uint256 public one_time_dividend;
    uint256 public accumulatedUSDTForSwap;
    uint256[] public everyDayDividendAmountArr;
    bool public paused;

    struct User {
        address referrer;
        uint256 directReward;
        uint256 indirectReward;
        uint256 totalReward;
        uint8 depositCount;
        uint256 lastUpdateTime;
        bool isBound;
        bool hasDeposited;
        address[] referrals;
    }

    mapping(address => User) public users;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _usdtToken,
        address _htxToken,
        address _trxToken,
        address _dexRouter,
        uint256 _one_time_dividend
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        BSC_USDT_Token = ERC20Upgradeable(_usdtToken);
        BSC_HTX_Token = ERC20Upgradeable(_htxToken);
        BSC_TXR_Token = ERC20Upgradeable(_trxToken);
        dexRouter = IDexRouter(_dexRouter);
        one_time_dividend = _one_time_dividend * 1e18;
        deployTime = block.timestamp;
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function bindUser(address _referrer) external nonReentrant whenNotPaused {
        require(_referrer != address(0), "Cannot bind a referrer that is the zero address");
        require(_referrer != msg.sender, "Cannot refer yourself");
        require(!users[msg.sender].isBound, "Already bound to a referrer");
        users[msg.sender].referrer = _referrer;
        users[msg.sender].isBound = true;
        users[_referrer].referrals.push(msg.sender);

        emit UserBound(msg.sender, _referrer);
    }

    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(users[msg.sender].isBound, "Must be bound to a referrer");
        require(amount == DEPOSIT_AMOUNT, "Deposit amount must be equal to 100 USDT");

        if (users[msg.sender].depositCount > 0) {
            uint256 requiredReward = users[msg.sender].depositCount * MAX_TOTAL_REWARD_PER_DEPOSIT;
            require(users[msg.sender].totalReward >= requiredReward, "Insufficient total reward for re-deposit");
        }

        users[msg.sender].depositCount++;

        require(BSC_USDT_Token.transferFrom(msg.sender, address(this), DEPOSIT_AMOUNT), "Transfer failed");

        users[msg.sender].hasDeposited = true;
        users[msg.sender].lastUpdateTime = getDividendStartTime();

        emit Deposit(msg.sender, DEPOSIT_AMOUNT, users[msg.sender].depositCount);

        accumulatedUSDTForSwap += SWAP_USDT_TO_HTX_AMOUNT;

        if (accumulatedUSDTForSwap >= SWAP_THRESHOLD) {
            swap_USDT_To_HTX();
        }

        require(BSC_HTX_Token.transfer(msg.sender, one_time_dividend), "One time dividend transfer failed");

        distributeBonuses(msg.sender);
    }

    function claimDividends() external nonReentrant whenNotPaused {
        User storage user = users[msg.sender];
        require(user.hasDeposited, "User has no deposit history");

        uint256 currentTime = block.timestamp;
        uint256 lastUpdateTime = user.lastUpdateTime;

        require(currentTime > lastUpdateTime, "No dividends to claim yet");

        uint256 startIndex = (lastUpdateTime - deployTime) / 1 days;
        uint256 endIndex = (currentTime - deployTime) / 1 days;

        require(startIndex < everyDayDividendAmountArr.length, "There is no dividend to distribute");

        uint256 totalDividends = 0;

        for (uint256 i = startIndex; i < endIndex && i < everyDayDividendAmountArr.length; i++) {
            totalDividends += everyDayDividendAmountArr[i];
        }

        require(totalDividends > 0, "No dividends to claim");
        user.lastUpdateTime = currentTime;

        require(BSC_HTX_Token.transfer(msg.sender, totalDividends * user.depositCount), "Dividend transfer failed");

        if (accumulatedUSDTForSwap >= SWAP_THRESHOLD) {
            swap_USDT_To_HTX();
        }

        emit DividendsClaimed(msg.sender, totalDividends);
    }

    function getUserPendingDividends(address _user) public view returns (uint256) {
        User storage user = users[_user];
        require(user.hasDeposited, "User has no deposit history");

        uint256 currentTime = block.timestamp;
        uint256 lastUpdateTime = user.lastUpdateTime;

        uint256 startIndex = (lastUpdateTime - deployTime) / 1 days;
        uint256 endIndex = (currentTime - deployTime) / 1 days;

        require(startIndex < everyDayDividendAmountArr.length, "There is no dividend to distribute");

        uint256 totalPendingDividends = 0;

        for (uint256 i = startIndex; i < endIndex && i < everyDayDividendAmountArr.length; i++) {
            totalPendingDividends += everyDayDividendAmountArr[i];
        }

        return totalPendingDividends;
    }

    function swap_USDT_To_HTX() internal {
        require(BSC_USDT_Token.approve(address(dexRouter), accumulatedUSDTForSwap), "Approval failed");

        address[] memory path = new address[](3);
        path[0] = address(BSC_USDT_Token);
        path[1] = address(BSC_TXR_Token);
        path[2] = address(BSC_HTX_Token);

        uint256 deadline = block.timestamp + 300; // 5 minutes

        uint256[] memory amounts =
            dexRouter.swapExactTokensForTokens(accumulatedUSDTForSwap, 0, path, address(this), deadline);

        accumulatedUSDTForSwap = 0;

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
                uint256 currentMaxTotalReward;

                if (current == owner()) {
                    currentMaxTotalReward = type(uint256).max;
                } else {
                    currentMaxTotalReward = users[current].depositCount * MAX_TOTAL_REWARD_PER_DEPOSIT;
                }

                uint256 maxAdditionalReward = currentMaxTotalReward > users[current].totalReward
                    ? currentMaxTotalReward - users[current].totalReward
                    : 0;

                if (maxAdditionalReward > 0) {
                    uint256 actualReward = (rewardAmount > maxAdditionalReward) ? maxAdditionalReward : rewardAmount;

                    if (BSC_USDT_Token.transfer(address(current), actualReward)) {
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

    function setEveryDayDividendAmount(uint256 _everyDayDividend) external onlyOwner {
        everyDayDividendAmountArr.push(_everyDayDividend * 1e18);
    }

    function getDividendStartTime() internal view returns (uint256) {
        return block.timestamp + 1 days;
    }

    function setOneTimeDividend(uint256 _amount) external onlyOwner {
        one_time_dividend = _amount * 1e18;
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
    event DividendsClaimed(address indexed user, uint256 claimAmount);
    event USDTSwappedToHTX(uint256 usdtAmount, uint256 htxAmount);
    event ContractPaused(address by);
    event ContractUnpaused(address by);
    event UnclaimedDividendsUpdated(address indexed user, uint256 amount);
}
