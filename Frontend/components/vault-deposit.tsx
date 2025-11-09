"use client"

import type React from "react"

import { useState, useEffect, useRef } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { useAccount } from "wagmi"
import {
  useApproveUSDC,
  useDepositToAaveVault,
  useDepositToMorphoVault,
  useUSDCBalance,
  formatUSDC,
} from "@/hooks/useContracts"
import { CONTRACTS } from "@/lib/contracts"
import { TransactionModal, VaultDepositSuccessDetails } from "@/components/transaction-modal"
import { useApprovalTransaction } from "@/hooks/useTransactionModal"

interface VaultDepositProps {
  onSuccess?: () => void
}

export default function VaultDeposit({ onSuccess }: VaultDepositProps) {
  const { address } = useAccount()
  const [vaultType, setVaultType] = useState("aave")
  const [amount, setAmount] = useState("")
  const [tokenType, setTokenType] = useState("usdc")
  const [error, setError] = useState("")
  const hasDepositedRef = useRef(false)

  const modal = useApprovalTransaction()

  // Fetch USDC balance
  const { data: usdcBalance } = useUSDCBalance(address)
  const usdcBalanceFormatted = usdcBalance ? formatUSDC(usdcBalance as bigint) : "0"

  // Hooks for transactions
  const { approve, isPending: isApproving, isSuccess: isApproved, hash: approvalHash, error: approveError } = useApproveUSDC()
  const { deposit: depositAave, isPending: isDepositingAave, isSuccess: isDepositedAave, hash: depositAaveHash, error: depositAaveError } = useDepositToAaveVault()
  const { deposit: depositMorpho, isPending: isDepositingMorpho, isSuccess: isDepositedMorpho, hash: depositMorphoHash, error: depositMorphoError } = useDepositToMorphoVault()

  // Handle approval success
  useEffect(() => {
    console.log("👀 Watching approval state:", {
      isApproved,
      approvalHash,
      isApproving,
      approveError: approveError?.message,
      hasDeposited: hasDepositedRef.current
    })

    if (isApproved && approvalHash && !hasDepositedRef.current) {
      console.log("✅ USDC Approval confirmed:", { hash: approvalHash })
      modal.approvalSuccess()
    }
  }, [isApproved, approvalHash, isApproving, approveError])

  // Auto-deposit after approval
  useEffect(() => {
    console.log("🔍 Checking auto-deposit:", {
      approvalCompleted: modal.approvalCompleted,
      isDepositingAave,
      isDepositingMorpho,
      isDepositedAave,
      isDepositedMorpho,
      address,
      amount,
      vaultType,
      hasDeposited: hasDepositedRef.current,
    })

    if (modal.approvalCompleted && !isDepositingAave && !isDepositingMorpho && !isDepositedAave && !isDepositedMorpho && !hasDepositedRef.current && address && amount) {
      const amountNum = Number.parseFloat(amount)
      console.log("🚀 Auto-depositing to vault:", { vaultType, amount, amountNum })

      if (amountNum > 0) {
        hasDepositedRef.current = true
        modal.startSubmit()

        try {
          if (vaultType === "aave") {
            console.log("📝 Calling depositAave:", { amount, receiver: address })
            depositAave(amount, address)
          } else {
            console.log("📝 Calling depositMorpho:", { amount, receiver: address })
            depositMorpho(amount, address)
          }
        } catch (err: any) {
          console.error("❌ Error in auto-deposit:", err)
          modal.transactionError(err)
          hasDepositedRef.current = false
        }
      }
    }
  }, [modal.approvalCompleted, isDepositingAave, isDepositingMorpho, isDepositedAave, isDepositedMorpho, address, amount, vaultType])

  // Handle deposit pending
  useEffect(() => {
    const hash = depositAaveHash || depositMorphoHash
    if ((isDepositingAave || isDepositingMorpho) && hash) {
      modal.submitPending(hash)
    }
  }, [isDepositingAave, isDepositingMorpho, depositAaveHash, depositMorphoHash])

  // Detect if transaction was rejected (isPending went from true to false without hash)
  useEffect(() => {
    const wasDepositing = hasDepositedRef.current
    const notDepositingAnymore = !isDepositingAave && !isDepositingMorpho
    const noHash = !depositAaveHash && !depositMorphoHash
    const noSuccess = !isDepositedAave && !isDepositedMorpho

    if (wasDepositing && notDepositingAnymore && noHash && noSuccess && modal.step === "confirming") {
      console.log("⚠️ Deposit transaction likely rejected or failed")
      modal.transactionError("Transaction was rejected or failed to send. Please try again.")
      hasDepositedRef.current = false
    }
  }, [isDepositingAave, isDepositingMorpho, depositAaveHash, depositMorphoHash, isDepositedAave, isDepositedMorpho, modal.step])

  // Handle deposit success
  useEffect(() => {
    const hash = depositAaveHash || depositMorphoHash
    if ((isDepositedAave || isDepositedMorpho) && hash) {
      modal.submitSuccess(hash)
      setTimeout(() => {
        setAmount("")
        hasDepositedRef.current = false // Reset for next transaction
        if (onSuccess) onSuccess()
      }, 1000)
    }
  }, [isDepositedAave, isDepositedMorpho, depositAaveHash, depositMorphoHash, onSuccess])

  // Handle errors
  useEffect(() => {
    if (approveError) {
      modal.transactionError(approveError)
      setError(approveError.message)
      hasDepositedRef.current = false // Reset on error
    }
  }, [approveError])

  useEffect(() => {
    if (depositAaveError) {
      modal.transactionError(depositAaveError)
      setError(depositAaveError.message)
      hasDepositedRef.current = false // Reset on error
    }
  }, [depositAaveError])

  useEffect(() => {
    if (depositMorphoError) {
      modal.transactionError(depositMorphoError)
      setError(depositMorphoError.message)
      hasDepositedRef.current = false // Reset on error
    }
  }, [depositMorphoError])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")
    hasDepositedRef.current = false // Reset for new transaction

    if (!address) {
      setError("Please connect your wallet")
      return
    }

    // Validate amount
    const amountNum = Number.parseFloat(amount)
    if (isNaN(amountNum) || amountNum <= 0) {
      setError("Please enter a valid amount greater than 0")
      return
    }

    // Check minimum amount (lowered for testnet)
    if (amountNum < 1) {
      setError("Minimum deposit amount is 1 USDC")
      return
    }

    // Check if user has sufficient balance
    const balance = Number.parseFloat(usdcBalanceFormatted)
    if (amountNum > balance) {
      setError(`Insufficient balance. You have ${balance.toFixed(2)} USDC`)
      return
    }

    try {
      // Start approval process
      console.log("🚀 Starting approval process:", {
        vaultType,
        amount,
        address,
        vaultAddress: vaultType === "aave" ? CONTRACTS.AAVE_VAULT.address : CONTRACTS.MORPHO_VAULT.address
      })

      modal.startApproval()
      const vaultAddress = vaultType === "aave" ? CONTRACTS.AAVE_VAULT.address : CONTRACTS.MORPHO_VAULT.address

      approve(vaultAddress, amount)

      console.log("✅ Approve function called - waiting for hash in useEffect")
    } catch (err: any) {
      console.error("❌ Error in handleSubmit:", {
        message: err?.message,
        code: err?.code,
        name: err?.name,
        stack: err?.stack
      })

      // Handle user rejection
      if (err?.message?.includes("User rejected") || err?.code === 4001) {
        setError("Transaction was rejected. Please try again.")
        modal.closeModal()
      } else {
        setError(err?.message || "Transaction failed. Please try again.")
        modal.transactionError(err)
      }
    }
  }

  const depositAmount = Number.parseFloat(amount) || 0
  const apy = vaultType === "aave" ? 0.065 : 0.082
  const estimatedYield = depositAmount * apy
  const vaultName = vaultType === "aave" ? "Aave v3" : "Morpho"

  return (
    <>
      <TransactionModal
        isOpen={modal.isOpen}
        onClose={modal.closeModal}
        step={modal.step}
        txHash={modal.txHash}
        error={modal.error}
        title={`Deposit to ${vaultName} Vault`}
        approvalMessage={`Approve ${depositAmount.toFixed(2)} USDC for ${vaultName} vault`}
        confirmMessage="Depositing your USDC to the vault..."
        pendingMessage="Your deposit is being processed. You'll receive vault shares shortly!"
        successMessage={`Successfully deposited to ${vaultName} vault!`}
        successDetails={
          amount && (
            <VaultDepositSuccessDetails
              vaultName={vaultName}
              depositAmount={depositAmount}
              sharesReceived={(depositAmount * 1).toFixed(6)}
              apy={apy}
              estimatedYield={estimatedYield}
            />
          )
        }
        onSuccess={() => {
          modal.closeModal()
        }}
      />

      <Card className="p-6 sm:p-8 max-w-2xl">
        <h2 className="text-2xl font-bold mb-6">Deposit to Vault</h2>

        {error && !modal.isOpen && (
          <div className="mb-4 p-4 bg-red-50 dark:bg-red-900/20 text-red-600 rounded-lg text-sm">{error}</div>
        )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Vault Selection */}
        <div>
          <Label className="text-base font-semibold mb-4 block">Select Vault</Label>
          <RadioGroup value={vaultType} onValueChange={setVaultType}>
            <div className="space-y-3">
              <div className="flex items-center space-x-2 p-4 border border-border rounded-lg cursor-pointer hover:bg-muted/50 transition">
                <RadioGroupItem value="aave" id="aave" />
                <Label htmlFor="aave" className="flex-1 cursor-pointer">
                  <div className="font-semibold">Aave v3 Vault</div>
                  <div className="text-sm text-muted-foreground">6.5% APY • Stable & Proven</div>
                </Label>
              </div>
              <div className="flex items-center space-x-2 p-4 border border-border rounded-lg cursor-pointer hover:bg-muted/50 transition">
                <RadioGroupItem value="morpho" id="morpho" />
                <Label htmlFor="morpho" className="flex-1 cursor-pointer">
                  <div className="font-semibold">Morpho Vault</div>
                  <div className="text-sm text-muted-foreground">8.2% APY • Optimized Yields</div>
                </Label>
              </div>
            </div>
          </RadioGroup>
        </div>

        {/* Token Selection */}
        <div>
          <Label className="text-base font-semibold mb-4 block">Token</Label>
          <RadioGroup value={tokenType} onValueChange={setTokenType}>
            <div className="flex gap-4 flex-wrap">
              {["usdc", "dai", "usdt"].map((token) => (
                <div key={token} className="flex items-center space-x-2">
                  <RadioGroupItem value={token} id={token} />
                  <Label htmlFor={token} className="cursor-pointer uppercase font-medium text-sm">
                    {token}
                  </Label>
                </div>
              ))}
            </div>
          </RadioGroup>
        </div>

        {/* Amount */}
        <div>
          <div className="flex justify-between items-center mb-2">
            <Label htmlFor="amount">Amount</Label>
            <span className="text-xs text-muted-foreground">Balance: {usdcBalanceFormatted} USDC</span>
          </div>
          <Input
            id="amount"
            type="number"
            placeholder="10"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            required
            min="1"
            step="0.01"
            className="mt-2"
          />
          <p className="text-xs text-muted-foreground mt-2">Minimum: 1 {tokenType.toUpperCase()} • Testnet only</p>
        </div>

        {/* Summary */}
        {amount && (
          <div className="bg-gradient-to-r from-blue-50 to-pink-50 dark:from-blue-900/20 dark:to-pink-900/20 p-4 rounded-lg space-y-2">
            <div className="flex justify-between text-sm">
              <span>Deposit Amount</span>
              <span className="font-semibold">
                {amount} {tokenType.toUpperCase()}
              </span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Estimated Annual Yield</span>
              <span className="font-semibold text-green-600">
                ${(Number.parseFloat(amount) * (vaultType === "aave" ? 0.065 : 0.082)).toFixed(2)}
              </span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Public Goods Contribution</span>
              <span className="font-semibold text-pink-600">
                ${(Number.parseFloat(amount) * (vaultType === "aave" ? 0.065 : 0.082) * 0.25).toFixed(2)}/year
              </span>
            </div>
          </div>
        )}

        <Button
          type="submit"
          className="w-full bg-pink-600 hover:bg-pink-700 text-white"
          size="lg"
          disabled={!amount || isApproving || isDepositingAave || isDepositingMorpho || !address}
        >
          {isApproving
            ? "Approving USDC..."
            : isDepositingAave || isDepositingMorpho
              ? "Depositing..."
              : `Deposit to ${vaultName} Vault`}
        </Button>
      </form>
    </Card>
    </>
  )
}
