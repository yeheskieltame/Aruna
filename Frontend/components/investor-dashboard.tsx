"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from "recharts"
import { TrendingUp, Gift, Zap, CheckCircle, Loader2, AlertCircle } from "lucide-react"
import { useAccount } from "wagmi"
import { useVaultBalance, useClaimableYield, useClaimYield, formatUSDC } from "@/hooks/useContracts"
import { CONTRACTS } from "@/lib/contracts"

const yieldData = [
  { month: "Jan", aave: 450, morpho: 520 },
  { month: "Feb", aave: 520, morpho: 580 },
  { month: "Mar", aave: 480, morpho: 610 },
  { month: "Apr", aave: 650, morpho: 720 },
]

const publicGoodsData = [
  { name: "Octant", value: 1200 },
  { name: "Other", value: 800 },
]

interface InvestorDashboardProps {
  onManageClick?: (vault: "aave" | "morpho") => void
}

export default function InvestorDashboard({ onManageClick }: InvestorDashboardProps) {
  const { address } = useAccount()
  const [isClaiming, setIsClaiming] = useState(false)
  const [claimSuccess, setClaimSuccess] = useState(false)

  // Fetch vault balances
  const { data: aaveBalance, refetch: refetchAave } = useVaultBalance(CONTRACTS.AAVE_VAULT.address, address)
  const { data: morphoBalance, refetch: refetchMorpho } = useVaultBalance(CONTRACTS.MORPHO_VAULT.address, address)

  // Fetch claimable yield
  const { data: claimableYield, refetch: refetchYield } = useClaimableYield(address)

  // Claim yield hook
  const { claim, isPending, isConfirming, isSuccess } = useClaimYield()

  // Calculate total deposited (sum of vault shares - in real implementation, convert shares to assets)
  const aaveBalanceFormatted = aaveBalance ? Number(formatUSDC(aaveBalance as bigint)) : 0
  const morphoBalanceFormatted = morphoBalance ? Number(formatUSDC(morphoBalance as bigint)) : 0
  const totalDeposited = aaveBalanceFormatted + morphoBalanceFormatted

  // Calculate public goods contribution (25% of yield)
  const yieldEarned = claimableYield ? Number(claimableYield) : 0
  const publicGoodsFunded = yieldEarned * 0.25

  // Handle claim success
  useEffect(() => {
    if (isSuccess && isClaiming) {
      setClaimSuccess(true)
      refetchYield()
      refetchAave()
      refetchMorpho()

      // Reset success message after 3 seconds
      setTimeout(() => {
        setClaimSuccess(false)
        setIsClaiming(false)
      }, 3000)
    }
  }, [isSuccess, isClaiming, refetchYield, refetchAave, refetchMorpho])

  const handleClaimYield = () => {
    setIsClaiming(true)
    claim()
  }

  return (
    <div className="space-y-6">
      {/* Claim Yield Section */}
      {yieldEarned > 0 && (
        <Alert className="bg-gradient-to-r from-cyan-50 to-blue-50 dark:from-cyan-950/20 dark:to-blue-950/20 border-cyan-200 dark:border-cyan-900">
          <AlertDescription>
            <div className="flex items-center justify-between">
              <div>
                <p className="font-semibold text-lg mb-1">Claimable Yield Available!</p>
                <p className="text-sm text-muted-foreground">
                  You have ${yieldEarned.toFixed(2)} USDC ready to claim (70% of total yield)
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  ${publicGoodsFunded.toFixed(2)} goes to public goods automatically
                </p>
              </div>
              <Button
                onClick={handleClaimYield}
                disabled={isPending || isConfirming}
                className="bg-cyan-600 hover:bg-cyan-700 text-white"
                size="lg"
              >
                {isPending || isConfirming ? (
                  <>
                    <Loader2 className="animate-spin mr-2" size={20} />
                    Claiming...
                  </>
                ) : (
                  <>
                    <CheckCircle size={20} className="mr-2" />
                    Claim Yield
                  </>
                )}
              </Button>
            </div>
          </AlertDescription>
        </Alert>
      )}

      {/* Success Message */}
      {claimSuccess && (
        <Alert className="bg-green-50 dark:bg-green-950/20 border-green-200 dark:border-green-900">
          <CheckCircle className="h-4 w-4 text-green-600" />
          <AlertDescription>
            <p className="font-semibold text-green-600">Yield claimed successfully!</p>
            <p className="text-sm text-muted-foreground">USDC has been transferred to your wallet</p>
          </AlertDescription>
        </Alert>
      )}

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Total Deposited</p>
              <p className="text-2xl sm:text-3xl font-bold">${totalDeposited.toFixed(2)}</p>
            </div>
            <div className="w-12 h-12 bg-pink-100 dark:bg-pink-900/30 rounded-lg flex items-center justify-center">
              <Zap size={24} className="text-pink-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Yield Earned</p>
              <p className="text-2xl sm:text-3xl font-bold">${yieldEarned.toFixed(2)}</p>
            </div>
            <div className="w-12 h-12 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg flex items-center justify-center">
              <TrendingUp size={24} className="text-cyan-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Public Goods Funded</p>
              <p className="text-2xl sm:text-3xl font-bold">${publicGoodsFunded.toFixed(2)}</p>
            </div>
            <div className="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
              <Gift size={24} className="text-green-600" />
            </div>
          </div>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="p-6">
          <h3 className="font-semibold text-lg mb-4">Yield Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={yieldData}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
              <XAxis dataKey="month" stroke="var(--muted-foreground)" />
              <YAxis stroke="var(--muted-foreground)" />
              <Tooltip
                contentStyle={{
                  backgroundColor: "var(--card)",
                  border: "1px solid var(--border)",
                  borderRadius: "8px",
                }}
              />
              <Line type="monotone" dataKey="aave" stroke="#3b82f6" strokeWidth={2} name="Aave" />
              <Line type="monotone" dataKey="morpho" stroke="#ec4899" strokeWidth={2} name="Morpho" />
            </LineChart>
          </ResponsiveContainer>
        </Card>

        <Card className="p-6">
          <h3 className="font-semibold text-lg mb-4">Public Goods Distribution</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={publicGoodsData}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
              <XAxis dataKey="name" stroke="var(--muted-foreground)" />
              <YAxis stroke="var(--muted-foreground)" />
              <Tooltip
                contentStyle={{
                  backgroundColor: "var(--card)",
                  border: "1px solid var(--border)",
                  borderRadius: "8px",
                }}
              />
              <Bar dataKey="value" fill="#06b6d4" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>
      </div>

      {/* Vault Options */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card className="p-6 card-hover">
          <h3 className="font-semibold text-lg mb-2">Aave v3 Vault</h3>
          <p className="text-sm text-muted-foreground mb-4">Stable, proven yield source</p>
          <div className="space-y-2 mb-4">
            <div className="flex justify-between text-sm">
              <span>Current APY</span>
              <span className="font-semibold text-blue-600">6.5%</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Your Balance</span>
              <span className="font-semibold">${aaveBalanceFormatted.toFixed(2)}</span>
            </div>
          </div>
          <Button
            onClick={() => onManageClick?.("aave")}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white"
            size="sm"
          >
            Manage
          </Button>
        </Card>

        <Card className="p-6 card-hover">
          <h3 className="font-semibold text-lg mb-2">Morpho Vault</h3>
          <p className="text-sm text-muted-foreground mb-4">Optimized for higher yields</p>
          <div className="space-y-2 mb-4">
            <div className="flex justify-between text-sm">
              <span>Current APY</span>
              <span className="font-semibold text-pink-600">8.2%</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Your Balance</span>
              <span className="font-semibold">${morphoBalanceFormatted.toFixed(2)}</span>
            </div>
          </div>
          <Button
            onClick={() => onManageClick?.("morpho")}
            className="w-full bg-pink-600 hover:bg-pink-700 text-white"
            size="sm"
          >
            Manage
          </Button>
        </Card>
      </div>
    </div>
  )
}
