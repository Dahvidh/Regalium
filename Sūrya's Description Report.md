 Sūrya's Description Report

 Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| c:\Users\user\OneDrive\Desktop\worc to be done\Regalium\regalium\regalium-foundry\src\AccessControl.sol | c516ab60c737dfa50f3d366564981864b305548c |
| c:\Users\user\OneDrive\Desktop\worc to be done\Regalium\regalium\regalium-foundry\src\RegaliumPresale.sol | ae4320be1eba58ccae7c75d5eec7f9c6bf09cacf |
| c:\Users\user\OneDrive\Desktop\worc to be done\Regalium\regalium\regalium-foundry\src\Regalium.sol | efff0502abb3a23f746db1d8c0e5b99af94dbca5 |
| c:\Users\user\OneDrive\Desktop\worc to be done\Regalium\regalium\regalium-foundry\src\interfaces\IRegaliumToken.sol | 93c06d3721637818e757da383d0b967804e4d8fe |


 Contracts Description Table


| **Contract**              | **Type**       | **Bases**      | **Function Name**    | **Visibility** | **Mutability** | **Modifiers**  |
| ------------------------- | -------------- | -------------- | -------------------- | -------------- | -------------- | -------------- |
| **RegaliumAccessControl** | Implementation | AccessControl  | `<Constructor>`      | Public ❗️      | 🛑             | NO❗️           |
|                           |                |                | `grantPlayerRole`    | External ❗️    | 🛑             | `onlyRole`     |
|                           |                |                |                      |                |                |                |
| **Presale**               | Implementation | —              | `<Constructor>`      | Public ❗️      | 🛑             | NO❗️           |
|                           |                |                | `buyTokens`          | External ❗️    | 💵             | NO❗️           |
|                           |                |                | `withdraw`           | External ❗️    | 🛑             | `onlyOwner`    |
|                           |                |                |                      |                |                |                |
| **RegaliumToken**         | Implementation | ERC20, Ownable | `<Constructor>`      | Public ❗️      | 🛑             | ERC20, Ownable |
|                           |                |                | `getMaticPriceInUSD` | Public ❗️      | —              | NO❗️           |
|                           |                |                | `getRglmPriceInUSD`  | Public ❗️      | —              | NO❗️           |
|                           |                |                | `getPriceInMatic`    | Public ❗️      | —              | NO❗️           |
|                           |                |                |                      |                |                |                |
| **IRegaliumToken**        | Interface      | IERC20         | `transferFrom`       | External ❗️    | 🛑             | NO❗️           |
|                           |                |                | `burnFrom`           | External ❗️    | 🛑             | NO❗️           |

  0

 Legend
| **Symbol** | **Meaning**                                |
| ---------- | ------------------------------------------ |
| 🛑         | Function can modify state                  |
| 💵         | Function is payable                        |
| ❗️         | Important or externally visible            |
| NO❗️       | No modifier applied (potential audit area) |
