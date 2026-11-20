// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract GameStore is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    mapping(address => uint256) public rewards;

    // Existing storage: keep these declarations in their original order.
    uint256 private _reentrancyStatus;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // Appended storage for UUPS-safe upgrades.
    uint256 public dailyPlayerRewardCap;
    uint256 public dailyGlobalRewardCap;
    uint256 public globalRewardsAssignedToday;
    uint256 public globalRewardDay;
    mapping(address => uint256) public playerRewardsAssignedToday;
    mapping(address => uint256) public playerRewardDay;
    uint256 public totalOutstandingRewards;
    bool public outstandingLiabilityInitialized;

    event RewardWithdrawn(address indexed user, uint256 amount);
    event RewardAssigned(address indexed user, uint256 amount, uint256 indexed day);
    event RewardLimitsUpdated(uint256 dailyPlayerCap, uint256 dailyGlobalCap);

    modifier nonReentrant() {
        require(_reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        _reentrancyStatus = _ENTERED;
        _;
        _reentrancyStatus = _NOT_ENTERED;
    }

    function initialize(address _token, address initialOwner) public initializer {
        require(_token != address(0), "Invalid token");
        require(initialOwner != address(0), "Invalid owner");
        __Ownable_init(initialOwner);
        _reentrancyStatus = _NOT_ENTERED;
        token = IERC20(_token);
        outstandingLiabilityInitialized = true;
    }

    /// @notice One-time migration for an existing proxy: supply the sum of all users' accrued rewards.
    /// The owner must calculate this from the pre-upgrade rewards mapping before enabling assignments.
    function initializeOutstandingRewards(uint256 legacyOutstanding) external onlyOwner {
        require(!outstandingLiabilityInitialized, "Liability already initialized");
        require(token.balanceOf(address(this)) >= legacyOutstanding, "Legacy liabilities exceed reserve");
        totalOutstandingRewards = legacyOutstanding;
        outstandingLiabilityInitialized = true;
    }

    /// @notice Configure whole-day RGLM assignment limits (amounts use token's 18 decimals).
    /// Setting either cap to zero pauses new reward assignments.
    function setRewardLimits(uint256 playerCap, uint256 globalCap) external onlyOwner {
        require(playerCap <= globalCap || globalCap == 0, "Player cap exceeds global cap");
        dailyPlayerRewardCap = playerCap;
        dailyGlobalRewardCap = globalCap;
        emit RewardLimitsUpdated(playerCap, globalCap);
    }

    /// @notice Assign rewards after the game backend has verified gameplay and anti-cheat checks.
    /// This contract enforces per-wallet and ecosystem-wide daily RGLM limits.
    function rewardUser(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid user");
        require(amount > 0, "Invalid amount");
        require(outstandingLiabilityInitialized, "Outstanding liabilities not initialized");
        require(dailyPlayerRewardCap > 0 && dailyGlobalRewardCap > 0, "Rewarding is paused");

        uint256 currentDay = block.timestamp / 1 days;

        if (globalRewardDay != currentDay) {
            globalRewardDay = currentDay;
            globalRewardsAssignedToday = 0;
        }
        if (playerRewardDay[user] != currentDay) {
            playerRewardDay[user] = currentDay;
            playerRewardsAssignedToday[user] = 0;
        }

        require(
            playerRewardsAssignedToday[user] + amount <= dailyPlayerRewardCap,
            "Daily player reward limit exceeded"
        );
        require(
            globalRewardsAssignedToday + amount <= dailyGlobalRewardCap,
            "Daily global reward limit exceeded"
        );
        require(
            token.balanceOf(address(this)) >= totalOutstandingRewards + amount,
            "Insufficient uncommitted reward reserve"
        );

        playerRewardsAssignedToday[user] += amount;
        globalRewardsAssignedToday += amount;
        rewards[user] += amount;
        totalOutstandingRewards += amount;

        emit RewardAssigned(user, amount, currentDay);
    }

    function withdraw() external nonReentrant {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "No rewards to withdraw");
        rewards[msg.sender] = 0;
        totalOutstandingRewards -= amount;
        token.safeTransfer(msg.sender, amount);
        emit RewardWithdrawn(msg.sender, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    constructor() {
        _disableInitializers();
    }
}
