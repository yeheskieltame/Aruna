"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from "recharts"
import { TrendingUp, Gift, Zap, CheckCircle, Loader2, AlertCircle, Sparkles } from "lucide-react"
import { useAccount } from "wagmi"
import {
  useVaultBalance,
  useClaimableYield,
  useClaimYield,
  useHarvestAaveYield,
  useHarvestMorphoYield,
  formatUSDC
} from "@/hooks/useContracts"
import { CONTRACTS } from "@/lib/contracts"
import { TransactionModal } from "@/components/transaction-modal"

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

  // Harvest modal states
  const [harvestModalOpen, setHarvestModalOpen] = useState(false)
  const [harvestStep, setHarvestStep] = useState<"idle" | "confirming" | "pending" | "success" | "error">("idle")
  const [harvestTxHash, setHarvestTxHash] = useState<string | undefined>()
  const [harvestError, setHarvestError] = useState<string | undefined>()
  const [harvestVault, setHarvestVault] = useState<"aave" | "morpho" | null>(null)

  // Fetch vault balances
  const { data: aaveBalance, refetch: refetchAave } = useVaultBalance(CONTRACTS.AAVE_VAULT.address, address)
  const { data: morphoBalance, refetch: refetchMorpho } = useVaultBalance(CONTRACTS.MORPHO_VAULT.address, address)

  // Fetch claimable yield
  const { data: claimableYield, refetch: refetchYield } = useClaimableYield(address)

  // Claim yield hook
  const { claim, isPending, isConfirming, isSuccess } = useClaimYield()

  // Harvest hooks
  const aaveHarvest = useHarvestAaveYield()
  const morphoHarvest = useHarvestMorphoYield()

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

  const handleHarvest = (vault: "aave" | "morpho") => {
    setHarvestVault(vault)
    setHarvestModalOpen(true)
    setHarvestStep("confirming")
    setHarvestError(undefined)

    if (vault === "aave") {
      aaveHarvest.harvest()
    } else {
      morphoHarvest.harvest()
    }
  }

  // Handle harvest transaction states
  useEffect(() => {
    const harvest = harvestVault === "aave" ? aaveHarvest : morphoHarvest

    if (harvest.isPending) {
      setHarvestStep("confirming")
    }

    if (harvest.isConfirming && harvest.hash) {
      setHarvestStep("pending")
      setHarvestTxHash(harvest.hash)
    }

    if (harvest.isSuccess && harvest.hash) {
      setHarvestStep("success")
      setHarvestTxHash(harvest.hash)

      // Refetch data after success
      setTimeout(() => {
        refetchYield()
        refetchAave()
        refetchMorpho()
      }, 2000)
    }

    if (harvest.error) {
      setHarvestStep("error")
      setHarvestError(harvest.error.message || "Harvest failed")
    }
  }, [
    aaveHarvest.isPending, aaveHarvest.isConfirming, aaveHarvest.isSuccess, aaveHarvest.hash, aaveHarvest.error,
    morphoHarvest.isPending, morphoHarvest.isConfirming, morphoHarvest.isSuccess, morphoHarvest.hash, morphoHarvest.error,
    harvestVault, refetchYield, refetchAave, refetchMorpho
  ])

  return (
    <div className="space-y-6">
      {/* Harvest Transaction Modal */}
      <TransactionModal
        isOpen={harvestModalOpen}
        onClose={() => setHarvestModalOpen(false)}
        step={harvestStep}
        txHash={harvestTxHash}
        error={harvestError}
        title={`Harvest Yield - ${harvestVault === "aave" ? "Aave" : "Morpho"} Vault`}
        confirmMessage="Confirming harvest transaction..."
        pendingMessage="Harvesting yield and distributing to stakeholders..."
        successMessage="Yield harvested successfully!"
        successDetails={
          <div className="bg-gradient-to-r from-green-50 to-cyan-50 dark:from-green-950/20 dark:to-cyan-950/20 p-4 rounded-lg border border-green-200 dark:border-green-900 text-left">
            <div className="space-y-2 text-sm">
              <p className="font-semibold text-green-600 dark:text-green-400">Yield Distribution:</p>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Investors (70%):</span>
                <span className="font-semibold">Claimable now!</span>
              </div>
              <div className="flex justify-between">
                <span className="text-pink-600 dark:text-pink-400">Public Goods (25%):</span>
                <span className="font-semibold text-pink-600 dark:text-pink-400">Auto-donated ✓</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Protocol Fee (5%):</span>
                <span className="font-semibold">To treasury</span>
              </div>
            </div>
          </div>
        }
        onSuccess={() => {
          setHarvestModalOpen(false)
          setHarvestStep("idle")
          setHarvestVault(null)
        }}
      />
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

      {/* Harvest Yield Section */}
      {totalDeposited > 0 && (
        <Card className="p-6 bg-gradient-to-r from-purple-50 to-pink-50 dark:from-purple-950/20 dark:to-pink-950/20 border-purple-200 dark:border-purple-900">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center flex-shrink-0">
              <Sparkles size={24} className="text-purple-600" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold text-lg mb-2">Harvest Vault Yield</h3>
              <div className="space-y-2 text-sm text-muted-foreground mb-4">
                <p>
                  Trigger yield distribution from vaults. This collects generated yield and automatically splits it:
                </p>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 mt-2">
                  <div className="p-2 bg-white dark:bg-gray-900 rounded border border-border">
                    <p className="text-xs font-semibold">70% → Investors</p>
                    <p className="text-xs text-muted-foreground">Claimable yield</p>
                  </div>
                  <div className="p-2 bg-pink-50 dark:bg-pink-900/20 rounded border border-pink-200 dark:border-pink-800">
                    <p className="text-xs font-semibold text-pink-600 dark:text-pink-400">25% → Public Goods</p>
                    <p className="text-xs text-muted-foreground">Via Octant</p>
                  </div>
                  <div className="p-2 bg-white dark:bg-gray-900 rounded border border-border">
                    <p className="text-xs font-semibold">5% → Protocol</p>
                    <p className="text-xs text-muted-foreground">Treasury</p>
                  </div>
                </div>
                <p className="text-xs pt-2">
                  ⏰ <strong>Harvest Interval:</strong> Can be called once every 24 hours per vault
                </p>
              </div>
              <div className="flex flex-wrap gap-3">
                <Button
                  onClick={() => handleHarvest("aave")}
                  disabled={aaveHarvest.isPending || aaveHarvest.isConfirming || aaveBalanceFormatted === 0}
                  className="bg-blue-600 hover:bg-blue-700 text-white"
                  size="sm"
                >
                  {aaveHarvest.isPending || aaveHarvest.isConfirming ? (
                    <>
                      <Loader2 className="animate-spin mr-2" size={16} />
                      Harvesting Aave...
                    </>
                  ) : (
                    <>
                      <Sparkles size={16} className="mr-2" />
                      Harvest Aave Vault
                    </>
                  )}
                </Button>
                <Button
                  onClick={() => handleHarvest("morpho")}
                  disabled={morphoHarvest.isPending || morphoHarvest.isConfirming || morphoBalanceFormatted === 0}
                  className="bg-pink-600 hover:bg-pink-700 text-white"
                  size="sm"
                >
                  {morphoHarvest.isPending || morphoHarvest.isConfirming ? (
                    <>
                      <Loader2 className="animate-spin mr-2" size={16} />
                      Harvesting Morpho...
                    </>
                  ) : (
                    <>
                      <Sparkles size={16} className="mr-2" />
                      Harvest Morpho Vault
                    </>
                  )}
                </Button>
              </div>
            </div>
          </div>
        </Card>
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
