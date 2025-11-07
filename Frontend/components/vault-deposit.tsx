"use client"

import type React from "react"

import { useState } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { depositToAave, approveUSDC } from "@/lib/web3-utils"
import { useAccount } from "wagmi"

export default function VaultDeposit() {
  const { address } = useAccount()
  const [vaultType, setVaultType] = useState("aave")
  const [amount, setAmount] = useState("")
  const [tokenType, setTokenType] = useState("usdc")
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

      // Approve USDC
      await approveUSDC(amount)

      // Deposit to Aave
      if (vaultType === "aave") {
        await depositToAave(amount, address)
      }

      setAmount("")
    } catch (err) {
      setError(err instanceof Error ? err.message : "An error occurred")
    } finally {
      setLoading(false)
    }
  }

  return (
    <Card className="p-6 sm:p-8 max-w-2xl">
      <h2 className="text-2xl font-bold mb-6">Deposit to Vault</h2>

      {error && <div className="mb-4 p-4 bg-red-50 dark:bg-red-900/20 text-red-600 rounded-lg text-sm">{error}</div>}

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
          <Label htmlFor="amount">Amount</Label>
          <Input
            id="amount"
            type="number"
            placeholder="1000"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            required
            className="mt-2"
          />
          <p className="text-xs text-muted-foreground mt-2">Minimum: 100 {tokenType.toUpperCase()}</p>
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
          disabled={!amount || loading || !address}
        >
          {loading ? "Processing..." : `Deposit to ${vaultType === "aave" ? "Aave" : "Morpho"} Vault`}
        </Button>
      </form>
    </Card>
  )
}
