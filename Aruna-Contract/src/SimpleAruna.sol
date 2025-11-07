// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SimpleAruna
 * @dev Simplified version of Aruna for demonstration
 * @notice Basic invoice commitment NFT system with instant grants
 */
contract SimpleAruna is ERC721, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    IERC20 public immutable USDC;
    uint256 public constant GRANT_PERCENTAGE = 300; // 3% in basis points
    uint256 public constant COLLATERAL_PERCENTAGE = 1000; // 10% in basis points
    uint256 public constant MAX_GRANT_AMOUNT = 10000 * 1e6; // $10,000 USDC max grant

    // Counters
    uint256 private _nextTokenId;

    // Invoice commitment structure
    struct InvoiceCommitment {
        address business;
        string customerName;
        uint256 invoiceAmount;
        uint256 dueDate;
        uint256 collateralAmount;
        uint256 grantAmount;
        string ipfsHash;
        bool isSettled;
        uint256 createdAt;
    }

    // Mappings
    mapping(uint256 => InvoiceCommitment) public commitments;
    mapping(address => uint256[]) public userCommitments;

    // Vault tracking
    mapping(address => uint256) public aaveDeposits;
    mapping(address => uint256) public morphoDeposits;
    mapping(address => uint256) public userYield;

    // Events
    event InvoiceCommitted(
        uint256 indexed tokenId,
        address indexed business,
        uint256 invoiceAmount,
        uint256 collateralAmount,
        uint256 grantAmount
    );

    event GrantDistributed(
        address indexed business,
        uint256 amount,
        uint256 indexed tokenId
    );

    event InvoiceSettled(
        uint256 indexed tokenId,
        address indexed business
    );

    event VaultDeposit(
        address indexed user,
        string vaultType,
        uint256 amount
    );

    event YieldDistributed(
        address indexed user,
        uint256 amount
    );

    // Errors
    error InvalidAmount();
    error InvalidDueDate();
    error InsufficientCollateral();
    error InvoiceNotFound();
    error InvalidStatus();
    error GrantExceedsMaximum();

    constructor(address _usdc, address _owner) ERC721("Aruna Invoice", "YFINV") Ownable(_owner) {
        USDC = IERC20(_usdc);
        _nextTokenId = 1;
    }

    /**
     * @dev Creates a new invoice commitment and distributes instant grant
     * @param business Business wallet address
     * @param customerName Customer name
     * @param invoiceAmount Invoice amount in USD (6 decimals for USDC)
     * @param dueDate Unix timestamp for payment due date
     * @param ipfsHash IPFS hash of invoice PDF
     */
    function submitInvoiceCommitment(
        address business,
        string memory customerName,
        uint256 invoiceAmount,
        uint256 dueDate,
        string memory ipfsHash
    ) external nonReentrant returns (uint256) {
        // Validations
        if (invoiceAmount == 0) revert InvalidAmount();
        if (dueDate <= block.timestamp) revert InvalidDueDate();
        if (invoiceAmount > MAX_GRANT_AMOUNT * 10000 / GRANT_PERCENTAGE) revert GrantExceedsMaximum();

        // Calculate amounts
        uint256 collateralAmount = (invoiceAmount * COLLATERAL_PERCENTAGE) / 10000;
        uint256 grantAmount = (invoiceAmount * GRANT_PERCENTAGE) / 10000;

        // Create commitment
        uint256 tokenId = _nextTokenId++;

        commitments[tokenId] = InvoiceCommitment({
            business: business,
            customerName: customerName,
            invoiceAmount: invoiceAmount,
            dueDate: dueDate,
            collateralAmount: collateralAmount,
            grantAmount: grantAmount,
            ipfsHash: ipfsHash,
            isSettled: false,
            createdAt: block.timestamp
        });

        // Track user commitments
        userCommitments[business].push(tokenId);

        // Mint NFT to business
        _safeMint(business, tokenId);

        // Distribute instant grant
        _distributeGrant(business, grantAmount, tokenId);

        emit InvoiceCommitted(tokenId, business, invoiceAmount, collateralAmount, grantAmount);

        return tokenId;
    }

    /**
     * @dev Deposits collateral for invoice commitment
     * @param tokenId Invoice commitment token ID
     */
    function depositCollateral(uint256 tokenId) external nonReentrant {
        InvoiceCommitment storage commitment = commitments[tokenId];
        if (commitment.business == address(0)) revert InvoiceNotFound();
        if (commitment.isSettled) revert InvalidStatus();

        // Transfer collateral from business to this contract
        USDC.safeTransferFrom(msg.sender, address(this), commitment.collateralAmount);
    }

    /**
     * @dev Settles an invoice when it's been paid
     * @param tokenId Invoice commitment token ID
     */
    function settleInvoice(uint256 tokenId) external nonReentrant {
        InvoiceCommitment storage commitment = commitments[tokenId];
        if (commitment.business == address(0)) revert InvoiceNotFound();
        if (commitment.isSettled) revert InvalidStatus();
        if (msg.sender != commitment.business) revert InvalidStatus();

        // Update status
        commitment.isSettled = true;

        // Return collateral
        USDC.safeTransfer(commitment.business, commitment.collateralAmount);

        emit InvoiceSettled(tokenId, commitment.business);
    }

    /**
     * @dev Internal function to distribute instant grant
     */
    function _distributeGrant(address business, uint256 amount, uint256 tokenId) internal {
        // This would integrate with grant system
        // For now, assume grants are funded from protocol reserves
        require(USDC.balanceOf(address(this)) >= amount, "Insufficient grant reserves");

        USDC.safeTransfer(business, amount);

        emit GrantDistributed(business, amount, tokenId);
    }

    /**
     * @dev Get commitment details for a token ID
     */
    function getCommitment(uint256 tokenId) external view returns (InvoiceCommitment memory) {
        return commitments[tokenId];
    }

    /**
     * @dev Get all commitments for a user
     */
    function getUserCommitments(address user) external view returns (uint256[] memory) {
        return userCommitments[user];
    }

    /**
     * @dev Fund contract with USDC for grants
     */
    function fundGrants(uint256 amount) external {
        USDC.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Deposit to Aave vault
     * @param amount Amount to deposit in USDC (6 decimals)
     */
    function depositToAaveVault(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();

        // Update user's Aave deposit
        aaveDeposits[msg.sender] += amount;

        // Update user's yield (simplified calculation - in real implementation this would come from Aave)
        uint256 yieldAmount = (amount * 65) / 1000; // 6.5% annual yield, simplified
        userYield[msg.sender] += yieldAmount;

        emit VaultDeposit(msg.sender, "aave", amount);
        emit YieldDistributed(msg.sender, yieldAmount);
    }

    /**
     * @dev Deposit to Morpho vault
     * @param amount Amount to deposit in USDC (6 decimals)
     */
    function depositToMorphoVault(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();

        // Update user's Morpho deposit
        morphoDeposits[msg.sender] += amount;

        // Update user's yield (simplified calculation - in real implementation this would come from Morpho)
        uint256 yieldAmount = (amount * 82) / 1000; // 8.2% annual yield, simplified
        userYield[msg.sender] += yieldAmount;

        emit VaultDeposit(msg.sender, "morpho", amount);
        emit YieldDistributed(msg.sender, yieldAmount);
    }

    /**
     * @dev Get user's accumulated yield
     * @param user User address
     * @return Total yield amount in USDC (6 decimals)
     */
    function getUserYield(address user) external view returns (uint256) {
        return userYield[user];
    }

    /**
     * @dev Emergency withdrawal
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    // ERC721 overrides
    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }
}