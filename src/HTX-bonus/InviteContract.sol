// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InviteContract {
    address public owner;
    IERC20 public BSC_UsdtToken;
    IERC20 public BSC_HTXToken;

    uint256 public constant DEPOSIT_AMOUNT = 100 * 1e18; // 100 USDT
    uint256 public constant DIRECT_REWARD_AMOUNT = 38 * 1e18; // 38 USDT
    // uint256 public constant teamRewardPercent = 32; // 32 USDT
    uint256 public constant INDIRECT_REWARD_AMOUNT = 2 * 1e18; //  2usdt

    mapping(address => User) users;

    event UserBound(address indexed user, address indexed referrer);
    event Deposit(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    struct User {
        address referrer;
        address[] referrals;
        uint256 deposit;
        uint256 level;
        uint256 directReward;
        uint256 teamReward;
        uint256 totalReward;
        bool isBound;
        bool hasDeposited;
    }

    constructor(address _usdtToken, address _htxToken) {
        owner = msg.sender;
        BSC_UsdtToken = IERC20(_usdtToken);
        BSC_HTXToken = IERC20(_htxToken);
    }

    function bindUser(address _referrer) external {
        require(_referrer != address(0), "Cannot bind a referrer that is the zero address");
        require(_referrer != msg.sender, "Cannot refer yourself");
        require(!users[msg.sender].isBound, "Already bound to a referrer");
        // require(users[_referrer].isBound || _referrer == owner(), "Referrer must be bound or owner");

        users[msg.sender].referrer = _referrer;
        users[msg.sender].isBound = true;
        users[_referrer].referrals.push(msg.sender);
        users[_referrer].level = users[_referrer].referrals.length;

        emit UserBound(msg.sender, _referrer);
    }

    function deposit(uint256 amount) external {
        require(users[msg.sender].isBound, "Must be bound to a referrer");
        // 暂时按照只能投入1次计算，后续优化可以支持多次投注
        require(amount == DEPOSIT_AMOUNT, "Deposit amount must be equal to 100 USDT");
        require(!users[msg.sender].hasDeposited, "Already deposited");

        // Transfer 100 USDT from user to contract
        require(BSC_UsdtToken.transferFrom(msg.sender, address(this), DEPOSIT_AMOUNT), "Transfer failed");

        users[msg.sender].hasDeposited = true;

        emit Deposit(msg.sender, DEPOSIT_AMOUNT);

        address current = users[msg.sender].referrer;

        uint256 level = 1;

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
                rewardAmount = INDIRECT_REWARD_AMOUNT; // 2 USDT for upper levels
            }

            if (rewardAmount > 0) {
                require(BSC_UsdtToken.transfer(current, rewardAmount), "Reward transfer failed");
                emit RewardPaid(current, rewardAmount);
            }

            current = users[current].referrer;
            level++;
        }
    }
}
