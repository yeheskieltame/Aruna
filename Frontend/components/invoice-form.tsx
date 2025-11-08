"use client"

import type React from "react"

import { useState, useEffect } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { useAccount } from "wagmi"
import { useApproveUSDC, useSubmitInvoice } from "@/hooks/useContracts"
import { CONTRACTS } from "@/lib/contracts"

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
  const [step, setStep] = useState<"input" | "approve" | "submit">("input")

  const { approve, isPending: isApproving, isSuccess: isApproved, error: approveError } = useApproveUSDC()
  const { submit, isPending: isSubmitting, isSuccess: isSubmitted, hash, error: submitError } = useSubmitInvoice()

  // Handle approval completion
  useEffect(() => {
    if (isApproved && step === "approve") {
      setStep("submit")
    }
  }, [isApproved, step])

  // Handle submission completion
  useEffect(() => {
    if (isSubmitted && hash) {
      const amount = Number.parseFloat(formData.amount)
      const grant = amount * 0.03

      onSubmit({
        id: Date.now().toString(),
        customerName: formData.customerName,
        amount,
        grant,
        dueDate: formData.dueDate,
        status: "pending",
        txHash: hash,
      })

      setFormData({ customerName: "", amount: "", dueDate: "", description: "" })
      setStep("input")
    }
  }, [isSubmitted, hash])

  // Handle errors
  useEffect(() => {
    if (approveError) {
      setError(approveError.message)
      setStep("input")
    }
    if (submitError) {
      setError(submitError.message)
      setStep("input")
    }
  }, [approveError, submitError])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

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

    // Start approval process
    setStep("approve")
    approve(CONTRACTS.ARUNA_CORE.address, collateral.toString())
  }

  // Automatically submit invoice after approval
  useEffect(() => {
    if (step === "submit" && !isSubmitting && !isSubmitted && formData.dueDate) {
      const amount = formData.amount
      const dueDateTimestamp = Math.floor(new Date(formData.dueDate).getTime() / 1000)

      // Additional safety check
      if (dueDateTimestamp > 0) {
        const dueDate = BigInt(dueDateTimestamp)
        submit(formData.customerName, amount, dueDate)
      } else {
        setError("Invalid due date")
        setStep("input")
      }
    }
  }, [step])

  return (
    <Card className="p-6 sm:p-8 max-w-2xl">
      <h2 className="text-2xl font-bold mb-6">Submit Invoice Commitment</h2>

      {error && <div className="mb-4 p-4 bg-red-50 dark:bg-red-900/20 text-red-600 rounded-lg text-sm">{error}</div>}

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
          <Label htmlFor="amount">Invoice Amount (USD)</Label>
          <Input
            id="amount"
            type="number"
            placeholder="10000"
            value={formData.amount}
            onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
            required
            className="mt-2"
          />
          {formData.amount && (
            <p className="text-sm text-green-600 mt-2">
              You'll receive ${(Number.parseFloat(formData.amount) * 0.03).toFixed(2)} grant instantly
            </p>
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

        <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg">
          <p className="text-sm text-blue-900 dark:text-blue-200">
            <strong>Note:</strong> You'll need to deposit 10% collateral in USDC to complete this commitment.
          </p>
        </div>

        <Button
          type="submit"
          className="w-full bg-blue-600 hover:bg-blue-700 text-white"
          size="lg"
          disabled={isApproving || isSubmitting || !address}
        >
          {step === "approve" && isApproving
            ? "Approving USDC..."
            : step === "submit" && isSubmitting
              ? "Submitting Invoice..."
              : "Submit Invoice Commitment"}
        </Button>
      </form>
    </Card>
  )
}
