"use client"

import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { TrendingUp, Calendar, DollarSign, CheckCircle, Loader2, Clock, AlertCircle } from "lucide-react"
import { useAccount } from "wagmi"
import { useUserReputation, useUserInvoices, useInvoiceDetails, useSettleInvoice, formatUSDC } from "@/hooks/useContracts"
import { useState, useEffect } from "react"
import { TransactionModal, SettlementSuccessDetails } from "@/components/transaction-modal"
import { useSettlementTransaction } from "@/hooks/useTransactionModal"

interface BusinessDashboardProps {
  refreshTrigger?: number
}

export default function BusinessDashboard({ refreshTrigger }: BusinessDashboardProps = {}) {
  const { address } = useAccount()
  const { data: reputationData } = useUserReputation(address)
  const { data: invoiceIds, refetch: refetchInvoices } = useUserInvoices(address)
  const { settle, isPending: isSettling, isSuccess: isSettled, hash: settleHash } = useSettleInvoice()
  const [settlingId, setSettlingId] = useState<bigint | null>(null)
  const [settlingInvoice, setSettlingInvoice] = useState<any>(null)
  const modal = useSettlementTransaction()

  // Refetch when refresh trigger changes
  useEffect(() => {
    if (refreshTrigger && refreshTrigger > 0) {
      console.log("🔄 Refreshing invoices from blockchain in 2s...")
      setTimeout(() => {
        refetchInvoices()
      }, 2000)
    }
  }, [refreshTrigger, refetchInvoices])

  // Handle settlement transaction states
  useEffect(() => {
    if (isSettling && settleHash) {
      modal.settlePending(settleHash)
    }
  }, [isSettling, settleHash])

  // Handle settlement success
  useEffect(() => {
    if (isSettled && settleHash && settlingInvoice) {
      const collateralReturned = Number(formatUSDC(settlingInvoice.collateralAmount)) - Number(formatUSDC(settlingInvoice.grantAmount))
      modal.settleSuccess(settleHash, {
        invoiceAmount: Number(formatUSDC(settlingInvoice.invoiceAmount)),
        collateralReturned,
        reputationGain: 1
      })

      // Refetch invoices and reset state
      setTimeout(() => {
        refetchInvoices()
        setSettlingId(null)
        setSettlingInvoice(null)
      }, 2000)
    }
  }, [isSettled, settleHash, settlingInvoice])

  // Convert reputation to score
  const reputation = reputationData ? Number(reputationData) : 0

  // Parse invoice IDs
  const tokenIds = invoiceIds ? (invoiceIds as bigint[]) : []

  // Count active invoices (not settled or liquidated)
  const [activeCount, setActiveCount] = useState(0)

  const handleSettle = (tokenId: bigint, invoice: any) => {
    setSettlingId(tokenId)
    setSettlingInvoice(invoice)
    modal.startSettle()
    settle(tokenId)
  }

  return (
    <>
      <TransactionModal
        isOpen={modal.isOpen}
        onClose={modal.closeModal}
        step={modal.step}
        txHash={modal.txHash}
        error={modal.error}
        title="Settle Invoice"
        confirmMessage="Confirming settlement transaction..."
        pendingMessage="Your invoice is being settled on the blockchain..."
        successMessage="Invoice settled successfully!"
        successDetails={
          modal.settlementDetails && (
            <SettlementSuccessDetails
              invoiceAmount={modal.settlementDetails.invoiceAmount}
              collateralReturned={modal.settlementDetails.collateralReturned}
              reputationGain={modal.settlementDetails.reputationGain}
            />
          )
        }
        onSuccess={() => {
          modal.closeModal()
        }}
      />

      <div className="space-y-6">
        {/* Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <Card className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground mb-1">Total Invoices</p>
                <p className="text-2xl sm:text-3xl font-bold">{tokenIds.length}</p>
              </div>
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
                <DollarSign size={24} className="text-blue-600" />
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground mb-1">Active Invoices</p>
                <p className="text-2xl sm:text-3xl font-bold">{activeCount}</p>
              </div>
              <div className="w-12 h-12 bg-pink-100 dark:bg-pink-900/30 rounded-lg flex items-center justify-center">
                <Calendar size={24} className="text-pink-600" />
              </div>
            </div>
          </Card>

          <Card className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground mb-1">Reputation Score</p>
                <p className="text-2xl sm:text-3xl font-bold">{reputation}</p>
              </div>
              <div className="w-12 h-12 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg flex items-center justify-center">
                <TrendingUp size={24} className="text-cyan-600" />
              </div>
            </div>
          </Card>
        </div>

        {/* Invoices List */}
        <Card className="p-6">
          <h3 className="font-semibold text-lg mb-4">Your Invoices</h3>

          {tokenIds.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-muted-foreground mb-4">No invoices yet</p>
              <p className="text-sm text-muted-foreground">Submit your first invoice to get started</p>
            </div>
          ) : (
            <div className="space-y-3">
              {tokenIds.map((tokenId) => (
                <InvoiceItem
                  key={tokenId.toString()}
                  tokenId={tokenId}
                  onSettle={handleSettle}
                  onActiveCountChange={(isActive) => {
                    setActiveCount(prev => isActive ? prev + 1 : prev)
                  }}
                  isSettling={isSettling && settlingId === tokenId}
                />
              ))}
            </div>
          )}
        </Card>
      </div>
    </>
  )
}

// Component to display individual invoice details
function InvoiceItem({
  tokenId,
  onSettle,
  onActiveCountChange,
  isSettling,
}: {
  tokenId: bigint
  onSettle: (tokenId: bigint, invoice: any) => void
  onActiveCountChange: (isActive: boolean) => void
  isSettling: boolean
}) {
  const { data: invoiceData } = useInvoiceDetails(tokenId)

  useEffect(() => {
    if (invoiceData) {
      const invoice = invoiceData as any
      const isActive = !invoice.isSettled && !invoice.isLiquidated
      onActiveCountChange(isActive)
    }
  }, [invoiceData])

  if (!invoiceData) {
    return (
      <div className="flex items-center justify-center p-4 bg-muted/50 rounded-lg">
        <Loader2 className="animate-spin" size={20} />
        <span className="ml-2 text-sm text-muted-foreground">Loading invoice...</span>
      </div>
    )
  }

  const invoice = invoiceData as any

  // Get values from blockchain (not calculated!)
  const amount = invoice.invoiceAmount ? formatUSDC(invoice.invoiceAmount) : "0"
  const collateral = invoice.collateralAmount ? formatUSDC(invoice.collateralAmount) : "0"
  const grant = invoice.grantAmount ? formatUSDC(invoice.grantAmount) : "0" // ← FROM BLOCKCHAIN!
  const dueDate = invoice.dueDate ? new Date(Number(invoice.dueDate) * 1000).toLocaleDateString() : "N/A"
  const createdAt = invoice.createdAt ? new Date(Number(invoice.createdAt) * 1000).toLocaleDateString() : "N/A"

  // Calculate time-based info
  const now = Date.now()
  const dueDateMs = invoice.dueDate ? Number(invoice.dueDate) * 1000 : 0
  const createdAtMs = invoice.createdAt ? Number(invoice.createdAt) * 1000 : 0
  const daysOld = Math.floor((now - createdAtMs) / (1000 * 60 * 60 * 24))
  const isOverdue = dueDateMs > 0 && now > dueDateMs
  const daysOverdue = isOverdue ? Math.floor((now - dueDateMs) / (1000 * 60 * 60 * 24)) : 0

  // Fix status using boolean flags from blockchain
  const isSettled = invoice.isSettled || false
  const isLiquidated = invoice.isLiquidated || false

  let statusText = "Active"
  let statusColor = "bg-blue-600"

  if (isSettled) {
    statusText = "Settled"
    statusColor = "bg-green-600"
  } else if (isLiquidated) {
    statusText = "Liquidated"
    statusColor = "bg-red-600"
  } else if (isOverdue) {
    statusText = "Overdue"
    statusColor = "bg-orange-600"
  }

  // Calculate collateral return amount (for settlement preview)
  const collateralReturn = (Number(collateral) - Number(grant)).toFixed(2)

  return (
    <div className="flex flex-col p-4 bg-muted/50 rounded-lg gap-4 border border-border">
      {/* Header Row */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <p className="font-medium text-lg">{invoice.customerName || "Unknown Customer"}</p>
            <Badge className={statusColor}>{statusText}</Badge>
          </div>
          <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
            <span className="flex items-center gap-1">
              <Calendar size={12} />
              Due: {dueDate}
            </span>
            <span className="flex items-center gap-1">
              <Clock size={12} />
              Created: {createdAt} ({daysOld}d ago)
            </span>
            <span>NFT #{tokenId.toString()}</span>
          </div>
          {isOverdue && !isSettled && !isLiquidated && (
            <div className="mt-2 flex items-center gap-1 text-xs text-orange-600 dark:text-orange-400">
              <AlertCircle size={12} />
              <span className="font-semibold">Overdue by {daysOverdue} day{daysOverdue !== 1 ? 's' : ''}</span>
            </div>
          )}
        </div>

        {/* Amount Info */}
        <div className="text-right">
          <p className="font-semibold text-lg">${Number(amount).toFixed(2)}</p>
          <p className="text-sm text-green-600 dark:text-green-400">+${Number(grant).toFixed(2)} grant received</p>
          <p className="text-xs text-muted-foreground">${Number(collateral).toFixed(2)} collateral locked</p>
        </div>
      </div>

      {/* Settlement Info & Action */}
      {!isSettled && !isLiquidated && (
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 pt-3 border-t border-border">
          <div className="flex-1 bg-green-50 dark:bg-green-900/20 p-3 rounded-lg border border-green-200 dark:border-green-800">
            <p className="text-xs text-muted-foreground mb-1">Settlement Preview:</p>
            <div className="flex justify-between items-center">
              <span className="text-sm text-muted-foreground">You'll receive:</span>
              <span className="font-semibold text-green-600 dark:text-green-400">${collateralReturn} USDC</span>
            </div>
            <div className="flex justify-between items-center mt-1">
              <span className="text-xs text-muted-foreground">Reputation:</span>
              <span className="text-xs font-semibold text-cyan-600 dark:text-cyan-400">+1</span>
            </div>
          </div>
          <Button
            size="sm"
            onClick={() => onSettle(tokenId, invoice)}
            disabled={isSettling}
            className="bg-green-600 hover:bg-green-700 text-white sm:w-auto w-full"
          >
            {isSettling ? (
              <>
                <Loader2 className="animate-spin mr-1" size={14} />
                Settling...
              </>
            ) : (
              <>
                <CheckCircle size={14} className="mr-1" />
                Settle Invoice
              </>
            )}
          </Button>
        </div>
      )}

      {/* Settled Info */}
      {isSettled && (
        <div className="pt-3 border-t border-green-200 dark:border-green-800">
          <div className="bg-green-50 dark:bg-green-900/20 p-3 rounded-lg border border-green-200 dark:border-green-800">
            <p className="text-sm text-green-600 dark:text-green-400 font-semibold">
              ✓ Settled - Collateral returned: ${collateralReturn} USDC
            </p>
          </div>
        </div>
      )}

      {/* Liquidated Info */}
      {isLiquidated && (
        <div className="pt-3 border-t border-red-200 dark:border-red-800">
          <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-lg border border-red-200 dark:border-red-800">
            <p className="text-sm text-red-600 dark:text-red-400 font-semibold">
              ✗ Liquidated - Collateral seized due to non-payment
            </p>
          </div>
        </div>
      )}
    </div>
  )
}
