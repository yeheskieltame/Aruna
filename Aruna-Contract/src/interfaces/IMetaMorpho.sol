// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title IMetaMorpho
 * @notice Interface for Morpho MetaMorpho vaults (ERC-4626 compliant)
 * @dev MetaMorpho vaults are noncustodial risk management vaults built on Morpho Blue
 * @dev Reference: https://github.com/morpho-org/metamorpho
 */
interface IMetaMorpho is IERC4626 {
    // ============ Structs ============

    struct MarketAllocation {
        bytes32 marketId;
        uint256 assets;
    }

    // ============ Events ============

    event UpdateLastTotalAssets(uint256 updatedTotalAssets);
    event SubmitTimelock(uint256 newTimelock);
    event SetFee(address indexed caller, uint256 newFee);
    event SetFeeRecipient(address indexed newFeeRecipient);
    event Skim(address indexed token, uint256 amount);
    event SetCurator(address indexed newCurator);
    event SetIsAllocator(address indexed allocator, bool isAllocator);
    event SetGuardian(address indexed guardian, address indexed newGuardian);

    event ReallocateSupply(
        address indexed caller,
        bytes32 indexed id,
        uint256 suppliedAssets,
        uint256 suppliedShares
    );

    event ReallocateWithdraw(
        address indexed caller,
        bytes32 indexed id,
        uint256 withdrawnAssets,
        uint256 withdrawnShares
    );

    // ============ View Functions ============

    /**
     * @notice Returns the address of the Morpho Blue protocol
     * @return The Morpho Blue contract address
     */
    function MORPHO() external view returns (address);

    /**
     * @notice Returns the curator address
     * @return The curator who can manage the vault
     */
    function curator() external view returns (address);

    /**
     * @notice Returns whether an address is an allocator
     * @param allocator Address to check
     * @return True if the address is an allocator
     */
    function isAllocator(address allocator) external view returns (bool);

    /**
     * @notice Returns the fee (in basis points)
     * @return The current fee
     */
    function fee() external view returns (uint96);

    /**
     * @notice Returns the fee recipient address
     * @return The address receiving fees
     */
    function feeRecipient() external view returns (address);

    /**
     * @notice Returns the guardian address
     * @return The guardian who can pause the vault
     */
    function guardian() external view returns (address);

    /**
     * @notice Returns the timelock period
     * @return The timelock duration in seconds
     */
    function timelock() external view returns (uint256);

    /**
     * @notice Returns the last total assets value
     * @return The last recorded total assets
     */
    function lastTotalAssets() external view returns (uint256);

    // ============ Management Functions ============

    /**
     * @notice Reallocates the vault's liquidity across markets
     * @param allocations Array of market allocations
     * @dev Only callable by allocators
     */
    function reallocate(MarketAllocation[] calldata allocations) external;

    /**
     * @notice Sets a new fee
     * @param newFee New fee in basis points
     * @dev Only callable by owner
     */
    function setFee(uint256 newFee) external;

    /**
     * @notice Sets a new fee recipient
     * @param newFeeRecipient New fee recipient address
     * @dev Only callable by owner
     */
    function setFeeRecipient(address newFeeRecipient) external;

    /**
     * @notice Sets a new curator
     * @param newCurator New curator address
     * @dev Only callable by owner
     */
    function setCurator(address newCurator) external;

    /**
     * @notice Skims tokens from the vault
     * @param token Token address to skim
     * @dev Sends surplus tokens to the fee recipient
     */
    function skim(address token) external;

    /**
     * @notice Updates the last total assets value
     * @dev Used for fee accrual calculation
     */
    function updateLastTotalAssets() external;

    // ============ ERC4626 Functions (inherited from IERC4626) ============
    // These are already defined in IERC4626:
    // - deposit(uint256 assets, address receiver)
    // - mint(uint256 shares, address receiver)
    // - withdraw(uint256 assets, address receiver, address owner)
    // - redeem(uint256 shares, address receiver, address owner)
    // - totalAssets()
    // - convertToShares(uint256 assets)
    // - convertToAssets(uint256 shares)
    // - maxDeposit(address receiver)
    // - maxMint(address receiver)
    // - maxWithdraw(address owner)
    // - maxRedeem(address owner)
    // - previewDeposit(uint256 assets)
    // - previewMint(uint256 shares)
    // - previewWithdraw(uint256 assets)
    // - previewRedeem(uint256 shares)
}
