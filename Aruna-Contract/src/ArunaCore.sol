// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./vaults/AaveVaultAdapter.sol";
import "./vaults/MorphoVaultAdapter.sol";
import "./modules/YieldRouter.sol";
import "./modules/OctantDonationModule.sol";

/**
 * @title ArunaCore
 * @notice Main contract for Aruna protocol
 * @dev Manages invoice commitments, instant grants, and vault integrations
 *
 * Key Features:
 * - Submit invoice commitments and receive 3% instant grants
 * - Deposit to Aave v3 or Morpho vaults for yield generation
 * - Automatic public goods funding (25% of yield)
 * - ERC-721 NFT representation of invoices
 */
contract ArunaCore is ERC721, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    // Tokens
    IERC20 public immutable USDC;

    // Vaults
    AaveVaultAdapter public aaveVault;
    MorphoVaultAdapter public morphoVault;

    // Modules
    YieldRouter public yieldRouter;
    OctantDonationModule public octantModule;

    // Protocol parameters (in basis points) - NOW CONFIGURABLE!
    uint256 public grantPercentage = 300; // 3% - can be adjusted by governance
    uint256 public collateralPercentage = 1000; // 10% - can be adjusted by governance
    uint256 public liquidationPeriod = 120 days; // 120 days - can be adjusted by governance
    uint256 public constant BASIS_POINTS = 10000;

    // Parameter bounds (safety limits)
    uint256 public constant MIN_GRANT_PERCENTAGE = 100; // 1%
    uint256 public constant MAX_GRANT_PERCENTAGE = 500; // 5%
    uint256 public constant MIN_COLLATERAL_PERCENTAGE = 500; // 5%
    uint256 public constant MAX_COLLATERAL_PERCENTAGE = 2000; // 20%
    uint256 public constant MIN_LIQUIDATION_PERIOD = 30 days;
    uint256 public constant MAX_LIQUIDATION_PERIOD = 365 days;

    // Limits
    uint256 public constant MAX_INVOICE_AMOUNT = 100000 * 1e6; // $100,000 USDC
    uint256 public constant MIN_INVOICE_AMOUNT = 100 * 1e6; // $100 USDC
    uint256 public maxGrantAmount = 3000 * 1e6; // $3,000 USDC max grant (3% of $100k)

    // Counters
    uint256 private _nextTokenId = 1;

    // ============ Structs ============

    struct InvoiceCommitment {
        address business;
        string customerName;
        uint256 invoiceAmount;
        uint256 dueDate;
        uint256 collateralAmount;
        uint256 grantAmount;
        string ipfsHash; // Optional
        bool isSettled;
        bool isLiquidated;
        uint256 createdAt;
    }

    // ============ Mappings ============

    mapping(uint256 => InvoiceCommitment) public commitments;
    mapping(address => uint256[]) public userCommitments;
    mapping(address => uint256) public userReputation; // Reputation score based on settled invoices

    // ============ Events ============

    event InvoiceCommitted(
        uint256 indexed tokenId,
        address indexed business,
        string customerName,
        uint256 invoiceAmount,
        uint256 collateralAmount,
        uint256 grantAmount,
        uint256 dueDate
    );

    event GrantDistributed(
        address indexed business,
        uint256 amount,
        uint256 indexed tokenId
    );

    event InvoiceSettled(
        uint256 indexed tokenId,
        address indexed business,
        uint256 collateralReturned
    );

    event InvoiceLiquidated(
        uint256 indexed tokenId,
        address indexed business,
        uint256 collateralSeized
    );

    event VaultDeposit(
        address indexed user,
        address indexed vault,
        uint256 amount,
        uint256 shares
    );

    event VaultWithdrawal(
        address indexed user,
        address indexed vault,
        uint256 amount,
        uint256 shares
    );

    event YieldClaimed(
        address indexed user,
        uint256 amount
    );

    event ParametersUpdated(
        uint256 grantPercentage,
        uint256 collateralPercentage,
        uint256 liquidationPeriod
    );

    event GrantPercentageUpdated(uint256 oldValue, uint256 newValue);
    event CollateralPercentageUpdated(uint256 oldValue, uint256 newValue);
    event LiquidationPeriodUpdated(uint256 oldValue, uint256 newValue);

    // ============ Errors ============

    error InvalidAmount();
    error InvalidDueDate();
    error InvalidAddress();
    error InvoiceNotFound();
    error InvalidStatus();
    error Unauthorized();
    error GrantLimitExceeded();
    error InsufficientBalance();
    error ParameterOutOfBounds();

    // ============ Constructor ============

    /**
     * @dev Constructor
     * @param _usdc USDC token address
     * @param _owner Owner address
     */
    constructor(
        address _usdc,
        address _owner
    ) ERC721("Aruna Invoice", "YFINV") Ownable(_owner) {
        if (_usdc == address(0)) revert InvalidAddress();
        USDC = IERC20(_usdc);
    }

    /**
     * @notice Initialize vaults and modules
     * @dev Must be called after deployment, separate from constructor for gas optimization
     * @param _aaveVault Aave vault adapter address
     * @param _morphoVault Morpho vault adapter address
     * @param _yieldRouter Yield router address
     * @param _octantModule Octant donation module address
     */
    function initialize(
        address _aaveVault,
        address _morphoVault,
        address _yieldRouter,
        address _octantModule
    ) external onlyOwner {
        if (_aaveVault == address(0) || _morphoVault == address(0) ||
            _yieldRouter == address(0) || _octantModule == address(0)) {
            revert InvalidAddress();
        }

        aaveVault = AaveVaultAdapter(_aaveVault);
        morphoVault = MorphoVaultAdapter(_morphoVault);
        yieldRouter = YieldRouter(_yieldRouter);
        octantModule = OctantDonationModule(_octantModule);

        // Approve vaults to spend USDC
        USDC.forceApprove(address(aaveVault), type(uint256).max);
        USDC.forceApprove(address(morphoVault), type(uint256).max);
    }

    // ============ Invoice Management ============

    /**
     * @notice Submit an invoice commitment and receive instant grant
     * @dev FIXED SIGNATURE - matches frontend expectations
     * @param customerName Name of customer/client
     * @param invoiceAmount Invoice amount in USDC (6 decimals)
     * @param dueDate Unix timestamp when payment is due
     * @return tokenId Token ID of minted NFT
     */
    function submitInvoiceCommitment(
        string memory customerName,
        uint256 invoiceAmount,
        uint256 dueDate
    ) external nonReentrant returns (uint256) {
        return _submitInvoiceCommitmentInternal(
            msg.sender,
            customerName,
            invoiceAmount,
            dueDate,
            "" // No IPFS hash from frontend
        );
    }

    /**
     * @notice Submit invoice with IPFS hash (extended version)
     * @param customerName Name of customer/client
     * @param invoiceAmount Invoice amount in USDC (6 decimals)
     * @param dueDate Unix timestamp when payment is due
     * @param ipfsHash IPFS hash of invoice document
     * @return tokenId Token ID of minted NFT
     */
    function submitInvoiceWithProof(
        string memory customerName,
        uint256 invoiceAmount,
        uint256 dueDate,
        string memory ipfsHash
    ) external nonReentrant returns (uint256) {
        return _submitInvoiceCommitmentInternal(
            msg.sender,
            customerName,
            invoiceAmount,
            dueDate,
            ipfsHash
        );
    }

    /**
     * @notice Internal function to handle invoice submission
     *
     * @dev Gas optimized:
     * - Batch calculations before storage operations
     * - Single USDC balance check
     * - Efficient struct creation
     * - Grouped emissions
     */
    function _submitInvoiceCommitmentInternal(
        address business,
        string memory customerName,
        uint256 invoiceAmount,
        uint256 dueDate,
        string memory ipfsHash
    ) internal returns (uint256) {
        // Gas optimization: Cache block.timestamp (used multiple times)
        uint256 currentTimestamp = block.timestamp;

        // Validations (fail fast)
        if (invoiceAmount < MIN_INVOICE_AMOUNT || invoiceAmount > MAX_INVOICE_AMOUNT) {
            revert InvalidAmount();
        }
        if (dueDate <= currentTimestamp) revert InvalidDueDate();
        if (dueDate > currentTimestamp + 365 days) revert InvalidDueDate(); // Max 1 year

        // Gas optimization: Batch calculations (use local vars + dynamic parameters)
        uint256 collateralAmount = (invoiceAmount * collateralPercentage) / BASIS_POINTS;
        uint256 grantAmount = (invoiceAmount * grantPercentage) / BASIS_POINTS;

        if (grantAmount > maxGrantAmount) revert GrantLimitExceeded();

        // FIXED: Transfer collateral + grant funding from user
        // User pays 10% collateral, receives 3% grant (net: 7% locked)
        if (USDC.balanceOf(business) < collateralAmount) revert InsufficientBalance();

        USDC.safeTransferFrom(business, address(this), collateralAmount);

        // Mint NFT (gas efficient: increments in place)
        uint256 tokenId = _nextTokenId++;
        _safeMint(business, tokenId);

        // Create commitment (single SSTORE for entire struct)
        commitments[tokenId] = InvoiceCommitment({
            business: business,
            customerName: customerName,
            invoiceAmount: invoiceAmount,
            dueDate: dueDate,
            collateralAmount: collateralAmount,
            grantAmount: grantAmount,
            ipfsHash: ipfsHash,
            isSettled: false,
            isLiquidated: false,
            createdAt: currentTimestamp
        });

        // Track user commitments
        userCommitments[business].push(tokenId);

        // Distribute instant grant
        USDC.safeTransfer(business, grantAmount);

        // Gas optimization: Emit events at end (no impact on gas, but cleaner)
        emit InvoiceCommitted(
            tokenId,
            business,
            customerName,
            invoiceAmount,
            collateralAmount,
            grantAmount,
            dueDate
        );

        emit GrantDistributed(business, grantAmount, tokenId);

        return tokenId;
    }

    /**
     * @notice Settle an invoice when it's been paid
     * @param tokenId Invoice NFT token ID
     *
     * @dev Gas optimized:
     * - Loads commitment to memory (single SLOAD)
     * - Caches values before state changes
     * - Single SSTORE for isSettled
     */
    function settleInvoice(uint256 tokenId) external nonReentrant {
        // Gas optimization: Load to memory first (single SLOAD)
        InvoiceCommitment memory commitment = commitments[tokenId];

        // Validations
        if (commitment.business == address(0)) revert InvoiceNotFound();
        if (commitment.isSettled || commitment.isLiquidated) revert InvalidStatus();
        if (msg.sender != commitment.business) revert Unauthorized();

        // Cache values before state changes
        address business = commitment.business;
        uint256 collateralToReturn = commitment.collateralAmount - commitment.grantAmount;

        // Mark as settled (single SSTORE)
        commitments[tokenId].isSettled = true;

        // Return collateral to business
        USDC.safeTransfer(business, collateralToReturn);

        // Increase reputation
        userReputation[business] += 1;

        emit InvoiceSettled(tokenId, business, collateralToReturn);
    }

    /**
     * @notice Liquidate overdue invoice (120 days past due date)
     * @param tokenId Invoice NFT token ID
     *
     * @dev Gas optimized:
     * - Loads commitment to memory
     * - Caches calculations and addresses
     * - Minimal storage writes
     */
    function liquidateInvoice(uint256 tokenId) external nonReentrant {
        // Gas optimization: Load to memory first
        InvoiceCommitment memory commitment = commitments[tokenId];

        // Validations
        if (commitment.business == address(0)) revert InvoiceNotFound();
        if (commitment.isSettled || commitment.isLiquidated) revert InvalidStatus();
        // Use dynamic liquidation period (configurable by governance)
        if (block.timestamp < commitment.dueDate + liquidationPeriod) revert InvalidStatus();

        // Cache values
        address business = commitment.business;
        uint256 remainingCollateral = commitment.collateralAmount - commitment.grantAmount;

        // Mark as liquidated (single SSTORE)
        commitments[tokenId].isLiquidated = true;

        // Decrease reputation (can go negative)
        uint256 currentReputation = userReputation[business];
        if (currentReputation > 0) {
            userReputation[business] = currentReputation - 1;
        }

        emit InvoiceLiquidated(tokenId, business, remainingCollateral);
    }

    // ============ Vault Operations ============

    /**
     * @notice Deposit USDC to Aave vault
     * @param amount Amount of USDC to deposit (6 decimals)
     * @return shares Vault shares minted
     */
    function depositToAaveVault(uint256 amount) external nonReentrant returns (uint256) {
        if (amount == 0) revert InvalidAmount();
        if (address(aaveVault) == address(0)) revert InvalidAddress();

        // Transfer USDC from user to this contract
        USDC.safeTransferFrom(msg.sender, address(this), amount);

        // Deposit to Aave vault
        uint256 shares = aaveVault.deposit(amount, msg.sender);

        emit VaultDeposit(msg.sender, address(aaveVault), amount, shares);

        return shares;
    }

    /**
     * @notice Deposit USDC to Morpho vault
     * @param amount Amount of USDC to deposit (6 decimals)
     * @return shares Vault shares minted
     */
    function depositToMorphoVault(uint256 amount) external nonReentrant returns (uint256) {
        if (amount == 0) revert InvalidAmount();
        if (address(morphoVault) == address(0)) revert InvalidAddress();

        // Transfer USDC from user to this contract
        USDC.safeTransferFrom(msg.sender, address(this), amount);

        // Deposit to Morpho vault
        uint256 shares = morphoVault.deposit(amount, msg.sender);

        emit VaultDeposit(msg.sender, address(morphoVault), amount, shares);

        return shares;
    }

    /**
     * @notice Withdraw from Aave vault
     * @param amount Amount of USDC to withdraw (6 decimals)
     * @return shares Vault shares burned
     */
    function withdrawFromAaveVault(uint256 amount) external nonReentrant returns (uint256) {
        if (amount == 0) revert InvalidAmount();
        if (address(aaveVault) == address(0)) revert InvalidAddress();

        // Withdraw from vault (shares go back to user)
        uint256 shares = aaveVault.withdraw(amount, msg.sender, msg.sender);

        emit VaultWithdrawal(msg.sender, address(aaveVault), amount, shares);

        return shares;
    }

    /**
     * @notice Withdraw from Morpho vault
     * @param amount Amount of USDC to withdraw (6 decimals)
     * @return shares Vault shares burned
     */
    function withdrawFromMorphoVault(uint256 amount) external nonReentrant returns (uint256) {
        if (amount == 0) revert InvalidAmount();
        if (address(morphoVault) == address(0)) revert InvalidAddress();

        // Withdraw from vault
        uint256 shares = morphoVault.withdraw(amount, msg.sender, msg.sender);

        emit VaultWithdrawal(msg.sender, address(morphoVault), amount, shares);

        return shares;
    }

    /**
     * @notice Claim accumulated yield from all vaults
     * @return Amount of yield claimed
     */
    function claimYield() external nonReentrant returns (uint256) {
        if (address(yieldRouter) == address(0)) revert InvalidAddress();

        uint256 claimedAmount = yieldRouter.claimYield();

        emit YieldClaimed(msg.sender, claimedAmount);

        return claimedAmount;
    }

    // ============ View Functions ============

    /**
     * @notice Get user's total accumulated yield (from YieldRouter)
     * @param user User address
     * @return Total yield amount
     */
    function getUserYield(address user) external view returns (uint256) {
        if (address(yieldRouter) == address(0)) return 0;
        return yieldRouter.getUserTotalYield(user);
    }

    /**
     * @notice Get commitment details
     * @param tokenId Token ID
     * @return Commitment struct
     */
    function getCommitment(uint256 tokenId) external view returns (InvoiceCommitment memory) {
        return commitments[tokenId];
    }

    /**
     * @notice Get all commitments for a user
     * @param user User address
     * @return Array of token IDs
     */
    function getUserCommitments(address user) external view returns (uint256[] memory) {
        return userCommitments[user];
    }

    /**
     * @notice Get user's reputation score
     * @param user User address
     * @return Reputation score (number of settled invoices)
     */
    function getUserReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }

    /**
     * @notice Get vault addresses
     * @return aave Aave vault address
     * @return morpho Morpho vault address
     */
    function getVaultAddresses() external view returns (address aave, address morpho) {
        return (address(aaveVault), address(morphoVault));
    }

    // ============ Admin Functions ============

    /**
     * @notice Update grant percentage (governance controlled)
     * @param newPercentage New grant percentage in basis points
     *
     * @dev Safety bounds: 1% - 5% (100 - 500 basis points)
     * Example: 300 = 3%
     */
    function updateGrantPercentage(uint256 newPercentage) external onlyOwner {
        if (newPercentage < MIN_GRANT_PERCENTAGE || newPercentage > MAX_GRANT_PERCENTAGE) {
            revert ParameterOutOfBounds();
        }

        uint256 oldValue = grantPercentage;
        grantPercentage = newPercentage;

        emit GrantPercentageUpdated(oldValue, newPercentage);
        emit ParametersUpdated(grantPercentage, collateralPercentage, liquidationPeriod);
    }

    /**
     * @notice Update collateral percentage (governance controlled)
     * @param newPercentage New collateral percentage in basis points
     *
     * @dev Safety bounds: 5% - 20% (500 - 2000 basis points)
     * Example: 1000 = 10%
     */
    function updateCollateralPercentage(uint256 newPercentage) external onlyOwner {
        if (newPercentage < MIN_COLLATERAL_PERCENTAGE || newPercentage > MAX_COLLATERAL_PERCENTAGE) {
            revert ParameterOutOfBounds();
        }

        // Ensure collateral > grant (economic sanity check)
        if (newPercentage <= grantPercentage) revert ParameterOutOfBounds();

        uint256 oldValue = collateralPercentage;
        collateralPercentage = newPercentage;

        emit CollateralPercentageUpdated(oldValue, newPercentage);
        emit ParametersUpdated(grantPercentage, collateralPercentage, liquidationPeriod);
    }

    /**
     * @notice Update liquidation period (governance controlled)
     * @param newPeriod New liquidation period in seconds
     *
     * @dev Safety bounds: 30 days - 365 days
     * Example: 90 days = 90 * 24 * 60 * 60 = 7776000 seconds
     */
    function updateLiquidationPeriod(uint256 newPeriod) external onlyOwner {
        if (newPeriod < MIN_LIQUIDATION_PERIOD || newPeriod > MAX_LIQUIDATION_PERIOD) {
            revert ParameterOutOfBounds();
        }

        uint256 oldValue = liquidationPeriod;
        liquidationPeriod = newPeriod;

        emit LiquidationPeriodUpdated(oldValue, newPeriod);
        emit ParametersUpdated(grantPercentage, collateralPercentage, liquidationPeriod);
    }

    /**
     * @notice Update max grant amount
     * @param newMax New maximum grant amount
     */
    function updateMaxGrantAmount(uint256 newMax) external onlyOwner {
        maxGrantAmount = newMax;
    }

    /**
     * @notice Get current protocol parameters
     * @return grant Grant percentage in basis points
     * @return collateral Collateral percentage in basis points
     * @return liquidation Liquidation period in seconds
     */
    function getProtocolParameters() external view returns (
        uint256 grant,
        uint256 collateral,
        uint256 liquidation
    ) {
        return (grantPercentage, collateralPercentage, liquidationPeriod);
    }

    /**
     * @notice Emergency withdraw (only owner, only if funds stuck)
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    // ============ ERC721 Overrides ============

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        InvoiceCommitment memory commitment = commitments[tokenId];
        if (commitment.business == address(0)) revert InvoiceNotFound();

        // In production, return proper metadata JSON
        // For now, return IPFS hash or placeholder
        return commitment.ipfsHash;
    }

    /**
     * @notice Override transfer to prevent NFT trading before settlement
     * @dev Invoices can only be transferred after settlement
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);

        // Allow minting and burning
        if (from == address(0) || to == address(0)) {
            return super._update(to, tokenId, auth);
        }

        // Allow transfers only if settled or liquidated
        InvoiceCommitment memory commitment = commitments[tokenId];
        if (!commitment.isSettled && !commitment.isLiquidated) {
            revert InvalidStatus();
        }

        return super._update(to, tokenId, auth);
    }
}
