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
    mapping(address => bool) public hasBound; // 是否已经绑定邀请人

    struct User {
        address inviter; // 上级的地址
        address[] invitees; // 下级用户的数组
        uint256 deposit; // 存入的金额
        uint256 directReward; // 直接奖励
        uint256 teamReward; // 团队奖励
        uint256 totalReward; // 用户获得的总奖励
    }

    constructor(address _usdtToken) {
        owner = msg.sender;
        usdtToken = IERC20(_usdtToken);
    }

    function bindUser(address _inviter) external {
        require(!hasBound[msg.sender], "User has already bound an inviter");
        require(_inviter != address(0), "Invalid inviter address");
        require(_inviter != msg.sender, "Cannot invite yourself");
        // 确保邀请人是一个已注册用户，并且已经入金
        require(hasDeposited[_inviter], "Inviter must be an active user");

        // 记录推荐关系
        users[msg.sender].inviter = _inviter;
        users[_inviter].invitees.push(msg.sender);

        // 设置用户为已绑定
        hasBound[msg.sender] = true;
    }

    function deposit(uint256 amount) external payable {}
}
