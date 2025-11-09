/**
 * Aruna Protocol Configuration
 * Network: Base Sepolia (Testnet)
 * Chain ID: 84532
 * Deployed: 2024-11-08
 */

export const CHAIN_CONFIG = {
  name: "Base Sepolia",
  chainId: 84532,
  rpcUrl: process.env.NEXT_PUBLIC_BASE_SEPOLIA_RPC || "https://sepolia.base.org",
  blockExplorer: "https://sepolia.basescan.org",
}

export const APP_CONFIG = {
  name: "Aruna",
  description: "Turn invoice payments into public goods funding",
  // Legacy fallback for old env var name
  ArunaAddress: process.env.NEXT_PUBLIC_ARUNA_CORE || process.env.NEXT_PUBLIC_Aruna_ADDRESS || "",
}

/**
 * Deployed Contract Addresses - Base Sepolia
 * All addresses verified and deployed on 2024-11-09
 * Deployer: 0x77c4a1cD22005b67Eb9CcEaE7E9577188d7Bca82
 */
export const CONTRACT_ADDRESSES = {
  // Core Aruna Protocol
  ARUNA_CORE: "0xE60dcA6869F072413557769bDFd4e30ceFa6997f",
  AAVE_VAULT: "0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905",
  MORPHO_VAULT: "0x16dea7eE228c0781938E6869c07ceb2EEA7bd564",
  YIELD_ROUTER: "0x124d8F59748860cdD851fB176c7630dD71016e89",
  OCTANT_MODULE: "0xEDc5CeE824215cbeEBC73e508558a955cdD75F00",

  // Mock Contracts (Testnet Only)
  MOCK_OCTANT: "0x480d28E02b449086efA3f01E2EdA4A4EAE99C3e6",
  MOCK_METAMORPHO: "0x7deB84aAe25A2168782E6c8C0CF30714cbaaA025",

  // Base Sepolia Infrastructure
  USDC: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
} as const

export const VAULT_CONFIG = {
  aave: {
    name: "Aave v3",
    apy: 6.5,
    description: "Stable, proven yield source",
    address: CONTRACT_ADDRESSES.AAVE_VAULT,
  },
  morpho: {
    name: "Morpho",
    apy: 8.2,
    description: "Optimized for higher yields",
    address: CONTRACT_ADDRESSES.MORPHO_VAULT,
  },
}

export const PROTOCOL_CONFIG = {
  grantPercentage: 0.03, // 3% instant grant
  collateralPercentage: 0.1, // 10% collateral requirement
  publicGoodsPercentage: 0.25, // 25% to public goods
  investorPercentage: 0.70, // 70% to investors
  protocolFeePercentage: 0.05, // 5% protocol fee
}
