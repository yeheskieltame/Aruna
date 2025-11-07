# Octant Public Goods Integration

This document details Aruna's integration with Octant v2 for automatic public goods funding, including the distribution mechanism, tracking systems, and implementation details.

## Overview

Aruna automatically allocates 25% of all generated yield to public goods projects through Octant v2. This creates a sustainable funding mechanism where every dollar of yield generates $0.25 for the Ethereum ecosystem.

**File:** `src/modules/OctantDonationModule.sol`

## The 70/25/5 Distribution Model

### Allocation Breakdown

Every dollar of yield is distributed according to a fixed formula:

```
Total Yield Generated (100%)
├─ 70% → Investors (userYieldBalance mapping)
├─ 25% → Public Goods (OctantDonationModule)
└─ 5% → Protocol Treasury
```

This split is hardcoded as constants and cannot be changed:

```solidity
uint256 public constant INVESTOR_PERCENTAGE = 7000;     // 70%
uint256 public constant PUBLIC_GOODS_PERCENTAGE = 2500; // 25%
uint256 public constant PROTOCOL_FEE_PERCENTAGE = 500;  // 5%
uint256 public constant BASIS_POINTS = 10000;
```

### Why 25%?

The 25% allocation balances three objectives:

1. **Investor Competitiveness:** 70% maintains attractive returns (5.46% effective vs 7.8% gross)
2. **Meaningful Impact:** 25% generates substantial public goods funding at scale
3. **Protocol Sustainability:** 5% ensures long-term protocol maintenance

Example at $10M TVL with 7.8% APY:
- Total yield: $780,000
- Investors: $546,000
- Public goods: $195,000
- Protocol: $39,000

## Architecture

### Contract Flow

```
Vault generates yield
    ↓
harvestYield() called
    ↓
YieldRouter.distributeYield()
    ├─ Calculate 25% portion
    ├─ Approve OctantDonationModule
    └─ Call octantModule.donate()
        ↓
OctantDonationModule
    ├─ Transfer tokens from YieldRouter
    ├─ Update totalDonated
    ├─ Update currentEpochDonations
    ├─ Update businessContributions[contributor]
    ├─ Update donationsPerEpoch[epoch]
    └─ Emit DonationMade event
        ↓
forwardToOctant() (periodic, owner-only)
    ├─ Batch donations for epoch
    ├─ Approve Octant Deposits contract
    └─ Call octantDeposits.lock()
        ↓
Octant v2 Ecosystem
    └─ Distributes to projects via allocation mechanisms
```

### Key Components

**YieldRouter:**
- Calculates distribution percentages
- Executes transfers
- Calls OctantDonationModule

**OctantDonationModule:**
- Receives public goods allocation
- Tracks contributions
- Manages Octant interaction

**IOctantDeposits:**
- Interface to Octant v2
- Handles epoch-based donations

## Implementation Details

### OctantDonationModule Contract

```solidity
contract OctantDonationModule is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Octant integration
    IOctantDeposits public octantDeposits;
    IERC20 public donationToken;

    // Constants
    uint256 public constant PUBLIC_GOODS_PERCENTAGE = 2500;
    uint256 public constant BASIS_POINTS = 10000;

    // Tracking
    uint256 public totalDonated;
    uint256 public currentEpochDonations;
    mapping(uint256 => uint256) public donationsPerEpoch;
    mapping(address => uint256) public businessContributions;

    // Supported projects
    string[] public supportedProjects;
}
```

### Core Functions

**donate()**

Called by YieldRouter for each yield distribution:

```solidity
function donate(uint256 amount, address contributor) external nonReentrant {
    if (amount == 0) revert InvalidAmount();

    // Transfer from YieldRouter
    donationToken.safeTransferFrom(msg.sender, address(this), amount);

    // Update tracking
    totalDonated += amount;
    currentEpochDonations += amount;
    businessContributions[contributor] += amount;

    // Track by epoch
    uint256 currentEpoch = octantDeposits.getCurrentEpoch();
    donationsPerEpoch[currentEpoch] += amount;

    emit DonationMade(currentEpoch, amount, contributor, block.timestamp);
}
```

**forwardToOctant()**

Batches donations and sends to Octant:

```solidity
function forwardToOctant() external onlyOwner nonReentrant {
    if (currentEpochDonations == 0) revert InvalidAmount();

    uint256 amount = currentEpochDonations;
    uint256 currentEpoch = octantDeposits.getCurrentEpoch();

    // Approve Octant contract
    donationToken.safeIncreaseAllowance(address(octantDeposits), amount);

    // Lock funds for epoch
    try octantDeposits.lock(amount) {
        currentEpochDonations = 0;
        emit EpochFinalized(currentEpoch, amount);
    } catch {
        revert DonationFailed();
    }
}
```

## Tracking and Transparency

### Per-Business Attribution

Every business can see their contribution:

```solidity
mapping(address => uint256) public businessContributions;

function getBusinessContribution(address business)
    external
    view
    returns (uint256)
{
    return businessContributions[business];
}
```

Example:
```
Business A submitted $50,000 invoice
Generated $200 yield over 3 months
Business A's contribution: $50 (25% of $200)
```

### Per-Epoch Tracking

Donations are tracked by Octant epoch:

```solidity
mapping(uint256 => uint256) public donationsPerEpoch;

function getEpochDonations(uint256 epoch)
    external
    view
    returns (uint256)
{
    return donationsPerEpoch[epoch];
}
```

This enables:
- Historical analysis
- Epoch-by-epoch accountability
- Trend identification
- Performance metrics

### Global Statistics

Total donations across all time:

```solidity
uint256 public totalDonated;
```

Current epoch accumulated donations:

```solidity
uint256 public currentEpochDonations;
```

### Event Emissions

All donations emit events for transparency:

```solidity
event DonationMade(
    uint256 indexed epoch,
    uint256 amount,
    address indexed contributor,
    uint256 timestamp
);

event EpochFinalized(
    uint256 indexed epoch,
    uint256 totalDonations
);
```

## Supported Projects

### Project Registry

The contract maintains a list of supported projects:

```solidity
string[] public supportedProjects;

function getSupportedProjects() external view returns (string[] memory) {
    return supportedProjects;
}
```

### Default Projects

Initialized in constructor:

```solidity
supportedProjects.push("Ethereum Foundation");
supportedProjects.push("Gitcoin");
supportedProjects.push("Protocol Guild");
supportedProjects.push("OpenZeppelin");
supportedProjects.push("EFF");
```

### Adding Projects

Owner can add new projects:

```solidity
function addSupportedProject(string memory projectName) external onlyOwner {
    supportedProjects.push(projectName);
    emit ProjectAdded(projectName);
}
```

## Octant v2 Interface

### IOctantDeposits

Simplified interface for Octant integration:

```solidity
interface IOctantDeposits {
    /**
     * @notice Lock funds for the current epoch
     * @param amount Amount to lock
     */
    function lock(uint256 amount) external;

    /**
     * @notice Get the current epoch number
     * @return Current epoch
     */
    function getCurrentEpoch() external view returns (uint256);
}
```

**Integration Pattern:**
- Accumulate donations throughout epoch
- Call `lock()` once per epoch
- Octant handles distribution to projects

## Security Features

### Reentrancy Protection

All state-changing functions protected:

```solidity
function donate(uint256 amount, address contributor)
    external
    nonReentrant
{
    // Function body
}
```

### Safe Token Transfers

Using OpenZeppelin SafeERC20:

```solidity
using SafeERC20 for IERC20;

donationToken.safeTransferFrom(msg.sender, address(this), amount);
donationToken.safeIncreaseAllowance(address(octantDeposits), amount);
```

### Access Control

Critical functions are owner-only:

```solidity
function forwardToOctant() external onlyOwner nonReentrant {
    // Only trusted party can forward
}

function addSupportedProject(string memory projectName) external onlyOwner {
    // Only owner can modify project list
}
```

### Error Handling

Try-catch on external calls:

```solidity
try octantDeposits.lock(amount) {
    currentEpochDonations = 0;
    emit EpochFinalized(currentEpoch, amount);
} catch {
    revert DonationFailed();
}
```

### Input Validation

All inputs validated:

```solidity
if (amount == 0) revert InvalidAmount();
if (_octantDeposits == address(0)) revert InvalidAddress();
```

## Gas Optimization

### Batch Donations

Accumulate donations and forward once per epoch:

```solidity
// Multiple donations throughout epoch
donate(100)
donate(200)
donate(300)

// Single forward operation
forwardToOctant() // Sends 600 total
```

This reduces:
- Gas costs by ~80%
- Octant contract interactions
- Transaction overhead

### Storage Efficiency

Efficient use of storage slots:

```solidity
uint256 public totalDonated;                    // One slot
uint256 public currentEpochDonations;           // One slot
mapping(uint256 => uint256) public donationsPerEpoch;     // Sparse
mapping(address => uint256) public businessContributions; // Sparse
```

## Impact Projections

### Scaling Scenarios

**Year 1: $1M TVL**
```
Yield (7.8%): $78,000
Public Goods (25%): $19,500
```

**Year 3: $10M TVL**
```
Yield (7.8%): $780,000
Public Goods (25%): $195,000
```

**Year 5: $50M TVL**
```
Yield (7.8%): $3,900,000
Public Goods (25%): $975,000
```

### Comparative Impact

Traditional Gitcoin Grants Round: $1M (one-time)
Aruna at $10M TVL: $195k/year (recurring)
5-year total: $975,000 sustainable funding

## Frontend Integration

### Business Dashboard Display

Show contribution on business interface:

```typescript
const contribution = await octantModule.getBusinessContribution(address);

<Card>
  <h3>Your Public Goods Impact</h3>
  <p>Total Contributed: ${formatUSDC(contribution)}</p>
  <p>Current Epoch: {currentEpoch}</p>
</Card>
```

### Public Goods Page

Dedicated transparency page:

```typescript
const totalDonated = await octantModule.totalDonated();
const projects = await octantModule.getSupportedProjects();
const epochDonations = await octantModule.getEpochDonations(epoch);

<Page>
  <TotalImpact amount={totalDonated} />
  <ProjectsList projects={projects} />
  <EpochBreakdown donations={epochDonations} />
</Page>
```

### Investor Dashboard

Show impact alongside returns:

```typescript
<Card>
  <h3>Your Impact</h3>
  <p>Your Yield (70%): ${userYield}</p>
  <p>Public Goods (25%): ${publicGoodsShare}</p>
  <p>Total Value: ${userYield + publicGoodsShare}</p>
</Card>
```

## Deployment Configuration

### Environment Variables

Required for deployment:

```bash
# Smart contract deployment
PROTOCOL_TREASURY=<treasury_address>
OWNER_ADDRESS=<owner_address>
```

### Base Sepolia Setup

The deployment script includes:

```solidity
// Mock Octant for testnet
if (config.useTestnet) {
    mockOctant = new MockOctantDeposits(config.usdc);
    config.octantDeposits = address(mockOctant);
}
```

For mainnet, use actual Octant v2 contract addresses.

## Testing

### Recommended Tests

```solidity
// Basic functionality
testDonate() - Verify donation tracking
testForwardToOctant() - Verify batch forwarding
testBusinessContribution() - Verify attribution

// Security
testUnauthorizedForward() - Should revert
testZeroDonation() - Should revert
testReentrancy() - Should be protected

// Integration
testFullFlow() - Harvest → Donate → Forward
testEpochTracking() - Verify epoch accounting
testMultipleDonations() - Test accumulation
```

## Future Enhancements

### Potential Improvements

1. **Automated Forwarding**
   - Integrate Chainlink Keepers
   - Automatic epoch finalization
   - Reduced manual intervention

2. **Governance Integration**
   - Business voting on project allocation
   - Weighted by contribution amount
   - Democratic public goods selection

3. **Impact NFTs**
   - Milestone badges for contributors
   - Visual representation of impact
   - Gamification elements

4. **Multi-Chain Support**
   - Deploy on multiple networks
   - Cross-chain Octant integration
   - Expanded reach and impact

## References

- Octant v2 Documentation: https://docs.v2.octant.build
- Octant Application: https://octant.app
- Implementation: `src/modules/OctantDonationModule.sol`
- Yield Router: `src/modules/YieldRouter.sol`
