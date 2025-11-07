/**
 * Aruna Protocol Contract Configuration
 * Base Sepolia Testnet - Development Environment
 */

export const CONTRACTS = {
  // Token Addresses - Base Sepolia
  USDC: {
    address: "0x036CbD53842c5426634e7929541eC2318f3dCF7e", // Base Sepolia USDC
    decimals: 6,
  },

  // Aave v3 Pool on Base Sepolia
  AAVE_POOL: {
    address: "0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b",
  },

  // Aave aUSDC token on Base Sepolia
  AAVE_AUSDC: {
    address: "0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB",
  },
}

// ERC20 ABI (minimal - for USDC interactions)
export const ERC20_ABI = [
  {
    inputs: [{ name: "_owner", type: "address" }],
    name: "balanceOf",
    outputs: [{ name: "balance", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "_spender", type: "address" },
      { name: "_value", type: "uint256" },
    ],
    name: "approve",
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { name: "_to", type: "address" },
      { name: "_value", type: "uint256" },
    ],
    name: "transfer",
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const

/**
 * ArunaCore ABI - Main Protocol Contract
 *
 * Key Changes from SimpleAruna:
 * - submitInvoiceCommitment() signature fixed (no business, no ipfsHash params)
 * - depositToAaveVault() returns shares (uint256)
 * - depositToMorphoVault() returns shares (uint256)
 * - withdrawFromAaveVault() - NEW function
 * - withdrawFromMorphoVault() - NEW function
 * - claimYield() - NEW function
 * - getUserYield() remains the same
 * - getCommitment() returns expanded struct with isLiquidated
 * - getUserReputation() - NEW function
 * - getVaultAddresses() - NEW function
 */
export const Aruna_ABI = [
  // ============ Invoice Management ============
  {
    type: "function",
    name: "submitInvoiceCommitment",
    inputs: [
      { name: "customerName", type: "string" },
      { name: "invoiceAmount", type: "uint256" },
      { name: "dueDate", type: "uint256" },
    ],
    outputs: [{ name: "tokenId", type: "uint256" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "settleInvoice",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "liquidateInvoice",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
  },

  // ============ Vault Operations ============
  {
    type: "function",
    name: "depositToAaveVault",
    inputs: [{ name: "amount", type: "uint256" }],
    outputs: [{ name: "shares", type: "uint256" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "depositToMorphoVault",
    inputs: [{ name: "amount", type: "uint256" }],
    outputs: [{ name: "shares", type: "uint256" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "withdrawFromAaveVault",
    inputs: [{ name: "amount", type: "uint256" }],
    outputs: [{ name: "shares", type: "uint256" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "withdrawFromMorphoVault",
    inputs: [{ name: "amount", type: "uint256" }],
    outputs: [{ name: "shares", type: "uint256" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "claimYield",
    inputs: [],
    outputs: [{ name: "amount", type: "uint256" }],
    stateMutability: "nonpayable",
  },

  // ============ View Functions ============
  {
    type: "function",
    name: "getUserYield",
    inputs: [{ name: "user", type: "address" }],
    outputs: [{ name: "yield", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getCommitment",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "business", type: "address" },
          { name: "customerName", type: "string" },
          { name: "invoiceAmount", type: "uint256" },
          { name: "dueDate", type: "uint256" },
          { name: "collateralAmount", type: "uint256" },
          { name: "grantAmount", type: "uint256" },
          { name: "ipfsHash", type: "string" },
          { name: "isSettled", type: "bool" },
          { name: "isLiquidated", type: "bool" },
          { name: "createdAt", type: "uint256" },
        ],
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getUserCommitments",
    inputs: [{ name: "user", type: "address" }],
    outputs: [{ name: "", type: "uint256[]" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getUserReputation",
    inputs: [{ name: "user", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getVaultAddresses",
    inputs: [],
    outputs: [
      { name: "aave", type: "address" },
      { name: "morpho", type: "address" },
    ],
    stateMutability: "view",
  },

  // ============ Events ============
  {
    type: "event",
    name: "InvoiceCommitted",
    inputs: [
      { name: "tokenId", type: "uint256", indexed: true },
      { name: "business", type: "address", indexed: true },
      { name: "customerName", type: "string", indexed: false },
      { name: "invoiceAmount", type: "uint256", indexed: false },
      { name: "collateralAmount", type: "uint256", indexed: false },
      { name: "grantAmount", type: "uint256", indexed: false },
      { name: "dueDate", type: "uint256", indexed: false },
    ],
  },
  {
    type: "event",
    name: "InvoiceSettled",
    inputs: [
      { name: "tokenId", type: "uint256", indexed: true },
      { name: "business", type: "address", indexed: true },
      { name: "collateralReturned", type: "uint256", indexed: false },
    ],
  },
  {
    type: "event",
    name: "VaultDeposit",
    inputs: [
      { name: "user", type: "address", indexed: true },
      { name: "vault", type: "address", indexed: true },
      { name: "amount", type: "uint256", indexed: false },
      { name: "shares", type: "uint256", indexed: false },
    ],
  },
  {
    type: "event",
    name: "VaultWithdrawal",
    inputs: [
      { name: "user", type: "address", indexed: true },
      { name: "vault", type: "address", indexed: true },
      { name: "amount", type: "uint256", indexed: false },
      { name: "shares", type: "uint256", indexed: false },
    ],
  },
  {
    type: "event",
    name: "YieldClaimed",
    inputs: [
      { name: "user", type: "address", indexed: true },
      { name: "amount", type: "uint256", indexed: false },
    ],
  },
] as const

/**
 * YieldRouter ABI - For advanced yield tracking
 * (Optional - most functions are called internally by ArunaCore)
 */
export const YIELD_ROUTER_ABI = [
  {
    type: "function",
    name: "claimYield",
    inputs: [],
    outputs: [{ name: "amount", type: "uint256" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "getClaimableYield",
    inputs: [{ name: "user", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getUserTotalYield",
    inputs: [{ name: "user", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getDistributionBreakdown",
    inputs: [{ name: "amount", type: "uint256" }],
    outputs: [
      { name: "investorAmount", type: "uint256" },
      { name: "publicGoodsAmount", type: "uint256" },
      { name: "protocolFeeAmount", type: "uint256" },
    ],
    stateMutability: "pure",
  },
] as const

/**
 * Octant Donation Module ABI - For public goods transparency
 */
export const OCTANT_MODULE_ABI = [
  {
    type: "function",
    name: "getBusinessContribution",
    inputs: [{ name: "business", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getEpochDonations",
    inputs: [{ name: "epoch", type: "uint256" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getCurrentEpoch",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getSupportedProjects",
    inputs: [],
    outputs: [{ name: "", type: "string[]" }],
    stateMutability: "view",
  },
] as const

// Export types for TypeScript
export type ArunaABI = typeof Aruna_ABI
export type ERC20ABI = typeof ERC20_ABI
export type YieldRouterABI = typeof YIELD_ROUTER_ABI
export type OctantModuleABI = typeof OCTANT_MODULE_ABI
