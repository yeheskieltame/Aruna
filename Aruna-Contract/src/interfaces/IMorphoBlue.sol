// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMorphoBlue
 * @notice Interface for Morpho Blue protocol (simplified for our use case)
 * @dev This is a simplified interface containing only the functions we need
 * @dev Full interface: https://github.com/morpho-org/morpho-blue
 */
interface IMorphoBlue {
    // ============ Structs ============

    struct MarketParams {
        address loanToken;
        address collateralToken;
        address oracle;
        address irm;
        uint256 lltv;
    }

    struct Position {
        uint256 supplyShares;
        uint128 borrowShares;
        uint128 collateral;
    }

    struct Market {
        uint128 totalSupplyAssets;
        uint128 totalSupplyShares;
        uint128 totalBorrowAssets;
        uint128 totalBorrowShares;
        uint128 lastUpdate;
        uint128 fee;
    }

    // ============ Events ============

    event Supply(
        bytes32 indexed id,
        address indexed caller,
        address indexed onBehalf,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        bytes32 indexed id,
        address caller,
        address indexed onBehalf,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );

    // ============ View Functions ============

    /**
     * @notice Returns the market parameters for a given market ID
     * @param id Market identifier
     * @return The market parameters
     */
    function idToMarketParams(bytes32 id) external view returns (MarketParams memory);

    /**
     * @notice Returns market data for a given market ID
     * @param id Market identifier
     * @return The market data
     */
    function market(bytes32 id) external view returns (Market memory);

    /**
     * @notice Returns a user's position in a market
     * @param id Market identifier
     * @param user User address
     * @return The position data
     */
    function position(bytes32 id, address user) external view returns (Position memory);

    // ============ Core Functions ============

    /**
     * @notice Supplies assets to a market
     * @param marketParams Market parameters
     * @param assets Amount of assets to supply
     * @param shares Minimum shares to receive (0 for no minimum)
     * @param onBehalf Address to credit the supply
     * @param data Additional callback data
     * @return assetsSupplied Actual assets supplied
     * @return sharesSupplied Actual shares received
     */
    function supply(
        MarketParams memory marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        bytes memory data
    ) external returns (uint256 assetsSupplied, uint256 sharesSupplied);

    /**
     * @notice Withdraws assets from a market
     * @param marketParams Market parameters
     * @param assets Amount of assets to withdraw
     * @param shares Maximum shares to burn (0 for no maximum)
     * @param onBehalf Address from which to withdraw
     * @param receiver Address to receive the assets
     * @return assetsWithdrawn Actual assets withdrawn
     * @return sharesWithdrawn Actual shares burned
     */
    function withdraw(
        MarketParams memory marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        address receiver
    ) external returns (uint256 assetsWithdrawn, uint256 sharesWithdrawn);

    /**
     * @notice Accrues interest for a market
     * @param marketParams Market parameters
     */
    function accrueInterest(MarketParams memory marketParams) external;
}
