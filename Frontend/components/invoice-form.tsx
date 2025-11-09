"use client"

import type React from "react"

import { useState, useEffect, useRef } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { useAccount } from "wagmi"
import { useApproveUSDC, useSubmitInvoice, useUSDCBalance, formatUSDC } from "@/hooks/useContracts"
import { CONTRACTS } from "@/lib/contracts"
import { TransactionModal, InvoiceSuccessDetails } from "@/components/transaction-modal"
import { useApprovalTransaction } from "@/hooks/useTransactionModal"

interface InvoiceFormProps {
  onSubmit: (invoice: any) => void
}

export default function InvoiceForm({ onSubmit }: InvoiceFormProps) {
  const { address } = useAccount()
  const [formData, setFormData] = useState({
    customerName: "",
    amount: "",
    dueDate: "",
    description: "",
  })
  const [error, setError] = useState("")
  const hasSubmittedRef = useRef(false)

  const modal = useApprovalTransaction()
  const { approve, isPending: isApproving, isSuccess: isApproved, hash: approvalHash, error: approveError } = useApproveUSDC()
  const { submit, isPending: isSubmitting, isSuccess: isSubmitted, hash: submitHash, error: submitError } = useSubmitInvoice()

  // Check USDC balance
  const { data: usdcBalance } = useUSDCBalance(address)
  const usdcBalanceFormatted = usdcBalance ? formatUSDC(usdcBalance as bigint) : "0"

  // Handle approval success
  useEffect(() => {
    if (isApproved && approvalHash && !hasSubmittedRef.current) {
      modal.approvalSuccess()
    }
  }, [isApproved, approvalHash])

  // Auto-submit after approval
  useEffect(() => {
    if (modal.approvalCompleted && !isSubmitting && !isSubmitted && !hasSubmittedRef.current && formData.dueDate) {
      const amount = formData.amount
      const dueDateTimestamp = Math.floor(new Date(formData.dueDate).getTime() / 1000)

      console.log("🔍 Auto-submitting invoice after approval:", {
        customerName: formData.customerName,
        amount,
        dueDateTimestamp,
        approvalCompleted: modal.approvalCompleted,
        hasSubmitted: hasSubmittedRef.current,
      })

      if (dueDateTimestamp > 0) {
        hasSubmittedRef.current = true
        modal.startSubmit()
        const dueDate = BigInt(dueDateTimestamp)
        submit(formData.customerName, amount, dueDate)
      }
    }
  }, [modal.approvalCompleted, isSubmitting, isSubmitted, formData.dueDate, formData.customerName, formData.amount])

  // Handle submit pending
  useEffect(() => {
    if (isSubmitting && submitHash) {
      modal.submitPending(submitHash)
    }
  }, [isSubmitting, submitHash])

  // Detect if transaction was rejected (isSubmitting went from true to false without hash)
  useEffect(() => {
    const wasSubmitting = hasSubmittedRef.current
    const notSubmittingAnymore = !isSubmitting
    const noHash = !submitHash
    const noSuccess = !isSubmitted

    if (wasSubmitting && notSubmittingAnymore && noHash && noSuccess && modal.step === "confirming") {
      console.log("⚠️ Submit transaction likely rejected or failed")
      modal.transactionError("Transaction was rejected or failed to send. Please try again.")
      hasSubmittedRef.current = false
    }
  }, [isSubmitting, submitHash, isSubmitted, modal.step])

  // Handle submission success
  useEffect(() => {
    if (isSubmitted && submitHash) {
      const amount = Number.parseFloat(formData.amount)
      const grant = amount * 0.03

      modal.submitSuccess(submitHash)

      // Call parent callback
      onSubmit({
        id: Date.now().toString(),
        customerName: formData.customerName,
        amount,
        grant,
        dueDate: formData.dueDate,
        status: "pending",
        txHash: submitHash,
      })

      // Reset form and submission flag
      setTimeout(() => {
        setFormData({ customerName: "", amount: "", dueDate: "", description: "" })
        hasSubmittedRef.current = false
      }, 1000)
    }
  }, [isSubmitted, submitHash, formData])

  // Handle errors
  useEffect(() => {
    if (approveError) {
      modal.transactionError(approveError)
      setError(approveError.message)
      hasSubmittedRef.current = false // Reset on error
    }
  }, [approveError])

  useEffect(() => {
    if (submitError) {
      modal.transactionError(submitError)
      setError(submitError.message)
      hasSubmittedRef.current = false // Reset on error
    }
  }, [submitError])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")
    hasSubmittedRef.current = false // Reset submission flag for new transaction

    if (!address) {
      setError("Please connect your wallet")
      return
    }

    // Validate amount
    const amount = Number.parseFloat(formData.amount)
    if (isNaN(amount) || amount <= 0) {
      setError("Please enter a valid amount")
      return
    }

    // Check minimum and maximum invoice amount (from smart contract)
    const MIN_INVOICE_AMOUNT = 1 // $1 USDC (lowered for testing)
    const MAX_INVOICE_AMOUNT = 100000 // $100,000 USDC

    if (amount < MIN_INVOICE_AMOUNT) {
      setError(`Invoice amount must be at least $${MIN_INVOICE_AMOUNT} USDC`)
      return
    }

    if (amount > MAX_INVOICE_AMOUNT) {
      setError(`Invoice amount cannot exceed $${MAX_INVOICE_AMOUNT.toLocaleString()} USDC`)
      return
    }

    // Validate due date
    const dueDate = new Date(formData.dueDate)
    if (isNaN(dueDate.getTime())) {
      setError("Please enter a valid due date")
      return
    }

    // Check if due date is in the future
    if (dueDate.getTime() <= Date.now()) {
      setError("Due date must be in the future")
      return
    }

    const collateral = amount * 0.1

    // Check USDC balance
    const balance = Number.parseFloat(usdcBalanceFormatted)
    if (collateral > balance) {
      setError(`Insufficient USDC balance. You need ${collateral.toFixed(2)} USDC but only have ${balance.toFixed(2)} USDC. Get testnet USDC from Base Sepolia faucet.`)
      return
    }

    try {
      // Start approval process
      modal.startApproval()
      approve(CONTRACTS.ARUNA_CORE.address, collateral.toString())
    } catch (err: any) {
      console.error("Error in handleSubmit:", err)
      setError(err.message || "Failed to submit transaction")
      modal.closeModal()
    }
  }

  const amount = Number.parseFloat(formData.amount) || 0
  const grant = amount * 0.03
  const collateral = amount * 0.07

  return (
    <>
      <TransactionModal
        isOpen={modal.isOpen}
        onClose={modal.closeModal}
        step={modal.step}
        txHash={modal.txHash}
        error={modal.error}
        title="Submit Invoice Commitment"
        approvalMessage="Approve 10% collateral (USDC) for your invoice"
        confirmMessage="Submitting your invoice commitment to the blockchain..."
        pendingMessage="Your invoice is being processed. You'll receive your 3% grant shortly!"
        successMessage="Invoice commitment submitted successfully!"
        successDetails={
          formData.amount && (
            <InvoiceSuccessDetails
              customerName={formData.customerName}
              invoiceAmount={amount}
              grantAmount={grant}
              collateralAmount={collateral}
            />
          )
        }
        onSuccess={() => {
          modal.closeModal()
        }}
      />

      <Card className="p-6 sm:p-8 max-w-2xl">
        <h2 className="text-2xl font-bold mb-6">Submit Invoice Commitment</h2>

        {/* Display USDC Balance */}
        {address && (
          <div className="mb-4 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
            <div className="flex justify-between items-center">
              <span className="text-sm text-muted-foreground">Your USDC Balance:</span>
              <span className="font-semibold">{Number.parseFloat(usdcBalanceFormatted).toFixed(2)} USDC</span>
            </div>
            {Number.parseFloat(usdcBalanceFormatted) === 0 && (
              <div className="mt-2 pt-2 border-t border-blue-200 dark:border-blue-800">
                <p className="text-xs text-blue-600 dark:text-blue-400">
                  You need testnet USDC to submit invoices. Get free testnet USDC from:
                </p>
                <a
                  href="https://faucet.circle.com/"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-xs text-blue-600 dark:text-blue-400 hover:underline mt-1 inline-block"
                >
                  Circle USDC Faucet →
                </a>
              </div>
            )}
          </div>
        )}

        {error && !modal.isOpen && (
          <div className="mb-4 p-4 bg-red-50 dark:bg-red-900/20 text-red-600 rounded-lg text-sm">
            {error}
            {error.includes("Insufficient USDC") && (
              <a
                href="https://faucet.circle.com/"
                target="_blank"
                rel="noopener noreferrer"
                className="block mt-2 text-blue-600 hover:underline text-xs"
              >
                Get testnet USDC from Circle Faucet →
              </a>
            )}
          </div>
        )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <Label htmlFor="customerName">Customer Name</Label>
          <Input
            id="customerName"
            placeholder="Acme Corporation"
            value={formData.customerName}
            onChange={(e) => setFormData({ ...formData, customerName: e.target.value })}
            required
            className="mt-2"
          />
        </div>

        <div>
          <div className="flex justify-between items-baseline">
            <Label htmlFor="amount">Invoice Amount (USD)</Label>
            <span className="text-xs text-muted-foreground">Min: $1 • Max: $100,000</span>
          </div>
          <Input
            id="amount"
            type="number"
            placeholder="Enter amount (minimum $1)"
            min="1"
            max="100000"
            step="0.01"
            value={formData.amount}
            onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
            required
            className="mt-2"
          />
          {formData.amount && (
            <div className="mt-2 space-y-1">
              {Number.parseFloat(formData.amount) < 1 && (
                <p className="text-sm text-red-600">
                  ⚠ Amount must be at least $1 USDC
                </p>
              )}
              {Number.parseFloat(formData.amount) >= 1 && (
                <>
                  <p className="text-sm text-green-600">
                    ✓ You'll receive ${(Number.parseFloat(formData.amount) * 0.03).toFixed(2)} grant instantly
                  </p>
                  <p className="text-sm text-muted-foreground">
                    • Required collateral: ${(Number.parseFloat(formData.amount) * 0.1).toFixed(2)} USDC (10%)
                  </p>
                  {Number.parseFloat(formData.amount) * 0.1 > Number.parseFloat(usdcBalanceFormatted) && (
                    <p className="text-sm text-red-600">
                      ⚠ Insufficient USDC balance for this invoice amount
                    </p>
                  )}
                </>
              )}
            </div>
          )}
        </div>

        <div>
          <Label htmlFor="dueDate">Expected Payment Date</Label>
          <Input
            id="dueDate"
            type="date"
            value={formData.dueDate}
            onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })}
            required
            className="mt-2"
          />
        </div>

        <div>
          <Label htmlFor="description">Description (Optional)</Label>
          <Input
            id="description"
            placeholder="Q4 marketing campaign..."
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            className="mt-2"
          />
        </div>

        <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg space-y-2">
          <p className="text-sm text-blue-900 dark:text-blue-200">
            <strong>Protocol Requirements:</strong>
          </p>
          <ul className="text-sm text-blue-800 dark:text-blue-300 space-y-1 list-disc list-inside">
            <li>Minimum invoice amount: $1 USDC</li>
            <li>Maximum invoice amount: $100,000 USDC</li>
            <li>Collateral required: 10% of invoice amount</li>
            <li>Grant received: 3% of invoice amount (instant)</li>
          </ul>
        </div>

        <Button
          type="submit"
          className="w-full bg-blue-600 hover:bg-blue-700 text-white"
          size="lg"
          disabled={isApproving || isSubmitting || !address}
        >
          {isApproving ? "Approving USDC..." : isSubmitting ? "Submitting Invoice..." : "Submit Invoice Commitment"}
        </Button>
      </form>
    </Card>
    </>
  )
}
