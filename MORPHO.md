# Morpho V2 Integration

This document provides comprehensive technical documentation of Aruna's Morpho V2 MetaMorpho integration, including architecture, implementation details, and safety mechanisms.

## Overview

The `MorphoVaultAdapter` integrates with Morpho's MetaMorpho vaults, which are ERC-4626 compliant noncustodial risk management vaults built on Morpho Blue. This integration provides users with access to optimized yields through Morpho's peer-to-peer lending markets.

**File:** `src/vaults/MorphoVaultAdapter.sol`

## Architecture

### What is MetaMorpho?

MetaMorpho is Morpho's vault system that sits on top of Morpho Blue, the base lending protocol. It provides:

- Automated capital allocation across multiple Morpho Blue markets
- Curator-managed risk strategies
- Higher yields than traditional lending protocols
- Full ERC-4626 compliance for composability

### Design Pattern

The adapter wraps MetaMorpho vaults, providing an additional layer of yield distribution logic:

```
User (USDC) → MorphoVaultAdapter → MetaMorpho Vault → Morpho Blue Markets
                      ↓
                 Mints shares (yfMorpho tokens)
                      ↓
                 Tracks in YieldRouter
```

### Integration Flow

```
Deposit Flow:
  User approves USDC → Adapter
  Adapter receives USDC
  Adapter deposits to MetaMorpho → receives MetaMorpho shares
  Adapter mints yfMorpho shares to user (1:1 with deposits)
  YieldRouter updates user shares

Withdraw Flow:
  User requests withdrawal
  Adapter burns yfMorpho shares
  Adapter redeems from MetaMorpho → receives USDC
  Adapter transfers USDC to user
  YieldRouter updates user shares

Harvest Flow:
  **Investor triggers harvestYield() from frontend** (24-hour minimum interval)
  Calculate yield: MetaMorpho value - total shares
  Withdraw yield from MetaMorpho
  Distribute via YieldRouter:
    - 70% → investors (proportional to shares)
    - 25% → public goods via OctantDonationModule
    - 5% → protocol treasury

**⚠️ Important**: Yield must be manually harvested via the "Harvest Yield" button in the investor dashboard. Public goods donations only occur AFTER harvest is triggered.
```

## Interfaces

### IMetaMorpho

Primary interface for MetaMorpho vaults:

```solidity
interface IMetaMorpho is IERC4626 {
    /**
     * @notice Returns the Morpho Blue protocol address
     */
    function MORPHO() external view returns (address);

    /**
     * @notice Returns the vault curator
     */
    function curator() external view returns (address);

    /**
     * @notice Returns the vault fee in basis points
     */
    function fee() external view returns (uint96);

    /**
     * @notice ERC-4626 deposit function
     */
    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares);

    /**
     * @notice ERC-4626 withdraw function
     */
    function withdraw(uint256 assets, address receiver, address owner)
        external
        returns (uint256 shares);

    /**
     * @notice Convert MetaMorpho shares to assets
     */
    function convertToAssets(uint256 shares)
        external
        view
        returns (uint256);

    /**
     * @notice Get total assets under management
     */
    function totalAssets() external view returns (uint256);
}
```

**Key Functions Used:**
- `deposit()` - Supply assets to MetaMorpho
- `withdraw()` - Retrieve assets from MetaMorpho
- `convertToAssets()` - Calculate current value of shares
- `MORPHO()` - Get underlying Morpho Blue address

### IMorphoBlue

Simplified interface for Morpho Blue (used for reference):

```solidity
interface IMorphoBlue {
    struct MarketParams {
        address loanToken;
        address collateralToken;
        address oracle;
        address irm;
        uint256 lltv;
    }

    function supply(
        MarketParams memory marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        bytes memory data
    ) external returns (uint256, uint256);
}
```

Note: We interact with Morpho Blue indirectly through MetaMorpho, not directly.

## Accounting Mechanisms

### Share Tracking

The adapter maintains two layers of shares:

1. **Adapter Shares (yfMorpho)**: Minted to users, represent deposits
2. **MetaMorpho Shares**: Held by adapter, represent underlying value

```solidity
// Track MetaMorpho shares separately
uint256 private lastMetaMorphoShares;

// Update on deposits
lastMetaMorphoShares += metaMorphoSharesReceived;

// Update on withdrawals
lastMetaMorphoShares -= metaMorphoSharesBurned;
```

### Asset Calculation

The adapter's total assets come from MetaMorpho's share value:

```solidity
function totalAssets() public view returns (uint256) {
    if (lastMetaMorphoShares == 0) return 0;

    // MetaMorpho automatically includes accrued yield
    return metaMorphoVault.convertToAssets(lastMetaMorphoShares);
}
```

**Why This Works:**
- MetaMorpho's `convertToAssets()` accounts for all yield
- Includes interest from Morpho Blue markets
- Reflects current market conditions
- Updates automatically as markets accrue interest

### Yield Calculation

Similar to Aave integration, yield is the appreciation above deposits:

```solidity
uint256 currentAssets = totalAssets();           // From MetaMorpho
uint256 expectedBalance = totalSupply();          // Adapter shares minted
uint256 yieldGenerated = currentAssets - expectedBalance;
```

**Example:**

Initial:
- User deposits: 1,000 USDC
- MetaMorpho shares received: 950 (0.95 exchange rate)
- Adapter shares minted: 1,000

After 30 days at 8.2% APY:
- MetaMorpho shares: 950 (unchanged)
- MetaMorpho share value: 1,006.71 USDC (appreciation)
- Adapter shares: 1,000 (unchanged)
- Yield generated: 6.71 USDC

## ERC-4626 Compliance

### Required Functions

Full implementation of the standard:

```solidity
function deposit(uint256 assets, address receiver)
    external
    returns (uint256 shares);

function mint(uint256 shares, address receiver)
    external
    returns (uint256 assets);

function withdraw(uint256 assets, address receiver, address owner)
    external
    returns (uint256 shares);

function redeem(uint256 shares, address receiver, address owner)
    external
    returns (uint256 assets);

function totalAssets() external view returns (uint256);
function convertToShares(uint256 assets) external view returns (uint256);
function convertToAssets(uint256 shares) external view returns (uint256);

function maxDeposit(address) external view returns (uint256);
function maxMint(address) external view returns (uint256);
function maxWithdraw(address owner) external view returns (uint256);
function maxRedeem(address owner) external view returns (uint256);

function previewDeposit(uint256 assets) external view returns (uint256);
function previewMint(uint256 shares) external view returns (uint256);
function previewWithdraw(uint256 assets) external view returns (uint256);
function previewRedeem(uint256 shares) external view returns (uint256);
```

All functions properly implemented via OpenZeppelin's ERC4626 base contract.

## Safety Mechanisms

### 1. Reentrancy Protection

All external functions are protected:

```solidity
function deposit(uint256 assets, address receiver)
    public
    override
    nonReentrant
    returns (uint256)
{
    // Function implementation
}
```

### 2. Try-Catch on External Calls

All MetaMorpho interactions use error handling:

```solidity
try metaMorphoVault.deposit(assets, address(this))
    returns (uint256 metaMorphoShares)
{
    lastMetaMorphoShares += metaMorphoShares;
    emit MetaMorphoSharesUpdated(lastMetaMorphoShares, lastMetaMorphoShares - metaMorphoShares);
} catch {
    revert MetaMorphoCallFailed();
}
```

This prevents:
- Silent failures in MetaMorpho calls
- State inconsistencies on errors
- Fund loss from failed operations

### 3. Minimum Shares Requirement

Prevents inflation attacks on first deposit:

```solidity
uint256 public constant MIN_SHARES = 1000;

if (shares < MIN_SHARES && totalSupply() == 0) {
    revert MinimumSharesNotMet();
}
```

### 4. Asset Matching Verification

Constructor validates vault compatibility:

```solidity
require(
    address(metaMorphoVault.asset()) == address(_asset),
    "Asset mismatch with MetaMorpho vault"
);
```

### 5. Share Tracking

Explicit tracking prevents accounting errors:

```solidity
uint256 private lastMetaMorphoShares;

event MetaMorphoSharesUpdated(uint256 newShares, uint256 oldShares);
```

Benefits:
- Always know exact MetaMorpho position
- Can detect discrepancies
- Audit trail via events
- Prevents silent balance changes

### 6. Pause Mechanism

Emergency stop for deposits:

```solidity
if (isPaused) revert ContractPaused();
```

Allows:
- Stopping new deposits during issues
- Withdrawals still work (users can exit)
- Time to address problems

### 7. Preview Function Protection

Uses standard ERC-4626 preview functions:

```solidity
shares = previewDeposit(assets);
assets = previewWithdraw(shares);
assets = previewRedeem(shares);
```

These functions:
- Calculate exact exchange rates
- Account for current yield
- Prevent manipulation
- Follow ERC-4626 standard

## Role Model Compliance

### Respecting MetaMorpho Roles

The adapter respects MetaMorpho's governance:

**Curator:**
- Manages vault strategies
- Allocates capital to markets
- We don't interfere with these decisions

**Guardian:**
- Can pause the vault
- Emergency controls
- We respect their authority

**Fee Recipient:**
- Receives vault performance fees
- We don't modify fee structure

**Our Role:**
- Simple wrapper for yield distribution
- No direct market manipulation
- Works through MetaMorpho's interfaces
- Maintains Morpho's security model

### Safe Adapter Wiring

Proper integration patterns:

```solidity
// Always use MetaMorpho's functions
metaMorphoVault.deposit(assets, address(this));

// Never try to bypass MetaMorpho
// Never interact with Morpho Blue directly
// Never manipulate vault state
```

## Contract Addresses

### Base Sepolia Testnet

**Infrastructure Addresses:**

```
USDC: 0x036CbD53842c5426634e7929541eC2318f3dCF7e
```

**Deployed Aruna Contracts (Nov 2024):**

```
MorphoVaultAdapter: 0x16dea7eE228c0781938E6869c07ceb2EEA7bd564
MockMetaMorpho: 0x7deB84aAe25A2168782E6c8C0CF30714cbaaA025
```

**Note**: For Base Sepolia testnet, we deployed MockMetaMorpho since there are no production MetaMorpho vaults available on the testnet. This mock vault simulates MetaMorpho behavior with an 8.2% APY for testing purposes.

View on BaseScan:
- [MorphoVaultAdapter](https://sepolia.basescan.org/address/0x16dea7eE228c0781938E6869c07ceb2EEA7bd564)
- [MockMetaMorpho](https://sepolia.basescan.org/address/0x7deB84aAe25A2168782E6c8C0CF30714cbaaA025)

### Deployment Configuration

When deploying, set environment variable:

```bash
METAMORPHO_VAULT=DEPLOY_MOCK_METAMORPHO
```

This triggers automatic MockMetaMorpho deployment for testing.

### For Mainnet Deployment

To use a real MetaMorpho vault:

```bash
METAMORPHO_VAULT=<actual_metamorpho_vault_address>
```

To find MetaMorpho vaults:
1. Visit https://app.morpho.org
2. Select target network
3. Filter for USDC vaults
4. Copy vault address

All deployment addresses saved to:
```
Aruna-Contract/deployments/84532.json
```

## Testing

### Unit Tests

Recommended test scenarios:

```solidity
// Basic operations
testDeposit() - Verify MetaMorpho interaction
testWithdraw() - Verify proper redemption
testShareTracking() - Verify lastMetaMorphoShares updates

// Yield mechanics
testYieldAccrual() - Verify MetaMorpho share appreciation
testHarvest() - Verify yield extraction
testMetaMorphoShareConversion() - Test convertToAssets

// Safety
testAssetMismatch() - Constructor should revert
testMetaMorphoCallFailure() - Should handle errors
testMinimumShares() - First deposit validation
testPause() - Pause should block deposits

// Integration
testFullFlow() - Complete user journey
testMetaMorphoIntegration() - Verify MetaMorpho calls work
testYieldDistribution() - Verify 70/25/5 split
```

### Integration Testing

Test with real or mock MetaMorpho:

```bash
forge test --fork-url https://sepolia.base.org --match-contract MorphoVaultAdapterTest -vvv
```

## Deployment

### Prerequisites

1. MetaMorpho vault address on Base Sepolia
2. Configured environment variables
3. Base Sepolia ETH for gas

### Environment Configuration

Add to `.env`:

```bash
METAMORPHO_VAULT=0x<your_metamorpho_vault_address>
```

### Deployment Process

```bash
forge script script/DeployAruna.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

### Post-Deployment Verification

Verify the integration:

```bash
# Check MetaMorpho vault address
cast call <MORPHO_VAULT_ADAPTER> "getMetaMorphoVault()" --rpc-url https://sepolia.base.org

# Check Morpho Blue address
cast call <MORPHO_VAULT_ADAPTER> "getMorphoBlue()" --rpc-url https://sepolia.base.org

# Check asset compatibility
cast call <MORPHO_VAULT_ADAPTER> "asset()" --rpc-url https://sepolia.base.org

# Check current MetaMorpho shares
cast call <MORPHO_VAULT_ADAPTER> "getMetaMorphoShares()" --rpc-url https://sepolia.base.org
```

## Frontend Integration

### Using Harvest Functionality

Investors trigger yield harvesting from the investor dashboard using the `useHarvestMorphoYield()` hook:

```typescript
import { useHarvestMorphoYield } from "@/hooks/useContracts"

const { harvest, isPending, isConfirming, isSuccess, hash, error } = useHarvestMorphoYield()

// Trigger harvest
const handleHarvest = () => {
  harvest() // Calls harvestYield() on MorphoVaultAdapter
}

// Transaction states:
// - isPending: Waiting for user wallet confirmation
// - isConfirming: Transaction submitted, waiting for confirmation
// - isSuccess: Harvest complete, yield distributed
// - hash: Transaction hash for BaseScan verification
```

**Harvest Requirements:**
- Minimum 24-hour interval between harvests per vault
- Anyone can call harvest (permissionless)
- Transaction automatically triggers 70/25/5 distribution
- Public goods donations created immediately upon harvest
- Independent from Aave vault (each can be harvested separately)

### Transaction Flow

The frontend displays a multi-step transaction modal:
1. **Confirming** - User confirms transaction in wallet
2. **Pending** - Transaction submitted to blockchain
3. **Success** - Yield distributed, shows transaction hash

Users can verify the harvest transaction on BaseScan to see:
- Yield amount withdrawn from MetaMorpho
- Distribution to YieldRouter
- Allocation to investors, public goods, and protocol

## Performance Metrics

Gas costs (estimated):

| Operation | Gas Used | Notes |
|-----------|----------|-------|
| First Deposit | ~220,000 | Includes MetaMorpho deposit |
| Subsequent Deposit | ~170,000 | Optimized path |
| Withdraw | ~170,000 | Includes MetaMorpho withdraw |
| Redeem | ~170,000 | Similar to withdraw |
| Harvest Yield | ~200,000 | Includes distribution |

Note: Slightly higher than Aave due to additional MetaMorpho layer.

## Comparison: Direct vs Adapter

### Direct MetaMorpho Use

```solidity
// User interacts directly
metaMorpho.deposit(1000 USDC) → 100% user yield
```

### Via MorphoVaultAdapter

```solidity
// User deposits through adapter
adapter.deposit(1000 USDC) → 70% user, 25% public goods, 5% protocol
```

Benefits of adapter:
- Automatic public goods funding
- Integration with Aruna ecosystem
- Consistent interface with Aave vault
- Reputation system access
- Invoice collateral pooling

## Differences from Aave Integration

| Feature | Aave Integration | Morpho Integration |
|---------|------------------|-------------------|
| Protocol | Aave v3 | Morpho Blue via MetaMorpho |
| Interface | IPool | IMetaMorpho (ERC-4626) |
| Yield Tracking | aToken balance | Share appreciation |
| APY (typical) | 6.5% | 8.2% |
| Complexity | Lower | Moderate |
| Risk Management | Aave's model | Curator-managed |
| Share Layers | One | Two (adapter + MetaMorpho) |

## References

- Morpho Documentation: https://docs.morpho.org
- MetaMorpho GitHub: https://github.com/morpho-org/metamorpho
- Morpho Blue: https://github.com/morpho-org/morpho-blue
- ERC-4626 Standard: https://eips.ethereum.org/EIPS/eip-4626
- Implementation: `src/vaults/MorphoVaultAdapter.sol`
