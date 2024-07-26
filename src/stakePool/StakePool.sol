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

    // Record user stake information
    struct UserStakeInfo {
        uint256 stakedAmount;
        uint256 updateTime;
        uint256 unclaimedAmount;
    }

    // Mapping of user addresses to their stakes
    mapping(address => mapping(address => uint256)) private stakes;

    // Mapping of user addresses to their stake information
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
        // Get the user's stake information from the struct
        UserStakeInfo storage user = userStakeInfo[msg.sender];

        // Update the user's unclaimed rewards
        // The reward calculation needs to be precise to the second level, according to the rules, each staked RNT can earn one esRNT per day
        // One day is converted to seconds, which is 86400
        // The number of seconds since the user's last update time is the number of seconds that need to be added
        // The number of seconds that need to be added * the user's current staked RNT amount / 86400 = the number of esRNT that need to be added
        if (user.stakedAmount > 0) {
            uint256 newUnclaimedAmount = (block.timestamp - user.updateTime) * user.stakedAmount / 86400;
            user.unclaimedAmount += newUnclaimedAmount;

            if (newUnclaimedAmount > 0) {
                emit RewardUpdated(msg.sender, user.unclaimedAmount);
            }
        } else {
            // Record the user's first stake time
            user.updateTime = block.timestamp;
        }

        // Update the user's staked amount and update time
        user.stakedAmount += amount;

        // Transfer the user's RNT tokens to this contract
        // transferFrom needs to be set to allow this contract to transfer RNT tokens from the user's address
        rntToken.transferFrom(msg.sender, address(this), amount);

        // Update the user's staked RNT amount in this contract
        stakes[address(rntToken)][msg.sender] += amount;

        emit Staked(msg.sender, amount);
    }

    function unStake(uint256 amount) public {
        // Get the user's stake information from the struct
        UserStakeInfo storage user = userStakeInfo[msg.sender];
        // The user's unstaked RNT amount cannot exceed their current unclaimed RNT amount
        require(user.stakedAmount >= amount, "Insufficient staked amount");

        // Update the user's unclaimed rewards when unstaking
        uint256 newUnclaimedAmount = (block.timestamp - user.updateTime) * user.stakedAmount / 86400;
        user.unclaimedAmount += newUnclaimedAmount;

        if (newUnclaimedAmount > 0) {
            emit RewardUpdated(msg.sender, user.unclaimedAmount);
        }

        // Update the user's staked amount and update time
        user.stakedAmount -= amount;
        user.updateTime = block.timestamp;

        // Transfer the user's RNT tokens to their address
        rntToken.transfer(msg.sender, amount);

        // Update the user's staked RNT amount in this contract
        stakes[address(rntToken)][msg.sender] -= amount;

        emit Unstaked(msg.sender, amount);
    }

    function claim() public {
        // Get the user's stake information from the struct
        UserStakeInfo storage user = userStakeInfo[msg.sender];

        // Calculate the user's total rewards at the time of claiming
        uint256 reward = user.unclaimedAmount + (block.timestamp - user.updateTime) * user.stakedAmount / 86400;

        // Reset the user's unclaimed rewards and last update time
        user.unclaimedAmount = 0;
        user.updateTime = block.timestamp;

        // Transfer the equivalent RNT from the stake pool to the esRNT contract
        rntToken.safeTransfer(address(esrntToken), reward);

        // Mint the rewards' esRNT to the user
        esrntToken.mint(msg.sender, reward);

        emit Claimed(msg.sender, reward);
    }
}
