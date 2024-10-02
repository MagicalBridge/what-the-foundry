// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PackDexWrapper is ReentrancyGuard {
    address public owner;
    uint256 public constant FEE_PERCENTAGE = 15; // 0.15% fee
    uint256 public constant FEE_DENOMINATOR = 10000;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant AGGREGATOR_ADDRESS = 0xd0F08FE0B691C6a7b280c8DD5C7bC6D44Ad35e35; // 0.01% fee

    receive() external payable {}

    constructor(address _owner) {
        owner = _owner;
    }

    function wrapSwapExactETHForTokens(address fromToken, uint256 amount, bytes calldata swapData)
        external
        payable
        nonReentrant
    {
        require(amount > 0, "Amount must be greater than zero");
        require(fromToken == ETH_ADDRESS, "Only ETH swaps");
        uint256 fee = (amount * FEE_PERCENTAGE) / FEE_DENOMINATOR;

        require(msg.value >= (amount + fee), "Not enough ETH sent");

        (bool success,) = owner.call{value: fee}("");
        require(success, "Paying fee via transfer failed");
        emit FeeReceived(msg.sender, fee);

        (bool successFlag,) = AGGREGATOR_ADDRESS.call{value: msg.value - fee}(swapData);
        require(successFlag, "Swapping ETH into tokens failed");
    }

    function wrapSwapTokensForExactTokens(address fromToken, uint256 amount, bytes calldata swapData)
        external
        nonReentrant
    {
        require(amount > 0, "Amount must be greater than zero");
        uint256 fee = (amount * FEE_PERCENTAGE) / FEE_DENOMINATOR;
        uint256 totalAmount = amount + fee;
        require(IERC20(fromToken).transferFrom(msg.sender, address(this), totalAmount), "Insufficient balance");

        // Pay fee before swapping.
        require(IERC20(fromToken).transfer(owner, fee), "Paying fee via transfer failed");

        // Check allowance to avoid repetitive approvals
        uint256 allowance = IERC20(fromToken).allowance(address(this), AGGREGATOR_ADDRESS);
        if (allowance < amount) {
            // Approve the maximum token amount if the allowance is insufficient
            IERC20(fromToken).approve(AGGREGATOR_ADDRESS, type(uint256).max);
        }

        (bool successFlag,) = AGGREGATOR_ADDRESS.call(swapData);
        require(successFlag, "Swapping tokens into tokens failed");
    }

    event FeeReceived(address indexed user, uint256 fee);
}
