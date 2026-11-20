# Regalium (RGLM)

Regalium is an on-chain token ecosystem implemented in Solidity and built with Foundry. It includes an ERC20 token plus supporting modules for presale, staking, buyback & burn, and a game reward store. The project is designed for deployment on EVM-compatible chains such as Polygon.

## Key Features

- Token: `RegaliumToken` (ERC20) with a fixed MAX_SUPPLY of 100,000,000 RGLM and a Chainlink MATIC/USD price-feed connector.
- Presale: `Presale` accepts native chain currency (POL on Polygon; MATIC is the legacy name) and distributes RGLM at a fixed rate (1 POL = 2 RGLM).
- Team vesting: the team's 40,000,000 RGLM allocation is held by a dedicated vesting contract for four years, with a one-year cliff.
- GameStore: holds the 40,000,000 RGLM game-reward allocation and lets players withdraw earned RGLM.
- Presale inventory: the presale proxy receives the 20,000,000 RGLM sale allocation.
- Staking and buyback contracts also exist in the repository, but are not part of the three-way allocation performed by the current deployment script.

## Token Allocation

| Allocation | Percentage | RGLM |
| --- | ---: | ---: |
| Team vesting | 40% | 40,000,000 |
| GameStore | 40% | 40,000,000 |
| Presale | 20% | 20,000,000 |
| **Total** | **100%** | **100,000,000** |

The deployment script requires the three configured allocations to sum to exactly 100,000,000 RGLM and enforces the 40% / 40% / 20% split. It transfers the complete supply from the deployer and verifies the balance held by each destination.

### Team Vesting Schedule

- Vesting starts at deployment.
- No team tokens are claimable before the one-year cliff.
- At the one-year cliff, 25% of the team allocation (10,000,000 RGLM) becomes claimable.
- The remaining 75% (30,000,000 RGLM) vests linearly over the following three years.
- The named beneficiary can claim vested tokens by calling `release()` on the vesting contract.

The team beneficiary is supplied at deployment as `TEAM_BENEFICIARY`. Use a secure team multisig wallet where possible. The beneficiary address is fixed in the vesting contract and cannot be changed.

## GameStore Daily Reward Controls

The upgradeable GameStore now enforces two owner-configured limits on newly assigned rewards:
- A maximum RGLM amount per player per UTC day.
- A maximum total RGLM amount across all players per UTC day.

The owner configures both limits with `setRewardLimits(playerCap, globalCap)`, using 18-decimal token units. Setting either limit to zero pauses new reward assignments. Limits reset automatically at the next UTC day. Existing accrued player balances remain withdrawable and are not erased by a limit change.

The owner-only `rewardUser` function should only be called after the game backend verifies match results, eligibility, and anti-cheat checks. The contract does not independently verify gameplay or calculate USD values. The $5–$10/day target must be translated into RGLM by a trusted reward service using a documented price methodology; it is not a guaranteed payout.

For an existing proxy upgrade, the owner must set non-zero limits after upgrading before new rewards can be assigned. Existing storage declarations are preserved and the new limit state is appended. Review the storage layout and run the full Foundry upgrade tests before authorizing an upgrade.

## Player Reward Economics

The GameStore receives a 40,000,000 RGLM reserve. A planning target of approximately $5–$10 per day for highly active, high-performing players is an economic objective, not a guaranteed on-chain payout. Actual RGLM amounts must be calculated from a defensible market-price source and a sustainable emissions budget. The GameStore owner currently assigns rewards; gameplay scoring, anti-cheat checks, daily limits, and the 1,000 / 5,000 / 10,000 daily-active-player simulations must be implemented and validated in the game/reward service before promising fixed daily earnings.

The current GameStore contract does not itself enforce a daily USD value or a daily per-player cap. Do not advertise guaranteed dollar-denominated rewards until those controls and the price methodology have been implemented and independently tested.

## Contracts (src/)

- `Regalium.sol` — `RegaliumToken`: ERC20 token, fixed 100,000,000 RGLM supply, Chainlink price-feed integration, and helper price-view functions.
- `RegaliumPresale.sol` — `Presale`: accepts native chain currency, sells RGLM at a fixed rate, and lets the owner withdraw proceeds.
- `RegaliumGameStore.sol` — `GameStore`: tracks and distributes off-chain-earned rewards with per-player and global daily RGLM assignment caps.
- `TeamVesting.sol` — non-upgradeable team allocation vesting vault with a one-year cliff and four-year total schedule.
- `RegaliumStaking.sol` — `Staking`: stake and reward functionality.
- `RegaliumBuyback.sol` — `Buyback`: buyback and burn functionality.
- `AccessControl.sol` — role-based access control.
- `interfaces/IRegaliumToken.sol` — token interface extending `IERC20` with `burnFrom`.

See `script/DeployAll.s.sol` for the deployment flow.

## Project Structure

- `src/` — Solidity contracts.
- `script/` — Foundry deployment scripts.
- `test/` — Forge tests.
- `mocks/` — mock contracts used by tests.
- `broadcast/` and `cache/` — generated deployment and build data.

## Quickstart

Prerequisites: Foundry (`forge`, `cast`, `anvil`) installed. See https://book.getfoundry.sh/.

```bash
forge build
forge test
forge fmt
anvil
```

## Deployment

Set the allocation values as whole-token RGLM amounts (not wei). These values implement the approved split:

```bash
export PRIVATE_KEY=<your_deployer_private_key>
export TEAM_BENEFICIARY=<your_team_multisig_wallet_address>
export TEAM_ALLOCATION=40000000
export GAMESTORE_ALLOCATION=40000000
export PRESALE_ALLOCATION=20000000
forge script script/DeployAll.s.sol:DeployAll --rpc-url <RPC_URL> --broadcast
```

The script rejects zero allocations, a zero team beneficiary, or allocations that do not total exactly 100,000,000 RGLM and match the 40/40/20 split. It deploys the token, GameStore proxy, Presale proxy, and TeamVesting contract; distributes all tokens; then verifies all three destination balances and that the deployer retains zero RGLM.

The script currently contains a sample Chainlink MATIC/USD feed address. **Do not deploy until that address has been independently confirmed for the target network.** The presale currently uses its fixed 1 POL = 2 RGLM rate; it does not dynamically read the Chainlink feed. This fixed sale rate is not a guarantee of the RGLM/POL market price or liquidity-pool value.

Never paste or commit your private key into the repository. Use a secure environment or secret manager. Confirm the team beneficiary wallet carefully before deployment: it is immutable in the vesting contract.

## Testing and Security

Run `forge fmt`, `forge build`, and `forge test` before deployment. The team vesting tests should cover the cliff, linear vesting, releases, and full vesting at four years. The presale tests separately fund the mock presale inventory.

This repository is for development and experimentation; obtain an independent security review before production deployment. These source changes do not alter or mint tokens for an already deployed token contract. A new fixed-supply token deployment is required to create the 100,000,000 RGLM supply, and all ecosystem contracts/integrations must then point to that new token address. The deployment script has not been executed against a live network as part of these source changes.

## Contributing

Fork the repo, create a feature branch, and open a pull request. Run `forge fmt`, `forge build`, and `forge test` before submitting changes.

## License

SPDX-License-Identifier: MIT
