// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IDOContract is Ownable, ReentrancyGuard {
    IERC20 public rntToken;
    // 代币的比率是 1:1000 ，所以 1 ETH = 1000 RNT
    uint256 public constant TOKEN_RATE = 1000; // 1 ETH = 1000 RNT
    uint256 public constant MIN_GOAL = 100 ether; // Minimum goal
    uint256 public constant HARD_CAP = 200 ether; // Hard cap

    uint256 public totalFundsRaised; // 本合约中总共已经筹集到的ETH资金数量
    bool public isIDOActive; // IDO活动是否正在进行中
    bool public isIDOSuccess; // IDO是否成功完成

    mapping(address => uint256) public contributions;
    mapping(address => bool) public hasClaimed;

    event PreSale(address indexed contributor, uint256 amount);
    event ClaimTokens(address indexed claimer, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);

    constructor(IERC20 _rntToken) Ownable(msg.sender) {
        rntToken = _rntToken;
        isIDOActive = true;
    }

    modifier onlyWhenIDOActive() {
        require(isIDOActive, "IDO is not active");
        _;
    }

    modifier onlyWhenIDOInactive() {
        require(!isIDOActive, "IDO is still active");
        _;
    }

    modifier onlyWhenIDOSuccess() {
        require(isIDOSuccess, "IDO did not meet the minimum goal");
        _;
    }

    // To receive ETH
    receive() external payable {
        preSale();
    }

    function preSale() public payable onlyWhenIDOActive {
        // 用户发送的 ETH 必须大于等于 0
        require(msg.value > 0, "Must send ETH to participate");
        // 确保总资金不超过硬顶
        require(totalFundsRaised + msg.value <= HARD_CAP, "Hard cap reached");
        // 记录用户的参与金额
        contributions[msg.sender] += msg.value;
        // 总的筹资金额增加
        totalFundsRaised += msg.value;
        // 事件日志 - 用户参与预销售
        emit PreSale(msg.sender, msg.value);

        if (totalFundsRaised >= HARD_CAP) {
            isIDOActive = false;
            isIDOSuccess = true;
        }
    }

    function endIDO() external onlyOwner onlyWhenIDOActive {
        isIDOActive = false;
        if (totalFundsRaised >= MIN_GOAL) {
            isIDOSuccess = true;
        } else {
            isIDOSuccess = false;
        }
    }

    function claimTokens() external onlyWhenIDOInactive nonReentrant {
        require(contributions[msg.sender] > 0, "No contribution made");
        require(!hasClaimed[msg.sender], "Tokens already claimed");

        uint256 contribution = contributions[msg.sender];
        hasClaimed[msg.sender] = true;

        if (isIDOSuccess) {
            uint256 tokenAmount = contribution * TOKEN_RATE / totalFundsRaised;
            rntToken.transfer(msg.sender, tokenAmount);
            emit ClaimTokens(msg.sender, tokenAmount);
        } else {
            (bool success,) = payable(msg.sender).call{value: contribution}("");
            require(success, "Transfer failed");
            emit ClaimTokens(msg.sender, contribution);
        }
    }

    function withdraw() external onlyOwner onlyWhenIDOSuccess {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit Withdraw(owner(), balance);
    }
}
