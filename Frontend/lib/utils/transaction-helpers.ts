/**
 * Transaction Helper Utilities
 * Provides utilities for handling blockchain transactions
 */

import { formatUnits } from "viem"

/**
 * Transaction states
 */
export type TransactionState = "idle" | "approving" | "signing" | "pending" | "success" | "error"

/**
 * Format transaction hash for display
 */
export function formatTxHash(hash: string, length = 10): string {
  if (!hash) return ""
  return `${hash.slice(0, length)}...${hash.slice(-8)}`
}

/**
 * Get explorer URL for transaction
 */
export function getTxExplorerUrl(hash: string, chainId: number = 84532): string {
  const explorers: Record<number, string> = {
    84532: "https://sepolia.basescan.org/tx", // Base Sepolia
    8453: "https://basescan.org/tx", // Base Mainnet
  }

  const baseUrl = explorers[chainId] || explorers[84532]
  return `${baseUrl}/${hash}`
}

/**
 * Get explorer URL for address
 */
export function getAddressExplorerUrl(address: string, chainId: number = 84532): string {
  const explorers: Record<number, string> = {
    84532: "https://sepolia.basescan.org/address", // Base Sepolia
    8453: "https://basescan.org/address", // Base Mainnet
  }

  const baseUrl = explorers[chainId] || explorers[84532]
  return `${baseUrl}/${address}`
}

/**
 * Show transaction pending toast
 * Note: Import and use this in your components, not in utility files
 */
export function getPendingTxMessage(hash: string, message: string = "Transaction submitted") {
  return {
    title: message,
    description: `Transaction hash: ${formatTxHash(hash)}\nView on BaseScan: ${getTxExplorerUrl(hash)}`,
  }
}

/**
 * Show transaction success toast
 * Note: Import and use this in your components, not in utility files
 */
export function getSuccessTxMessage(hash: string, message: string = "Transaction successful") {
  return {
    title: "✅ " + message,
    description: `Your transaction has been confirmed!\nView on BaseScan: ${getTxExplorerUrl(hash)}`,
  }
}

/**
 * Show transaction error toast
 * Note: Import and use this in your components, not in utility files
 */
export function getErrorTxMessage(error: Error | string) {
  const errorMessage = typeof error === "string" ? error : error.message

  // Parse common errors
  let userFriendlyMessage = errorMessage

  if (errorMessage.includes("User rejected")) {
    userFriendlyMessage = "Transaction was rejected"
  } else if (errorMessage.includes("insufficient funds")) {
    userFriendlyMessage = "Insufficient funds for gas fees"
  } else if (errorMessage.includes("nonce")) {
    userFriendlyMessage = "Transaction nonce issue. Please try again."
  }

  return {
    title: "❌ Transaction failed",
    description: userFriendlyMessage,
  }
}

/**
 * Format token amount for display
 */
export function formatTokenAmount(amount: bigint | string, decimals: number = 6, maxDecimals: number = 2): string {
  if (typeof amount === "string") return amount

  const formatted = formatUnits(amount, decimals)
  const num = Number.parseFloat(formatted)

  // Handle very small numbers
  if (num < 0.01 && num > 0) {
    return "< 0.01"
  }

  return num.toLocaleString("en-US", {
    minimumFractionDigits: 0,
    maximumFractionDigits: maxDecimals,
  })
}

/**
 * Calculate collateral amount (10% of invoice)
 */
export function calculateCollateral(invoiceAmount: number | string): number {
  const amount = typeof invoiceAmount === "string" ? Number.parseFloat(invoiceAmount) : invoiceAmount
  return amount * 0.1
}

/**
 * Calculate grant amount (3% of invoice)
 */
export function calculateGrant(invoiceAmount: number | string): number {
  const amount = typeof invoiceAmount === "string" ? Number.parseFloat(invoiceAmount) : invoiceAmount
  return amount * 0.03
}

/**
 * Calculate net collateral (10% - 3% = 7%)
 */
export function calculateNetCollateral(invoiceAmount: number | string): number {
  const amount = typeof invoiceAmount === "string" ? Number.parseFloat(invoiceAmount) : invoiceAmount
  return amount * 0.07
}

/**
 * Validate Ethereum address
 */
export function isValidAddress(address: string): boolean {
  return /^0x[a-fA-F0-9]{40}$/.test(address)
}

/**
 * Shorten address for display
 */
export function shortenAddress(address: string, chars = 4): string {
  if (!isValidAddress(address)) return address
  return `${address.slice(0, chars + 2)}...${address.slice(-chars)}`
}

/**
 * Format date for invoice display
 */
export function formatInvoiceDate(timestamp: number): string {
  const date = new Date(timestamp * 1000)
  return date.toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  })
}

/**
 * Check if invoice is overdue
 */
export function isInvoiceOverdue(dueDateTimestamp: number): boolean {
  const now = Math.floor(Date.now() / 1000)
  return now > dueDateTimestamp
}

/**
 * Get days until due date
 */
export function getDaysUntilDue(dueDateTimestamp: number): number {
  const now = Math.floor(Date.now() / 1000)
  const secondsUntilDue = dueDateTimestamp - now
  return Math.floor(secondsUntilDue / 86400)
}

/**
 * Format APY percentage
 */
export function formatAPY(apy: number): string {
  return `${(apy * 100).toFixed(2)}%`
}

/**
 * Calculate estimated yield
 */
export function calculateEstimatedYield(principal: number, apy: number, days: number = 365): number {
  return (principal * apy * days) / 365
}

/**
 * Wait for multiple seconds (for testing/demo)
 */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}
