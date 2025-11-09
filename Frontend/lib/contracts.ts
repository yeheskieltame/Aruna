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
 * Deployment Date: 2024-11-09
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
    address: (process.env.NEXT_PUBLIC_ARUNA_CORE || "0xE60dcA6869F072413557769bDFd4e30ceFa6997f") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0xE60dcA6869F072413557769bDFd4e30ceFa6997f",
  },
  AAVE_VAULT: {
    address: (process.env.NEXT_PUBLIC_AAVE_VAULT || "0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905",
  },
  MORPHO_VAULT: {
    address: (process.env.NEXT_PUBLIC_MORPHO_VAULT || "0x16dea7eE228c0781938E6869c07ceb2EEA7bd564") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0x16dea7eE228c0781938E6869c07ceb2EEA7bd564",
  },
  YIELD_ROUTER: {
    address: (process.env.NEXT_PUBLIC_YIELD_ROUTER || "0x124d8F59748860cdD851fB176c7630dD71016e89") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0x124d8F59748860cdD851fB176c7630dD71016e89",
  },
  OCTANT_MODULE: {
    address: (process.env.NEXT_PUBLIC_OCTANT_MODULE || "0xEDc5CeE824215cbeEBC73e508558a955cdD75F00") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0xEDc5CeE824215cbeEBC73e508558a955cdD75F00",
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

  // ========================================
  // MOCK CONTRACTS (TESTNET ONLY)
  // ========================================

  MOCK_OCTANT: {
    address: (process.env.NEXT_PUBLIC_MOCK_OCTANT || "0x480d28E02b449086efA3f01E2EdA4A4EAE99C3e6") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0x480d28E02b449086efA3f01E2EdA4A4EAE99C3e6",
  },
  MOCK_METAMORPHO: {
    address: (process.env.NEXT_PUBLIC_MOCK_METAMORPHO || "0x7deB84aAe25A2168782E6c8C0CF30714cbaaA025") as `0x${string}`,
    explorer: "https://sepolia.basescan.org/address/0x7deB84aAe25A2168782E6c8C0CF30714cbaaA025",
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
