"use client"

import type React from "react"

import { useState } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { submitInvoice, approveUSDC } from "@/lib/web3-utils"
import { useAccount } from "wagmi"

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
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")
    setLoading(true)

    try {
      if (!address) {
        throw new Error("Please connect your wallet")
      }

      const amount = Number.parseFloat(formData.amount)
      const grant = amount * 0.03
      const collateral = amount * 0.1

      // Approve USDC for collateral
      await approveUSDC(collateral.toString())

      // Submit invoice to contract
      const dueDate = Math.floor(new Date(formData.dueDate).getTime() / 1000)
      const txHash = await submitInvoice(
        formData.customerName,
        amount.toString(),
        dueDate,
        process.env.NEXT_PUBLIC_Aruna_ADDRESS || "",
      )

      onSubmit({
        id: Date.now().toString(),
        customerName: formData.customerName,
        amount,
        grant,
        dueDate: formData.dueDate,
        status: "pending",
        txHash,
      })

      setFormData({ customerName: "", amount: "", dueDate: "", description: "" })
    } catch (err) {
      setError(err instanceof Error ? err.message : "An error occurred")
    } finally {
      setLoading(false)
    }
  }

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
          disabled={loading || !address}
        >
          {loading ? "Processing..." : "Submit Invoice Commitment"}
        </Button>
      </form>
    </Card>
  )
}
