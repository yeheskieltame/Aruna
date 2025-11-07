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

// Mock MetaMorpho Contract for Base Sepolia Testing
contract MockMetaMorpho is ERC4626 {
    uint256 private constant MOCK_APY = 820; // 8.2% APY
    uint256 private constant BASIS_POINTS = 10000;

    constructor(IERC20 _asset, string memory name, string memory symbol)
        ERC20(name, symbol) ERC4626(_asset) {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function totalAssets() public view override returns (uint256) {
        // Mock total assets with yield
        uint256 principal = IERC20(asset()).balanceOf(address(this));
        uint256 mockYield = (principal * MOCK_APY) / BASIS_POINTS;
        return principal + mockYield;
    }

    function getAPY() external pure returns (uint256) {
        return MOCK_APY;
    }

    // Mock Morpho Blue interface
    function MORPHO() external pure returns (address) {
        return address(0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB);
    }

    function curator() external pure returns (address) {
        return address(0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC);
    }

    function supplyQueue() external pure returns (address[] memory) {
        address[] memory empty;
        return empty;
    }

    function withdrawQueue() external pure returns (address[] memory) {
        address[] memory empty;
        return empty;
    }
}

/**
 * @title DeployAruna
 * @notice Deployment script for Aruna protocol
 * @dev Deploys all contracts in correct order with proper initialization
 */
contract DeployAruna is Script {
    // Deployment addresses (will be updated after deployment)
    ArunaCore public arunaCore;
    AaveVaultAdapter public aaveVault;
    MorphoVaultAdapter public morphoVault;
    YieldRouter public yieldRouter;
    OctantDonationModule public octantModule;
    MockOctantDeposits public mockOctant; // For testnet only
    MockMetaMorpho public mockMetaMorpho; // For testnet when no real MetaMorpho

    // Configuration
    struct DeployConfig {
        address usdc;
        address aavePool;
        address aaveAToken;
        address metaMorphoVault; // MetaMorpho vault for Morpho V2 integration
        address octantDeposits;
        address protocolTreasury;
        address owner;
        bool useTestnet; // If true, deploy mock Octant
        bool deployMockMetaMorpho; // If true, deploy mock MetaMorpho
    }

    function run() external {
        // Load configuration based on chain
        DeployConfig memory config = getConfig();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Aruna Protocol");
        console.log("Deployer:", deployer);
        console.log("Network:", block.chainid);
        console.log("---");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy Mock Octant if testnet
        if (config.useTestnet) {
            console.log("Deploying MockOctantDeposits...");
            mockOctant = new MockOctantDeposits(config.usdc);
            config.octantDeposits = address(mockOctant);
            console.log("MockOctantDeposits deployed at:", address(mockOctant));
        }

        // Step 2: Deploy OctantDonationModule
        console.log("Deploying OctantDonationModule...");
        octantModule = new OctantDonationModule(
            config.octantDeposits,
            config.usdc,
            config.owner
        );
        console.log("OctantDonationModule deployed at:", address(octantModule));

        // Step 3: Deploy YieldRouter
        console.log("Deploying YieldRouter...");
        yieldRouter = new YieldRouter(
            config.usdc,
            address(octantModule),
            config.protocolTreasury,
            config.owner
        );
        console.log("YieldRouter deployed at:", address(yieldRouter));

        // Step 4: Deploy AaveVaultAdapter
        console.log("Deploying AaveVaultAdapter...");
        aaveVault = new AaveVaultAdapter(
            IERC20(config.usdc),
            config.aavePool,
            config.aaveAToken,
            address(yieldRouter),
            config.owner
        );
        console.log("AaveVaultAdapter deployed at:", address(aaveVault));

        // Step 5: Deploy Mock MetaMorpho if needed
        address actualMetaMorphoVault = config.metaMorphoVault;
        if (config.deployMockMetaMorpho) {
            console.log("Deploying Mock MetaMorpho...");
            mockMetaMorpho = new MockMetaMorpho(
                IERC20(config.usdc),
                "Mock MetaMorpho USDC Vault",
                "mmUSDC"
            );
            actualMetaMorphoVault = address(mockMetaMorpho);
            console.log("Mock MetaMorpho deployed at:", actualMetaMorphoVault);
        }

        // Step 6: Deploy MorphoVaultAdapter
        console.log("Deploying MorphoVaultAdapter...");
        console.log("MetaMorpho Vault:", actualMetaMorphoVault);
        morphoVault = new MorphoVaultAdapter(
            IERC20(config.usdc),
            actualMetaMorphoVault,
            address(yieldRouter),
            config.owner
        );
        console.log("MorphoVaultAdapter deployed at:", address(morphoVault));

        // Step 7: Deploy ArunaCore
        console.log("Deploying ArunaCore...");
        arunaCore = new ArunaCore(
            config.usdc,
            config.owner
        );
        console.log("ArunaCore deployed at:", address(arunaCore));

        // Step 8: Initialize ArunaCore with vault addresses
        console.log("Initializing ArunaCore...");
        arunaCore.initialize(
            address(aaveVault),
            address(morphoVault),
            address(yieldRouter),
            address(octantModule)
        );
        console.log("ArunaCore initialized");

        // Step 9: Set YieldRouter's vault address
        console.log("Setting vault address in YieldRouter...");
        yieldRouter.addVaultAuthorization(address(aaveVault));
        yieldRouter.addVaultAuthorization(address(morphoVault));
        console.log("YieldRouter configured");

        vm.stopBroadcast();

        // Print summary
        console.log("\n=== Deployment Summary ===");
        console.log("ArunaCore:", address(arunaCore));
        console.log("AaveVaultAdapter:", address(aaveVault));
        console.log("MorphoVaultAdapter:", address(morphoVault));
        console.log("YieldRouter:", address(yieldRouter));
        console.log("OctantDonationModule:", address(octantModule));
        if (config.useTestnet) {
            console.log("MockOctantDeposits:", address(mockOctant));
        }
        if (config.deployMockMetaMorpho) {
            console.log("MockMetaMorpho:", address(mockMetaMorpho));
        }
        console.log("========================\n");

        // Save addresses to file
        _saveDeploymentAddresses(config);
    }

    /**
     * @notice Get deployment configuration for Base Sepolia
     * @return config Deployment configuration
     */
    function getConfig() internal view returns (DeployConfig memory config) {
        uint256 chainId = block.chainid;

        if (chainId == 84532) {
            // Base Sepolia Testnet - PRIMARY DEPLOYMENT TARGET
            console.log("Configuring for Base Sepolia Testnet");

            // Try to get MetaMorpho vault from environment
            address metaMorphoVault;
            bool deployMockMetaMorpho = false;

            try vm.envString("METAMORPHO_VAULT") returns (string memory vaultConfig) {
                if (keccak256(bytes(vaultConfig)) == keccak256(bytes("DEPLOY_MOCK_METAMORPHO"))) {
                    deployMockMetaMorpho = true;
                    console.log("Will deploy Mock MetaMorpho for testing");
                } else {
                    // Try to parse as address
                    try vm.envAddress("METAMORPHO_VAULT") returns (address vault) {
                        metaMorphoVault = vault;
                        console.log("Using MetaMorpho vault:", vault);
                    } catch {
                        revert("Invalid METAMORPHO_VAULT configuration. Use address or DEPLOY_MOCK_METAMORPHO");
                    }
                }
            } catch {
                revert("METAMORPHO_VAULT not configured. Add METAMORPHO_VAULT=DEPLOY_MOCK_METAMORPHO to .env");
            }

            config = DeployConfig({
                usdc: 0x036CbD53842c5426634e7929541eC2318f3dCF7e, // Base Sepolia USDC
                aavePool: 0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b, // Aave v3 Pool on Base Sepolia
                aaveAToken: 0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB, // aUSDC on Base Sepolia
                metaMorphoVault: metaMorphoVault, // MetaMorpho USDC vault on Base Sepolia
                octantDeposits: address(0), // Will deploy mock
                protocolTreasury: vm.envAddress("PROTOCOL_TREASURY"),
                owner: vm.envAddress("OWNER_ADDRESS"),
                useTestnet: true,
                deployMockMetaMorpho: deployMockMetaMorpho
            });
        } else if (chainId == 31337) {
            // Local Anvil testnet (for local development)
            console.log("Configuring for Local Anvil");
            config = DeployConfig({
                usdc: vm.envAddress("USDC_ADDRESS"), // Deploy mock USDC first
                aavePool: vm.envAddress("AAVE_POOL"), // Deploy mocks
                aaveAToken: vm.envAddress("AAVE_ATOKEN"),
                metaMorphoVault: vm.envAddress("METAMORPHO_VAULT"), // Deploy mock MetaMorpho
                octantDeposits: address(0),
                protocolTreasury: vm.addr(vm.envUint("PRIVATE_KEY")),
                owner: vm.addr(vm.envUint("PRIVATE_KEY")),
                useTestnet: true,
                deployMockMetaMorpho: true // Always deploy mock for local
            });
        } else {
            revert("Unsupported chain ID. Please deploy to Base Sepolia (84532) or Local Anvil (31337)");
        }

        return config;
    }

    /**
     * @notice Save deployment addresses to JSON file
     * @param config Deployment configuration
     */
    function _saveDeploymentAddresses(DeployConfig memory config) internal {
        string memory json = "deployment";

        vm.serializeAddress(json, "ArunaCore", address(arunaCore));
        vm.serializeAddress(json, "aaveVault", address(aaveVault));
        vm.serializeAddress(json, "morphoVault", address(morphoVault));
        vm.serializeAddress(json, "yieldRouter", address(yieldRouter));
        vm.serializeAddress(json, "octantModule", address(octantModule));

        if (config.useTestnet) {
            vm.serializeAddress(json, "mockOctant", address(mockOctant));
        }

        vm.serializeAddress(json, "usdc", config.usdc);
        vm.serializeAddress(json, "owner", config.owner);

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
