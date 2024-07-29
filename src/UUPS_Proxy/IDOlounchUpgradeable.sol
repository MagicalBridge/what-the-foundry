// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract IDOlounchUpgradeable is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IERC20 public rntToken;
    uint256 public constant MIN_CONTRIBUTION = 0.1 ether;
    uint256 public constant MAX_CONTRIBUTION = 5 ether;
    uint256 public constant MAX_PARTICIPANTS = 1000;
    uint256 public participantCount;
    uint256 public constant TOKEN_RATE = 1000;
    uint256 public constant MIN_GOAL = 100 ether;
    uint256 public constant HARD_CAP = 200 ether;
    uint256 public totalFundsRaised;
    bool public isIDOActive;
    bool public isIDOSuccess;
    mapping(address => uint256) public contributions;
    mapping(address => bool) public hasClaimed;

    event PreSale(address indexed contributor, uint256 amount);
    event ClaimTokens(address indexed claimer, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);

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

    receive() external payable {
        preSale();
    }

    function preSale() public payable onlyWhenIDOActive {
        require(msg.value > 0, "Must send ETH to participate");

        require(msg.value >= MIN_CONTRIBUTION, "Contribution too low");
        require(msg.value <= MAX_CONTRIBUTION, "Contribution too high");
        require(contributions[msg.sender] + msg.value <= MAX_CONTRIBUTION, "Would exceed max contribution");

        require(totalFundsRaised + msg.value <= HARD_CAP, "Hard cap reached");

        if (contributions[msg.sender] == 0) {
            require(participantCount < MAX_PARTICIPANTS, "Max participants reached");
            participantCount++;
        }

        contributions[msg.sender] += msg.value;

        totalFundsRaised += msg.value;

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

    function initialize(IERC20 _rntToken) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        rntToken = _rntToken;
        isIDOActive = true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
