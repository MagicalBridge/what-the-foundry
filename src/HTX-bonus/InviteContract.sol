// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InviteContract {
    address public owner;
    IERC20 public usdtToken;

    uint256 public constant depositAmount = 100 * 1e18; // 100 USDT
    uint256 public constant directRewardPercent = 38; // 38 USDT 直接奖励
    uint256 public constant teamRewardPercent = 32; // 32 USDT 团队奖励
    uint256 public constant indirectRewardPercent = 2; // 间接奖励百分比 (2%)

    mapping(address => User) users;
    mapping(address => bool) public hasDeposited;
    mapping(address => bool) public hasBound;

    struct User {
        address inviter; // upper user address
        address[] invitees; // lower users address
        uint256 deposit; // deposit USDT amount
        uint256 directReward;
        uint256 teamReward;
        uint256 totalReward;
    }

    constructor(address _usdtToken) {
        owner = msg.sender;
        usdtToken = IERC20(_usdtToken);
    }

    function bindUser(address _inviter) external {
        // make sure user didn't deposit before
        require(!hasBound[msg.sender], "User has already bound an inviter");
        // make sure not the zero address
        require(_inviter != address(0), "Invalid inviter address");
        require(_inviter != msg.sender, "Cannot invite yourself");
        // Make sure the inviter is a registered user and has made a deposit
        require(hasDeposited[_inviter], "Inviter must be an active user");

        // recoder binding relationship
        users[msg.sender].inviter = _inviter;
        users[_inviter].invitees.push(msg.sender);

        // setting inviter address
        hasBound[msg.sender] = true;
    }

    function deposit(uint256 amount) external payable {}
}
