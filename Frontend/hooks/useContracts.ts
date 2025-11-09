import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi"
import { CONTRACTS, ABIS } from "@/lib/contracts"
import { parseUnits, formatUnits } from "viem"
import { useEffect } from "react"

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
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
    query: {
      enabled: !!hash, // Only run when we have a hash
      refetchInterval: 1000, // Poll every second instead of subscribing
      retry: 3, // Retry 3 times on failure
    },
  })

  // Debug logging
  useEffect(() => {
    if (hash || isPending || isConfirming || isSuccess || error) {
      console.log("🔄 Approval status update:", {
        hash: hash ? hash.substring(0, 10) + "..." : "none",
        fullHash: hash,
        isPending,
        isConfirming,
        isSuccess,
        error: error?.message
      })

      // Log BaseScan link when hash appears
      if (hash && !isSuccess) {
        console.log(`🔗 Check transaction on BaseScan: https://sepolia.basescan.org/tx/${hash}`)
      }
    }
  }, [hash, isPending, isConfirming, isSuccess, error])

  const approve = (spender: `0x${string}`, amount: string) => {
    // Validate amount before parsing
    const amountNum = Number.parseFloat(amount)
    if (isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount: must be greater than 0")
    }

    try {
      const parsedAmount = parseUnits(amount, CONTRACTS.USDC.decimals)

      console.log("✅ Approving USDC:", {
        token: CONTRACTS.USDC.address,
        spender,
        amount,
        parsedAmount: parsedAmount.toString(),
      })

      writeContract({
        address: CONTRACTS.USDC.address as `0x${string}`,
        abi: ABIS.ERC20,
        functionName: "approve",
        args: [spender, parsedAmount],
        gas: 100000n, // Set explicit gas limit for approval
      })

      console.log("📤 Approval writeContract called - hash will appear in data property")
    } catch (err: any) {
      console.error("❌ Error approving USDC:", {
        message: err?.message,
        code: err?.code,
        data: err?.data,
        cause: err?.cause,
        shortMessage: err?.shortMessage,
      })
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
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
    query: {
      enabled: !!hash,
      refetchInterval: 1000, // Poll every second instead of subscribing
      retry: 3, // Retry 3 times on failure
    },
  })

  // Debug logging
  useEffect(() => {
    if (hash || isPending || isConfirming || isSuccess || error) {
      console.log("🔄 Invoice Submit status update:", {
        hash: hash ? hash.substring(0, 10) + "..." : "none",
        fullHash: hash,
        isPending,
        isConfirming,
        isSuccess,
        error: error?.message
      })

      if (hash && !isSuccess) {
        console.log(`🔗 Check invoice on BaseScan: https://sepolia.basescan.org/tx/${hash}`)
      }
    }
  }, [hash, isPending, isConfirming, isSuccess, error])

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

      console.log("📝 Submitting invoice commitment:", {
        contract: CONTRACTS.ARUNA_CORE.address,
        customerName,
        invoiceAmount,
        parsedAmount: parsedAmount.toString(),
        dueDate: dueDate.toString(),
        function: "submitInvoiceCommitment",
      })

      writeContract({
        address: CONTRACTS.ARUNA_CORE.address as `0x${string}`,
        abi: ABIS.ARUNA_CORE,
        functionName: "submitInvoiceCommitment",
        args: [customerName, parsedAmount, dueDate],
        gas: 500000n, // Set explicit gas limit
      })

      console.log("📤 Invoice submit writeContract called - waiting for hash")
    } catch (err: any) {
      console.error("❌ Error submitting invoice:", {
        message: err?.message,
        code: err?.code,
        data: err?.data,
        cause: err?.cause,
        shortMessage: err?.shortMessage,
      })
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
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
    query: {
      enabled: !!hash,
      refetchInterval: 1000, // Poll every second instead of subscribing
      retry: 3, // Retry 3 times on failure
    },
  })

  // Debug logging
  useEffect(() => {
    if (hash || isPending || isConfirming || isSuccess || error) {
      console.log("🔄 Aave Deposit status update:", {
        hash: hash ? hash.substring(0, 10) + "..." : "none",
        fullHash: hash,
        isPending,
        isConfirming,
        isSuccess,
        error: error?.message
      })

      if (hash && !isSuccess) {
        console.log(`🔗 Check deposit on BaseScan: https://sepolia.basescan.org/tx/${hash}`)
      }
    }
  }, [hash, isPending, isConfirming, isSuccess, error])

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

      console.log("💰 Depositing to Aave Vault:", {
        contract: CONTRACTS.AAVE_VAULT.address,
        amount,
        parsedAmount: parsedAmount.toString(),
        receiver,
        function: "deposit",
      })

      writeContract({
        address: CONTRACTS.AAVE_VAULT.address as `0x${string}`,
        abi: ABIS.AAVE_VAULT,
        functionName: "deposit",
        args: [parsedAmount, receiver],
        gas: 500000n, // Set explicit gas limit
      })

      console.log("📤 Deposit writeContract called - waiting for hash")
    } catch (err: any) {
      console.error("❌ Error depositing to Aave:", {
        message: err?.message,
        code: err?.code,
        data: err?.data,
        cause: err?.cause,
        shortMessage: err?.shortMessage,
      })
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
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
    query: {
      enabled: !!hash,
      refetchInterval: 1000, // Poll every second instead of subscribing
      retry: 3, // Retry 3 times on failure
    },
  })

  // Debug logging
  useEffect(() => {
    if (hash || isPending || isConfirming || isSuccess || error) {
      console.log("🔄 Morpho Deposit status update:", {
        hash: hash ? hash.substring(0, 10) + "..." : "none",
        fullHash: hash,
        isPending,
        isConfirming,
        isSuccess,
        error: error?.message
      })

      if (hash && !isSuccess) {
        console.log(`🔗 Check deposit on BaseScan: https://sepolia.basescan.org/tx/${hash}`)
      }
    }
  }, [hash, isPending, isConfirming, isSuccess, error])

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

      console.log("💰 Depositing to Morpho Vault:", {
        contract: CONTRACTS.MORPHO_VAULT.address,
        amount,
        parsedAmount: parsedAmount.toString(),
        receiver,
        function: "deposit",
      })

      writeContract({
        address: CONTRACTS.MORPHO_VAULT.address as `0x${string}`,
        abi: ABIS.MORPHO_VAULT,
        functionName: "deposit",
        args: [parsedAmount, receiver],
        gas: 500000n, // Set explicit gas limit
      })

      console.log("📤 Deposit writeContract called - waiting for hash")
    } catch (err: any) {
      console.error("❌ Error depositing to Morpho:", {
        message: err?.message,
        code: err?.code,
        data: err?.data,
        cause: err?.cause,
        shortMessage: err?.shortMessage,
      })
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
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
    query: {
      enabled: !!hash,
      refetchInterval: 1000, // Poll every second instead of subscribing
      retry: 3, // Retry 3 times on failure
    },
  })

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
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
    query: {
      enabled: !!hash,
      refetchInterval: 1000, // Poll every second instead of subscribing
      retry: 3, // Retry 3 times on failure
    },
  })

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

// ============================================================================
// PUBLIC GOODS HOOKS - Octant Integration
// ============================================================================

// Hook for getting total donations (public goods)
export function useTotalDonations() {
  return useReadContract({
    address: CONTRACTS.OCTANT_MODULE.address as `0x${string}`,
    abi: ABIS.OCTANT_MODULE,
    functionName: "totalDonated",
  })
}

// Hook for getting current epoch donations
export function useCurrentEpochDonations() {
  return useReadContract({
    address: CONTRACTS.OCTANT_MODULE.address as `0x${string}`,
    abi: ABIS.OCTANT_MODULE,
    functionName: "currentEpochDonations",
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

// Hook for getting current epoch
export function useCurrentEpoch() {
  return useReadContract({
    address: CONTRACTS.OCTANT_MODULE.address as `0x${string}`,
    abi: ABIS.OCTANT_MODULE,
    functionName: "getCurrentEpoch",
  })
}

// Hook for getting donations per epoch
export function useEpochDonations(epoch?: bigint) {
  return useReadContract({
    address: CONTRACTS.OCTANT_MODULE.address as `0x${string}`,
    abi: ABIS.OCTANT_MODULE,
    functionName: "donationsPerEpoch",
    args: epoch !== undefined ? [epoch] : undefined,
    query: {
      enabled: epoch !== undefined,
    },
  })
}

// Hook for getting supported projects
export function useSupportedProjects() {
  return useReadContract({
    address: CONTRACTS.OCTANT_MODULE.address as `0x${string}`,
    abi: ABIS.OCTANT_MODULE,
    functionName: "getSupportedProjects",
  })
}

// ============================================================================
// VAULT HARVEST HOOKS - Trigger Yield Distribution
// ============================================================================

// Hook for harvesting yield from Aave Vault
export function useHarvestAaveYield() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
    query: {
      enabled: !!hash,
      refetchInterval: 1000,
      retry: 3,
    },
  })

  const harvest = () => {
    try {
      console.log("🌾 Harvesting Aave vault yield...")
      writeContract({
        address: CONTRACTS.AAVE_VAULT.address as `0x${string}`,
        abi: ABIS.AAVE_VAULT,
        functionName: "harvestYield",
        gas: 500000n,
      })
    } catch (err) {
      console.error("Error harvesting Aave yield:", err)
      throw err
    }
  }

  return {
    harvest,
    isPending,
    isConfirming,
    isSuccess,
    hash,
    error,
  }
}

// Hook for harvesting yield from Morpho Vault
export function useHarvestMorphoYield() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
    query: {
      enabled: !!hash,
      refetchInterval: 1000,
      retry: 3,
    },
  })

  const harvest = () => {
    try {
      console.log("🌾 Harvesting Morpho vault yield...")
      writeContract({
        address: CONTRACTS.MORPHO_VAULT.address as `0x${string}`,
        abi: ABIS.MORPHO_VAULT,
        functionName: "harvestYield",
        gas: 500000n,
      })
    } catch (err) {
      console.error("Error harvesting Morpho yield:", err)
      throw err
    }
  }

  return {
    harvest,
    isPending,
    isConfirming,
    isSuccess,
    hash,
    error,
  }
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
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
    query: {
      enabled: !!hash,
      refetchInterval: 1000, // Poll every second instead of subscribing
      retry: 3, // Retry 3 times on failure
    },
  })

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
