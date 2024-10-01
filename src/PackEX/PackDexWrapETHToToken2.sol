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
    address private constant UNISWAP_V2_ROUTER = 0xd0F08FE0B691C6a7b280c8DD5C7bC6D44Ad35e35;
    address userAddress = 0x2b754dEF498d4B6ADada538F01727Ddf67D91A7D;

    receive() external payable {}

    constructor(address _owner) {
        owner = _owner;
    }

    function wrapSwapExactETHForTokens(address fromToken, uint256 amount, bytes calldata swapData)
        external
        payable
        nonReentrant
    {
        require(fromToken == ETH_ADDRESS, "Only ETH swaps");
        uint256 fee = (amount * FEE_PERCENTAGE) / FEE_DENOMINATOR;

        require(msg.value >= (amount + fee), "Not enough ETH sent");

        (bool success,) = owner.call{value: fee}("");
        require(success, "Paying fee via transfer failed");
        emit FeeReceived(msg.sender, fee);

        (bool successFlag,) = UNISWAP_V2_ROUTER.call{value: msg.value - fee}(swapData);
        require(successFlag, "Swapping ETH into tokens failed");
    }

    function wrapSwapTokensForExactTokens(address fromToken, uint256 amount, bytes calldata swapData)
        external
        nonReentrant
    {
        uint256 fee = (amount * FEE_PERCENTAGE) / FEE_DENOMINATOR;
        require(IERC20(fromToken).transferFrom(msg.sender, address(this), amount + fee), "Insufficient balance");
        require(IERC20(fromToken).approve(UNISWAP_V2_ROUTER, type(uint256).max), "Approve transfer to swap failed");

        // Pay fee before swapping.
        require(IERC20(fromToken).transfer(owner, fee), "Paying fee via transfer failed");

        (bool successFlag,) = UNISWAP_V2_ROUTER.call(swapData);
        require(successFlag, "Swapping tokens into tokens failed");
    }

    event FeeReceived(address indexed user, uint256 fee);
}
