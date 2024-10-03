// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeRouter {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function WETH() external pure returns (address); // 获取 WBNB 地址
}

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract DailyDividend {
    address private constant PANCAKE_ROUTER =
        0x1b81D678ffb9C0263b24A97847620C99d213eB14; // PancakeSwap Router 地址
    address private constant CAKE = 0xFa60D973F7642B748046464e165A65B7323b0DEE; // CAKE 代币地址

    IPancakeRouter public pancakeRouter;
    IERC20 public cakeToken;

    address public owner;
    uint public lastDividendTime;
    uint public totalUsers; // 用户总数

    mapping(address => uint) public userShares; // 每个用户的份额
    address[] public allUsers; // 存储所有用户地址
    mapping(address => uint) public userDividends; // 每个用户应领取的分红

    event DividendDistributed(uint amountBNB, uint amountCake);
    event Claimed(address indexed user, uint amountCake);

    constructor() {
        pancakeRouter = IPancakeRouter(PANCAKE_ROUTER);
        cakeToken = IERC20(CAKE);
        owner = msg.sender;
    }

    // 添加用户并设置用户的份额
    function addUser(address user, uint shares) external {
        require(msg.sender == owner, "Only owner can add users");
        if (userShares[user] == 0) {
            allUsers.push(user);
            totalUsers++;
        }
        userShares[user] = shares;
    }

    // 每日分红函数，由管理员调用
    function distributeDividends() external payable {
        require(msg.value == 1 ether, "Must send 1 BNB for dividends");
        require(
            block.timestamp >= lastDividendTime + 1 days,
            "Dividends can only be distributed once per day"
        );

        // 兑换 1 BNB 为 CAKE
        address[] memory path;
        path[0] = 0xFa60D973F7642B748046464e165A65B7323b0DEE;
        path[1] = CAKE;

        uint[] memory amounts = pancakeRouter.swapExactETHForTokens{
            value: msg.value
        }(
            0, // 最小接收 CAKE 数量
            path,
            address(this),
            block.timestamp + 300
        );

        uint amountCake = amounts[1];

        // 按照每个用户的份额计算 CAKE 分红
        for (uint i = 0; i < allUsers.length; i++) {
            address user = allUsers[i];
            uint userShare = userShares[user];
            uint userCake = (amountCake * userShare) / totalUsers;
            userDividends[user] += userCake; // 增加用户的分红金额
        }

        lastDividendTime = block.timestamp; // 更新最后分红时间
        emit DividendDistributed(1 ether, amountCake);
    }

    // 用户提取自己的分红
    function claimDividends() external {
        uint dividend = userDividends[msg.sender];
        require(dividend > 0, "No dividends to claim");

        userDividends[msg.sender] = 0; // 重置用户的分红余额
        require(
            cakeToken.transfer(msg.sender, dividend),
            "CAKE transfer failed"
        );

        emit Claimed(msg.sender, dividend);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this");
        _;
    }

    function transferCake(address toAddress, uint amount) external onlyOwner {
        require(toAddress != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");

        // 将 CAKE 代币转移到指定的地址
        require(cakeToken.transfer(toAddress, amount), "Transfer failed");

        emit Claimed(toAddress, amount);
    }

    // 合约接受 BNB
    receive() external payable {}
}
