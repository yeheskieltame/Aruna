// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title TestHelpers
 * @notice Common test utilities and helper functions
 */
abstract contract TestHelpers is Test {
    // Common test addresses
    address public constant ALICE = address(0x1);
    address public constant BOB = address(0x2);
    address public constant CHARLIE = address(0x3);
    address public constant DAVID = address(0x4);
    address public constant EVE = address(0x5);

    address public owner = address(this);
    address public treasury = address(0x999);

    // Time constants
    uint256 public constant ONE_DAY = 1 days;
    uint256 public constant ONE_WEEK = 7 days;
    uint256 public constant ONE_MONTH = 30 days;
    uint256 public constant ONE_YEAR = 365 days;

    // Protocol constants
    uint256 public constant GRANT_PERCENTAGE = 300; // 3%
    uint256 public constant COLLATERAL_PERCENTAGE = 1000; // 10%
    uint256 public constant INVESTOR_PERCENTAGE = 7000; // 70%
    uint256 public constant PUBLIC_GOODS_PERCENTAGE = 2500; // 25%
    uint256 public constant PROTOCOL_FEE_PERCENTAGE = 500; // 5%
    uint256 public constant BASIS_POINTS = 10000;

    // Helper functions
    function labelAddresses() internal {
        vm.label(ALICE, "Alice");
        vm.label(BOB, "Bob");
        vm.label(CHARLIE, "Charlie");
        vm.label(DAVID, "David");
        vm.label(EVE, "Eve");
        vm.label(owner, "Owner");
        vm.label(treasury, "Treasury");
    }

    function calculateGrant(uint256 invoiceAmount) internal pure returns (uint256) {
        return (invoiceAmount * GRANT_PERCENTAGE) / BASIS_POINTS;
    }

    function calculateCollateral(uint256 invoiceAmount) internal pure returns (uint256) {
        return (invoiceAmount * COLLATERAL_PERCENTAGE) / BASIS_POINTS;
    }

    function calculateInvestorYield(uint256 totalYield) internal pure returns (uint256) {
        return (totalYield * INVESTOR_PERCENTAGE) / BASIS_POINTS;
    }

    function calculatePublicGoodsYield(uint256 totalYield) internal pure returns (uint256) {
        return (totalYield * PUBLIC_GOODS_PERCENTAGE) / BASIS_POINTS;
    }

    function calculateProtocolFee(uint256 totalYield) internal pure returns (uint256) {
        return (totalYield * PROTOCOL_FEE_PERCENTAGE) / BASIS_POINTS;
    }

    function getDueDateInFuture(uint256 daysAhead) internal view returns (uint256) {
        return block.timestamp + (daysAhead * 1 days);
    }

    function skipDays(uint256 numDays) internal {
        vm.warp(block.timestamp + (numDays * 1 days));
    }

    function skipHours(uint256 numHours) internal {
        vm.warp(block.timestamp + (numHours * 1 hours));
    }
}

/**
 * @title MockUSDC
 * @notice Mock USDC token for testing
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1_000_000_000 * 1e6); // 1 billion USDC
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

/**
 * @title MockAavePool
 * @notice Mock Aave v3 Pool for testing
 */
contract MockAavePool {
    mapping(address => mapping(address => uint256)) public deposits;
    MockAToken public aToken;

    constructor(address _aToken) {
        aToken = MockAToken(_aToken);
    }

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 /*referralCode*/
    ) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        deposits[asset][onBehalfOf] += amount;

        // Mint aTokens
        aToken.mint(onBehalfOf, amount);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(deposits[asset][msg.sender] >= amount, "Insufficient deposit");
        deposits[asset][msg.sender] -= amount;

        // Burn aTokens
        aToken.burn(msg.sender, amount);

        IERC20(asset).transfer(to, amount);
        return amount;
    }

    function simulateYieldAccrual(address asset, address user, uint256 yieldAmount) external {
        // Simulate yield by minting additional aTokens
        aToken.mint(user, yieldAmount);
    }
}

/**
 * @title MockAToken
 * @notice Mock Aave aToken for testing
 */
contract MockAToken is ERC20 {
    address public pool;

    constructor() ERC20("Aave USDC", "aUSDC") {}

    function setPool(address _pool) external {
        pool = _pool;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == pool, "Only pool");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == pool, "Only pool");
        _burn(from, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

/**
 * @title MockMetaMorpho
 * @notice Mock MetaMorpho vault for testing
 */
contract MockMetaMorpho is ERC4626 {
    address public immutable MORPHO;
    uint256 private _yieldMultiplier = 1e18; // 1.0 = no yield
    uint256 private _totalAssets; // Track total assets deposited

    constructor(
        IERC20 _asset,
        address _morpho
    ) ERC4626(_asset) ERC20("MetaMorpho USDC", "mmUSDC") {
        MORPHO = _morpho;
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        // Transfer assets to this contract
        IERC20(asset()).transferFrom(msg.sender, address(this), assets);

        // Update total assets tracking
        _totalAssets += assets;

        // Calculate shares (1:1 for simplicity)
        shares = assets;

        // Mint shares to receiver
        _mint(receiver, shares);

        return shares;
    }

    function simulateYield(uint256 yieldBps) external {
        // Increase yield multiplier (e.g., 100 bps = 1% = 1.01x)
        _yieldMultiplier = _yieldMultiplier * (10000 + yieldBps) / 10000;
    }

    function totalAssets() public view override returns (uint256) {
        // Simulate yield by multiplying total assets
        return (_totalAssets * _yieldMultiplier) / 1e18;
    }
}
