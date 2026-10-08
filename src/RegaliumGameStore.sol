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

    // -------------------------------------------------------------------------
    // Reentrancy Guard
    // -------------------------------------------------------------------------

    uint256 private _reentrancyStatus;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    modifier nonReentrant() {
        require(_reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");

        _reentrancyStatus = _ENTERED;

        _;

        _reentrancyStatus = _NOT_ENTERED;
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event RewardWithdrawn(address indexed user, uint256 amount);

    // -------------------------------------------------------------------------
    // Initializer
    // -------------------------------------------------------------------------

    function initialize(address _token, address initialOwner) public initializer {
        require(_token != address(0), "Invalid token");

        require(initialOwner != address(0), "Invalid owner");

        __Ownable_init(initialOwner);

        _reentrancyStatus = _NOT_ENTERED;

        token = IERC20(_token);
    }

    // -------------------------------------------------------------------------
    // Reward Management
    // -------------------------------------------------------------------------

    function rewardUser(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid user");

        require(amount > 0, "Invalid amount");

        rewards[user] += amount;
    }

    // -------------------------------------------------------------------------
    // Reward Withdrawal
    // -------------------------------------------------------------------------

    function withdraw() external nonReentrant {
        uint256 amount = rewards[msg.sender];

        require(amount > 0, "No rewards to withdraw");

        // Effects before interaction.
        rewards[msg.sender] = 0;

        // Interaction.
        token.safeTransfer(msg.sender, amount);

        emit RewardWithdrawn(msg.sender, amount);
    }

    // -------------------------------------------------------------------------
    // UUPS Authorization
    // -------------------------------------------------------------------------

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // -------------------------------------------------------------------------
    // Implementation Constructor
    // -------------------------------------------------------------------------

    constructor() {
        _disableInitializers();
    }
}
