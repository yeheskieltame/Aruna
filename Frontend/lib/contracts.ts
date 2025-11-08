// Import ABIs
import ArunaCoreABI from "./abis/ArunaCore.json"
import AaveVaultABI from "./abis/AaveVaultAdapter.json"
import MorphoVaultABI from "./abis/MorphoVaultAdapter.json"
import YieldRouterABI from "./abis/YieldRouter.json"
import OctantModuleABI from "./abis/OctantDonationModule.json"
import IERC20ABI from "./abis/IERC20.json"

/**
 * Deployed Contract Addresses on Base Sepolia (Chain ID: 84532)
 *
 * Deployment Date: 2024-11-08
 * Deployer: 0x77c4a1cD22005b67Eb9CcEaE7E9577188d7Bca82
 * Network: Base Sepolia Testnet
 *
 * All contracts verified on BaseScan:
 * https://sepolia.basescan.org
 */
export const CONTRACTS = {
  // ========================================
  // ARUNA PROTOCOL CONTRACTS
  // ========================================

  ARUNA_CORE: {
    address: (process.env.NEXT_PUBLIC_ARUNA_CORE || "0x5ee04F6377e03b47F5e932968e87ad5599664Cf2") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0x5ee04F6377e03b47F5e932968e87ad5599664Cf2",
  },
  AAVE_VAULT: {
    address: (process.env.NEXT_PUBLIC_AAVE_VAULT || "0x8E9F6B3230800B781e461fce5F7F118152FeD969") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0x8E9F6B3230800B781e461fce5F7F118152FeD969",
  },
  MORPHO_VAULT: {
    address: (process.env.NEXT_PUBLIC_MORPHO_VAULT || "0xc4388Fe5A3057eE1fc342a8018015f32f6aF6A7d") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0xc4388Fe5A3057eE1fc342a8018015f32f6aF6A7d",
  },
  YIELD_ROUTER: {
    address: (process.env.NEXT_PUBLIC_YIELD_ROUTER || "0x9721ee37de0F289A99f8EA2585293575AE2654CC") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0x9721ee37de0F289A99f8EA2585293575AE2654CC",
  },
  OCTANT_MODULE: {
    address: (process.env.NEXT_PUBLIC_OCTANT_MODULE || "0xB745282F0FCe7a669F9EbD50B403e895090b1b24") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0xB745282F0FCe7a669F9EbD50B403e895090b1b24",
  },

  // ========================================
  // BASE SEPOLIA INFRASTRUCTURE
  // ========================================

  // Base Sepolia USDC Token
  USDC: {
    address: (process.env.NEXT_PUBLIC_USDC || "0x036CbD53842c5426634e7929541eC2318f3dCF7e") as `0x${string}`,
    decimals: 6,
    symbol: "USDC",
    name: "USD Coin",
  },

  // Aave v3 on Base Sepolia
  AAVE_POOL: {
    address: (process.env.NEXT_PUBLIC_AAVE_POOL || "0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b") as `0x${string}`,
  },
  AAVE_AUSDC: {
    address: (process.env.NEXT_PUBLIC_AAVE_AUSDC || "0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB") as `0x${string}`,
    symbol: "aUSDC",
    name: "Aave Base Sepolia USDC",
  },

  // ========================================
  // MOCK CONTRACTS (TESTNET ONLY)
  // ========================================

  MOCK_OCTANT: {
    address: (process.env.NEXT_PUBLIC_MOCK_OCTANT || "0xd4d4F246DCAf4b2822E0D74Ac30B06771Ee37B23") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0xd4d4F246DCAf4b2822E0D74Ac30B06771Ee37B23",
  },
  MOCK_METAMORPHO: {
    address: (process.env.NEXT_PUBLIC_MOCK_METAMORPHO || "0x9D831F7d7BA69358c8A1A44Ea509C53372D9Fd19") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0x9D831F7d7BA69358c8A1A44Ea509C53372D9Fd19",
  },
}

// Export ABIs
export const ABIS = {
  ARUNA_CORE: ArunaCoreABI,
  AAVE_VAULT: AaveVaultABI,
  MORPHO_VAULT: MorphoVaultABI,
  YIELD_ROUTER: YieldRouterABI,
  OCTANT_MODULE: OctantModuleABI,
  ERC20: IERC20ABI,
}

// Export for backward compatibility
export const ERC20_ABI = IERC20ABI
export const Aruna_ABI = ArunaCoreABI
