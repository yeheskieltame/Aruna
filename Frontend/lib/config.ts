export const CHAIN_CONFIG = {
  name: "Base Sepolia",
  chainId: 84532,
  rpcUrl: process.env.NEXT_PUBLIC_BASE_SEPOLIA_RPC || "https://sepolia.base.org",
  blockExplorer: "https://sepolia.basescan.org",
}

export const APP_CONFIG = {
  name: "Aruna",
  description: "Turn invoice payments into public goods funding",
  ArunaAddress: process.env.NEXT_PUBLIC_Aruna_ADDRESS || "",
}

export const VAULT_CONFIG = {
  aave: {
    name: "Aave v3",
    apy: 6.5,
    description: "Stable, proven yield source",
  },
  morpho: {
    name: "Morpho",
    apy: 8.2,
    description: "Optimized for higher yields",
  },
}

export const PROTOCOL_CONFIG = {
  grantPercentage: 0.03, // 3% instant grant
  collateralPercentage: 0.1, // 10% collateral requirement
  publicGoodsPercentage: 0.25, // 25% to public goods
  protocolFeePercentage: 0.05, // 5% protocol fee
}
