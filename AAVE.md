# Aave v3 Integration

This document provides comprehensive technical documentation of Aruna's Aave v3 integration, covering implementation details, interfaces, accounting mechanisms, and security measures.

## Overview

The `AaveVaultAdapter` is an ERC-4626 compliant vault that wraps Aave v3 lending pools, enabling users to deposit stablecoins and earn yield. The adapter manages all interactions with Aave's IPool interface and handles automatic yield harvesting for distribution.

**File:** `src/vaults/AaveVaultAdapter.sol`

## Architecture

### Design Pattern

The adapter follows the ERC-4626 tokenized vault standard, providing a normalized interface for Aave v3 deposits:

```mermaid
graph LR
    U[User with USDC] -->|deposit| AVA[AaveVaultAdapter]
    AVA -->|supply| AP[Aave v3 Pool]
    AP -.->|mint aUSDC| AVA
    AVA -.->|mint yfAave shares| U
    AVA -->|track shares| YR[YieldRouter]

    classDef userClass fill:#3B82F6,stroke:#1E40AF,color:#fff
    classDef vaultClass fill:#8B5CF6,stroke:#6D28D9,color:#fff
    classDef protocolClass fill:#10B981,stroke:#047857,color:#fff
    classDef routerClass fill:#EC4899,stroke:#BE185D,color:#fff

    class U userClass
    class AVA vaultClass
    class AP protocolClass
    class YR routerClass
```

### Contract Hierarchy

```mermaid
classDiagram
    class ERC4626 {
        <<OpenZeppelin>>
        +deposit(assets, receiver)
        +withdraw(assets, receiver, owner)
        +totalAssets()
        +convertToShares(assets)
    }

    class Ownable {
        <<OpenZeppelin>>
        +owner()
        +transferOwnership(newOwner)
        +onlyOwner modifier
    }

    class ReentrancyGuard {
        <<OpenZeppelin>>
        +nonReentrant modifier
    }

    class IYieldVault {
        <<Custom Interface>>
        +harvestYield()
        +getYieldRouter()
    }

    class AaveVaultAdapter {
        +IPool aavePool
        +IERC20 aToken
        +deposit(assets, receiver)
        +withdraw(assets, receiver, owner)
        +harvestYield()
        +totalAssets()
    }

    ERC4626 <|-- AaveVaultAdapter
    Ownable <|-- AaveVaultAdapter
    ReentrancyGuard <|-- AaveVaultAdapter
    IYieldVault <|-- AaveVaultAdapter
```

**Inheritance Benefits:**
- **ERC4626**: Standard vault interface from OpenZeppelin
- **Ownable**: Access control for admin functions
- **ReentrancyGuard**: Protection against reentrancy attacks
- **IYieldVault**: Custom interface for yield operations

## Interfaces

### IPool (Aave v3 Core)

The primary interface for interacting with Aave v3:

```solidity
interface IPool {
    /**
     * @notice Supplies assets to the Aave protocol
     * @param asset Address of the underlying asset
     * @param amount Amount to supply
     * @param onBehalfOf Address that receives the aTokens
     * @param referralCode Referral program code (we use 0)
     */
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Withdraws assets from the Aave protocol
     * @param asset Address of the underlying asset
     * @param amount Amount to withdraw
     * @param to Address that receives the underlying
     * @return Actual amount withdrawn
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}
```

**Implementation Details:**
- `supply()` is called during deposits to move assets into Aave
- `withdraw()` is called during withdrawals and yield harvesting
- Referral code is always set to 0 (no referral program)

### aToken Interface

aTokens are Aave's interest-bearing tokens that represent supplied assets:

```solidity
// aTokens implement standard ERC20
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}
```

**Key Characteristics:**
- aToken balance increases automatically as interest accrues
- Balance represents principal + accumulated interest
- 1:1 redeemable for underlying asset at any time
- No explicit claim function needed

### ERC-4626 Standard

Full implementation of the vault standard:

```solidity
interface IERC4626 {
    // Deposit/Withdrawal
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    // Accounting
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);

    // Limits
    function maxDeposit(address receiver) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);

    // Preview
    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256);
}
```

## Accounting Mechanisms

### Share Calculation

The adapter maintains a 1:1 ratio between shares and initial deposits:

```solidity
// First deposit
shares = assets

// Subsequent deposits (after yield accrual)
shares = (assets * totalSupply()) / totalAssets()
```

**Rationale:**
- Simplifies accounting and user understanding
- Prevents share dilution attacks
- Yield is distributed separately via YieldRouter
- Fair for all depositors regardless of entry time

### Yield Tracking

Yield is calculated as the difference between current aToken balance and expected balance:

```solidity
uint256 currentBalance = aToken.balanceOf(address(this));  // Includes accrued interest
uint256 expectedBalance = totalSupply();                    // Shares minted to users
uint256 yieldGenerated = currentBalance - expectedBalance;
```

**Example Scenario:**

Initial state:
- User deposits: 1,000 USDC
- aToken balance: 1,000
- Shares minted: 1,000

After 30 days at 6.5% APY:
- aToken balance: 1,005.42 USDC
- Shares outstanding: 1,000
- Yield generated: 5.42 USDC

### Asset Flow

**Deposit Process:**

```mermaid
sequenceDiagram
    participant U as User
    participant AVA as AaveVaultAdapter
    participant USDC as USDC Token
    participant AP as Aave Pool
    participant aUSDC as aUSDC Token
    participant YR as YieldRouter

    U->>USDC: approve(AVA, amount)
    U->>AVA: deposit(1000 USDC, user)
    AVA->>USDC: safeTransferFrom(user, AVA, 1000)
    AVA->>USDC: approve(AavePool, 1000)
    AVA->>AP: supply(USDC, 1000, AVA, 0)
    AP->>aUSDC: mint(1000 aUSDC to AVA)
    AVA->>AVA: _mint(1000 shares to user)
    AVA->>YR: updateUserShares(user, +1000)
    AVA-->>U: return 1000 shares

    Note over U: User now has 1000 yfAave shares
    Note over AVA: Adapter holds 1000 aUSDC (earning yield)
```

**Withdrawal Process:**

```mermaid
sequenceDiagram
    participant U as User
    participant AVA as AaveVaultAdapter
    participant AP as Aave Pool
    participant aUSDC as aUSDC Token
    participant USDC as USDC Token
    participant YR as YieldRouter

    U->>AVA: withdraw(500 USDC, user, user)
    AVA->>AVA: previewWithdraw(500) → 500 shares
    AVA->>AVA: _burn(500 shares from user)
    AVA->>AP: withdraw(USDC, 500, user)
    AP->>aUSDC: burn(500 aUSDC from AVA)
    AP->>USDC: transfer(500 USDC to user)
    AVA->>YR: updateUserShares(user, -500)
    AVA-->>U: return 500 shares burned

    Note over U: User received 500 USDC
    Note over AVA: Adapter now holds 500 aUSDC
```

**Yield Harvest Process:**

```mermaid
sequenceDiagram
    participant U as Investor
    participant UI as Frontend
    participant AVA as AaveVaultAdapter
    participant aUSDC as aUSDC Token
    participant AP as Aave Pool
    participant YR as YieldRouter
    participant ODM as OctantDonationModule
    participant USDC as USDC Token

    Note over U,UI: Investor clicks "Harvest Yield" button

    U->>UI: Click Harvest
    UI->>AVA: harvestYield()

    Note over AVA: Check 24h interval passed
    AVA->>AVA: require(block.timestamp >= lastHarvestTime + 1 day)

    Note over AVA: Calculate yield
    AVA->>aUSDC: balanceOf(AVA) → 1050 aUSDC
    AVA->>AVA: totalSupply() → 1000 shares
    AVA->>AVA: yield = 1050 - 1000 = 50 USDC

    Note over AVA: Withdraw yield from Aave
    AVA->>AP: withdraw(USDC, 50, AVA)
    AP->>aUSDC: burn(50 aUSDC from AVA)
    AP->>USDC: transfer(50 USDC to AVA)

    Note over AVA: Approve and distribute
    AVA->>USDC: approve(YieldRouter, 50)
    AVA->>YR: distributeYield(50)

    Note over YR: 70/25/5 Distribution
    YR->>YR: investorAmount = 50 * 70% = 35
    YR->>YR: publicGoodsAmount = 50 * 25% = 12.5
    YR->>YR: protocolAmount = 50 * 5% = 2.5

    YR->>USDC: transfer(35 to investors)
    YR->>ODM: donate(12.5, contributor)
    YR->>USDC: transfer(2.5 to treasury)

    AVA->>AVA: lastHarvestTime = block.timestamp
    AVA->>AVA: totalYieldGenerated += 50

    AVA-->>UI: HarvestCompleted event
    UI-->>U: Show success + transaction hash

    Note over U: Earned 35 USDC (70% of 50)
    Note over ODM: 12.5 USDC donated to public goods
```

**⚠️ Important**: Yield must be manually harvested via the "Harvest Yield" button in the investor dashboard. Public goods donations only occur AFTER harvest is triggered.

## Safety Checks

### 1. Reentrancy Protection

All external state-changing functions use the `nonReentrant` modifier:

```solidity
function deposit(uint256 assets, address receiver)
    public
    override
    nonReentrant
    returns (uint256)
{
    // Function body
}
```

This prevents:
- Recursive calls during token transfers
- Cross-function reentrancy attacks
- External call manipulation

### 2. Input Validation

Comprehensive validation on all inputs:

```solidity
if (assets == 0) revert InvalidAmount();
if (receiver == address(0)) revert InvalidAddress();
if (isPaused) revert ContractPaused();
```

Checks include:
- Non-zero amounts for deposits and withdrawals
- Valid non-zero addresses in constructor
- Contract pause state
- Sufficient balance (implicit in SafeERC20)

### 3. Safe Token Operations

All token transfers use OpenZeppelin's SafeERC20:

```solidity
using SafeERC20 for IERC20;

IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);
IERC20(asset()).safeTransfer(receiver, assets);
```

Benefits:
- Handles non-standard ERC20 implementations
- Reverts on failed transfers (no silent failures)
- Protects against return value manipulation
- Compatible with tokens that don't return boolean

### 4. Approval Management

Optimized approval pattern:

```solidity
// One-time approval in constructor
IERC20(_asset).forceApprove(_aavePool, type(uint256).max);

// Per-harvest approval to YieldRouter
IERC20(asset()).forceApprove(address(yieldRouter), yieldGenerated);
```

Security measures:
- `forceApprove` safely handles existing approvals
- Infinite approval only to trusted Aave Pool
- Per-transaction approval to YieldRouter for exact amounts
- No approvals to user addresses

### 5. Harvest Timing Control

Rate limiting on yield harvesting:

```solidity
uint256 public constant HARVEST_INTERVAL = 1 days;

function harvestYield() external override {
    if (block.timestamp < lastHarvestTime + HARVEST_INTERVAL) {
        revert HarvestTooSoon();
    }
    _harvestYield();
}
```

Prevents:
- Harvest spamming and gas griefing
- Frequent small harvests that waste gas
- Accounting manipulation via rapid harvests

### 6. Share Calculation Protection

Uses ERC-4626 preview functions for accurate calculations:

```solidity
shares = previewDeposit(assets);
assets = previewWithdraw(shares);
```

These functions:
- Use `totalAssets() / totalSupply()` for exchange rate
- Account for current yield in calculations
- Prevent share inflation attacks
- Protect against rounding exploits
- Mitigate first depositor attacks

### 7. Emergency Controls

Owner-only safety mechanisms:

```solidity
function togglePause() external onlyOwner {
    isPaused = !isPaused;
    emit PauseToggled(isPaused);
}

function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
    IERC20(token).safeTransfer(owner(), amount);
}
```

Use cases:
- Pause deposits during detected vulnerabilities
- Circuit breaker for suspicious activity
- Recovery of accidentally sent tokens
- Emergency fund retrieval

### 8. Allowance Validation

Proper allowance checking in withdrawal functions:

```solidity
if (msg.sender != owner) {
    _spendAllowance(owner, msg.sender, shares);
}
```

This ensures:
- Only owner or approved addresses can withdraw
- Follows ERC-4626 standard allowance pattern
- Prevents unauthorized fund access
- Supports delegation via approve/transfer pattern

## Gas Optimization

### Immutable Variables

State variables that never change are marked immutable:

```solidity
IPool public immutable aavePool;
IERC20 public immutable aToken;
```

Gas savings: ~2,100 gas per read operation after deployment

### Calculation Caching

Local variables cache expensive operations:

```solidity
uint256 currentBalance = totalAssets();
uint256 expectedBalance = totalSupply();
uint256 yieldGenerated = currentBalance - expectedBalance;
```

Avoids multiple calls to the same view functions.

### Batch Operations

Harvest interval enforces batching:

```solidity
if (block.timestamp >= lastHarvestTime + HARVEST_INTERVAL) {
    _harvestYield();
}
```

This batches yield into daily distributions rather than per-transaction.

## Contract Addresses

### Base Sepolia Testnet

**⚠️ IMPORTANT: Correct Addresses for Base Sepolia**

```
USDC: 0x036CbD53842c5426634e7929541eC2318f3dCF7e
Aave v3 Pool: 0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b
Aave aUSDC: 0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB
```

**Note:** These are the officially verified Aave v3 addresses on Base Sepolia used in the deployment script.

### Deployed Aruna Contracts

After deployment, addresses are saved to:
```
Aruna-Contract/deployments/84532.json
```

**Current Deployment (Nov 2024):**
- AaveVaultAdapter: `0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905`
- View on BaseScan: https://sepolia.basescan.org/address/0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905

## Testing

### Unit Test Coverage

Recommended test scenarios:

```solidity
// Basic operations
testDeposit() - Verify shares minted correctly
testWithdraw() - Verify assets returned correctly
testRedeem() - Verify share burning works
testMultipleUsers() - Test with multiple depositors

// Yield mechanics
testYieldAccrual() - Verify aToken balance increases
testHarvest() - Verify yield extraction works
testYieldDistribution() - Verify 70/25/5 split

// Edge cases
testZeroDeposit() - Should revert
testDepositWhilePaused() - Should revert
testUnauthorizedWithdraw() - Should revert
testHarvestTooSoon() - Should revert

// Integration
testFullUserFlow() - Deposit → Time → Harvest → Withdraw
testAavePoolIntegration() - Verify Aave calls work correctly
```

### Integration Testing

Test with actual Aave contracts on Base Sepolia:

```bash
forge test --fork-url https://sepolia.base.org --match-contract AaveVaultAdapterTest -vvv
```

## Deployment

### Prerequisites

1. Base Sepolia ETH for gas
2. Configured environment variables
3. Verified Aave contract addresses

### Deployment Command

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
# Check aToken address
cast call <AAVE_VAULT_ADAPTER> "aToken()" --rpc-url https://sepolia.base.org

# Check Aave Pool address
cast call <AAVE_VAULT_ADAPTER> "aavePool()" --rpc-url https://sepolia.base.org

# Check asset
cast call <AAVE_VAULT_ADAPTER> "asset()" --rpc-url https://sepolia.base.org
```

## Frontend Integration

### Using Harvest Functionality

Investors trigger yield harvesting from the investor dashboard using the `useHarvestAaveYield()` hook:

```typescript
import { useHarvestAaveYield } from "@/hooks/useContracts"

const { harvest, isPending, isConfirming, isSuccess, hash, error } = useHarvestAaveYield()

// Trigger harvest
const handleHarvest = () => {
  harvest() // Calls harvestYield() on AaveVaultAdapter
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

### Transaction Flow

The frontend displays a multi-step transaction modal:
1. **Confirming** - User confirms transaction in wallet
2. **Pending** - Transaction submitted to blockchain
3. **Success** - Yield distributed, shows transaction hash

Users can verify the harvest transaction on BaseScan to see:
- Yield amount withdrawn from Aave
- Distribution to YieldRouter
- Allocation to investors, public goods, and protocol

## Performance Metrics

Gas costs (estimated):

| Operation | Gas Used | Notes |
|-----------|----------|-------|
| First Deposit | ~200,000 | Includes Aave supply call |
| Subsequent Deposit | ~150,000 | Optimized path |
| Withdraw | ~150,000 | Includes Aave withdraw |
| Redeem | ~150,000 | Similar to withdraw |
| Harvest Yield | ~180,000 | Includes distribution |

## References

- Aave v3 Documentation: https://docs.aave.com/developers/
- ERC-4626 Standard: https://eips.ethereum.org/EIPS/eip-4626
- OpenZeppelin ERC4626: https://docs.openzeppelin.com/contracts/4.x/erc4626
- Implementation: `src/vaults/AaveVaultAdapter.sol`
