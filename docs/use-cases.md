# Real-World Use Cases

## Use Case 1: Web3 Development Agency

**Scenario:** A blockchain development agency regularly invoices clients with 60-90 day payment terms.

### The Problem
- Monthly operating costs: $50,000
- Invoice payment delays: 60 days average
- Cash flow gaps create stress
- Can't take on new projects while waiting for payment

### Using Aruna

**Step-by-Step Flow:**

```mermaid
sequenceDiagram
    participant Agency
    participant Aruna
    participant Client

    Agency->>Aruna: Submit 50000 USD invoice (60 days)
    Agency->>Aruna: Lock 5000 USD collateral (10%)
    Aruna->>Agency: Send 1500 USD grant (3%)

    Note over Agency: Net: 3500 USD locked, 1500 USD grant received

    Client->>Agency: Pay 50000 USD invoice (after 60 days)
    Agency->>Aruna: Settle invoice
    Aruna->>Agency: Unlock 3500 USD collateral
    Aruna->>Agency: Grant +1 reputation point
```

### Results
- **Immediate**: $1,500 working capital unlocked
- **Cost**: $3,500 locked for 60 days
- **ROI**: 43% on locked funds (over 60 days)
- **Long-term**: On-chain reputation built

---

## Use Case 2: Individual DeFi Investor

**Scenario:** An investor has $100,000 USDC seeking yield while supporting Ethereum ecosystem.

### The Journey

**Timeline of Impact:**

```mermaid
graph LR
    A[Investor: 100000 USD] --> B[Deposit to Morpho Vault]
    B --> C[Month 1: Harvest 683 USD]
    C --> D[478 USD earned + 171 USD to public goods]
    D --> E[Month 2: Harvest 683 USD]
    E --> F[478 USD earned + 171 USD to public goods]
    F --> G[Year 1 Total]
    G --> H[5740 USD earned]
    G --> I[2050 USD to public goods]
```

### Five-Year Impact

| Year | Investor Earnings | Public Goods Funded | Cumulative Impact |
|------|------------------|---------------------|-------------------|
| 1 | $5,740 | $2,050 | $2,050 |
| 2 | $5,740 | $2,050 | $4,100 |
| 3 | $5,740 | $2,050 | $6,150 |
| 4 | $5,740 | $2,050 | $8,200 |
| 5 | $5,740 | $2,050 | $10,250 |

**Total after 5 years:**
- Investor earned: $28,700
- Public goods funded: $10,250
- **From one deposit action**

---

## Use Case 3: DAO Treasury Management

**Scenario:** A DAO has $5M treasury seeking productive use while supporting ecosystem.

### Traditional Approach vs Aruna

**Comparison:**

**Traditional Treasury Management:**
```mermaid
graph TD
    A[DAO Treasury: 5M USD] --> B[Traditional Options]
    B --> C[Staking: Low yields]
    B --> D[Lending: No impact]
    B --> E[One-time grants only]
    C & D & E --> F[Result: Suboptimal]
```

**Aruna Treasury Strategy:**
```mermaid
graph TD
    A[DAO Treasury: 5M USD] --> B[Deposit to Aruna]
    B --> C[287K USD/year earned]
    B --> D[102K USD/year to public goods]
    B --> E[Full liquidity maintained]
    C & D & E --> F[Result: Optimal + Impact]
```

### Annual Impact at $5M Deposit

**At 8.2% APY:**
- Total yield: $410,000
- DAO receives (70%): $287,000
- Public goods (25%): $102,500
- Protocol (5%): $20,500

**Compared to $100K Gitcoin donation:**
- Aruna funds **$102K every year** from yield alone
- DAO still earns $287K (competitive returns)
- Zero principal consumed
- Scales with treasury growth

---

## Use Case 4: Protocol-to-Protocol Integration

**Scenario:** A DeFi protocol wants to offer users public goods funding without complexity.

### Integration Flow

**Seamless User Experience:**

```mermaid
sequenceDiagram
    participant User
    participant PartnerProtocol
    participant ArunaVaults
    participant PublicGoods

    User->>PartnerProtocol: Deposit via partner UI
    PartnerProtocol->>ArunaVaults: Forward to Aruna vault
    ArunaVaults-->>PartnerProtocol: Return vault shares
    PartnerProtocol-->>User: Show balance and yield

    User->>PartnerProtocol: Request withdraw
    PartnerProtocol->>ArunaVaults: Harvest and withdraw
    ArunaVaults->>ArunaVaults: Distribute 70/25/5 split
    ArunaVaults-->>PartnerProtocol: Return funds (70% yield)
    ArunaVaults->>PublicGoods: Send 25% to public goods
    PartnerProtocol-->>User: Transfer funds to wallet
```

### Benefits for Partner Protocol
- Differentiate with public goods impact
- No additional smart contract development
- Leverage Aruna's audited infrastructure
- Market as "impact-aligned" protocol

### Benefits for Users
- No workflow changes
- Automatic public goods support
- Competitive yields maintained
- Transparent impact tracking

---

## Use Case 5: Ethereum Core Developer Funding

**Scenario:** Protocol Guild receives funding from Aruna's 25% yield allocation.

### Funding Flow

**From Investors to Core Developers:**

```mermaid
graph TD
    A[Multiple Investors] --> B[Total: 10M USD TVL]
    B --> C[Generate 820K USD/year yield at 8.2% APY]

    C --> D1[574K USD/year to Investors - 70%]
    C --> D2[205K USD/year to Public Goods - 25%]
    C --> D3[41K USD/year to Protocol - 5%]

    D2 --> E[Octant v2 Distribution]

    E --> F1[Protocol Guild: 50K USD/year]
    E --> F2[Ethereum Foundation: 30K USD/year]
    E --> F3[Gitcoin: 25K USD/year]
    E --> F4[Other Projects: 100K USD/year]

    F1 --> G[Funds 10 Core Developers]
```

### Impact on Protocol Guild

**With $10M Aruna TVL:**
- Protocol Guild receives: ~$50,000/year
- Funds approximately: 10 part-time core developers
- Recurring: Every year, indefinitely
- Predictable: Can plan multi-year roadmaps

**As Aruna Grows to $100M TVL:**
- Protocol Guild receives: ~$500,000/year
- Funds approximately: 100 part-time developers
- Transforms ecosystem sustainability

---

## Use Case 6: Small Business Cash Flow

**Scenario:** A local blockchain consultancy with lumpy revenue.

### Monthly Cash Flow Comparison

**Without Aruna:**
- Month 1: Invoice $10K → Wait 60 days
- Month 2: Invoice $15K → Wait 60 days
- Cash crunch months 1-2
- Can't hire freelancer needed for project

**With Aruna:**
- Month 1: Invoice $10K → Lock $1K, get $300 grant → Hire freelancer
- Month 2: Invoice $15K → Lock $1.5K, get $450 grant → Cover expenses
- Month 3: First invoice paid → Unlock $700 collateral
- Smooth cash flow, business growth

### The Numbers

| Invoice | Collateral | Grant | Net Locked | Days | Effective APY |
|---------|-----------|-------|------------|------|---------------|
| $10,000 | $1,000 | $300 | $700 | 60 | 262% |
| $15,000 | $1,500 | $450 | $1,050 | 60 | 262% |
| $20,000 | $2,000 | $600 | $1,400 | 90 | 175% |

**Result:** Sustainable business growth with minimal capital requirements.

---

## Use Case 7: Yield Aggregator Integration

**Scenario:** Yield aggregator wants to offer "impact vaults" to users.

### User Experience

**Through Yield Aggregator:**

```mermaid
sequenceDiagram
    participant User
    participant Aggregator
    participant ArunaVaults

    User->>Aggregator: Browse vaults
    Aggregator-->>User: Show Standard vs Impact Vault

    User->>Aggregator: Select Impact Vault (Aruna)
    Aggregator->>ArunaVaults: Deposit user funds
    ArunaVaults-->>Aggregator: Return vault shares

    loop Monthly Cycle
        ArunaVaults->>ArunaVaults: Accrue yield automatically
        User->>Aggregator: View dashboard
        Aggregator->>ArunaVaults: Query yield earned
        Aggregator-->>User: Display earnings and public goods funded
    end
```

### Aggregator Benefits
- Differentiate with impact-focused products
- Attract ESG-conscious users
- No additional smart contract risk
- Marketing advantage in competitive market

---

## Summary: Who Benefits?

| User Type | Primary Benefit | Secondary Benefit |
|-----------|----------------|-------------------|
| **Businesses** | Instant cash grants | On-chain credit history |
| **Investors** | Competitive yields | Automatic impact creation |
| **DAOs** | Treasury optimization | Values alignment |
| **Public Goods** | Sustainable funding | Predictable revenue |
| **Protocols** | User differentiation | Impact marketing |
| **Ecosystem** | Developer funding | Long-term sustainability |

---

## Getting Started

Ready to try Aruna? Here's what to do:

1. **For Investors**: Visit [Aruna App](https://aruna-defi.vercel.app), connect wallet, deposit USDC
2. **For Businesses**: Submit your first invoice commitment via business dashboard
3. **For Protocols**: Check our [GitHub](https://github.com/yeheskieltame/Aruna) for integration docs
4. **For Public Goods**: Apply to Octant v2 to receive allocations

**Questions?** Check out [How It Works](how-it-works.md) or review [Key Concepts](concepts.md).
