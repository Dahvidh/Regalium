```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract Presale is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public rate;

    function initialize(
        address _token,
        address initialOwner
    ) public initializer {
        require(_token != address(0), "Invalid token");
        require(initialOwner != address(0), "Invalid owner");

        __UUPSUpgradeable_init();
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();

        token = IERC20(_token);

        // Temporary legacy rate.
        // This will be replaced by the RGLM/POL market-price oracle.
        rate = 2;
    }

    function buyTokens() external payable nonReentrant {
        require(msg.value > 0, "Send POL to buy tokens");

        uint256 tokenAmount = msg.value * rate;

        require(
            token.balanceOf(address(this)) >= tokenAmount,
            "Not enough tokens in contract"
        );

        token.safeTransfer(msg.sender, tokenAmount);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        require(balance > 0, "No POL to withdraw");

        (bool sent, ) = payable(owner()).call{value: balance}("");

        require(sent, "Failed to send POL");
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    constructor() {
        _disableInitializers();
    }
}
```
