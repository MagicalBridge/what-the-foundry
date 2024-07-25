// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EsRNTToken is ERC20 {
    IERC20 public rntToken;

    LockInfo[] public lockArr;
    uint256 public lockPeriod = 2592000;

    struct LockInfo {
        address user;
        uint256 amount;
        uint256 lockTime;
        uint256 burnedAmount;
    }

    constructor(IERC20 _rntToken) ERC20("EsRNTToken", "esRNT") {
        // 部署的时候，需要传入RNT的地址
        rntToken = _rntToken;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);

        // 记录锁仓信息，其中的时间是mint那一刻的时间
        lockArr.push(LockInfo({user: to, amount: amount, lockTime: block.timestamp, burnedAmount: 0}));
    }

    // 用户解锁esRNT
    function burn(uint256 id) external {
        require(id < lockArr.length, "Invalid lock ID");
        LockInfo storage lockInfo = lockArr[id];
        require(lockInfo.user == msg.sender, "Not the owner");
        require(lockInfo.amount > 0, "Already burned");

        uint256 unlockableAmount = (block.timestamp - lockInfo.lockTime) * lockInfo.amount / lockPeriod;

        if (unlockableAmount > lockInfo.amount) {
            unlockableAmount = lockInfo.amount;
        }
        // 燃烧的代币数量
        uint256 burnAmount = lockInfo.amount - unlockableAmount;
        uint256 totalAmount = lockInfo.amount;

        // 更新锁定信息
        lockInfo.burnedAmount += burnAmount;
        lockInfo.amount = 0;

        // 检查合约的 RNT 余额
        require(rntToken.balanceOf(address(this)) >= totalAmount, "Insufficient RNT balance");

        // 处理可解锁的 RNT
        if (unlockableAmount > 0) {
            require(rntToken.transfer(msg.sender, unlockableAmount), "Transfer failed");
        }

        // 处理不可解锁的 RNT（这里选择将其保留在合约中，而不是真正"销毁"）
        // 如果真的需要销毁，可以转到一个永不使用的地址，但要小心不要使用地址(0)

        // 销毁全部相关的 esRNT
        _burn(msg.sender, totalAmount);

        emit Burned(msg.sender, id, burnAmount, unlockableAmount, getUserTotalBurned(msg.sender));
    }

    function getUserTotalBurned(address user) public view returns (uint256) {
        uint256 totalBurned = 0;
        for (uint256 i = 0; i < lockArr.length; i++) {
            if (lockArr[i].user == user) {
                totalBurned += lockArr[i].burnedAmount;
            }
        }
        return totalBurned;
    }

    event Burned(address indexed user, uint256 id, uint256 burnAmount, uint256 unlockedAmount, uint256 totalBurned);
}
