// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IDOContract is Ownable, ReentrancyGuard {
    // Reference to the RNT token contract
    IERC20 public rntToken;

    // Token rate: 1 ETH = 1000 RNT
    uint256 public constant TOKEN_RATE = 1000;

    // Minimum goal: 100 ETH
    uint256 public constant MIN_GOAL = 100 ether;

    // Hard cap: 200 ETH
    uint256 public constant HARD_CAP = 200 ether;

    // Total funds raised
    uint256 public totalFundsRaised;

    // Flag to indicate if the IDO is active
    bool public isIDOActive;

    // Flag to indicate if the IDO was successful
    bool public isIDOSuccess;

    // Mapping of contributors to their contributions
    mapping(address => uint256) public contributions;

    // Mapping of contributors to their claim status
    mapping(address => bool) public hasClaimed;

    // Event emitted when a contributor participates in the pre-sale
    event PreSale(address indexed contributor, uint256 amount);

    // Event emitted when a contributor claims their tokens
    event ClaimTokens(address indexed claimer, uint256 amount);

    // Event emitted when the owner withdraws funds
    event Withdraw(address indexed owner, uint256 amount);

    // Constructor
    constructor(IERC20 _rntToken) Ownable(msg.sender) {
        // Set the RNT token contract address
        rntToken = _rntToken;
        // Set the IDO to active
        isIDOActive = true;
    }

    // Modifier to ensure the IDO is active
    modifier onlyWhenIDOActive() {
        require(isIDOActive, "IDO is not active");
        _;
    }

    // Modifier to ensure the IDO is inactive
    modifier onlyWhenIDOInactive() {
        require(!isIDOActive, "IDO is still active");
        _;
    }

    // Modifier to ensure the IDO was successful
    modifier onlyWhenIDOSuccess() {
        require(isIDOSuccess, "IDO did not meet the minimum goal");
        _;
    }

    // Receive ETH
    receive() external payable {
        // Participate in the pre-sale
        preSale();
    }

    // Participate in the pre-sale
    function preSale() public payable onlyWhenIDOActive {
        // Ensure the contribution is greater than 0
        require(msg.value > 0, "Must send ETH to participate");

        // Ensure the total funds raised do not exceed the hard cap
        require(totalFundsRaised + msg.value <= HARD_CAP, "Hard cap reached");

        // Record the contributor's contribution
        contributions[msg.sender] += msg.value;

        // Increase the total funds raised
        totalFundsRaised += msg.value;

        // Emit the PreSale event
        emit PreSale(msg.sender, msg.value);

        // Check if the IDO has reached the hard cap
        if (totalFundsRaised >= HARD_CAP) {
            // Set the IDO to inactive
            isIDOActive = false;
            // Set the IDO to successful
            isIDOSuccess = true;
        }
    }

    // End the IDO
    function endIDO() external onlyOwner onlyWhenIDOActive {
        // Set the IDO to inactive
        isIDOActive = false;

        // Check if the IDO met the minimum goal
        if (totalFundsRaised >= MIN_GOAL) {
            // Set the IDO to successful
            isIDOSuccess = true;
        } else {
            // Set the IDO to unsuccessful
            isIDOSuccess = false;
        }
    }

    // Claim tokens
    function claimTokens() external onlyWhenIDOInactive nonReentrant {
        // Ensure the contributor has made a contribution
        require(contributions[msg.sender] > 0, "No contribution made");

        // Ensure the contributor has not already claimed their tokens
        require(!hasClaimed[msg.sender], "Tokens already claimed");

        // Get the contributor's contribution
        uint256 contribution = contributions[msg.sender];

        // Set the contributor's claim status to true
        hasClaimed[msg.sender] = true;

        // Check if the IDO was successful
        if (isIDOSuccess) {
            // Calculate the token amount
            uint256 tokenAmount = contribution * TOKEN_RATE / totalFundsRaised;

            // Transfer the tokens to the contributor
            rntToken.transfer(msg.sender, tokenAmount);

            // Emit the ClaimTokens event
            emit ClaimTokens(msg.sender, tokenAmount);
        } else {
            // Transfer the contribution to the contributor
            (bool success,) = payable(msg.sender).call{value: contribution}("");
            require(success, "Transfer failed");

            // Emit the ClaimTokens event
            emit ClaimTokens(msg.sender, contribution);
        }
    }

    // Withdraw funds
    function withdraw() external onlyOwner onlyWhenIDOSuccess {
        // Get the contract's balance
        uint256 balance = address(this).balance;

        // Transfer the balance to the owner
        payable(owner()).transfer(balance);

        // Emit the Withdraw event
        emit Withdraw(owner(), balance);
    }
}
