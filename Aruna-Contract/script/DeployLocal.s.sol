// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/ArunaCore.sol";
import "../src/vaults/AaveVaultAdapter.sol";
import "../src/vaults/MorphoVaultAdapter.sol";
import "../src/modules/YieldRouter.sol";
import "../src/modules/OctantDonationModule.sol";
import "../src/mocks/MockOctantDeposits.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

// Mock Contracts for Local Testing
contract MockUSDC is ERC20 {
    constructor() ERC20("USDC Coin", "USDC") {
        _mint(msg.sender, 1000000000 * 1e6); // 1B USDC initial supply
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockAavePool {
    IERC20 public usdc;
    IERC20 public aToken;

    constructor(address _usdc) {
        usdc = IERC20(_usdc);
    }

    function setAToken(address _aToken) external {
        aToken = IERC20(_aToken);
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        require(asset == address(usdc), "Invalid asset");
        usdc.transferFrom(msg.sender, address(this), amount);
        // Mock yield accrual
        uint256 yieldAmount = (amount * 65) / 1000; // 6.5% APY mock
        aToken.transfer(onBehalfOf, amount + yieldAmount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        require(asset == address(usdc), "Invalid asset");
        aToken.transferFrom(msg.sender, address(this), amount);
        usdc.transfer(to, amount);
        return amount;
    }
}

contract MockAToken is ERC20 {
    address public pool;

    constructor(string memory name, string memory symbol, address _underlying, address _pool)
        ERC20(name, symbol) {
        pool = _pool;
    }

    function setPool(address _pool) external {
        pool = _pool;
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract MockMetaMorpho is ERC4626 {
    constructor(IERC20 _asset, string memory name, string memory symbol)
        ERC20(name, symbol) ERC4626(_asset) {
        // Constructor properly initialized
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function totalAssets() public view override returns (uint256) {
        // Mock total assets with yield
        return IERC20(asset()).balanceOf(address(this)) * 1082 / 1000; // 8.2% APY mock
    }
}

/**
 * @title DeployLocal
 * @notice Deployment script for local Anvil development with mock contracts
 * @dev Deploys mock USDC, Aave, Morpho, then all Aruna contracts
 */
contract DeployLocal is Script {
    // Mock contracts for testing
    MockUSDC public usdc;
    MockAavePool public aavePool;
    MockAToken public aToken;
    MockMetaMorpho public metaMorpho;

    // Aruna contracts
    ArunaCore public arunaCore;
    AaveVaultAdapter public aaveVault;
    MorphoVaultAdapter public morphoVault;
    YieldRouter public yieldRouter;
    OctantDonationModule public octantModule;
    MockOctantDeposits public mockOctant;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deploying Aruna Protocol to Local Anvil ===");
        console.log("Deployer:", deployer);
        console.log("Network:", block.chainid);
        console.log("---");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy Mock Contracts
        console.log("Deploying Mock USDC...");
        usdc = new MockUSDC();
        console.log("Mock USDC deployed at:", address(usdc));

        console.log("Deploying Mock Aave Pool...");
        aavePool = new MockAavePool(address(usdc));
        console.log("Mock Aave Pool deployed at:", address(aavePool));

        console.log("Deploying Mock aToken...");
        aToken = new MockAToken("Aave USDC", "aUSDC", address(usdc), address(aavePool));
        console.log("Mock aToken deployed at:", address(aToken));

        console.log("Deploying Mock MetaMorpho...");
        metaMorpho = new MockMetaMorpho(IERC20(address(usdc)), "MetaMorpho USDC Vault", "mmUSDC");
        console.log("Mock MetaMorpho deployed at:", address(metaMorpho));

        // Step 2: Setup Mock Contracts
        console.log("Setting up mock contracts...");
        aavePool.setAToken(address(aToken));
        aToken.setPool(address(aavePool));

        // Fund mock contracts with USDC for testing
        usdc.mint(address(aavePool), 100_000_000 * 1e6); // 100M USDC to Aave
        usdc.mint(address(metaMorpho), 100_000_000 * 1e6); // 100M USDC to Morpho
        console.log("Mock contracts funded with USDC");

        // Step 3: Deploy Mock Octant
        console.log("Deploying MockOctantDeposits...");
        mockOctant = new MockOctantDeposits(address(usdc));
        console.log("MockOctantDeposits deployed at:", address(mockOctant));

        // Step 4: Deploy OctantDonationModule
        console.log("Deploying OctantDonationModule...");
        octantModule = new OctantDonationModule(
            address(mockOctant),
            address(usdc),
            deployer
        );
        console.log("OctantDonationModule deployed at:", address(octantModule));

        // Step 5: Deploy YieldRouter
        console.log("Deploying YieldRouter...");
        yieldRouter = new YieldRouter(
            address(usdc),
            address(octantModule),
            deployer, // protocol treasury
            deployer  // owner
        );
        console.log("YieldRouter deployed at:", address(yieldRouter));

        // Step 6: Deploy AaveVaultAdapter
        console.log("Deploying AaveVaultAdapter...");
        aaveVault = new AaveVaultAdapter(
            usdc,
            address(aavePool),
            address(aToken),
            address(yieldRouter),
            deployer
        );
        console.log("AaveVaultAdapter deployed at:", address(aaveVault));

        // Step 7: Deploy MorphoVaultAdapter
        console.log("Deploying MorphoVaultAdapter...");
        morphoVault = new MorphoVaultAdapter(
            usdc,
            address(metaMorpho),
            address(yieldRouter),
            deployer
        );
        console.log("MorphoVaultAdapter deployed at:", address(morphoVault));

        // Step 8: Deploy ArunaCore
        console.log("Deploying ArunaCore...");
        arunaCore = new ArunaCore(
            address(usdc),
            deployer
        );
        console.log("ArunaCore deployed at:", address(arunaCore));

        // Step 9: Initialize ArunaCore
        console.log("Initializing ArunaCore...");
        arunaCore.initialize(
            address(aaveVault),
            address(morphoVault),
            address(yieldRouter),
            address(octantModule)
        );
        console.log("ArunaCore initialized");

        // Step 10: Configure YieldRouter
        console.log("Setting up YieldRouter...");
        yieldRouter.addVaultAuthorization(address(aaveVault));
        yieldRouter.addVaultAuthorization(address(morphoVault));
        console.log("YieldRouter configured");

        // Step 11: Fund contracts for testing
        console.log("Funding contracts for testing...");
        usdc.mint(address(arunaCore), 1_000_000 * 1e6); // 1M USDC for grants

        // Fund test accounts
        address alice = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address bob = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        address charlie = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

        usdc.mint(alice, 1_000_000 * 1e6);   // Business user
        usdc.mint(bob, 1_000_000 * 1e6);     // Investor 1
        usdc.mint(charlie, 1_000_000 * 1e6);  // Investor 2

        console.log("Test accounts funded with USDC");

        vm.stopBroadcast();

        // Print deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("--- Mock Contracts ---");
        console.log("USDC:", address(usdc));
        console.log("Aave Pool:", address(aavePool));
        console.log("aToken:", address(aToken));
        console.log("MetaMorpho:", address(metaMorpho));
        console.log("Mock Octant:", address(mockOctant));
        console.log("--- Aruna Contracts ---");
        console.log("ArunaCore:", address(arunaCore));
        console.log("AaveVaultAdapter:", address(aaveVault));
        console.log("MorphoVaultAdapter:", address(morphoVault));
        console.log("YieldRouter:", address(yieldRouter));
        console.log("OctantDonationModule:", address(octantModule));
        console.log("--- Test Accounts ---");
        console.log("Alice (Business):", alice);
        console.log("Bob (Investor 1):", bob);
        console.log("Charlie (Investor 2):", charlie);
        console.log("========================\n");

        // Save deployment addresses
        _saveDeploymentAddresses(deployer);

        console.log("Local deployment complete!");
        console.log("Ready for testing all Aruna features!");
    }

    function _saveDeploymentAddresses(address deployer) internal {
        string memory json = "deployment";

        // Mock contracts
        vm.serializeAddress(json, "usdc", address(usdc));
        vm.serializeAddress(json, "aavePool", address(aavePool));
        vm.serializeAddress(json, "aToken", address(aToken));
        vm.serializeAddress(json, "metaMorpho", address(metaMorpho));
        vm.serializeAddress(json, "mockOctant", address(mockOctant));

        // Aruna contracts
        vm.serializeAddress(json, "ArunaCore", address(arunaCore));
        vm.serializeAddress(json, "aaveVault", address(aaveVault));
        vm.serializeAddress(json, "morphoVault", address(morphoVault));
        vm.serializeAddress(json, "yieldRouter", address(yieldRouter));
        vm.serializeAddress(json, "octantModule", address(octantModule));

        // Additional info
        vm.serializeAddress(json, "deployer", deployer);

        string memory finalJson = vm.serializeUint(json, "chainId", block.chainid);

        string memory filename = string.concat(
            "deployments/",
            vm.toString(block.chainid),
            ".json"
        );

        vm.writeJson(finalJson, filename);

        console.log("Deployment addresses saved to:", filename);
    }
}