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
 * All addresses verified and deployed on 2024-11-08
 * Deployer: 0x77c4a1cD22005b67Eb9CcEaE7E9577188d7Bca82
 */
export const CONTRACT_ADDRESSES = {
  // Core Aruna Protocol
  ARUNA_CORE: "0x5ee04F6377e03b47F5e932968e87ad5599664Cf2",
  AAVE_VAULT: "0x8E9F6B3230800B781e461fce5F7F118152FeD969",
  MORPHO_VAULT: "0xc4388Fe5A3057eE1fc342a8018015f32f6aF6A7d",
  YIELD_ROUTER: "0x9721ee37de0F289A99f8EA2585293575AE2654CC",
  OCTANT_MODULE: "0xB745282F0FCe7a669F9EbD50B403e895090b1b24",

  // Mock Contracts (Testnet Only)
  MOCK_OCTANT: "0xd4d4F246DCAf4b2822E0D74Ac30B06771Ee37B23",
  MOCK_METAMORPHO: "0x9D831F7d7BA69358c8A1A44Ea509C53372D9Fd19",

  // Base Sepolia Infrastructure
  USDC: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
  AAVE_POOL: "0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b",
  AAVE_AUSDC: "0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB",
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
