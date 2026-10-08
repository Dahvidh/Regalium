// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Presale is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public token;

    uint256 public rate;

    // Explicit POL withdrawal destination.
    address payable public treasury;

    // -------------------------------------------------------------------------
    // Reentrancy protection
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
    // Initialization
    // -------------------------------------------------------------------------

    function initialize(address _token, address initialOwner) public initializer {
        require(_token != address(0), "Invalid token");
        require(initialOwner != address(0), "Invalid owner");

        __Ownable_init(initialOwner);

        _reentrancyStatus = _NOT_ENTERED;

        token = IERC20(_token);

        // Explicit withdrawal destination.
        treasury = payable(initialOwner);

        // Temporary legacy rate:
        // 1 POL = 2 RGLM.
        //
        // This should be replaced by the RGLM/POL
        // market-price architecture/oracle before production deployment.
        rate = 2;
    }

    // -------------------------------------------------------------------------
    // Presale
    // -------------------------------------------------------------------------

    function buyTokens() external payable nonReentrant {
        require(msg.value > 0, "Send POL to buy tokens");

        uint256 tokenAmount = msg.value * rate;

        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens in contract");

        token.safeTransfer(msg.sender, tokenAmount);
    }

    // -------------------------------------------------------------------------
    // Withdraw POL
    // -------------------------------------------------------------------------

    function withdraw() external nonReentrant onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "No POL to withdraw");
        require(treasury != address(0), "Invalid treasury");

        // Treasury is intentionally owner-controlled.
        // onlyOwner restricts withdrawal access.
        // nonReentrant prevents re-entry.
        // The lint warnings are suppressed because the external
        // native-token transfer is intentional.
        // forge-lint: disable-next-line(arbitrary-send-eth,reentrancy-eth)
        (bool sent,) = treasury.call{value: balance}("");

        require(sent, "Failed to send POL");
    }
    // -------------------------------------------------------------------------
    // Treasury
    // -------------------------------------------------------------------------

    function setTreasury(address payable newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury");

        treasury = newTreasury;
    }

    // -------------------------------------------------------------------------
    // UUPS authorization
    // -------------------------------------------------------------------------

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // -------------------------------------------------------------------------
    // Implementation initialization lock
    // -------------------------------------------------------------------------

    constructor() {
        _disableInitializers();
    }
}
