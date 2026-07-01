# Regalium (RGLM)

Regalium is an on-chain token ecosystem implemented in Solidity and built with Foundry. It includes an ERC20 token (`RegaliumToken`) plus supporting modules for presale, staking, buyback & burn, and a game reward store. The project is designed for deployment on EVM-compatible chains (example: Polygon/Matic).

## Key Features

- Token: `RegaliumToken` (ERC20) with a fixed MAX_SUPPLY of 50,000,000 RGLM and a built-in Chainlink MATIC/USD price feed connector.
- Presale: `Presale` contract accepts MATIC and distributes RGLM at a fixed rate (1 MATIC = 2 RGLM).
- Staking: `Staking` contract allows users to stake RGLM and earn time-based rewards.
- Buyback & Burn: `Buyback` can collect tokens and burn them to reduce circulating supply.
- GameStore: `GameStore` holds reward balances and lets players withdraw earned RGLM.
- Access Control: `RegaliumAccessControl` defines `ADMIN_ROLE` and `PLAYER_ROLE` for role-based permissions.

## Contracts (src/)

- `Regalium.sol` — `RegaliumToken`: ERC20 token, `MAX_SUPPLY = 50_000_000 * 10**18`, Chainlink price feed integration, and helper price-view functions.
- `RegaliumPresale.sol` — `Presale`: Accepts native chain currency (e.g., MATIC), sells RGLM at a fixed rate, owner can withdraw proceeds.
- `RegaliumStaking.sol` — `Staking`: Stake RGLM, accumulate rewards at a configured per-second rate, claimable by stakers.
- `RegaliumBuyback.sol` — `Buyback`: Receives tokens and burns them via `burnFrom` on the `IRegaliumToken` interface.
- `RegaliumGameStore.sol` — `GameStore`: Tracks and distributes off-chain-earned rewards to players; includes `RewardWithdrawn` events.
- `AccessControl.sol` — `RegaliumAccessControl`: Role-based access control using OpenZeppelin's `AccessControl`.
- `interfaces/IRegaliumToken.sol` — Interface extending `IERC20` with `burnFrom`.

See the `script/DeployAll.s.sol` script for a sample deployment flow that deploys the token and supporting contracts.

## Project Structure

- `src/` — Solidity contracts (token, modules, interfaces).
- `script/` — Foundry deployment scripts (`DeployAll.s.sol`).
- `test/` — Forge tests (unit and integration tests).
- `mocks/` — Mock contracts used for testing.
- `broadcast/` & `cache/` — Foundry output and build caches (auto-generated).

## Quickstart (Development)

Prerequisites: `foundry` (forge/cast/anvil) installed. See https://book.getfoundry.sh/ for setup.

1. Build contracts:

```bash
forge build
```

### Test

```bash
forge test
```

3. Format code:

```bash
forge fmt
```

4. Run a local node (Anvil) for manual testing:

```bash
anvil
```

## Deployment

Use the provided Foundry script `script/DeployAll.s.sol`. Set your deployer private key in the environment and run:

```bash
export PRIVATE_KEY=<your_key>
forge script script/DeployAll.s.sol:DeployAll --rpc-url <RPC_URL> --broadcast
```

`DeployAll` expects a Chainlink MATIC/USD price feed address; the sample script includes a placeholder address. Review and replace with the correct feed for your network.

## Testing Notes

- Tests are under `test/` and can be run with `forge test`.
- Mocks for external integrations are in `mocks/`.

## Security & Auditing

- Contracts use OpenZeppelin primitives for ERC20 and access control patterns.
- This repository is for development and experimentation; perform a formal audit before any production deployment.

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

If you want, I can also open a short CONTRIBUTING.md or add a deployment checklist.
