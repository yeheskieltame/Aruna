# Key Concepts

## The 70/25/5 Model

This is Aruna's core innovation - an immutable yield distribution formula:

| Recipient | Percentage | Purpose |
|-----------|------------|---------|
| **Investors** | 70% | Competitive returns for depositors |
| **Public Goods** | 25% | Sustainable ecosystem funding |
| **Protocol** | 5% | Maintenance and development |

**Why These Numbers?**

- **70%** keeps investor returns competitive (5.74% effective vs 8.2% gross)
- **25%** generates meaningful impact at scale ($205K/year at $10M TVL)
- **5%** ensures long-term protocol sustainability

**Immutable:** This split is hardcoded in smart contracts and cannot be changed by anyone, including the protocol team.

---

## ERC-4626 Vault Standard

Aruna's vaults follow the ERC-4626 tokenized vault standard.

**What This Means:**
- Standardized deposit/withdraw interface
- Composable with other DeFi protocols
- Predictable share accounting
- Compatible with vault aggregators

**How It Works:**
1. You deposit 1,000 USDC
2. Vault mints you 1,000 shares
3. As yield accrues, share value increases
4. Redeem shares anytime for USDC + yield

**Benefits:**
- Industry standard interface
- Reduced integration complexity
- Interoperable with DeFi ecosystem
- Well-tested security model

---

## Invoice Commitments as NFTs

When businesses submit invoices, they receive ERC-721 NFTs.

**Why NFTs?**
- Unique identifier for each commitment
- Provable on-chain ownership
- Transferable after settlement
- Composable with other systems

**NFT Properties:**
- Token ID = unique invoice identifier
- Metadata includes customer, amount, due date
- Transfer restricted until settled
- Reputation tied to owner address

**Future Use Cases:**
- Secondary markets for settled invoices
- Collateral for other DeFi protocols
- Proof of creditworthiness
- Business credit scores

---

## Reputation System

Businesses build on-chain reputation through invoice settlements.

**How Reputation Works:**
- Start at 0 reputation
- **+1** for each on-time settlement
- **-1** for each default/liquidation
- Visible to all potential partners

**Reputation Benefits:**
- Higher grant limits over time
- Better terms from partners
- Verifiable credit history
- Portable across platforms

**Impact:**
- Encourages timely payments
- Rewards good behavior
- Builds trust transparently
- Creates accountability

---

## Yield Harvesting

Yield doesn't distribute automatically - it must be "harvested."

**Why Manual Harvesting?**
- Optimizes gas costs
- Batches transactions efficiently
- Allows user control of timing
- Prevents spam transactions

**Harvest Mechanics:**
- Can be triggered by anyone (permissionless)
- Must wait 24 hours between harvests per vault
- Calculates yield since last harvest
- Distributes via 70/25/5 split immediately

**Best Practice:**
- Harvest monthly for smaller deposits
- Harvest more frequently for large deposits
- Gas costs vs. yield earned trade-off

---

## Octant v2 Integration

Aruna routes 25% of yield through Octant v2's public goods distribution system.

**What is Octant?**
- Ethereum Foundation's public goods funding platform
- Epoch-based donation cycles
- Community-curated project selection
- Transparent allocation mechanisms

**How Integration Works:**
1. YieldRouter calculates 25% of harvest
2. Sends to OctantDonationModule
3. Module accumulates donations per epoch
4. Forwards batch to Octant v2 contract
5. Octant distributes to approved projects

**Supported Projects (Examples):**
- Ethereum Foundation core development
- Protocol Guild (core dev funding)
- Gitcoin grants infrastructure
- OpenZeppelin security tools
- Community-selected ecosystem projects

---

## Aave v3 Vault Adapter

One of two yield sources in Aruna.

**How It Works:**
- Deposits USDC to Aave lending pool
- Receives aUSDC (interest-bearing token)
- aUSDC balance grows automatically
- Withdraw anytime with accrued interest

**Characteristics:**
- Target APY: 6.5%
- Risk level: Low (battle-tested protocol)
- Liquidity: High (largest DeFi lending protocol)
- Stability: Very stable rates

**When to Use:**
- Prefer stability over maximum yield
- Want battle-tested protocols
- Need reliable, predictable returns

---

## Morpho Vault Adapter

Second yield source offering higher returns.

**How It Works:**
- Deposits to MetaMorpho vault
- MetaMorpho allocates across Morpho Blue markets
- Curator optimizes yield strategies
- Higher returns from peer-to-peer efficiency

**Characteristics:**
- Target APY: 8.2%
- Risk level: Moderate (newer protocol)
- Liquidity: Good (growing TVL)
- Stability: Optimized for higher yields

**When to Use:**
- Want maximum yields
- Comfortable with newer protocols
- Understand Morpho's architecture

---

## Collateral vs Grant Model

Businesses lock collateral but receive instant grants.

**The Mechanism:**
- Lock 10% of invoice amount as collateral
- Immediately receive 3% as grant
- **Net effect**: 7% locked, 3% earned

**Example:**
- $10,000 invoice submitted
- Lock $1,000 USDC (10%)
- Receive $300 USDC grant (3%)
- Actual cost: $700 locked for 90 days
- Settlement unlocks $700

**Why This Works:**
- Businesses get immediate cash incentive
- Protocol has collateral security
- ROI is instant (30% on locked amount)
- Risk is minimized for both parties

---

## Liquidation & Default

Invoices that aren't settled trigger automatic liquidation.

**Default Conditions:**
- Invoice unpaid 120 days after due date
- No settlement transaction submitted
- Collateral held by contract

**Liquidation Process:**
1. After 120 days overdue, invoice marked defaulted
2. Locked collateral forfeited to protocol
3. Business loses 1 reputation point
4. Invoice NFT remains (as proof of default)

**Investor Protection:**
- Collateral mitigates default risk
- Investor deposits unaffected by defaults
- Yield generation continues normally

---

## TVL (Total Value Locked)

Understanding protocol growth metrics.

**What TVL Measures:**
- Total USDC deposited across all vaults
- Indicates protocol adoption
- Determines public goods funding scale

**Impact on Public Goods:**
- $1M TVL → $20,500/year to public goods
- $10M TVL → $205,000/year to public goods
- $50M TVL → $1,025,000/year to public goods

**Growth Drivers:**
- More investors discovering Aruna
- Higher yields attracting deposits
- Public goods impact awareness
- DeFi ecosystem growth

---

## Gas Optimization

Aruna minimizes transaction costs through smart design.

**Key Optimizations:**
- Batch yield distributions (not per-transaction)
- 24-hour harvest interval prevents spam
- Immutable variables reduce storage costs
- Standard interfaces reduce complexity

**User Costs:**
- Deposit: ~$0.50-1 (one-time)
- Harvest: ~$1-2 (monthly)
- Withdraw: ~$0.50-1 (when needed)
- Claim rewards: ~$0.50 (after harvest)

**On Base Network:**
- Significantly cheaper than Ethereum mainnet
- Fast confirmations (2 seconds)
- Low congestion
- Predictable costs

---

## Next Steps

Now that you understand the concepts:
1. See [How It Works](how-it-works.md) for step-by-step flows
2. Read [Use Cases](use-cases.md) for real-world examples
3. Check [Smart Contracts](contracts.md) for deployment details
4. Try the protocol on Base Sepolia testnet
