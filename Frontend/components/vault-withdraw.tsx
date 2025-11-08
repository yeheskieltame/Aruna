"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card } from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Loader2, ArrowDownToLine, CheckCircle, AlertCircle } from "lucide-react"
import { useAccount } from "wagmi"
import {
  useVaultBalance,
  useWithdrawFromVault,
  useConvertToAssets,
  useMaxWithdraw,
  formatUSDC,
} from "@/hooks/useContracts"
import { CONTRACTS } from "@/lib/contracts"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

interface VaultWithdrawProps {
  onSuccess?: () => void
}

export default function VaultWithdraw({ onSuccess }: VaultWithdrawProps) {
  const { address } = useAccount()
  const [vault, setVault] = useState<"aave" | "morpho">("aave")
  const [amount, setAmount] = useState("")
  const [error, setError] = useState("")
  const [step, setStep] = useState<"input" | "withdrawing" | "success">("input")

  const isAave = vault === "aave"
  const vaultAddress = isAave ? CONTRACTS.AAVE_VAULT.address : CONTRACTS.MORPHO_VAULT.address

  // Fetch vault balance (shares)
  const { data: vaultShares } = useVaultBalance(vaultAddress, address)

  // Convert shares to assets (USD value)
  const { data: vaultAssets } = useConvertToAssets(vaultAddress, vaultShares as bigint)

  // Get max withdrawable
  const { data: maxWithdrawAmount } = useMaxWithdraw(vaultAddress, address)

  // Withdraw hook
  const { withdraw, isPending, isConfirming, isSuccess } = useWithdrawFromVault(isAave)

  // Format balances
  const sharesFormatted = vaultShares ? formatUSDC(vaultShares as bigint) : "0"
  const assetsFormatted = vaultAssets ? formatUSDC(vaultAssets as bigint) : "0"
  const maxWithdrawFormatted = maxWithdrawAmount ? formatUSDC(maxWithdrawAmount as bigint) : "0"

  // Handle success
  useEffect(() => {
    if (isSuccess && step === "withdrawing") {
      setStep("success")
      setAmount("")
      setError("")

      // Call onSuccess callback if provided
      if (onSuccess) {
        setTimeout(() => {
          onSuccess()
        }, 2000)
      }
    }
  }, [isSuccess, step, onSuccess])

  const handleWithdraw = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    // Validate amount
    const amountNum = Number.parseFloat(amount)
    if (isNaN(amountNum) || amountNum <= 0) {
      setError("Please enter a valid amount greater than 0")
      return
    }

    // Check if user has sufficient balance
    const balance = Number.parseFloat(assetsFormatted)
    if (amountNum > balance) {
      setError(`Insufficient balance. You have ${balance.toFixed(2)} USDC`)
      return
    }

    // Check max withdraw
    const maxWithdraw = Number.parseFloat(maxWithdrawFormatted)
    if (amountNum > maxWithdraw) {
      setError(`Maximum withdrawable amount is ${maxWithdraw.toFixed(2)} USDC`)
      return
    }

    try {
      setStep("withdrawing")

      if (!address) {
        throw new Error("Wallet not connected")
      }

      // Call withdraw function
      withdraw(amount, address, address)
    } catch (err: any) {
      console.error("Withdrawal error:", err)
      setError(err.message || "Failed to withdraw")
      setStep("input")
    }
  }

  const handleMaxClick = () => {
    setAmount(maxWithdrawFormatted)
  }

  const resetForm = () => {
    setStep("input")
    setAmount("")
    setError("")
  }

  return (
    <Card className="p-6 max-w-2xl mx-auto">
      <h2 className="text-2xl font-bold mb-6">Withdraw from Vault</h2>

      {step === "input" && (
        <form onSubmit={handleWithdraw} className="space-y-6">
          {/* Vault Selection */}
          <Tabs value={vault} onValueChange={(v) => setVault(v as "aave" | "morpho")}>
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="aave">Aave v3</TabsTrigger>
              <TabsTrigger value="morpho">Morpho</TabsTrigger>
            </TabsList>

            <TabsContent value="aave" className="mt-4">
              <Alert className="bg-blue-50 dark:bg-blue-950/20 border-blue-200 dark:border-blue-900">
                <AlertDescription>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span className="text-sm">Current APY:</span>
                      <span className="font-semibold text-blue-600">6.5%</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm">Your Balance:</span>
                      <span className="font-semibold">${Number(assetsFormatted).toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm">Shares:</span>
                      <span className="font-semibold">{Number(sharesFormatted).toFixed(6)}</span>
                    </div>
                  </div>
                </AlertDescription>
              </Alert>
            </TabsContent>

            <TabsContent value="morpho" className="mt-4">
              <Alert className="bg-pink-50 dark:bg-pink-950/20 border-pink-200 dark:border-pink-900">
                <AlertDescription>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span className="text-sm">Current APY:</span>
                      <span className="font-semibold text-pink-600">8.2%</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm">Your Balance:</span>
                      <span className="font-semibold">${Number(assetsFormatted).toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm">Shares:</span>
                      <span className="font-semibold">{Number(sharesFormatted).toFixed(6)}</span>
                    </div>
                  </div>
                </AlertDescription>
              </Alert>
            </TabsContent>
          </Tabs>

          {/* Withdrawal Amount */}
          <div>
            <Label htmlFor="amount">Withdrawal Amount (USDC)</Label>
            <div className="flex gap-2 mt-2">
              <Input
                id="amount"
                type="number"
                placeholder="0.00"
                min="0"
                step="0.01"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
              />
              <Button type="button" variant="outline" onClick={handleMaxClick}>
                Max
              </Button>
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Available: ${Number(maxWithdrawFormatted).toFixed(2)} USDC
            </p>
          </div>

          {/* Error Message */}
          {error && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          {/* Info */}
          <Alert>
            <AlertDescription>
              <p className="text-sm">
                No withdrawal fees. Your shares will be burned and you&apos;ll receive USDC directly to your wallet.
              </p>
            </AlertDescription>
          </Alert>

          {/* Submit Button */}
          <Button
            type="submit"
            className={`w-full ${isAave ? "bg-blue-600 hover:bg-blue-700" : "bg-pink-600 hover:bg-pink-700"} text-white`}
            size="lg"
            disabled={!address || isPending || isConfirming}
          >
            {isPending || isConfirming ? (
              <>
                <Loader2 className="animate-spin mr-2" size={20} />
                Withdrawing...
              </>
            ) : (
              <>
                <ArrowDownToLine size={20} className="mr-2" />
                Withdraw from {isAave ? "Aave" : "Morpho"}
              </>
            )}
          </Button>
        </form>
      )}

      {step === "withdrawing" && (
        <div className="text-center py-12">
          <Loader2 className="animate-spin mx-auto mb-4" size={48} />
          <h3 className="text-lg font-semibold mb-2">Processing Withdrawal...</h3>
          <p className="text-muted-foreground">
            {isPending && "Waiting for wallet confirmation..."}
            {isConfirming && "Confirming transaction on blockchain..."}
          </p>
        </div>
      )}

      {step === "success" && (
        <div className="text-center py-12">
          <CheckCircle className="mx-auto mb-4 text-green-600" size={48} />
          <h3 className="text-lg font-semibold mb-2">Withdrawal Successful!</h3>
          <p className="text-muted-foreground mb-4">
            Your USDC has been transferred to your wallet
          </p>
          <Alert className="mb-4">
            <AlertDescription>
              <p className="text-sm">
                Withdrawn: ${Number.parseFloat(amount).toFixed(2)} USDC
              </p>
            </AlertDescription>
          </Alert>
          <Button onClick={resetForm} variant="outline">
            Make Another Withdrawal
          </Button>
        </div>
      )}
    </Card>
  )
}
