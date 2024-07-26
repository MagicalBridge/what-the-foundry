// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EsRNTToken is ERC20, Ownable {
    // Reference to the RNT token contract
    IERC20 public rntToken;

    // Array to store lock information
    LockInfo[] public lockArr;
    // Lock period in seconds
    uint256 public lockPeriod = 2592000;

    // Address of the stake pool contract
    address public stakePoolAddress;

    // Struct to store lock information
    struct LockInfo {
        // Address of the user who locked the tokens
        address user;
        // Amount of tokens locked
        uint256 amount;
        // Time when the tokens were locked
        uint256 lockTime;
        // Amount of tokens burned
        uint256 burnedAmount;
    }

    // Constructor
    constructor(IERC20 _rntToken) ERC20("EsRNTToken", "esRNT") Ownable(msg.sender) {
        // Set the RNT token contract address
        rntToken = _rntToken;
    }

    // Function to set the stake pool address
    function setStakePoolAddress(address _stakePoolAddress) external onlyOwner {
        // Only the owner can set the stake pool address
        stakePoolAddress = _stakePoolAddress;
    }

    // Function to mint esRNT tokens
    function mint(address to, uint256 amount) external {
        // Only the stake pool contract can mint esRNT tokens
        require(msg.sender == stakePoolAddress, "Only stake pool can mint esRNT");
        // Mint the tokens
        _mint(to, amount);
        // Record the lock information
        lockArr.push(LockInfo({user: to, amount: amount, lockTime: block.timestamp, burnedAmount: 0}));
    }

    // Function to burn esRNT tokens
    function burn(uint256 id) external {
        // Check if the lock ID is valid
        require(id < lockArr.length, "Invalid lock ID");
        // Get the lock information
        LockInfo storage lockInfo = lockArr[id];
        // Check if the user is the owner
        require(lockInfo.user == msg.sender, "Not the owner");
        // Check if the tokens have not been burned yet
        require(lockInfo.amount > 0, "Already burned");

        // Calculate the unlockable amount
        uint256 unlockableAmount = (block.timestamp - lockInfo.lockTime) * lockInfo.amount / lockPeriod;

        // Check if the unlockable amount is greater than the total amount
        if (unlockableAmount > lockInfo.amount) {
            unlockableAmount = lockInfo.amount;
        }
        // Calculate the burn amount
        uint256 burnAmount = lockInfo.amount - unlockableAmount;
        uint256 totalAmount = lockInfo.amount;

        // Update the lock information
        lockInfo.burnedAmount += burnAmount;
        lockInfo.amount = 0;

        // Check if the contract has sufficient RNT balance
        require(rntToken.balanceOf(address(this)) >= totalAmount, "Insufficient RNT balance");

        // Transfer the unlockable RNT to the user
        if (unlockableAmount > 0) {
            require(rntToken.transfer(msg.sender, unlockableAmount), "Transfer failed");
        }

        // Do not burn the remaining RNT (instead, keep it in the contract)
        // If you really want to burn it, you can transfer it to an unused address, but be careful not to use address(0)

        // Burn all related esRNT tokens
        _burn(msg.sender, totalAmount);

        // Emit the Burned event
        emit Burned(msg.sender, id, burnAmount, unlockableAmount, getUserTotalBurned(msg.sender));
    }

    // Function to get the total burned amount for a user
    function getUserTotalBurned(address user) public view returns (uint256) {
        uint256 totalBurned = 0;
        // Iterate through the lock array
        for (uint256 i = 0; i < lockArr.length; i++) {
            // Check if the user is the owner of the lock
            if (lockArr[i].user == user) {
                // Add the burned amount to the total
                totalBurned += lockArr[i].burnedAmount;
            }
        }
        // Return the total burned amount
        return totalBurned;
    }

    // Event emitted when esRNT tokens are burned
    event Burned(address indexed user, uint256 id, uint256 burnAmount, uint256 unlockedAmount, uint256 totalBurned);
}
