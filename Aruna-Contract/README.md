# Aruna Smart Contracts

## Overview

Aruna is a decentralized finance protocol that turns future invoice payments into sustainable public goods funding. The protocol consists of 6 main smart contracts that work together to provide instant grants to businesses while generating yield for investors and funding public goods.

## Architecture

### Core Contracts

1. **ArunaCore.sol** - Main contract managing invoice commitments as NFTs
2. **YieldRouter.sol** - Routes yield distribution between investors, public goods, and protocol fees
3. **GrantDistributor.sol** - Manages instant grant distribution and reputation system

### Vault Adapters

4. **AaveVaultAdapter.sol** - ERC-4626 compliant adapter for Aave v3 integration
5. **MorphoVaultAdapter.sol** - ERC-4626 compliant adapter for Morpho Blue integration

### Public Goods Integration

6. **OctantDonationModule.sol** - Manages automatic donations to Octant v2 public goods projects

## Key Features

### Invoice Commitment System
- Businesses submit invoice details and receive 3% instant grants
- 10% collateral requirement in USDC
- ERC-721 NFTs represent invoice commitments
- Reputation system for trustworthy businesses

### Yield Generation
- Integration with Aave v3 (6.5% APY target)
- Integration with Morpho Blue (8.2% APY target)
- ERC-4626 standard compliance
- Automatic yield optimization

### Public Goods Funding
- 25% of all yield automatically routed to Octant
- Transparent tracking of donations
- Epoch-based donation distribution

### Risk Management
- Pausable contracts for emergency situations
- Reentrancy guards on all external functions
- Role-based access control
- Collateral liquidation after 120 days default

## Contract Details

### ArunaCore

**Purpose**: Manages invoice commitments and instant grants

**Key Functions**:
- `commitInvoice()` - Create new invoice commitment
- `depositCollateral()` - Deposit 10% collateral
- `settleInvoice()` - Mark invoice as paid
- `markDefaulted()` - Handle defaulted invoices

**Events**:
- `InvoiceCommitted` - New invoice commitment created
- `GrantDistributed` - Instant grant distributed
- `InvoiceSettled` - Invoice successfully settled

### YieldRouter

**Purpose**: Routes yield distribution across the protocol

**Key Functions**:
- `calculateAndDistributeYield()` - Process vault yield
- `calculateInvoiceYield()` - Calculate specific invoice yield
- `processInvoiceSettlementYield()` - Distribute yield on settlement

**Distribution**:
- 70% to investors
- 25% to public goods (Octant)
- 5% to protocol

### GrantDistributor

**Purpose**: Manages grants and business reputation

**Key Functions**:
- `distributeGrant()` - Distribute instant grants
- `updateReputationOnSettlement()` - Update business reputation
- `fundGrantPool()` - Add funds to grant pool

**Reputation System**:
- New businesses: $1,000 max grant
- Bronze (100+ rep): $2,500 max grant
- Silver (500+ rep): $5,000 max grant
- Gold (1000+ rep): $10,000 max grant
- Platinum (2000+ rep): $25,000 max grant
- Diamond (5000+ rep): $50,000 max grant

### AaveVaultAdapter & MorphoVaultAdapter

**Purpose**: ERC-4626 compliant vault adapters

**Key Functions**:
- `deposit()` - Deposit assets into vault
- `withdraw()` - Withdraw assets from vault
- `collectYield()` - Collect generated yield

**Features**:
- Standard ERC-4626 interface
- Automatic yield compounding
- Emergency withdrawal with penalty
- Performance fee tracking

### OctantDonationModule

**Purpose**: Manage public goods donations

**Key Functions**:
- `donateYield()` - Donate yield to Octant
- `manualDonate()` - Manual donation function
- `advanceEpoch()` - Move to next epoch

**Features**:
- Automatic epoch management
- Minimum donation thresholds
- Transparent donation tracking
- Emergency withdrawal capabilities

## Installation and Setup

### Prerequisites

- Foundry installed
- Node.js 18+
- Git

### Installation

```bash
git clone <repository-url>
cd Aruna-Contract
forge install
```

### Environment Variables

Create a `.env` file with:

```bash
PRIVATE_KEY=your_private_key
RPC_URL=https://sepolia.base.org
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### Dependencies

```bash
forge install openzeppelin/openzeppelin-contracts --no-commit
forge install aave/aave-v3-core --no-commit
forge install morpho-dao/morpho-blue --no-commit
```

## Testing

### Run All Tests

```bash
forge test
```

### Run Specific Test

```bash
forge test --match-test testCommitInvoice
```

### Gas Reports

```bash
forge test --gas-report
```

### Coverage

```bash
forge coverage
```

## Deployment

### Deploy to Testnet

```bash
# Deploy to Base Sepolia
forge script script/DeployAruna.s.sol:DeployAruna --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Verify contracts
forge verify-contract <contract_address> <contract_name> --chain-id 84532 --etherscan-api-key $ETHERSCAN_API_KEY
```

### Deploy to Mainnet

```bash
# Deploy to Base Mainnet
forge script script/DeployAruna.s.sol:DeployArunaMainnet --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast

# Verify contracts
forge verify-contract <contract_address> <contract_name> --chain-id 8453 --etherscan-api-key $ETHERSCAN_API_KEY
```

### Post-Deployment Setup

```bash
# Setup contracts after deployment
forge script script/DeployAruna.s.sol:SetupContracts --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Verify ownership
forge script script/DeployAruna.s.sol:VerifyContracts --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## Configuration

### Testnet Configuration (Base Sepolia)

- **USDC**: `0xd9aAEc86B65D86f6A7B5B1b0c42FFA531770b16F`
- **Aave Pool**: `0xA238Dd80C259072837bbd5ef41640D49473d9d82`
- **Chain ID**: 84532

### Mainnet Configuration (Base)

- **USDC**: `0xd9aAEc86B65D86f6A7B5B1b0c42FFA531770b16F`
- **Aave Pool**: `0xA238Dd80C259072837bbd5ef41640D49473d9d82`
- **Chain ID**: 8453

## Security Considerations

### Audit Checklist

- [ ] All external functions protected by access controls
- [ ] Reentrancy guards implemented on critical functions
- [ ] Pausable functions for emergency situations
- [ ] Proper input validation on all functions
- [ ] Integer overflow/underflow protection
- [ ] SafeERC20 usage for token transfers
- [ ] Event emission for all state changes

### Security Features

1. **Access Control**: Role-based permissions for sensitive operations
2. **Pausability**: All contracts can be paused in emergencies
3. **Reentrancy Protection**: Critical functions protected against reentrancy
4. **Emergency Withdrawals**: Owner can withdraw funds in emergency situations
5. **Input Validation**: Comprehensive validation on all user inputs

### Risk Mitigation

1. **Collateral Requirements**: 10% collateral ensures business commitment
2. **Default Handling**: 120-day default period with collateral liquidation
3. **Yield Limits**: Maximum grant amounts to limit exposure
4. **Reputation System**: Rewards good behavior, penalizes defaults

## API Integration

### Frontend Integration

```typescript
// Example frontend integration
const ArunaCore = new ethers.Contract(
  Aruna_CORE_ADDRESS,
  ArunaCoreABI,
  signer
);

// Commit invoice
const tx = await ArunaCore.commitInvoice(
  businessAddress,
  customerName,
  invoiceAmount,
  dueDate,
  ipfsHash
);
```

### Required Data from Frontend

1. **Invoice Information**:
   - Customer name
   - Invoice amount (USD, 6 decimals)
   - Due date (Unix timestamp)
   - IPFS hash of invoice PDF

2. **Business Information**:
   - Business wallet address
   - USDC balance for collateral

3. **Investor Information**:
   - Investment amount
   - Preferred vault (Aave or Morpho)

## Monitoring and Analytics

### Key Metrics to Track

1. **Invoice Metrics**:
   - Total invoice commitments
   - Settlement rate
   - Default rate
   - Average invoice amount

2. **Grant Metrics**:
   - Total grants distributed
   - Grant pool utilization
   - Average grant size
   - Reputation distribution

3. **Yield Metrics**:
   - Total yield generated
   - APY across vaults
   - Public goods donations
   - Protocol fees collected

### Event Monitoring

Monitor these key events:
- `InvoiceCommitted`
- `GrantDistributed`
- `YieldDistributed`
- `DonationMade`

## Upgrade Strategy

The protocol uses a modular architecture that allows for individual contract upgrades without affecting the entire system. Key considerations:

1. **Storage Layout**: Ensure storage compatibility when upgrading
2. **Proxy Pattern**: Consider using UUPS for upgradeable contracts
3. **Governance**: Implement governance for protocol upgrades
4. **Timelocks**: Add timelocks for critical changes

## Support and Documentation

- **Documentation**: `/docs` directory for detailed API documentation
- **Examples**: `/examples` directory for integration examples
- **Issues**: Report issues via GitHub Issues
- **Discord**: Community support via Discord

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- OpenZeppelin for secure contract libraries
- Aave for yield generation protocol
- Morpho for optimized yield strategies
- Octant for public goods funding infrastructure