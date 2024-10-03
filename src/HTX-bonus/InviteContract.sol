// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InviteContract {
    address public owner;
    IERC20 public BSC_USDT_Token;
    IERC20 public BSC_HTX_Token;

    uint256 public constant DEPOSIT_AMOUNT = 100 * 1e18; // 100 USDT
    uint256 public constant DIRECT_REWARD_AMOUNT = 38 * 1e18; // 38 USDT
    uint256 public constant INDIRECT_REWARD_AMOUNT = 2 * 1e18; //  2 USDT
    uint256 public constant MAX_TOTAL_REWARD = 500 * 1e18; // 500 USDT

    mapping(address => User) users;

    event UserBound(address indexed user, address indexed referrer);
    event Deposit(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event RewardTransferFailed(address indexed user, uint256 amount);

    struct User {
        address referrer;
        address[] referrals;
        uint256 level;
        uint256 directReward;
        uint256 indirectReward;
        uint256 totalReward;
        bool isBound;
        bool hasDeposited;
    }

    constructor(address _usdtToken, address _htxToken) {
        owner = msg.sender;
        BSC_USDT_Token = IERC20(_usdtToken);
        BSC_HTX_Token = IERC20(_htxToken);
    }

    function bindUser(address _referrer) external {
        require(_referrer != address(0), "Cannot bind a referrer that is the zero address");
        require(_referrer != msg.sender, "Cannot refer yourself");
        require(!users[msg.sender].isBound, "Already bound to a referrer");

        users[msg.sender].referrer = _referrer;
        users[msg.sender].isBound = true;
        users[_referrer].referrals.push(msg.sender);
        users[_referrer].level = users[_referrer].referrals.length;

        emit UserBound(msg.sender, _referrer);
    }

    function deposit(uint256 amount) external {
        require(users[msg.sender].isBound, "Must be bound to a referrer");
        require(amount == DEPOSIT_AMOUNT, "Deposit amount must be equal to 100 USDT");
        // TODO: 允许多次投注, 如果该用户从来没有投注，或者他的推荐总收益已经大于500USDT, 允许他再次投注, 每次投注为100USDT
        // require(!users[msg.sender].hasDeposited, "Already deposited");

        // Transfer 100 USDT from user to contract
        require(BSC_USDT_Token.transferFrom(msg.sender, address(this), DEPOSIT_AMOUNT), "Transfer failed");

        users[msg.sender].hasDeposited = true;

        emit Deposit(msg.sender, DEPOSIT_AMOUNT);

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
                uint256 maxAdditionalReward = MAX_TOTAL_REWARD - users[current].totalReward;

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
