# Smart Contract Flow Analysis - Aruna Protocol

## Overview

Analisa lengkap alur kerja smart contract Aruna Protocol dan implementasinya di frontend.

## Contract Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Layer                               │
│  (Business Users)              (Investors)                       │
└────────────┬────────────────────────────┬────────────────────────┘
             │                            │
             │                            │
┌────────────▼────────────────────────────▼────────────────────────┐
│                        ArunaCore.sol                              │
│  • submitInvoiceCommitment()   • depositToAaveVault()            │
│  • settleInvoice()             • depositToMorphoVault()          │
│  • claimYield()                • withdrawFromAaveVault()         │
│  • getUserCommitments()        • withdrawFromMorphoVault()       │
└────────────┬────────────────────────────┬────────────────────────┘
             │                            │
             │                            │
┌────────────▼────────────┐   ┌──────────▼─────────────────────────┐
│   YieldRouter.sol       │   │   Vault Adapters                   │
│  • distributeYield()    │   │  • AaveVaultAdapter (ERC-4626)     │
│  • claimYield()         │   │  • MorphoVaultAdapter (ERC-4626)   │
│  • getClaimableYield()  │   │                                    │
└────────────┬────────────┘   └──────────┬─────────────────────────┘
             │                           │
             │                           │
┌────────────▼──────────────────────────▼─────────────────────────┐
│                    External Protocols                            │
│  • Aave v3 Pool (Base Sepolia)                                  │
│  • Morpho Blue Vaults                                           │
│  • Octant v2 (Public Goods)                                     │
└──────────────────────────────────────────────────────────────────┘
```

## Business User Flow

### 1. Submit Invoice Commitment

**Contract Function:**
```solidity
function submitInvoiceCommitment(
    string memory customerName,
    uint256 invoiceAmount,
    uint256 dueDate
) external returns (uint256 tokenId)
```

**Steps:**
1. User approves USDC for 10% collateral
2. Call `submitInvoiceCommitment()`
3. Contract:
   - Transfers 10% collateral from user
   - Automatically sends 3% grant back to user
   - Net: 7% locked, 3% received
   - Mints ERC-721 NFT as proof
4. Returns NFT tokenId

**Frontend Implementation:**
```typescript
// Step 1: Approve USDC
await approve(ARUNA_CORE_ADDRESS, collateralAmount)

// Step 2: Submit invoice
await submit(customerName, invoiceAmount, dueDate)
```

**What's Missing in Current Frontend:**
- ❌ Display NFT tokenId after submission
- ❌ Show transaction receipt/confirmation
- ❌ Display actual grant received (3%)
- ❌ Show net collateral locked (7%)

### 2. View User Invoices

**Contract Function:**
```solidity
function getUserCommitments(address user) external view returns (uint256[] memory)
function getCommitment(uint256 tokenId) external view returns (Commitment memory)
```

**Returns:**
```solidity
struct Commitment {
    address business;
    string customerName;
    uint256 invoiceAmount;
    uint256 collateralAmount;
    uint256 dueDate;
    uint256 timestamp;
    CommitmentStatus status; // ACTIVE, SETTLED, DEFAULTED, LIQUIDATED
}
```

**What's Missing in Current Frontend:**
- ❌ Not implemented - need to fetch user's invoice list
- ❌ No display of invoice details
- ❌ No status tracking

### 3. Settle Invoice

**Contract Function:**
```solidity
function settleInvoice(uint256 tokenId) external
```

**Steps:**
1. Business receives payment from customer
2. Call `settleInvoice(tokenId)`
3. Contract:
   - Returns collateral to business
   - Updates status to SETTLED
   - Increases user reputation by 1
4. Business can claim accumulated yield

**What's Missing in Current Frontend:**
- ❌ Settle invoice button not implemented
- ❌ No invoice status display
- ❌ No collateral return tracking

### 4. Claim Yield

**Contract Function:**
```solidity
function claimYield() external returns (uint256)
function getUserYield(address user) external view returns (uint256)
```

**Steps:**
1. Check claimable yield with `getUserYield()`
2. Call `claimYield()`
3. Receive 70% of accumulated yield

**What's Missing in Current Frontend:**
- ❌ Claimable yield not displayed
- ❌ Claim button not prominent
- ❌ No yield history

## Investor User Flow

### 1. Check Vault Balances

**Contract Functions:**
```solidity
// From Vault Adapters (ERC-4626)
function balanceOf(address account) external view returns (uint256 shares)
function convertToAssets(uint256 shares) external view returns (uint256 assets)
function totalAssets() external view returns (uint256)
```

**What's Currently Implemented:**
- ✅ useVaultBalance hook exists
- ✅ Shows share balance

**What's Missing:**
- ❌ Convert shares to USD value
- ❌ Show APY calculation
- ❌ Display total deposited vs current value

### 2. Deposit to Vault

**Contract Functions:**
```solidity
function depositToAaveVault(uint256 assets, address receiver) external returns (uint256 shares)
function depositToMorphoVault(uint256 assets, address receiver) external returns (uint256 shares)
```

**Steps:**
1. Approve USDC for vault
2. Call deposit function
3. Receive ERC-4626 shares
4. Shares represent ownership in vault

**Current Implementation:**
- ✅ Approval flow implemented
- ✅ Deposit functions implemented

**What's Missing:**
- ❌ Show shares received after deposit
- ❌ Display share price
- ❌ Show estimated APY

### 3. Withdraw from Vault

**Contract Functions:**
```solidity
function withdrawFromAaveVault(uint256 assets, address receiver, address owner) external returns (uint256 shares)
function withdrawFromMorphoVault(uint256 assets, address receiver, address owner) external returns (uint256 shares)
```

**What's Missing:**
- ❌ Withdraw functionality NOT implemented in frontend
- ❌ No UI for withdrawal
- ❌ No max withdraw calculation

### 4. Claim Investor Yield

**Contract Function:**
```solidity
// Via YieldRouter
function claimYield() external returns (uint256)
function getClaimableYield(address user) external view returns (uint256)
```

**Yield Distribution:**
- Investors receive 70% of vault yield
- 25% goes to public goods
- 5% to protocol treasury

**What's Currently Implemented:**
- ✅ useClaimableYield hook exists
- ✅ Displays claimable amount

**What's Missing:**
- ❌ Claim yield button not implemented
- ❌ No yield history
- ❌ No breakdown of yield sources

## Missing Critical Features

### For Business Users

1. **Invoice List Display**
   - Fetch user invoices via `getUserCommitments()`
   - Display each invoice with status
   - Show collateral locked per invoice

2. **Invoice Details Modal**
   - Customer name
   - Invoice amount
   - Due date
   - Status (Active/Settled/Defaulted)
   - Grant received
   - Collateral locked

3. **Settle Invoice Action**
   - Button to settle each active invoice
   - Transaction confirmation
   - Collateral return notification

4. **Reputation Display**
   - Current reputation score
   - Reputation tier (Bronze/Silver/Gold/etc)
   - Max grant amount available

5. **Yield Tracking**
   - Show claimable yield
   - Prominent claim button
   - Yield history/transactions

### For Investors

1. **Enhanced Vault Display**
   - Convert shares to USD value
   - Show APY (current & historical)
   - Display profit/loss
   - Total deposited vs current value

2. **Withdraw Functionality**
   - Withdraw form/modal
   - Max withdraw button
   - Fee calculation (if any)
   - Transaction confirmation

3. **Yield Claiming**
   - Prominent claim yield button
   - Show yield breakdown (70% investor share)
   - Display public goods contribution (25%)
   - Yield history/timeline

4. **Portfolio Overview**
   - Total value across all vaults
   - Total yield earned
   - Public goods funded
   - Historical performance chart

## Implementation Priority

### High Priority (Critical for MVP)

1. ✅ **Fetch User Invoices**
   - Implement `getUserCommitments()` call
   - Display invoice list with details

2. ✅ **Settle Invoice**
   - Add settle button for each active invoice
   - Handle transaction and update UI

3. ✅ **Withdraw from Vaults**
   - Create withdraw modal/form
   - Implement withdraw transaction

4. ✅ **Claim Yield (Both Users)**
   - Add prominent claim buttons
   - Show claimable amounts
   - Handle claim transactions

### Medium Priority (Enhances UX)

5. **Transaction Status Tracking**
   - Show pending/confirming/success states
   - Display transaction hashes
   - Link to block explorer

6. **Share to USD Conversion**
   - Calculate USD value from shares
   - Show in vault displays

7. **Reputation System Display**
   - Show current reputation
   - Display tier and benefits

### Low Priority (Nice to Have)

8. **Yield History**
   - Chart of yield over time
   - Transaction history table

9. **Public Goods Impact**
   - Total funded visualization
   - Project breakdown

10. **APY Calculations**
    - Real-time APY from vaults
    - Historical APY chart

## Data Flow Architecture

### Current Implementation

```
User Action → Component → Custom Hook → Wagmi → Contract
              ↓
         State Update (local)
```

### Needed Implementation

```
User Action → Component → Custom Hook → Wagmi → Contract
              ↓                                    ↓
         Loading State                      Event Emitted
              ↓                                    ↓
         Success/Error ←────── Wait for Confirmation
              ↓
         Fetch Updated Data ←─── useReadContract
              ↓
         Update UI
```

## Required New Hooks

### Business Hooks

```typescript
// Get user's invoice list
export function useUserInvoices(address?: `0x${string}`)

// Get specific invoice details
export function useInvoiceDetails(tokenId?: bigint)

// Settle invoice
export function useSettleInvoice()

// Get user's reputation tier info
export function useReputationTier(address?: `0x${string}`)
```

### Investor Hooks

```typescript
// Convert shares to assets (USD value)
export function useConvertToAssets(
  vaultAddress: `0x${string}`,
  shares?: bigint
)

// Get max withdrawable amount
export function useMaxWithdraw(
  vaultAddress: `0x${string}`,
  owner?: `0x${string}`
)

// Withdraw from vault
export function useWithdrawFromVault(isAave: boolean)

// Get vault APY
export function useVaultAPY(vaultAddress: `0x${string}`)
```

### Shared Hooks

```typescript
// Enhanced claim yield with breakdown
export function useClaimYieldWithDetails()

// Get yield history
export function useYieldHistory(address?: `0x${string}`)

// Get transaction status
export function useTransactionStatus(hash?: `0x${string}`)
```

## Next Steps

1. ✅ Implement missing hooks for invoice management
2. ✅ Create invoice list component with real data
3. ✅ Add settle invoice functionality
4. ✅ Implement vault withdrawal
5. ✅ Add claim yield buttons prominently
6. ✅ Implement transaction status tracking
7. ✅ Test complete user flows end-to-end

## Summary

**Current State:**
- ✅ Basic deposit functionality works
- ✅ Invoice submission works
- ✅ Basic data display implemented

**Missing:**
- ❌ Invoice list and details
- ❌ Settle invoice action
- ❌ Withdraw from vaults
- ❌ Claim yield prominently
- ❌ Transaction confirmations
- ❌ Share to USD conversion
- ❌ Reputation display

**Goal:**
Complete end-to-end user flows where users can:
1. Business: Submit → View → Settle → Claim Yield
2. Investor: Deposit → Monitor → Withdraw → Claim Yield
