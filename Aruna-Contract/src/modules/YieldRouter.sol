// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./OctantDonationModule.sol";

/**
 * @title YieldRouter
 * @notice Routes yield to different stakeholders: investors, public goods, and protocol
 * @dev Distribution: 70% investors, 25% public goods, 5% protocol
 */
contract YieldRouter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Distribution percentages (in basis points)
    uint256 public constant INVESTOR_PERCENTAGE = 7000; // 70%
    uint256 public constant PUBLIC_GOODS_PERCENTAGE = 2500; // 25%
    uint256 public constant PROTOCOL_FEE_PERCENTAGE = 500; // 5%
    uint256 public constant BASIS_POINTS = 10000;

    // Addresses
    OctantDonationModule public octantModule;
    address public protocolTreasury;

    // Authorized vaults (supports multiple vaults: Aave, Morpho, etc.)
    mapping(address => bool) public authorizedVaults;

    // Yield token (e.g., USDC)
    IERC20 public yieldToken;

    // Tracking
    uint256 public totalYieldDistributed;
    uint256 public totalInvestorYield;
    uint256 public totalPublicGoodsYield;
    uint256 public totalProtocolFees;

    // Time-weighted yield tracking (Synthetix StakingRewards model)
    uint256 public yieldPerShareStored; // Accumulated yield per share (scaled by 1e18)
    mapping(address => uint256) public userYieldPerSharePaid; // Last checkpoint for user
    mapping(address => uint256) public rewards; // Pending unclaimed rewards

    // Legacy tracking (kept for backwards compatibility)
    mapping(address => uint256) public userYieldBalance;
    mapping(address => uint256) public userTotalClaimed;

    // Vault share tracking (for proportional distribution)
    // Per-vault per-user shares: vaultUserShares[vault][user] = shares
    mapping(address => mapping(address => uint256)) public vaultUserShares;
    // Total shares per user (aggregated across all vaults)
    mapping(address => uint256) public vaultShares;
    uint256 public totalVaultShares;

    // Precision multiplier for yield per share calculations
    uint256 private constant PRECISION = 1e18;

    // Events
    event YieldDistributed(
        uint256 totalAmount,
        uint256 investorAmount,
        uint256 publicGoodsAmount,
        uint256 protocolFeeAmount,
        uint256 timestamp
    );

    event YieldClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event SharesUpdated(
        address indexed user,
        uint256 newShares,
        uint256 totalShares
    );

    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event VaultAuthorized(address indexed vault);
    event VaultDeauthorized(address indexed vault);

    // Errors
    error InvalidAmount();
    error InvalidAddress();
    error InsufficientYield();
    error Unauthorized();

    /**
     * @dev Constructor
     * @param _yieldToken Token used for yield (e.g., USDC)
     * @param _octantModule Address of OctantDonationModule
     * @param _protocolTreasury Address of protocol treasury
     * @param _owner Owner address
     */
    constructor(
        address _yieldToken,
        address _octantModule,
        address _protocolTreasury,
        address _owner
    ) Ownable(_owner) {
        if (_yieldToken == address(0) || _octantModule == address(0) || _protocolTreasury == address(0)) {
            revert InvalidAddress();
        }

        yieldToken = IERC20(_yieldToken);
        octantModule = OctantDonationModule(_octantModule);
        protocolTreasury = _protocolTreasury;
    }

    /**
     * @notice Add a vault to authorized list
     * @param vault Address of the vault to authorize
     * @dev Allows multiple vaults (Aave, Morpho) to call distributeYield and updateUserShares
     */
    function addVaultAuthorization(address vault) external onlyOwner {
        if (vault == address(0)) revert InvalidAddress();
        authorizedVaults[vault] = true;
        emit VaultAuthorized(vault);
    }

    /**
     * @notice Remove a vault from authorized list
     * @param vault Address of the vault to deauthorize
     */
    function removeVaultAuthorization(address vault) external onlyOwner {
        authorizedVaults[vault] = false;
        emit VaultDeauthorized(vault);
    }

    /**
     * @notice Check if a vault is authorized
     * @param vault Address to check
     * @return Whether the vault is authorized
     */
    function isVaultAuthorized(address vault) external view returns (bool) {
        return authorizedVaults[vault];
    }

    // ============ Modifiers ============

    /**
     * @notice Update rewards for a user before share changes
     * @param user User address
     * @dev This ensures time-weighted fair distribution
     */
    modifier updateReward(address user) {
        if (totalVaultShares > 0) {
            // Update global yield per share (no new yield here, just checkpoint)
            // Actual yield is added in _distributeToInvestors
        }

        if (user != address(0)) {
            // Calculate pending rewards since last checkpoint
            rewards[user] = _earned(user);
            // Update user's checkpoint
            userYieldPerSharePaid[user] = yieldPerShareStored;
        }
        _;
    }

    // ============ Share Management ============

    /**
     * @notice Update vault shares for a user (TIME-WEIGHTED, MULTI-VAULT)
     * @param user User address
     * @param shares New share amount for this specific vault
     * @dev Called by authorized vaults when user deposits/withdraws
     *
     * IMPORTANT: This now properly accounts for time-weighted yield:
     * - Updates user's pending rewards before changing shares
     * - Prevents gaming by late depositors
     * - Fair distribution based on holding time
     * - Supports multiple vaults: aggregates shares across all vaults
     */
    function updateUserShares(address user, uint256 shares) external updateReward(user) {
        if (!authorizedVaults[msg.sender] && msg.sender != owner()) revert Unauthorized();

        address vault = msg.sender;

        // Get old shares for this specific vault
        uint256 oldVaultShares = vaultUserShares[vault][user];

        // Update this vault's shares for the user
        vaultUserShares[vault][user] = shares;

        // Update user's total shares (aggregate across all vaults)
        uint256 oldTotalUserShares = vaultShares[user];
        uint256 newTotalUserShares = oldTotalUserShares - oldVaultShares + shares;
        vaultShares[user] = newTotalUserShares;

        // Update global total shares
        totalVaultShares = totalVaultShares - oldTotalUserShares + newTotalUserShares;

        emit SharesUpdated(user, newTotalUserShares, totalVaultShares);
    }

    /**
     * @notice Distribute yield to all stakeholders
     * @param totalYield Total yield amount to distribute
     * @param contributor Address that contributed (for public goods tracking)
     * @dev Called by authorized vaults after harvesting yield
     */
    function distributeYield(uint256 totalYield, address contributor) external nonReentrant {
        if (!authorizedVaults[msg.sender] && msg.sender != owner()) revert Unauthorized();
        if (totalYield == 0) revert InvalidAmount();

        // Calculate distributions
        uint256 investorAmount = (totalYield * INVESTOR_PERCENTAGE) / BASIS_POINTS;
        uint256 publicGoodsAmount = (totalYield * PUBLIC_GOODS_PERCENTAGE) / BASIS_POINTS;
        uint256 protocolFeeAmount = (totalYield * PROTOCOL_FEE_PERCENTAGE) / BASIS_POINTS;

        // Transfer yield from vault to this router
        yieldToken.safeTransferFrom(msg.sender, address(this), totalYield);

        // 1. Distribute to investors (accumulate for claiming)
        totalInvestorYield += investorAmount;
        _distributeToInvestors(investorAmount);

        // 2. Send to public goods
        yieldToken.safeIncreaseAllowance(address(octantModule), publicGoodsAmount);
        octantModule.donate(publicGoodsAmount, contributor);
        totalPublicGoodsYield += publicGoodsAmount;

        // 3. Send protocol fees to treasury
        yieldToken.safeTransfer(protocolTreasury, protocolFeeAmount);
        totalProtocolFees += protocolFeeAmount;

        // Update total
        totalYieldDistributed += totalYield;

        emit YieldDistributed(
            totalYield,
            investorAmount,
            publicGoodsAmount,
            protocolFeeAmount,
            block.timestamp
        );
    }

    /**
     * @notice Distribute yield to investors proportionally based on their vault shares
     * @param amount Total amount to distribute to investors
     *
     * @dev TIME-WEIGHTED YIELD DISTRIBUTION MODEL (Synthetix StakingRewards):
     * - Calculates yieldPerShare = amount / totalShares
     * - Accumulates in yieldPerShareStored
     * - Each user's pending reward = shares * (yieldPerShareStored - userYieldPerSharePaid)
     * - Fair distribution: early depositors earn more than late depositors
     *
     * Gas Efficiency:
     * - O(1) operation, no loops
     * - Only updates global state, not individual users
     * - Users claim when convenient
     *
     * Example Timeline:
     * T0: User A deposits 100 shares (total: 100)
     * T1: Harvest 10 USDC → yieldPerShareStored += 10/100 * 1e18 = 0.1e18
     * T2: User B deposits 100 shares (total: 200)
     *     User A can claim: 100 * 0.1e18 / 1e18 = 10 USDC ✓
     * T3: Harvest 20 USDC → yieldPerShareStored += 20/200 * 1e18 = 0.2e18 (total: 0.3e18)
     *     User A can claim: 100 * (0.3e18 - 0.1e18) / 1e18 = 10 USDC (fair!)
     *     User B can claim: 100 * (0.3e18 - 0.2e18) / 1e18 = 10 USDC (fair!)
     */
    function _distributeToInvestors(uint256 amount) internal {
        if (totalVaultShares == 0) {
            // No shares yet, nothing to distribute
            return;
        }

        // Calculate yield per share and add to accumulated
        // Scale by PRECISION (1e18) to maintain precision
        uint256 yieldPerShare = (amount * PRECISION) / totalVaultShares;
        yieldPerShareStored += yieldPerShare;

        // No per-user updates needed - saves massive gas!
        // Users' rewards calculated on-demand in _earned()
    }

    /**
     * @notice Claim accumulated yield for msg.sender (TIME-WEIGHTED)
     * @return Amount of yield claimed
     *
     * @dev Gas optimized:
     * - Updates rewards once via modifier
     * - Single storage read of rewards[msg.sender]
     * - Single storage write to zero rewards
     */
    function claimYield() external nonReentrant updateReward(msg.sender) returns (uint256) {
        uint256 reward = rewards[msg.sender];

        // Return 0 if no yield to claim (instead of reverting)
        if (reward == 0) return 0;

        // Zero out rewards (reentrancy protection + accurate accounting)
        rewards[msg.sender] = 0;

        // Update claimed tracking (for backwards compatibility)
        userTotalClaimed[msg.sender] += reward;

        // Transfer yield to user
        yieldToken.safeTransfer(msg.sender, reward);

        emit YieldClaimed(msg.sender, reward, block.timestamp);

        return reward;
    }

    /**
     * @notice Calculate earned rewards for a user (internal helper)
     * @param user User address
     * @return Total earned amount (claimed + claimable)
     *
     * @dev Formula:
     * earned = stored_rewards + (shares * (yieldPerShareStored - userYieldPerSharePaid)) / PRECISION
     */
    function _earned(address user) internal view returns (uint256) {
        uint256 userShares = vaultShares[user];

        if (userShares == 0) {
            return rewards[user]; // Return stored rewards only
        }

        // Calculate new rewards since last checkpoint
        uint256 yieldPerShareDelta = yieldPerShareStored - userYieldPerSharePaid[user];
        uint256 newRewards = (userShares * yieldPerShareDelta) / PRECISION;

        // Add to previously stored rewards
        return rewards[user] + newRewards;
    }

    /**
     * @notice Get claimable yield for a user (TIME-WEIGHTED)
     * @param user User address
     * @return Amount of yield user can claim
     *
     * @dev This is now time-weighted - users earn proportional to:
     * - Their share balance
     * - How long they've held those shares
     */
    function getClaimableYield(address user) external view returns (uint256) {
        return _earned(user);
    }

    /**
     * @notice Get user's total yield (TIME-WEIGHTED: claimable only)
     * @param user User address
     * @return Total yield amount
     *
     * @dev Returns earned (claimable) rewards based on time-weighted model
     */
    function getUserTotalYield(address user) external view returns (uint256) {
        return _earned(user);
    }

    /**
     * @notice Update protocol treasury address
     * @param newTreasury New treasury address
     */
    function updateTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) revert InvalidAddress();
        address oldTreasury = protocolTreasury;
        protocolTreasury = newTreasury;
        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    /**
     * @notice Get distribution breakdown for an amount
     * @param amount Total yield amount
     * @return investorAmount Amount for investors
     * @return publicGoodsAmount Amount for public goods
     * @return protocolFeeAmount Amount for protocol
     */
    function getDistributionBreakdown(uint256 amount) external pure returns (
        uint256 investorAmount,
        uint256 publicGoodsAmount,
        uint256 protocolFeeAmount
    ) {
        investorAmount = (amount * INVESTOR_PERCENTAGE) / BASIS_POINTS;
        publicGoodsAmount = (amount * PUBLIC_GOODS_PERCENTAGE) / BASIS_POINTS;
        protocolFeeAmount = (amount * PROTOCOL_FEE_PERCENTAGE) / BASIS_POINTS;
    }
}
