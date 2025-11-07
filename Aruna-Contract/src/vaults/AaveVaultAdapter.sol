// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@aave/interfaces/IPool.sol";
import "../interfaces/IYieldVault.sol";
import "../modules/YieldRouter.sol";

/**
 * @title AaveVaultAdapter
 * @notice ERC-4626 compliant vault that deposits assets into Aave v3
 * @dev Implements yield tracking and distribution via YieldRouter
 */
contract AaveVaultAdapter is ERC4626, Ownable, ReentrancyGuard, IYieldVault {
    using SafeERC20 for IERC20;

    // Aave v3 contracts
    IPool public immutable aavePool;
    IERC20 public immutable aToken; // Aave aToken (ERC20 compatible)

    // Yield management
    YieldRouter public yieldRouter;
    uint256 public lastHarvestTime;
    uint256 public totalYieldGenerated;
    uint256 public constant HARVEST_INTERVAL = 1 days;

    // APY tracking (in basis points, e.g., 650 = 6.5%)
    uint256 public currentAPY = 650; // Default 6.5%

    // Per-user yield tracking
    mapping(address => uint256) private userYieldBalance;
    mapping(address => uint256) private userLastDepositTime;

    // Pause mechanism
    bool public isPaused;

    // Events (additional to IYieldVault)
    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 assets, uint256 shares);
    event APYUpdated(uint256 oldAPY, uint256 newAPY);
    event PauseToggled(bool isPaused);

    // Errors
    error ContractPaused();
    error InvalidAmount();
    error InvalidAddress();
    error HarvestTooSoon();

    /**
     * @dev Constructor
     * @param _asset Underlying asset (e.g., USDC)
     * @param _aavePool Aave v3 Pool address
     * @param _aToken Aave aToken address for the asset
     * @param _yieldRouter YieldRouter address
     * @param _owner Owner address
     */
    constructor(
        IERC20 _asset,
        address _aavePool,
        address _aToken,
        address _yieldRouter,
        address _owner
    ) ERC4626(_asset) ERC20("Aruna Aave Vault", "yfAave") Ownable(_owner) {
        if (_aavePool == address(0) || _aToken == address(0) || _yieldRouter == address(0)) {
            revert InvalidAddress();
        }

        aavePool = IPool(_aavePool);
        aToken = IERC20(_aToken);
        yieldRouter = YieldRouter(_yieldRouter);
        lastHarvestTime = block.timestamp;

        // Approve Aave Pool to spend assets
        IERC20(_asset).forceApprove(_aavePool, type(uint256).max);
    }

    /**
     * @notice Deposit assets into the vault and Aave
     * @param assets Amount of assets to deposit
     * @param receiver Address to receive vault shares
     * @return shares Amount of shares minted
     */
    function deposit(uint256 assets, address receiver)
        public
        override(ERC4626, IERC4626)
        nonReentrant
        returns (uint256 shares)
    {
        if (isPaused) revert ContractPaused();
        if (assets == 0) revert InvalidAmount();

        // Harvest yield before deposit to ensure fair share calculation
        if (block.timestamp >= lastHarvestTime + HARVEST_INTERVAL) {
            _harvestYield();
        }

        shares = super.deposit(assets, receiver);

        // Supply assets to Aave
        aavePool.supply(address(asset()), assets, address(this), 0);

        // Update user tracking
        userLastDepositTime[receiver] = block.timestamp;

        // Update YieldRouter shares
        yieldRouter.updateUserShares(receiver, balanceOf(receiver));

        emit Deposited(receiver, assets, shares);

        return shares;
    }

    /**
     * @notice Withdraw assets from Aave and the vault
     * @param assets Amount of assets to withdraw
     * @param receiver Address to receive assets
     * @param owner Address of share owner
     * @return shares Amount of shares burned
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

        // Calculate shares to burn
        shares = previewWithdraw(assets);

        // Withdraw from Aave
        uint256 withdrawn = aavePool.withdraw(address(asset()), assets, address(this));

        // Burn shares and transfer assets
        _withdraw(_msgSender(), receiver, owner, withdrawn, shares);

        // Update YieldRouter shares
        yieldRouter.updateUserShares(owner, balanceOf(owner));

        emit Withdrawn(receiver, withdrawn, shares);

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

        // Withdraw from Aave
        uint256 withdrawn = aavePool.withdraw(address(asset()), assets, address(this));

        // Burn shares and transfer assets
        _withdraw(_msgSender(), receiver, owner, withdrawn, shares);

        // Update YieldRouter shares
        yieldRouter.updateUserShares(owner, balanceOf(owner));

        emit Withdrawn(receiver, withdrawn, shares);

        return withdrawn;
    }

    /**
     * @notice Get total assets including Aave deposits and accrued yield
     * @return Total assets under management
     */
    function totalAssets() public view override(ERC4626, IERC4626) returns (uint256) {
        // Return aToken balance (principal + accrued interest)
        return aToken.balanceOf(address(this));
    }

    /**
     * @notice Harvest yield from Aave and distribute via YieldRouter
     * @dev Can be called by anyone after HARVEST_INTERVAL
     */
    function harvestYield() external override {
        if (block.timestamp < lastHarvestTime + HARVEST_INTERVAL) {
            revert HarvestTooSoon();
        }
        _harvestYield();
    }

    /**
     * @notice Internal harvest function
     *
     * @dev Gas optimized:
     * - Caches totalAssets() and totalSupply() calls
     * - Early return for zero yield scenarios
     * - Single timestamp read
     * - Batched state updates
     */
    function _harvestYield() internal {
        // Gas optimization: Cache expensive external/state reads
        uint256 currentBalance = totalAssets();
        uint256 expectedBalance = totalSupply(); // shares represent 1:1 with original deposits

        // Early return if no yield (saves gas on zero-yield harvests)
        if (currentBalance <= expectedBalance) {
            lastHarvestTime = block.timestamp;
            return;
        }

        // Calculate yield
        uint256 yieldGenerated = currentBalance - expectedBalance;

        // Gas optimization: Cache timestamp
        uint256 currentTimestamp = block.timestamp;

        // Withdraw yield from Aave
        aavePool.withdraw(address(asset()), yieldGenerated, address(this));

        // Approve YieldRouter to spend yield
        IERC20(asset()).forceApprove(address(yieldRouter), yieldGenerated);

        // Distribute yield via router (70% investors, 25% public goods, 5% protocol)
        yieldRouter.distributeYield(yieldGenerated, address(this));

        // Update tracking (batched for gas efficiency)
        totalYieldGenerated += yieldGenerated;
        lastHarvestTime = currentTimestamp;

        emit YieldHarvested(yieldGenerated, currentTimestamp);
    }

    /**
     * @notice Get user's accumulated yield
     * @param user User address
     * @return Yield amount
     */
    function getUserYield(address user) external view override returns (uint256) {
        // Get user's claimable yield from YieldRouter
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
     * @notice Get total yield generated by vault
     * @return Total yield amount
     */
    function getTotalYieldGenerated() external view override returns (uint256) {
        return totalYieldGenerated;
    }

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
     * @notice Toggle pause state
     */
    function togglePause() external onlyOwner {
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     * @notice Emergency withdraw (owner only)
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }
}
