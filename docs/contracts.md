# Smart Contracts

## Deployed on Base Sepolia

All Aruna contracts are deployed and verified on Base Sepolia testnet.

**Network Details:**
- Chain ID: 84532
- RPC URL: https://sepolia.base.org
- Block Explorer: https://sepolia.basescan.org

**Deployment Date:** November 9, 2024

## Core Contracts

### ArunaCore
Manages invoice commitments as ERC-721 NFTs, grants, and reputation.

```
Address: 0xE60dcA6869F072413557769bDFd4e30ceFa6997f
```

[View on BaseScan](https://sepolia.basescan.org/address/0xE60dcA6869F072413557769bDFd4e30ceFa6997f)

**Functions:**
- Submit invoice commitments
- Track business reputation
- Manage collateral and grants

---

### YieldRouter
Distributes harvested yield according to 70/25/5 model.

```
Address: 0x124d8F59748860cdD851fB176c7630dD71016e89
```

[View on BaseScan](https://sepolia.basescan.org/address/0x124d8F59748860cdD851fB176c7630dD71016e89)

**Functions:**
- Distribute yield to investors (70%)
- Route donations to public goods (25%)
- Collect protocol fees (5%)

---

### OctantDonationModule
Routes 25% of yield to Octant v2 for public goods allocation.

```
Address: 0xEDc5CeE824215cbeEBC73e508558a955cdD75F00
```

[View on BaseScan](https://sepolia.basescan.org/address/0xEDc5CeE824215cbeEBC73e508558a955cdD75F00)

**Functions:**
- Track total donations
- Monitor epoch contributions
- Forward funds to Octant v2

---

## Vault Adapters (ERC-4626 Compliant)

### AaveVaultAdapter
Integrates with Aave v3 for stable 6.5% APY.

```
Address: 0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905
```

[View on BaseScan](https://sepolia.basescan.org/address/0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905)

**Features:**
- ERC-4626 standard compliance
- Automatic yield harvesting
- Direct Aave v3 integration

---

### MorphoVaultAdapter
Integrates with Morpho for optimized 8.2% APY.

```
Address: 0x16dea7eE228c0781938E6869c07ceb2EEA7bd564
```

[View on BaseScan](https://sepolia.basescan.org/address/0x16dea7eE228c0781938E6869c07ceb2EEA7bd564)

**Features:**
- ERC-4626 standard compliance
- MetaMorpho vault integration
- Higher yield optimization

---

## External Protocol Addresses (Base Sepolia)

### USDC Token

```
Address: 0x036CbD53842c5426634e7929541eC2318f3dCF7e
```

Main stablecoin used for all deposits and transactions.

---

### Aave v3 Pool

```
Address: 0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b
```

Aave lending pool for yield generation.

---

### Aave aUSDC (Interest-Bearing Token)

```
Address: 0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB
```

Automatically accrues interest from Aave deposits.

---

## Testnet Mock Contracts

For testing purposes on Base Sepolia:

### MockOctantDeposits

```
Address: 0x480d28E02b449086efA3f01E2EdA4A4EAE99C3e6
```

Simulates Octant v2 donation system.

---

### MockMetaMorpho

```
Address: 0x7deB84aAe25A2168782E6c8C0CF30714cbaaA025
```

Simulates MetaMorpho vault with 8.2% APY.

---

## Verification

All contracts are verified on BaseScan with full source code visibility. You can:
- Read contract methods
- Verify transaction history
- Check current state
- Interact directly via BaseScan

## Security

**Audited Features:**
- ReentrancyGuard on all state-changing functions
- SafeERC20 for all token operations
- Pausable contracts for emergency situations
- No upgradeable proxies (immutable logic)

## Using These Addresses

**In Your Wallet:**
- Add Base Sepolia network
- Import USDC token for balance visibility
- Interact with contracts via frontend

**In Your Code:**
- Import ABI from verified contracts
- Use these addresses in environment variables
- Connect via wagmi/viem or ethers.js

**For Verification:**
- Check transaction hashes on BaseScan
- Verify yield distribution percentages
- Track public goods donations in real-time
