import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi"
import { CONTRACTS, ABIS } from "@/lib/contracts"
import { parseUnits, formatUnits } from "viem"

// Hook for reading USDC balance
export function useUSDCBalance(address?: `0x${string}`) {
  return useReadContract({
    address: CONTRACTS.USDC.address as `0x${string}`,
    abi: ABIS.ERC20,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  })
}

// Hook for approving USDC
export function useApproveUSDC() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const approve = (spender: `0x${string}`, amount: string) => {
    // Validate amount before parsing
    const amountNum = Number.parseFloat(amount)
    if (isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount: must be greater than 0")
    }

    try {
      const parsedAmount = parseUnits(amount, CONTRACTS.USDC.decimals)
      writeContract({
        address: CONTRACTS.USDC.address as `0x${string}`,
        abi: ABIS.ERC20,
        functionName: "approve",
        args: [spender, parsedAmount],
      })
    } catch (err) {
      console.error("Error approving USDC:", err)
      throw err
    }
  }

  return {
    approve,
    isPending,
    isConfirming,
    isSuccess,
    hash,
    error,
  }
}

// Hook for submitting invoice
export function useSubmitInvoice() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const submit = (customerName: string, invoiceAmount: string, dueDate: bigint) => {
    // Validate customer name
    if (!customerName || customerName.trim().length === 0) {
      throw new Error("Customer name is required")
    }

    // Validate amount
    const amountNum = Number.parseFloat(invoiceAmount)
    if (isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid invoice amount: must be greater than 0")
    }

    // Validate due date (must be positive)
    if (dueDate <= 0n) {
      throw new Error("Invalid due date")
    }

    try {
      const parsedAmount = parseUnits(invoiceAmount, CONTRACTS.USDC.decimals)
      writeContract({
        address: CONTRACTS.ARUNA_CORE.address as `0x${string}`,
        abi: ABIS.ARUNA_CORE,
        functionName: "submitInvoiceCommitment",
        args: [customerName, parsedAmount, dueDate],
      })
    } catch (err) {
      console.error("Error submitting invoice:", err)
      throw err
    }
  }

  return {
    submit,
    isPending,
    isConfirming,
    isSuccess,
    hash,
    error,
  }
}

// Hook for getting invoice details
export function useGetInvoice(tokenId?: bigint) {
  return useReadContract({
    address: CONTRACTS.ARUNA_CORE.address as `0x${string}`,
    abi: ABIS.ARUNA_CORE,
    functionName: "getInvoice",
    args: tokenId !== undefined ? [tokenId] : undefined,
    query: {
      enabled: tokenId !== undefined,
    },
  })
}

// Hook for getting user reputation
export function useUserReputation(address?: `0x${string}`) {
  return useReadContract({
    address: CONTRACTS.ARUNA_CORE.address as `0x${string}`,
    abi: ABIS.ARUNA_CORE,
    functionName: "userReputation",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  })
}

// Hook for depositing to Aave Vault
export function useDepositToAaveVault() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const deposit = (amount: string, receiver: `0x${string}`) => {
    // Validate amount
    const amountNum = Number.parseFloat(amount)
    if (isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid deposit amount: must be greater than 0")
    }

    // Validate receiver address
    if (!receiver || receiver === "0x0000000000000000000000000000000000000000") {
      throw new Error("Invalid receiver address")
    }

    try {
      const parsedAmount = parseUnits(amount, CONTRACTS.USDC.decimals)
      writeContract({
        address: CONTRACTS.AAVE_VAULT.address as `0x${string}`,
        abi: ABIS.AAVE_VAULT,
        functionName: "deposit",
        args: [parsedAmount, receiver],
      })
    } catch (err) {
      console.error("Error depositing to Aave:", err)
      throw err
    }
  }

  return {
    deposit,
    isPending,
    isConfirming,
    isSuccess,
    hash,
    error,
  }
}

// Hook for depositing to Morpho Vault
export function useDepositToMorphoVault() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const deposit = (amount: string, receiver: `0x${string}`) => {
    // Validate amount
    const amountNum = Number.parseFloat(amount)
    if (isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid deposit amount: must be greater than 0")
    }

    // Validate receiver address
    if (!receiver || receiver === "0x0000000000000000000000000000000000000000") {
      throw new Error("Invalid receiver address")
    }

    try {
      const parsedAmount = parseUnits(amount, CONTRACTS.USDC.decimals)
      writeContract({
        address: CONTRACTS.MORPHO_VAULT.address as `0x${string}`,
        abi: ABIS.MORPHO_VAULT,
        functionName: "deposit",
        args: [parsedAmount, receiver],
      })
    } catch (err) {
      console.error("Error depositing to Morpho:", err)
      throw err
    }
  }

  return {
    deposit,
    isPending,
    isConfirming,
    isSuccess,
    hash,
    error,
  }
}

// Hook for getting vault balance (shares)
export function useVaultBalance(vaultAddress: `0x${string}`, userAddress?: `0x${string}`) {
  return useReadContract({
    address: vaultAddress,
    abi: ABIS.AAVE_VAULT, // Same for both vaults (ERC4626)
    functionName: "balanceOf",
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress,
    },
  })
}

// Hook for withdrawing from vault
export function useWithdrawFromVault(isAave: boolean) {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const withdraw = (amount: string, receiver: `0x${string}`, owner: `0x${string}`) => {
    const parsedAmount = parseUnits(amount, CONTRACTS.USDC.decimals)
    const vaultAddress = isAave ? CONTRACTS.AAVE_VAULT.address : CONTRACTS.MORPHO_VAULT.address
    const vaultABI = isAave ? ABIS.AAVE_VAULT : ABIS.MORPHO_VAULT

    writeContract({
      address: vaultAddress as `0x${string}`,
      abi: vaultABI,
      functionName: "withdraw",
      args: [parsedAmount, receiver, owner],
    })
  }

  return {
    withdraw,
    isPending,
    isConfirming,
    isSuccess,
    hash,
    error,
  }
}

// Hook for getting claimable yield
export function useClaimableYield(address?: `0x${string}`) {
  const result = useReadContract({
    address: CONTRACTS.YIELD_ROUTER.address as `0x${string}`,
    abi: ABIS.YIELD_ROUTER,
    functionName: "getClaimableYield",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  })

  return {
    ...result,
    data: result.data ? formatUnits(result.data as bigint, CONTRACTS.USDC.decimals) : "0",
  }
}

// Hook for claiming yield
export function useClaimYield() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const claim = () => {
    writeContract({
      address: CONTRACTS.YIELD_ROUTER.address as `0x${string}`,
      abi: ABIS.YIELD_ROUTER,
      functionName: "claimYield",
    })
  }

  return {
    claim,
    isPending,
    isConfirming,
    isSuccess,
    hash,
    error,
  }
}

// Hook for getting total donations (public goods)
export function useTotalDonations() {
  return useReadContract({
    address: CONTRACTS.OCTANT_MODULE.address as `0x${string}`,
    abi: ABIS.OCTANT_MODULE,
    functionName: "totalDonated",
  })
}

// Hook for getting business contribution
export function useBusinessContribution(address?: `0x${string}`) {
  return useReadContract({
    address: CONTRACTS.OCTANT_MODULE.address as `0x${string}`,
    abi: ABIS.OCTANT_MODULE,
    functionName: "businessContributions",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  })
}

// Utility function to format USDC amount
export function formatUSDC(value: bigint | string): string {
  if (typeof value === "string") return value
  return formatUnits(value, CONTRACTS.USDC.decimals)
}

// Utility function to parse USDC amount
export function parseUSDC(value: string): bigint {
  return parseUnits(value, CONTRACTS.USDC.decimals)
}

// ============================================================================
// BUSINESS USER HOOKS - Invoice Management
// ============================================================================

// Hook for getting user's invoice list (tokenIds)
export function useUserInvoices(address?: `0x${string}`) {
  return useReadContract({
    address: CONTRACTS.ARUNA_CORE.address as `0x${string}`,
    abi: ABIS.ARUNA_CORE,
    functionName: "getUserCommitments",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  })
}

// Hook for getting specific invoice details
export function useInvoiceDetails(tokenId?: bigint) {
  return useReadContract({
    address: CONTRACTS.ARUNA_CORE.address as `0x${string}`,
    abi: ABIS.ARUNA_CORE,
    functionName: "getCommitment",
    args: tokenId !== undefined ? [tokenId] : undefined,
    query: {
      enabled: tokenId !== undefined,
    },
  })
}

// Hook for settling invoice
export function useSettleInvoice() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const settle = (tokenId: bigint) => {
    if (tokenId <= 0n) {
      throw new Error("Invalid token ID")
    }

    try {
      writeContract({
        address: CONTRACTS.ARUNA_CORE.address as `0x${string}`,
        abi: ABIS.ARUNA_CORE,
        functionName: "settleInvoice",
        args: [tokenId],
      })
    } catch (err) {
      console.error("Error settling invoice:", err)
      throw err
    }
  }

  return {
    settle,
    isPending,
    isConfirming,
    isSuccess,
    hash,
    error,
  }
}

// ============================================================================
// INVESTOR HOOKS - Advanced Vault Operations
// ============================================================================

// Hook for converting shares to assets (USD value)
export function useConvertToAssets(vaultAddress: `0x${string}`, shares?: bigint) {
  return useReadContract({
    address: vaultAddress,
    abi: ABIS.AAVE_VAULT, // Same interface for both vaults (ERC4626)
    functionName: "convertToAssets",
    args: shares !== undefined ? [shares] : undefined,
    query: {
      enabled: shares !== undefined && shares > 0n,
    },
  })
}

// Hook for getting max withdrawable amount
export function useMaxWithdraw(vaultAddress: `0x${string}`, owner?: `0x${string}`) {
  return useReadContract({
    address: vaultAddress,
    abi: ABIS.AAVE_VAULT, // Same interface for both vaults (ERC4626)
    functionName: "maxWithdraw",
    args: owner ? [owner] : undefined,
    query: {
      enabled: !!owner,
    },
  })
}

// Hook for getting vault total assets
export function useVaultTotalAssets(vaultAddress: `0x${string}`) {
  return useReadContract({
    address: vaultAddress,
    abi: ABIS.AAVE_VAULT, // Same interface for both vaults (ERC4626)
    functionName: "totalAssets",
  })
}

// ============================================================================
// UTILITY HOOKS
// ============================================================================

// Hook for getting current timestamp (for due date validation)
export function useCurrentTimestamp() {
  return Math.floor(Date.now() / 1000)
}
