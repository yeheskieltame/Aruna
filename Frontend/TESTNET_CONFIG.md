# Testnet Configuration - Base Sepolia

## Overview

Konfigurasi khusus untuk testing di Base Sepolia testnet dengan requirements yang lebih rendah untuk memudahkan development dan testing.

## Minimum Deposit Requirements

### Production vs Testnet

| Feature | Production | Testnet (Base Sepolia) |
|---------|-----------|------------------------|
| Vault Deposit Minimum | 100 USDC | **1 USDC** |
| Invoice Amount Minimum | No minimum | No minimum |
| Collateral Requirement | 10% | 10% |

### Alasan Perubahan

**Production (Mainnet):**
- Minimum 100 USDC untuk mengurangi gas cost overhead
- Memastikan deposit layak secara ekonomi
- Mencegah spam transactions

**Testnet (Base Sepolia):**
- **Minimum 1 USDC** untuk memudahkan testing
- Testnet tokens sulit didapat dalam jumlah besar
- Fokus pada functionality testing, bukan economic viability

## Updated Components

### 1. Vault Deposit Component

**File**: `components/vault-deposit.tsx`

**Perubahan:**

```typescript
// OLD (Production)
if (amountNum < 100) {
  setError("Minimum deposit amount is 100 USDC")
  return
}

// NEW (Testnet)
if (amountNum < 1) {
  setError("Minimum deposit amount is 1 USDC")
  return
}
```

**UI Updates:**
- Placeholder changed: `1000` → `10`
- Added `min="1"` attribute
- Added `step="0.01"` for decimal inputs
- Updated message: `"Minimum: 1 USDC • Testnet only"`

### 2. Input Validation

**Updated validation:**

```typescript
✅ Amount must be > 0
✅ Amount must be >= 1 USDC (testnet)
✅ Amount must be <= user balance
✅ Decimal amounts supported (0.01 precision)
```

## Testing with Low Amounts

### Recommended Test Amounts

**Vault Deposits:**
```
Minimum: 1 USDC
Recommended for testing:
- 1 USDC (minimum)
- 5 USDC (small test)
- 10 USDC (medium test)
- 50 USDC (large test)
```

**Invoice Commitments:**
```
No minimum, but practical amounts:
- 10 USDC (10% collateral = 1 USDC)
- 50 USDC (10% collateral = 5 USDC)
- 100 USDC (10% collateral = 10 USDC)
```

### Example Test Scenarios

#### Scenario 1: Minimal Vault Deposit
```typescript
Amount: 1 USDC
Expected APY (Aave): 6.5%
Annual Yield: 0.065 USDC
Your Share: 0.0455 USDC (70%)
Public Goods: 0.01625 USDC (25%)
```

#### Scenario 2: Small Invoice
```typescript
Invoice Amount: 10 USDC
Collateral Required: 1 USDC (10%)
Instant Grant: 0.3 USDC (3%)
Net Collateral: 0.7 USDC
```

#### Scenario 3: Medium Test
```typescript
Vault Deposit: 10 USDC
Expected APY (Morpho): 8.2%
Annual Yield: 0.82 USDC
Your Share: 0.574 USDC (70%)
Public Goods: 0.205 USDC (25%)
```

## Getting Testnet Tokens

### Base Sepolia ETH (for gas)

**Faucet 1: Coinbase Faucet**
```
URL: https://www.coinbase.com/faucets/base-sepolia-faucet
Amount: 0.05 ETH per request
Frequency: Once per 24 hours
Requirements: Coinbase account
```

**Faucet 2: Base Sepolia Faucet**
```
URL: https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet
Amount: 0.1 ETH per request
Requirements: Wallet address
```

### Base Sepolia USDC (for deposits)

**Circle Testnet Faucet**
```
URL: https://faucet.circle.com/
Network: Select "Base Sepolia"
Amount: 10 USDC per request
Frequency: Multiple requests allowed
Requirements: Wallet address only
```

**Steps:**
1. Visit https://faucet.circle.com/
2. Select "Base Sepolia" network
3. Enter your wallet address
4. Click "Request USDC"
5. Wait 10-30 seconds for tokens

### Alternative: Bridge from Sepolia

```
1. Get Sepolia ETH from faucets
2. Bridge to Base Sepolia using official bridge
3. Swap for USDC on Base Sepolia DEX
```

## Configuration Files

### Environment Variables

**File**: `.env.local`

```bash
# Testnet Configuration
NEXT_PUBLIC_CHAIN_ID=84532
NEXT_PUBLIC_BASE_SEPOLIA_RPC=https://sepolia.base.org

# Contract Addresses (Base Sepolia)
NEXT_PUBLIC_ARUNA_CORE=0x5ee04F6377e03b47F5e932968e87ad5599664Cf2
NEXT_PUBLIC_AAVE_VAULT=0x8E9F6B3230800B781e461fce5F7F118152FeD969
NEXT_PUBLIC_MORPHO_VAULT=0xc4388Fe5A3057eE1fc342a8018015f32f6aF6A7d
NEXT_PUBLIC_YIELD_ROUTER=0x9721ee37de0F289A99f8EA2585293575AE2654CC
NEXT_PUBLIC_OCTANT_MODULE=0xB745282F0FCe7a669F9EbD50B403e895090b1b24

# External Contracts
NEXT_PUBLIC_USDC=0x036CbD53842c5426634e7929541eC2318f3dCF7e
NEXT_PUBLIC_AAVE_POOL=0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b
```

## Testing Workflow

### Step 1: Setup Wallet
```
1. Install Coinbase Wallet Extension
2. Create new wallet or import existing
3. Switch to Base Sepolia network
```

### Step 2: Get Test Tokens
```
1. Get Base Sepolia ETH (0.05-0.1 ETH)
2. Get Base Sepolia USDC (10-50 USDC)
3. Verify balance in wallet
```

### Step 3: Connect to Aruna
```
1. Visit http://localhost:3000 or deployment URL
2. Click "Connect Wallet"
3. Select "Coinbase Wallet"
4. Approve connection
```

### Step 4: Test Deposits
```
Test Case 1: Minimum Deposit
- Amount: 1 USDC
- Vault: Aave
- Expected: Success

Test Case 2: Small Deposit
- Amount: 5 USDC
- Vault: Morpho
- Expected: Success

Test Case 3: Medium Deposit
- Amount: 10 USDC
- Vault: Aave
- Expected: Success
```

### Step 5: Test Invoices
```
Test Case 1: Small Invoice
- Amount: 10 USDC
- Collateral: 1 USDC
- Grant: 0.3 USDC
- Expected: Success

Test Case 2: Medium Invoice
- Amount: 50 USDC
- Collateral: 5 USDC
- Grant: 1.5 USDC
- Expected: Success
```

## Validation Rules (Testnet)

### Vault Deposits
```typescript
✅ Amount >= 1 USDC (minimum)
✅ Amount <= user balance
✅ Amount > 0 (positive)
✅ Decimal precision: 0.01
```

### Invoice Submissions
```typescript
✅ Amount > 0 (no minimum)
✅ Collateral = Amount * 10%
✅ Grant = Amount * 3%
✅ Due date must be future date
✅ Customer name required
```

## Gas Estimates (Base Sepolia)

| Transaction | Estimated Gas | Cost (0.01 gwei) |
|-------------|---------------|------------------|
| Approve USDC | ~50,000 | ~0.0000005 ETH |
| Vault Deposit | ~150,000 | ~0.0000015 ETH |
| Submit Invoice | ~200,000 | ~0.000002 ETH |
| Settle Invoice | ~100,000 | ~0.000001 ETH |
| Claim Yield | ~80,000 | ~0.0000008 ETH |

Total testing budget: **~0.001 ETH** untuk multiple transactions.

## Troubleshooting

### "Minimum deposit amount is 1 USDC"
**Cause**: Trying to deposit less than 1 USDC
**Solution**: Enter amount >= 1 USDC

### "Insufficient balance"
**Cause**: Not enough USDC in wallet
**Solution**: Get more test USDC from Circle faucet

### "Transaction failed"
**Cause**: Not enough ETH for gas
**Solution**: Get more test ETH from Base Sepolia faucet

### "Please connect your wallet"
**Cause**: Wallet not connected
**Solution**: Click "Connect Wallet" and approve connection

## Migrating to Production

Ketika ready untuk production deployment:

### Changes Required

**1. Update Minimum Amounts:**
```typescript
// In vault-deposit.tsx
if (amountNum < 100) { // Change back to 100
  setError("Minimum deposit amount is 100 USDC")
  return
}
```

**2. Update UI Messages:**
```typescript
// Remove "Testnet only" labels
<p>Minimum: 100 USDC</p>
```

**3. Update Contract Addresses:**
```bash
# Deploy to Base Mainnet
# Update .env.local with mainnet addresses
NEXT_PUBLIC_CHAIN_ID=8453
NEXT_PUBLIC_BASE_RPC=https://mainnet.base.org
```

**4. Update Faucet References:**
- Remove testnet faucet links
- Update documentation for mainnet usage
- Add mainnet bridge instructions

## Summary

### Current Testnet Configuration

| Parameter | Value |
|-----------|-------|
| Network | Base Sepolia |
| Chain ID | 84532 |
| Min Vault Deposit | **1 USDC** |
| Min Invoice | No minimum |
| Collateral Rate | 10% |
| Grant Rate | 3% |
| Public Goods Share | 25% |

### Benefits for Testing

✅ Low barrier to entry (1 USDC minimum)
✅ Easy to get testnet tokens
✅ Multiple test scenarios possible
✅ Realistic workflow testing
✅ Gas cost minimal on testnet

### Next Steps

1. Get testnet tokens from faucets
2. Connect wallet to Base Sepolia
3. Test with small amounts (1-10 USDC)
4. Verify all functionality works
5. Report any issues for fixes

## Resources

- **Base Sepolia Faucet**: https://www.coinbase.com/faucets/base-sepolia-faucet
- **Circle USDC Faucet**: https://faucet.circle.com/
- **Base Sepolia Explorer**: https://sepolia.basescan.org
- **Wallet Setup Guide**: See `WALLET_SETUP.md`
- **Integration Guide**: See `COINBASE_WALLET_INTEGRATION.md`
