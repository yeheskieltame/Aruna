# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Hackathon Context

**Aruna** is a submission for the **Octant DeFi Hackathon 2025**, competing in three categories:

1. **Best Public Goods Projects** - Transforms invoice financing into sustainable public goods funding
2. **Best Use of Aave v3** - ERC-4626 compliant AaveVaultAdapter for yield generation
3. **Best Use of Morpho V2** - ERC-4626 compliant MorphoVaultAdapter with safe adapter wiring

### Hackathon Requirements Met

- ✅ **ERC-4626 Compliance**: Both vault adapters follow the standard
- ✅ **Octant v2 Integration**: 25% of all yield automatically routed to Octant public goods
- ✅ **Aave v3 Integration**: Using Aave's ATokenVault for supply/withdraw with proper accounting
- ✅ **Morpho V2 Integration**: Respects role model and semantics with safe adapter wiring
- ✅ **Public Goods Mechanism**: Innovative approach to sustainable public goods funding
- ✅ **Documentation**: Comprehensive deployment guides, integration docs, and implementation summary

## Project Overview

Aruna turns future invoice payments into sustainable public goods funding by connecting:
- **Businesses**: Get instant 3% grants on invoices by committing future payments
- **Investors**: Earn yield on stablecoins in Aave v3/Morpho vaults while funding public goods
- **Public Goods**: Receive 25% of all yield automatically via Octant v2

### Core Innovation

Traditional invoice financing focuses solely on business liquidity. Aruna redirects investor yield (25%) to public goods, creating a sustainable funding mechanism where:
- Every invoice commitment generates public goods funding
- Businesses get working capital with minimal collateral (10%)
- Investors earn competitive yields while supporting Ethereum ecosystem
- Public goods receive ongoing, predictable funding

## Project Structure

1. **Frontend/** - Next.js 16 application with Web3 integration
2. **Aruna-Contract/** - Modular Solidity smart contracts (Foundry)

### Frontend Architecture

- **Framework**: Next.js 16 with App Router
- **UI Components**: Radix UI primitives with custom styling using shadcn/ui
- **Web3 Integration**: OnchainKit (Base) + Wagmi for wallet connections and blockchain interactions
- **State Management**: React Query (TanStack Query) for server state
- **Styling**: Tailwind CSS v4 with custom animations and responsive design
- **Charts**: Recharts for data visualization
- **Package Manager**: pnpm 10.20.0+

#### Key Frontend Directories

- `app/` - Next.js App Router pages
  - `business/` - Business dashboard for invoice management
  - `investor/` - Investor dashboard for vault deposits and yield tracking
  - `public-goods/` - Public goods impact tracker and project showcase
- `components/` - React components including UI primitives and feature components
- `lib/config.ts` - Protocol configuration (grant percentages, vault configs, chain settings)
- `lib/contracts.ts` - Contract ABIs and deployed addresses

### Smart Contract Architecture

**Modular V2 Architecture** - Built for hackathon ERC-4626 and Octant v2 requirements:

#### Core Contracts

1. **ArunaCore.sol** - Main entry point managing invoice commitments as ERC-721 NFTs
2. **YieldRouter.sol** - Routes yield distribution (70% investors, 25% public goods, 5% protocol)
3. **OctantDonationModule.sol** - Manages public goods donations and yield distribution

#### Vault Adapters (ERC-4626 Compliant)

4. **AaveVaultAdapter.sol** - Integrates with Aave v3 using ATokenVault interface
   - Implements full ERC-4626 standard (deposit, withdraw, redeem, mint)
   - Proper accounting for shares vs assets
   - Safety checks for supply/withdraw operations
   - Automatic yield collection via aToken balance tracking

5. **MorphoVaultAdapter.sol** - Integrates with Morpho Blue for optimized yields
   - Follows Morpho V2 role model and semantics
   - Safe adapter wiring with reentrancy guards
   - ERC-4626 compliant with proper share calculations
   - Ready for mainnet Morpho integration

#### Public Goods Integration

6. **OctantDonationModule.sol** - Automatic donations to Octant v2
   - Integrates with Octant's epoch-based donation system
   - Tracks contributions per business and per epoch
   - Supports manual and automatic donations
   - Transparent public goods allocation

#### Development Details

- **Framework**: Foundry (Solidity development toolkit)
- **Testing**: Built-in Foundry testing framework
- **Language**: Solidity ^0.8.13
- **Deployment**: Automated deployment scripts with verification
- **Dependencies**: OpenZeppelin, Aave v3 Core, Morpho contracts

## Development Commands

### Frontend Development

```bash
cd Frontend
pnpm install        # Install dependencies (pnpm required)
pnpm dev           # Start development server (http://localhost:3000)
pnpm build         # Build for production
pnpm start         # Start production server
pnpm lint          # Run ESLint
```

### Smart Contract Development

```bash
cd Aruna-Contract

# Building and Testing
forge build                              # Compile all contracts
forge test                               # Run all tests
forge test --match-test testName -vvv    # Run specific test with verbose output
forge test --gas-report                  # Show gas usage report
forge coverage                           # Generate code coverage report
forge fmt                                # Format Solidity code
forge snapshot                          # Generate gas snapshots

# Local Development
anvil                                    # Start local Ethereum node

# Deployment to Base Sepolia
forge script script/DeployAruna.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY

# Useful Cast Commands
cast balance <address> --rpc-url https://sepolia.base.org
cast call <contract> "functionName()" --rpc-url https://sepolia.base.org
```

#### Key Test Files

- `test/unit/ArunaCore.t.sol` - Core contract functionality tests
- `test/unit/YieldRouter.t.sol` - Yield distribution tests
- `test/unit/AaveVaultAdapter.t.sol` - Aave vault adapter tests
- `test/unit/MorphoVaultAdapter.t.sol` - Morpho vault adapter tests
- `test/unit/OctantDonationModule.t.sol` - Public goods donation tests
- `test/integration/FullUserFlow.t.sol` - End-to-end user flows

## Base Sepolia Testnet Configuration

**Chain Details:**
- Chain ID: 84532
- RPC URL: https://sepolia.base.org
- Block Explorer: https://sepolia.basescan.org

**Base Sepolia Infrastructure (External Protocols):**
```typescript
USDC: "0x036CbD53842c5426634e7929541eC2318f3dCF7e"
AAVE_POOL: "0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b"
AAVE_AUSDC: "0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB"
```

**Deployed Aruna Protocol Contracts (Base Sepolia):**
Deployment Date: November 9, 2024
Deployer: `0x77c4a1cD22005b67Eb9CcEaE7E9577188d7Bca82`

```typescript
ArunaCore: "0xE60dcA6869F072413557769bDFd4e30ceFa6997f"
AaveVaultAdapter: "0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905"
MorphoVaultAdapter: "0x16dea7eE228c0781938E6869c07ceb2EEA7bd564"
YieldRouter: "0x124d8F59748860cdD851fB176c7630dD71016e89"
OctantDonationModule: "0xEDc5CeE824215cbeEBC73e508558a955cdD75F00"
MockOctantDeposits: "0x480d28E02b449086efA3f01E2EdA4A4EAE99C3e6" // Testnet Only
MockMetaMorpho: "0x7deB84aAe25A2168782E6c8C0CF30714cbaaA025" // Testnet Only
```

All addresses are saved to `Aruna-Contract/deployments/84532.json` and verified on-chain.

**View on BaseScan:**
- [ArunaCore](https://sepolia.basescan.org/address/0xE60dcA6869F072413557769bDFd4e30ceFa6997f)
- [AaveVaultAdapter](https://sepolia.basescan.org/address/0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905)
- [MorphoVaultAdapter](https://sepolia.basescan.org/address/0x16dea7eE228c0781938E6869c07ceb2EEA7bd564)
- [YieldRouter](https://sepolia.basescan.org/address/0x124d8F59748860cdD851fB176c7630dD71016e89)

## Protocol Configuration

Key configuration is centralized in `Frontend/lib/config.ts`:

**Economics:**
- **Grant Percentage**: 3% instant grant on invoices
- **Collateral Requirement**: 10% of invoice amount (net 7% after grant)
- **Public Goods Allocation**: 25% of yield → Octant v2
- **Investor Allocation**: 70% of yield → vault depositors
- **Protocol Fee**: 5% of yield → protocol treasury

**Vault Options:**
- **Aave v3**: 6.5% target APY (stable, battle-tested)
- **Morpho**: 8.2% target APY (optimized peer-to-peer yields)

## Key Features

### Invoice Financing System
- Businesses submit invoice details and receive 3% instant grants
- 10% collateral requirement in USDC (net 7% locked after grant)
- ERC-721 NFTs represent invoice commitments
- Reputation system: earn reputation by settling on time, lose it by defaulting
- Automatic liquidation after 120 days overdue

### Yield Generation (Hackathon Focus)
- **Aave v3 Integration**: ERC-4626 compliant vault using ATokenVault interface
- **Morpho V2 Integration**: ERC-4626 compliant vault with safe adapter wiring
- Support for USDC, DAI, and USDT tokens
- **Investor-triggered yield harvesting**: `harvestYield()` function per vault
- Harvest interval: once per 24 hours per vault (independent)
- Real-time yield tracking per user

### Yield Distribution (70/25/5 Model)
- **70% to Investors**: Proportional to vault shares held
- **25% to Public Goods**: Triggered by harvest, routed to Octant v2
- **5% to Protocol**: Treasury for maintenance and development
- **Distribution Flow**: Harvest → YieldRouter → OctantDonationModule → Octant v2

### User Interfaces
- Business dashboard for invoice management and reputation tracking
- Investor dashboard for vault deposits, withdrawals, and yield claiming
- Public goods impact tracker showing ecosystem contributions

### Advanced Features
- **Withdrawal Functions**: `withdrawFromAaveVault()`, `withdrawFromMorphoVault()`
- **Yield Harvesting**: `harvestYield()` per vault with 24-hour interval enforcement
- **Public Goods Trigger**: Harvest automatically distributes 25% to Octant v2
- **No Lock-up Period**: Users can withdraw principal anytime
- **NFT Transfer Restrictions**: Invoices can only be transferred after settlement
- **Emergency Controls**: Pausable contracts with owner emergency functions

## Important Development Notes

### Contract Function Signatures

**Invoice Submission:**
```solidity
// Frontend calls this with 3 parameters only:
function submitInvoiceCommitment(
    string memory customerName,
    uint256 invoiceAmount,
    uint256 dueDate
) external returns (uint256 tokenId)
```
- The `business` address is automatically set to `msg.sender`
- IPFS hash is optional and can be added via separate function
- Returns ERC-721 token ID

### USDC Flow (Critical for Understanding)

**Invoice Commitment Flow:**
1. Business approves 10% collateral (e.g., $1000 for $10k invoice)
2. Contract transfers 10% from business
3. Contract automatically sends back 3% as instant grant
4. **Net result**: 7% locked as collateral, 3% grant received

This eliminates the old "insufficient grant reserves" error from V1.

### Vault Operations

**Deposits:**
- `depositToAaveVault(amount)` returns `uint256 shares`
- `depositToMorphoVault(amount)` returns `uint256 shares`
- Shares are ERC-4626 compliant vault tokens

**Withdrawals:**
- `withdrawFromAaveVault(amount)` burns shares proportionally
- `withdrawFromMorphoVault(amount)` burns shares proportionally
- No lock-up period - withdraw anytime

**Yield Harvesting:**
- `harvestYield()` on AaveVaultAdapter - triggers Aave vault yield distribution
- `harvestYield()` on MorphoVaultAdapter - triggers Morpho vault yield distribution
- Both vaults have independent 24-hour cooldown periods
- Harvest withdraws yield and distributes via YieldRouter (70/25/5 split)
- Investors receive their 70% portion automatically
- Public goods receive 25% via OctantDonationModule

**⚠️ Critical Note on Public Goods Data:**
Public goods donations (totalDonated, currentEpochDonations, etc.) will be ZERO until the first harvest is triggered. The data flow requires:
1. Investors deposit to vaults → Yield accumulates in Aave/Morpho
2. Investor clicks "Harvest Yield" button → Triggers `harvestYield()`
3. YieldRouter distributes → 25% sent to OctantDonationModule
4. Public goods page displays donation data

If the public goods page shows empty/zero data, it simply means harvest hasn't been called yet.

### Reputation System

```solidity
mapping(address => uint256) public userReputation;
```
- Increases by 1 for each on-time settlement
- Decreases by 1 for each default/liquidation
- Higher reputation = higher future grant limits
- Reputation displayed on business dashboard

### ERC-4626 Compliance (Hackathon Requirement)

Both `AaveVaultAdapter` and `MorphoVaultAdapter` implement:
- `deposit(assets, receiver)` → returns shares
- `withdraw(assets, receiver, owner)` → returns shares
- `redeem(shares, receiver, owner)` → returns assets
- `mint(shares, receiver)` → returns assets
- Proper `totalAssets()` accounting via underlying protocol
- `convertToShares()` and `convertToAssets()` helpers

### Frontend Harvest Implementation

**Harvest Hooks (hooks/useContracts.ts):**

```typescript
export function useHarvestAaveYield() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const harvest = () => {
    writeContract({
      address: CONTRACTS.AAVE_VAULT.address as `0x${string}`,
      abi: ABIS.AAVE_VAULT,
      functionName: "harvestYield",
      gas: 500000n,
    })
  }

  return { harvest, isPending, isConfirming, isSuccess, hash, error }
}

export function useHarvestMorphoYield() {
  // Similar implementation for Morpho vault
}
```

**Investor Dashboard Integration (components/investor-dashboard.tsx):**

```typescript
const aaveHarvest = useHarvestAaveYield()
const morphoHarvest = useHarvestMorphoYield()

const handleHarvest = (vault: "aave" | "morpho") => {
  if (vault === "aave") {
    aaveHarvest.harvest()
  } else {
    morphoHarvest.harvest()
  }
}

// UI shows:
// - Harvest button for each vault
// - 24-hour cooldown indicator
// - Visual breakdown of 70/25/5 distribution
// - Transaction modal (confirming → pending → success)
```

**Public Goods Data Hooks:**

```typescript
export function useTotalDonations() {
  return useReadContract({
    address: CONTRACTS.OCTANT_MODULE.address,
    abi: ABIS.OCTANT_MODULE,
    functionName: "totalDonated",
  })
}

export function useSupportedProjects() {
  return useReadContract({
    address: CONTRACTS.OCTANT_MODULE.address,
    abi: ABIS.OCTANT_MODULE,
    functionName: "getSupportedProjects",
  })
}

export function useCurrentEpochDonations() {
  return useReadContract({
    address: CONTRACTS.OCTANT_MODULE.address,
    abi: ABIS.OCTANT_MODULE,
    functionName: "currentEpochDonations",
  })
}
```

All public goods data is fetched directly from blockchain via these hooks.

## Environment Setup

### Required Environment Variables

**Frontend** - Create `.env.local`:
```bash
NEXT_PUBLIC_BASE_SEPOLIA_RPC=https://sepolia.base.org
NEXT_PUBLIC_CHAIN_ID=84532
NEXT_PUBLIC_ONCHAINKIT_API_KEY=<your_onchainkit_api_key>

# Deployed Contract Addresses (Base Sepolia - Chain ID: 84532)
# Deployed: 2024-11-09
NEXT_PUBLIC_ARUNA_CORE=0xE60dcA6869F072413557769bDFd4e30ceFa6997f
NEXT_PUBLIC_AAVE_VAULT=0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905
NEXT_PUBLIC_MORPHO_VAULT=0x16dea7eE228c0781938E6869c07ceb2EEA7bd564
NEXT_PUBLIC_YIELD_ROUTER=0x124d8F59748860cdD851fB176c7630dD71016e89
NEXT_PUBLIC_OCTANT_MODULE=0xEDc5CeE824215cbeEBC73e508558a955cdD75F00
```

**Smart Contracts** - Create `.env` in Aruna-Contract/:
```bash
PRIVATE_KEY=0xYourPrivateKey
PROTOCOL_TREASURY=0xTreasuryAddress
OWNER_ADDRESS=0xOwnerAddress
BASESCAN_API_KEY=YourBasescanAPIKey
```

Update `Web3Provider` component with your WalletConnect Project ID.

### Prerequisites

- Node.js 18+
- pnpm 10.20.0+ (Frontend package manager)
- Foundry installed for contract development
- MetaMask or compatible Web3 wallet
- Base Sepolia ETH for gas
- Base Sepolia USDC for testing

## Security Considerations

**Smart Contract Security:**
- ✅ All contracts are non-custodial
- ✅ Funds held in Aave/Morpho vaults (battle-tested DeFi protocols)
- ✅ ReentrancyGuard on all external functions
- ✅ SafeERC20 for all token transfers
- ✅ Pausable contracts for emergency situations
- ✅ Access control with OpenZeppelin Ownable
- ✅ Input validation on all user-facing functions
- ✅ No upgradeable proxies (immutable contracts)

**Risk Management:**
- 10% collateral requirement ensures business commitment
- 120-day default period with automatic liquidation
- Reputation system rewards good behavior
- Emergency withdrawal functions for owner

**Frontend Security:**
- No private keys stored on servers
- All transactions require user wallet signature
- Environment variables for sensitive configuration
- Client-side Web3 wallet integration only

## Deployment

### Smart Contract Deployment to Base Sepolia

**Full deployment script** (deploys all 6 contracts):
```bash
cd Aruna-Contract

# Setup environment
cp .env.example .env
# Edit .env with your keys

# Deploy and verify
forge script script/DeployAruna.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

**Post-deployment:**
1. Addresses saved to `deployments/84532.json`
2. Fund ArunaCore with USDC for grants
3. Test basic functions on BaseScan
4. Update frontend with deployed addresses

See `Aruna-Contract/DEPLOYMENT.md` for detailed deployment guide.

### Frontend Deployment to Vercel

```bash
cd Frontend

# Update environment variables
cp .env.example .env.local
# Edit with deployed contract addresses

# Deploy
vercel deploy

# Or deploy to production
vercel --prod
```

## Additional Documentation

- **Aruna-Contract/DEPLOYMENT.md** - Comprehensive deployment guide with troubleshooting
- **INTEGRATION_GUIDE.md** - Frontend integration and migration guide
- **IMPLEMENTATION_SUMMARY.md** - Complete V2 implementation details and gap analysis
- **Aruna-Contract/README.md** - Detailed contract documentation
- **Frontend/README.md** - Frontend setup and user flows