# Regalium (RGLM)

Regalium is an on-chain token ecosystem implemented in Solidity and built with Foundry. It includes an ERC20 token (`RegaliumToken`) plus supporting modules for presale, staking, buyback & burn, and a game reward store. The project is designed for deployment on EVM-compatible chains (example: Polygon).

## Key Features

- Token: `RegaliumToken` (ERC20) with a fixed MAX_SUPPLY of 50,000,000 RGLM and a built-in Chainlink MATIC/USD price feed connector.
- Presale: `Presale` accepts native chain currency (POL on Polygon; MATIC is the legacy name) and distributes RGLM at a fixed rate (1 POL = 2 RGLM).
- Staking: `Staking` allows users to stake RGLM and earn time-based rewards.
- Buyback & Burn: `Buyback` can collect tokens and burn them to reduce circulating supply.
- GameStore: `GameStore` holds reward balances and lets players withdraw earned RGLM.
- Access Control: `RegaliumAccessControl` defines `ADMIN_ROLE` and `PLAYER_ROLE` for role-based permissions.

## Contracts (src/)

- `Regalium.sol` — `RegaliumToken`: ERC20 token, `MAX_SUPPLY = 50_000_000 * 10**18`, Chainlink price feed integration, and helper price-view functions.
- `RegaliumPresale.sol` — `Presale`: Accepts native chain currency, sells RGLM at a fixed rate, and lets the owner withdraw proceeds.
- `RegaliumStaking.sol` — `Staking`: Stake RGLM and accumulate rewards at a configured per-second rate.
- `RegaliumBuyback.sol` — `Buyback`: Receives tokens and burns them via `burnFrom` on the `IRegaliumToken` interface.
- `RegaliumGameStore.sol` — `GameStore`: Tracks and distributes off-chain-earned rewards to players.
- `AccessControl.sol` — `RegaliumAccessControl`: Role-based access control.
- `interfaces/IRegaliumToken.sol` — Interface extending `IERC20` with `burnFrom`.

See `script/DeployAll.s.sol` for the sample deployment flow.

## Project Structure

- `src/` — Solidity contracts (token and modules).
- `script/` — Foundry deployment scripts.
- `test/` — Forge tests (unit and integration tests).
- `mocks/` — Mock contracts used for testing.
- `broadcast/` and `cache/` — Foundry output and build caches (auto-generated).

## Quickstart (Development)

Prerequisites: Foundry (`forge`, `cast`, `anvil`) installed. See https://book.getfoundry.sh/ for setup.

Build:

```bash
forge build
```

Test:

```bash
forge test
```

Format:

```bash
forge fmt
```

Run a local node:

```bash
anvil
```

## Deployment

The deployment script requires both a deployer key and an explicit presale inventory allocation. The allocation is entered as a whole-token RGLM amount, not wei.

```bash
export PRIVATE_KEY=<your_deployer_private_key>
export PRESALE_ALLOCATION=<whole_RGLM_amount>
forge script script/DeployAll.s.sol:DeployAll --rpc-url <RPC_URL> --broadcast
```

Choose the allocation deliberately as part of the token distribution plan. The script rejects a missing, zero, or above-supply allocation before broadcasting. After creating the presale proxy, it transfers the configured RGLM inventory from the deployer and verifies the proxy's token balance before reporting deployment complete.

The script currently contains a sample Chainlink MATIC/USD feed address. **Do not deploy until that address has been independently confirmed for the target network.** The presale currently uses its fixed 1 POL = 2 RGLM rate; it does not dynamically read the Chainlink feed.

Never paste or commit your private key into the repository. Use a secure environment or secret manager.

## Testing Notes

Run `forge test` before deployment. The presale unit tests separately fund the presale mock token balance in `setUp()`; the deployment script now performs and verifies that funding on-chain.

## Security & Auditing

- Contracts use OpenZeppelin primitives for ERC20 and access control patterns.
- This repository is for development and experimentation; obtain a formal audit before production deployment.

## Contributing

- Fork the repo, create a feature branch, and open a pull request.
- Run `forge fmt` and `forge test` before submitting changes.

## License

SPDX-License-Identifier: MIT

## Files of Interest

- Deployment script: [script/DeployAll.s.sol](script/DeployAll.s.sol)
- Token: [src/Regalium.sol](src/Regalium.sol)
- Presale: [src/RegaliumPresale.sol](src/RegaliumPresale.sol)
- Staking: [src/RegaliumStaking.sol](src/RegaliumStaking.sol)
- Buyback: [src/RegaliumBuyback.sol](src/RegaliumBuyback.sol)
- GameStore: [src/RegaliumGameStore.sol](src/RegaliumGameStore.sol)
- Access control: [src/AccessControl.sol](src/AccessControl.sol)
