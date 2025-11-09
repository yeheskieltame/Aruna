"use client"

import { useState, useCallback, useEffect } from "react"
import type { TransactionStep } from "@/components/transaction-modal"

interface UseTransactionModalOptions {
  onSuccess?: () => void
  onError?: (error: string) => void
}

export function useTransactionModal(options: UseTransactionModalOptions = {}) {
  const [isOpen, setIsOpen] = useState(false)
  const [step, setStep] = useState<TransactionStep>("idle")
  const [txHash, setTxHash] = useState<string | undefined>()
  const [error, setError] = useState<string | undefined>()

  const openModal = useCallback(() => {
    setIsOpen(true)
    setStep("idle")
    setTxHash(undefined)
    setError(undefined)
  }, [])

  const closeModal = useCallback(() => {
    setIsOpen(false)
    setStep("idle")
    setTxHash(undefined)
    setError(undefined)
  }, [])

  const setApproving = useCallback(() => {
    setStep("approving")
    setError(undefined)
  }, [])

  const setConfirming = useCallback(() => {
    setStep("confirming")
    setError(undefined)
  }, [])

  const setPending = useCallback((hash?: string) => {
    setStep("pending")
    if (hash) setTxHash(hash)
    setError(undefined)
  }, [])

  const setSuccess = useCallback(
    (hash?: string) => {
      setStep("success")
      if (hash) setTxHash(hash)
      setError(undefined)
      if (options.onSuccess) {
        options.onSuccess()
      }
    },
    [options]
  )

  const setErrorState = useCallback(
    (errorMessage: string) => {
      setStep("error")
      setError(errorMessage)
      if (options.onError) {
        options.onError(errorMessage)
      }
    },
    [options]
  )

  const reset = useCallback(() => {
    setStep("idle")
    setTxHash(undefined)
    setError(undefined)
  }, [])

  return {
    // State
    isOpen,
    step,
    txHash,
    error,

    // Actions
    openModal,
    closeModal,
    setApproving,
    setConfirming,
    setPending,
    setSuccess,
    setError: setErrorState,
    reset,
  }
}

/**
 * Hook untuk handle transaction flow dengan approval + submit
 */
export function useApprovalTransaction() {
  const modal = useTransactionModal()
  const [approvalCompleted, setApprovalCompleted] = useState(false)

  const startApproval = useCallback(() => {
    modal.openModal()
    modal.setApproving()
    setApprovalCompleted(false)
  }, [modal])

  const approvalSuccess = useCallback(() => {
    setApprovalCompleted(true)
    modal.setConfirming()
  }, [modal])

  const startSubmit = useCallback(() => {
    modal.setConfirming()
  }, [modal])

  const submitPending = useCallback(
    (hash: string) => {
      modal.setPending(hash)
    },
    [modal]
  )

  const submitSuccess = useCallback(
    (hash?: string) => {
      modal.setSuccess(hash)
      setApprovalCompleted(false)
    },
    [modal]
  )

  const transactionError = useCallback(
    (error: Error | string) => {
      const errorMessage = typeof error === "string" ? error : error.message
      modal.setError(parseErrorMessage(errorMessage))
      setApprovalCompleted(false)
    },
    [modal]
  )

  return {
    ...modal,
    approvalCompleted,
    startApproval,
    approvalSuccess,
    startSubmit,
    submitPending,
    submitSuccess,
    transactionError,
  }
}

/**
 * Parse error messages to be more user-friendly
 */
function parseErrorMessage(error: string): string {
  if (error.includes("User rejected") || error.includes("user rejected")) {
    return "Transaction was rejected by user"
  }
  if (error.includes("Port disconnected") || error.includes("port disconnected")) {
    return "Wallet connection interrupted. Your transaction may still be processing. Please check your wallet or refresh the page."
  }
  if (error.includes("Internal JSON-RPC error")) {
    return "Network communication error. This could be due to insufficient balance, network issues, or wallet connection problems. Please check your USDC balance and try again."
  }
  if (error.includes("insufficient funds")) {
    return "Insufficient funds for gas fees or token balance"
  }
  if (error.includes("nonce")) {
    return "Transaction nonce issue. Please try again."
  }
  if (error.includes("gas required exceeds allowance")) {
    return "Gas limit exceeded. Try increasing gas limit."
  }
  if (error.includes("execution reverted")) {
    // Try to extract revert reason
    const match = error.match(/execution reverted: (.+?)(?:\n|$)/)
    if (match) {
      return `Transaction failed: ${match[1]}`
    }
    return "Transaction was reverted by the contract"
  }
  if (error.includes("network")) {
    return "Network error. Please check your connection and try again."
  }
  if (error.includes("timeout")) {
    return "Transaction timeout. Please try again."
  }
  if (error.includes("exceeds balance") || error.includes("insufficient balance")) {
    return "Insufficient USDC balance. Please get testnet USDC from the faucet."
  }

  // Return original if no pattern matches, but truncate if too long
  return error.length > 200 ? error.substring(0, 200) + "..." : error
}
