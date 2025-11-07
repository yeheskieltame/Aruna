# Aruna V2 - Deployment Guide (Base Sepolia)

## 📋 Prerequisites

Before deploying, ensure you have:

1. **Foundry Installed**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Base Sepolia ETH**
   - Get testnet ETH from [Base Sepolia Faucet](https://faucet.quicknode.com/base/sepolia)
   - You'll need ~0.1 ETH for deployment

3. **Base Sepolia USDC**
   - USDC Address: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
   - Get from [Circle Faucet](https://faucet.circle.com/) or swap testnet ETH

4. **BaseScan API Key** (optional, for verification)
   - Get from [BaseScan](https://basescan.org/myapikey)

---

## 🔧 Setup

### 1. Clone and Install

```bash
cd Aruna-Contract
forge install
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your details:

```bash
# Your deployer wallet private key
PRIVATE_KEY=0xYourPrivateKeyHere

# Protocol configuration
PROTOCOL_TREASURY=0xYourTreasuryWalletAddress
OWNER_ADDRESS=0xYourOwnerWalletAddress

# RPC URL (optional, defaults to public RPC)
BASE_SEPOLIA_RPC=https://sepolia.base.org

# For contract verification
BASESCAN_API_KEY=YourBaseScanAPIKey
```

**Important:**
- `PROTOCOL_TREASURY`: Where protocol fees (5%) will be sent
- `OWNER_ADDRESS`: Admin address for contract ownership
- These can be the same address as your deployer address

---

## 🚀 Deployment

### Step 1: Build Contracts

```bash
forge build
```

Ensure all contracts compile without errors.

### Step 2: Run Tests (Optional but Recommended)

```bash
forge test
```

### Step 3: Deploy to Base Sepolia

```bash
forge script script/DeployAruna.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

**What this does:**
1. Deploys MockOctantDeposits (for testnet)
2. Deploys OctantDonationModule
3. Deploys YieldRouter
4. Deploys AaveVaultAdapter
5. Deploys MorphoVaultAdapter
6. Deploys ArunaCore
7. Initializes all contracts
8. Saves deployment addresses to `deployments/84532.json`

### Step 4: Verify Deployment

After deployment, you'll see output like:

```
=== Deployment Summary ===
ArunaCore: 0x123...
AaveVaultAdapter: 0x456...
MorphoVaultAdapter: 0x789...
YieldRouter: 0xabc...
OctantDonationModule: 0xdef...
MockOctantDeposits: 0x012...
========================
```

**Save these addresses!** You'll need them for frontend integration.

---

## 🧪 Post-Deployment Testing

### 1. Verify on BaseScan

Visit BaseScan and check each contract:
- https://sepolia.basescan.org/address/YOUR_CONTRACT_ADDRESS

Ensure:
- ✅ Contract is verified (green checkmark)
- ✅ Contract name shows correctly
- ✅ Read/Write functions are visible

### 2. Test Basic Functions

Using BaseScan's "Write Contract" interface:

#### A. Fund the Contract with USDC

The contract needs USDC to give grants. As the owner:

1. Go to USDC contract: `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
2. Call `transfer(ArunaCore_Address, 10000000000)` // 10,000 USDC
3. Verify balance: Call `balanceOf(ArunaCore_Address)`

#### B. Test Invoice Submission

On ArunaCore contract:

1. First approve USDC:
   ```
   USDC.approve(ArunaCore_Address, 1000000000) // 1,000 USDC
   ```

2. Submit test invoice:
   ```
   submitInvoiceCommitment(
     "Test Customer",           // customerName
     10000000000,               // invoiceAmount (10,000 USDC)
     1735689600                 // dueDate (Jan 1, 2025)
   )
   ```

3. Check you received grant:
   ```
   USDC.balanceOf(your_address) // Should increase by 300 USDC (3%)
   ```

#### C. Test Vault Deposit

1. Approve USDC to ArunaCore:
   ```
   USDC.approve(ArunaCore_Address, 1000000000) // 1,000 USDC
   ```

2. Deposit to Aave vault:
   ```
   depositToAaveVault(1000000000) // 1,000 USDC
   ```

3. Check vault shares received (should return non-zero)

#### D. Test Yield Claiming

Wait a bit for yield to accrue (or manually simulate), then:

```
getUserYield(your_address) // Check claimable yield
claimYield()                // Claim the yield
```

---

## 📊 Monitoring & Maintenance

### Check Contract State

You can monitor your deployment using these view functions:

```solidity
// On ArunaCore
getVaultAddresses() // Returns Aave and Morpho vault addresses
getUserReputation(address) // User's reputation score
getCommitment(tokenId) // Invoice details

// On YieldRouter
getUserTotalYield(address) // Total yield earned
getClaimableYield(address) // Yield available to claim
totalYieldDistributed() // Protocol-wide stats

// On OctantDonationModule
getCurrentEpoch() // Current epoch number
getEpochDonations(epoch) // Total donated this epoch
getSupportedProjects() // List of public goods projects
```

### Watch Events

Monitor these events for activity:

```solidity
// ArunaCore
event InvoiceCommitted(...)
event InvoiceSettled(...)
event VaultDeposit(...)
event YieldClaimed(...)

// YieldRouter
event YieldDistributed(...)

// OctantDonationModule
event DonationMade(...)
```

---

## 🔒 Security Considerations

### 1. Owner Responsibilities

The owner address can:
- ✅ Update max grant amount
- ✅ Emergency withdraw stuck funds
- ✅ Toggle pause on vaults
- ⚠️ **Cannot:** Steal user funds or change protocol parameters

### 2. Protocol Treasury

- Receives 5% of all yield
- Should be a secure multisig wallet for mainnet

### 3. Upgrade Path

Contracts are **not upgradeable**. To upgrade:
1. Deploy new versions
2. Migrate liquidity
3. Update frontend

---

## 🛠️ Troubleshooting

### Error: "Insufficient grant reserves"

**Solution:** Fund the ArunaCore contract with USDC:
```bash
# Transfer USDC to contract
cast send 0x036CbD53842c5426634e7929541eC2318f3dCF7e \
  "transfer(address,uint256)" \
  <ArunaCore_Address> \
  10000000000 \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY
```

### Error: "ERC20: insufficient allowance"

**Solution:** Approve USDC first:
```bash
cast send 0x036CbD53842c5426634e7929541eC2318f3dCF7e \
  "approve(address,uint256)" \
  <ArunaCore_Address> \
  <amount> \
  --rpc-url https://sepolia.base.org \
  --private-key $PRIVATE_KEY
```

### Error: "Unsupported chain ID"

**Solution:** Ensure you're on Base Sepolia (chain ID 84532):
```bash
cast chain-id --rpc-url https://sepolia.base.org
# Should return: 84532
```

---

## 📞 Next Steps

After successful deployment:

1. ✅ **Save deployment addresses** from `deployments/84532.json`
2. ✅ **Fund ArunaCore** with USDC for grants
3. ✅ **Test all functions** on BaseScan
4. ✅ **Update frontend** with new contract addresses
5. ✅ **Deploy frontend** to Vercel
6. ✅ **Test end-to-end** user flows

See `INTEGRATION_GUIDE.md` for frontend integration steps.

---

## 📚 Useful Commands

```bash
# Check deployment status
forge script script/DeployAruna.s.sol --rpc-url https://sepolia.base.org

# Verify a single contract
forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/ArunaCore.sol:ArunaCore \
  --chain base-sepolia \
  --etherscan-api-key $BASESCAN_API_KEY

# Check contract balance
cast balance <CONTRACT_ADDRESS> --rpc-url https://sepolia.base.org

# Call a read function
cast call <CONTRACT_ADDRESS> "getUserYield(address)" <USER_ADDRESS> --rpc-url https://sepolia.base.org

# Send a transaction
cast send <CONTRACT_ADDRESS> "claimYield()" --rpc-url https://sepolia.base.org --private-key $PRIVATE_KEY
```

---

## 🎯 Deployment Checklist

- [ ] Foundry installed and updated
- [ ] Base Sepolia ETH in deployer wallet (>0.1 ETH)
- [ ] `.env` file configured
- [ ] Contracts compile successfully (`forge build`)
- [ ] Tests pass (`forge test`)
- [ ] Deployment script run successfully
- [ ] All contracts verified on BaseScan
- [ ] ArunaCore funded with USDC
- [ ] Test invoice submitted successfully
- [ ] Test vault deposit successful
- [ ] Deployment addresses saved
- [ ] Frontend `.env.local` updated
- [ ] End-to-end test completed

---

**Need help?** Check the troubleshooting section or review transaction errors on BaseScan.
