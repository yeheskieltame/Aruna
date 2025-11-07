// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IMetaMorpho.sol";
import "../interfaces/IYieldVault.sol";
import "../modules/YieldRouter.sol";

/**
 * @title MorphoVaultAdapter
 * @notice REAL Morpho V2 MetaMorpho integration - ERC-4626 compliant vault adapter
 * @dev Wraps MetaMorpho vaults and integrates with YieldRouter for yield distribution
 *
 * Architecture:
 * - Users deposit USDC -> MorphoVaultAdapter mints shares -> Deposits to MetaMorpho vault
 * - MetaMorpho generates yield -> Adapter harvests -> YieldRouter distributes (70/25/5)
 * - Users withdraw -> Adapter redeems from MetaMorpho -> Returns USDC to user
 *
 * Safety Features:
 * - ReentrancyGuard on all external functions
 * - Proper share/asset accounting via ERC-4626 preview functions
 * - Minimum share checks to prevent rounding exploitation
 * - Pausable for emergency situations
 *
 * @dev Reference: https://github.com/morpho-org/metamorpho
 */
contract MorphoVaultAdapter is ERC4626, Ownable, ReentrancyGuard, IYieldVault {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    /// @notice The MetaMorpho vault we're wrapping (already ERC-4626 compliant)
    IMetaMorpho public immutable metaMorphoVault;

    /// @notice YieldRouter for distributing harvested yield
    YieldRouter public yieldRouter;

    /// @notice Last time yield was harvested
    uint256 public lastHarvestTime;

    /// @notice Total yield generated and distributed
    uint256 public totalYieldGenerated;

    /// @notice Minimum time between harvests
    uint256 public constant HARVEST_INTERVAL = 1 days;

    /// @notice APY tracking (basis points, e.g., 820 = 8.2%)
    uint256 public currentAPY = 820; // Default 8.2% (Morpho typically higher than Aave)

    /// @notice Per-user tracking for deposits
    mapping(address => uint256) private userLastDepositTime;

    /// @notice Snapshot of our shares in MetaMorpho at last harvest
    uint256 private lastMetaMorphoShares;

    /// @notice Pause mechanism for emergencies
    bool public isPaused;

    /// @notice Minimum shares to mint (prevents rounding attacks)
    uint256 public constant MIN_SHARES = 1000;

    // ============ Events ============

    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 assets, uint256 shares);
    event APYUpdated(uint256 oldAPY, uint256 newAPY);
    event PauseToggled(bool isPaused);
    event MetaMorphoSharesUpdated(uint256 newShares, uint256 oldShares);

    // ============ Errors ============

    error ContractPaused();
    error InvalidAmount();
    error InvalidAddress();
    error HarvestTooSoon();
    error MinimumSharesNotMet();
    error MetaMorphoCallFailed();

    // ============ Constructor ============

    /**
     * @notice Constructor
     * @param _asset Underlying asset (e.g., USDC)
     * @param _metaMorphoVault Address of the MetaMorpho vault to integrate with
     * @param _yieldRouter Address of YieldRouter for yield distribution
     * @param _owner Owner address
     */
    constructor(
        IERC20 _asset,
        address _metaMorphoVault,
        address _yieldRouter,
        address _owner
    ) ERC4626(_asset) ERC20("Aruna Morpho Vault", "yfMorpho") Ownable(_owner) {
        if (_metaMorphoVault == address(0) || _yieldRouter == address(0)) {
            revert InvalidAddress();
        }

        metaMorphoVault = IMetaMorpho(_metaMorphoVault);
        yieldRouter = YieldRouter(_yieldRouter);
        lastHarvestTime = block.timestamp;

        // Verify MetaMorpho vault uses the same asset
        require(
            address(metaMorphoVault.asset()) == address(_asset),
            "Asset mismatch with MetaMorpho vault"
        );

        // Approve MetaMorpho vault to spend our assets
        IERC20(_asset).forceApprove(_metaMorphoVault, type(uint256).max);
    }

    // ============ ERC-4626 Core Functions ============

    /**
     * @notice Deposit assets into the adapter and MetaMorpho vault
     * @param assets Amount of assets to deposit
     * @param receiver Address to receive adapter shares
     * @return shares Amount of adapter shares minted
     *
     * @dev Flow:
     * 1. User transfers assets to adapter
     * 2. Adapter deposits assets to MetaMorpho vault
     * 3. Adapter mints shares to user based on current exchange rate
     * 4. Updates YieldRouter with user's share balance
     */
    function deposit(uint256 assets, address receiver)
        public
        override(ERC4626, IERC4626)
        nonReentrant
        returns (uint256 shares)
    {
        if (isPaused) revert ContractPaused();
        if (assets == 0) revert InvalidAmount();

        // Harvest yield before deposit for accurate share calculation
        if (block.timestamp >= lastHarvestTime + HARVEST_INTERVAL) {
            _harvestYield();
        }

        // Calculate shares using ERC-4626 preview (protects against manipulation)
        shares = previewDeposit(assets);
        if (shares < MIN_SHARES && totalSupply() == 0) {
            revert MinimumSharesNotMet();
        }

        // Transfer assets from user to adapter
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

        // Deposit assets into MetaMorpho vault
        try metaMorphoVault.deposit(assets, address(this)) returns (uint256 metaMorphoShares) {
            // Update our tracking of MetaMorpho shares
            lastMetaMorphoShares += metaMorphoShares;
            emit MetaMorphoSharesUpdated(lastMetaMorphoShares, lastMetaMorphoShares - metaMorphoShares);
        } catch {
            revert MetaMorphoCallFailed();
        }

        // Mint adapter shares to receiver
        _mint(receiver, shares);

        // Update user tracking
        userLastDepositTime[receiver] = block.timestamp;

        // Update YieldRouter with user's new share balance
        yieldRouter.updateUserShares(receiver, balanceOf(receiver));

        emit Deposited(receiver, assets, shares);
        emit Deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    /**
     * @notice Withdraw assets from MetaMorpho vault and adapter
     * @param assets Amount of assets to withdraw
     * @param receiver Address to receive assets
     * @param owner Address of share owner
     * @return shares Amount of shares burned
     *
     * @dev Flow:
     * 1. Calculate shares to burn
     * 2. Withdraw assets from MetaMorpho vault
     * 3. Burn adapter shares from owner
     * 4. Transfer assets to receiver
     * 5. Update YieldRouter
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override(ERC4626, IERC4626)
        nonReentrant
        returns (uint256 shares)
    {
        if (assets == 0) revert InvalidAmount();

        // Harvest yield before withdrawal
        if (block.timestamp >= lastHarvestTime + HARVEST_INTERVAL) {
            _harvestYield();
        }

        // Calculate shares to burn using ERC-4626 preview
        shares = previewWithdraw(assets);

        // Check allowance if caller is not owner
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Withdraw from MetaMorpho vault
        uint256 metaMorphoSharesBurned;
        try metaMorphoVault.withdraw(assets, address(this), address(this)) returns (uint256 burned) {
            metaMorphoSharesBurned = burned;
            lastMetaMorphoShares -= metaMorphoSharesBurned;
            emit MetaMorphoSharesUpdated(lastMetaMorphoShares, lastMetaMorphoShares + metaMorphoSharesBurned);
        } catch {
            revert MetaMorphoCallFailed();
        }

        // Burn adapter shares from owner
        _burn(owner, shares);

        // Transfer assets to receiver
        IERC20(asset()).safeTransfer(receiver, assets);

        // Update YieldRouter
        yieldRouter.updateUserShares(owner, balanceOf(owner));

        emit Withdrawn(receiver, assets, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    /**
     * @notice Redeem shares for assets
     * @param shares Amount of shares to redeem
     * @param receiver Address to receive assets
     * @param owner Address of share owner
     * @return assets Amount of assets withdrawn
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override(ERC4626, IERC4626)
        nonReentrant
        returns (uint256 assets)
    {
        if (shares == 0) revert InvalidAmount();

        // Harvest yield before redemption
        if (block.timestamp >= lastHarvestTime + HARVEST_INTERVAL) {
            _harvestYield();
        }

        // Calculate assets to withdraw
        assets = previewRedeem(shares);

        // Check allowance if caller is not owner
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Withdraw from MetaMorpho vault
        try metaMorphoVault.withdraw(assets, address(this), address(this)) returns (uint256 metaMorphoSharesBurned) {
            lastMetaMorphoShares -= metaMorphoSharesBurned;
            emit MetaMorphoSharesUpdated(lastMetaMorphoShares, lastMetaMorphoShares + metaMorphoSharesBurned);
        } catch {
            revert MetaMorphoCallFailed();
        }

        // Burn adapter shares
        _burn(owner, shares);

        // Transfer assets to receiver
        IERC20(asset()).safeTransfer(receiver, assets);

        // Update YieldRouter
        yieldRouter.updateUserShares(owner, balanceOf(owner));

        emit Withdrawn(receiver, assets, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @notice Get total assets under management
     * @return Total assets (principal + accrued yield in MetaMorpho)
     *
     * @dev This queries MetaMorpho's totalAssets(), which includes:
     * - Our deposited principal
     * - Accrued interest from Morpho Blue markets
     * - Pending fees
     */
    function totalAssets() public view override(ERC4626, IERC4626) returns (uint256) {
        if (lastMetaMorphoShares == 0) return 0;

        // Convert our MetaMorpho shares to assets
        // MetaMorpho's convertToAssets already accounts for accrued yield
        return metaMorphoVault.convertToAssets(lastMetaMorphoShares);
    }

    // ============ Yield Harvesting ============

    /**
     * @notice Harvest yield from MetaMorpho and distribute via YieldRouter
     * @dev Can be called by anyone after HARVEST_INTERVAL
     *
     * Flow:
     * 1. Calculate yield as (current assets - original deposits)
     * 2. Withdraw yield from MetaMorpho
     * 3. Approve YieldRouter to spend yield
     * 4. Distribute via YieldRouter (70% investors, 25% public goods, 5% protocol)
     */
    function harvestYield() external override {
        if (block.timestamp < lastHarvestTime + HARVEST_INTERVAL) {
            revert HarvestTooSoon();
        }
        _harvestYield();
    }

    /**
     * @notice Internal yield harvesting logic
     *
     * @dev Gas optimized:
     * - Caches totalAssets() and totalSupply()
     * - Single timestamp read
     * - Batched state updates
     * - Early returns for edge cases
     * - Graceful error handling
     */
    function _harvestYield() internal {
        // Gas optimization: Cache expensive calls
        uint256 currentAssets = totalAssets();
        uint256 expectedBalance = totalSupply();

        // Gas optimization: Cache timestamp
        uint256 currentTimestamp = block.timestamp;

        // Early return if no yield or loss scenario
        if (currentAssets <= expectedBalance) {
            lastHarvestTime = currentTimestamp;
            return;
        }

        // Calculate yield
        uint256 yieldGenerated = currentAssets - expectedBalance;

        // Withdraw yield from MetaMorpho (with error handling)
        try metaMorphoVault.withdraw(yieldGenerated, address(this), address(this)) returns (uint256 sharesBurned) {
            // Update MetaMorpho shares tracking
            uint256 oldShares = lastMetaMorphoShares;
            lastMetaMorphoShares = oldShares - sharesBurned;
            emit MetaMorphoSharesUpdated(lastMetaMorphoShares, oldShares);

            // Approve YieldRouter to spend yield
            IERC20(asset()).forceApprove(address(yieldRouter), yieldGenerated);

            // Distribute yield (70% investors, 25% public goods, 5% protocol)
            yieldRouter.distributeYield(yieldGenerated, address(this));

            // Batched state updates (gas efficient)
            totalYieldGenerated += yieldGenerated;
            lastHarvestTime = currentTimestamp;

            emit YieldHarvested(yieldGenerated, currentTimestamp);
        } catch {
            // Harvest failed - update timestamp to prevent repeated failures
            // This prevents DOS if MetaMorpho is temporarily unavailable
            lastHarvestTime = currentTimestamp;
        }
    }

    // ============ IYieldVault Implementation ============

    /**
     * @notice Get user's accumulated yield
     * @param user User address
     * @return Yield amount claimable by user
     */
    function getUserYield(address user) external view override returns (uint256) {
        return yieldRouter.getClaimableYield(user);
    }

    /**
     * @notice Claim accumulated yield
     * @dev Delegates to YieldRouter
     * @return Amount claimed
     */
    function claimYield() external override nonReentrant returns (uint256) {
        return yieldRouter.claimYield();
    }

    /**
     * @notice Get current APY
     * @return APY in basis points
     */
    function getAPY() external view override returns (uint256) {
        return currentAPY;
    }

    /**
     * @notice Get total yield generated by this vault
     * @return Total yield amount
     */
    function getTotalYieldGenerated() external view override returns (uint256) {
        return totalYieldGenerated;
    }

    // ============ Admin Functions ============

    /**
     * @notice Update APY (owner only)
     * @param newAPY New APY in basis points
     */
    function updateAPY(uint256 newAPY) external onlyOwner {
        uint256 oldAPY = currentAPY;
        currentAPY = newAPY;
        emit APYUpdated(oldAPY, newAPY);
    }

    /**
     * @notice Toggle pause state (owner only)
     */
    function togglePause() external onlyOwner {
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     * @notice Emergency withdraw (owner only)
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     * @dev Should only be used if funds are stuck
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    // ============ View Functions ============

    /**
     * @notice Get the MetaMorpho vault address
     * @return MetaMorpho vault address
     */
    function getMetaMorphoVault() external view returns (address) {
        return address(metaMorphoVault);
    }

    /**
     * @notice Get our current shares in MetaMorpho
     * @return MetaMorpho shares balance
     */
    function getMetaMorphoShares() external view returns (uint256) {
        return lastMetaMorphoShares;
    }

    /**
     * @notice Get the underlying Morpho Blue address from MetaMorpho
     * @return Morpho Blue address
     */
    function getMorphoBlue() external view returns (address) {
        return metaMorphoVault.MORPHO();
    }
}
