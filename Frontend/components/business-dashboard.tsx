"use client"

import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { TrendingUp, Calendar, DollarSign, CheckCircle, Loader2 } from "lucide-react"
import { useAccount } from "wagmi"
import { useUserReputation, useUserInvoices, useInvoiceDetails, useSettleInvoice, formatUSDC } from "@/hooks/useContracts"
import { useState, useEffect } from "react"

interface BusinessDashboardProps {
  refreshTrigger?: number
}

export default function BusinessDashboard({ refreshTrigger }: BusinessDashboardProps = {}) {
  const { address } = useAccount()
  const { data: reputationData } = useUserReputation(address)
  const { data: invoiceIds, refetch: refetchInvoices } = useUserInvoices(address)
  const { settle, isPending: isSettling, isSuccess: isSettled } = useSettleInvoice()
  const [settlingId, setSettlingId] = useState<bigint | null>(null)

  // Refetch when refresh trigger changes
  useEffect(() => {
    if (refreshTrigger && refreshTrigger > 0) {
      console.log("🔄 Refreshing invoices from blockchain in 2s...")
      setTimeout(() => {
        refetchInvoices()
      }, 2000)
    }
  }, [refreshTrigger, refetchInvoices])

  // Refetch invoices when settlement succeeds
  useEffect(() => {
    if (isSettled) {
      refetchInvoices()
      setSettlingId(null)
    }
  }, [isSettled, refetchInvoices])

  // Convert reputation to score
  const reputation = reputationData ? Number(reputationData) : 0

  // Parse invoice IDs
  const tokenIds = invoiceIds ? (invoiceIds as bigint[]) : []

  const handleSettle = (tokenId: bigint) => {
    setSettlingId(tokenId)
    settle(tokenId)
  }

  return (
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
              <p className="text-2xl sm:text-3xl font-bold">{tokenIds.length}</p>
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
                isSettling={isSettling && settlingId === tokenId}
              />
            ))}
          </div>
        )}
      </Card>
    </div>
  )
}

// Component to display individual invoice details
function InvoiceItem({
  tokenId,
  onSettle,
  isSettling,
}: {
  tokenId: bigint
  onSettle: (tokenId: bigint) => void
  isSettling: boolean
}) {
  const { data: invoiceData } = useInvoiceDetails(tokenId)

  if (!invoiceData) {
    return (
      <div className="flex items-center justify-center p-4 bg-muted/50 rounded-lg">
        <Loader2 className="animate-spin" size={20} />
        <span className="ml-2 text-sm text-muted-foreground">Loading invoice...</span>
      </div>
    )
  }

  const invoice = invoiceData as any
  const amount = invoice.invoiceAmount ? formatUSDC(invoice.invoiceAmount) : "0"
  const collateral = invoice.collateralAmount ? formatUSDC(invoice.collateralAmount) : "0"
  const grant = (Number(amount) * 0.03).toFixed(2)
  const dueDate = invoice.dueDate ? new Date(Number(invoice.dueDate) * 1000).toLocaleDateString() : "N/A"
  const status = invoice.status || 0

  // Status: 0 = ACTIVE, 1 = SETTLED, 2 = DEFAULTED, 3 = LIQUIDATED
  const statusText = status === 0 ? "Active" : status === 1 ? "Settled" : status === 2 ? "Defaulted" : "Liquidated"
  const statusColor = status === 0 ? "bg-blue-600" : status === 1 ? "bg-green-600" : "bg-red-600"

  return (
    <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between p-4 bg-muted/50 rounded-lg gap-4">
      <div className="flex-1">
        <p className="font-medium">{invoice.customerName || "Unknown Customer"}</p>
        <p className="text-sm text-muted-foreground">Due: {dueDate}</p>
        <p className="text-xs text-muted-foreground mt-1">NFT #{tokenId.toString()}</p>
      </div>
      <div className="text-right">
        <p className="font-semibold">${Number(amount).toFixed(2)}</p>
        <p className="text-sm text-green-600">+${grant} grant</p>
        <p className="text-xs text-muted-foreground">${Number(collateral).toFixed(2)} collateral</p>
      </div>
      <div className="flex flex-col items-end gap-2">
        <Badge className={statusColor}>{statusText}</Badge>
        {status === 0 && (
          <Button
            size="sm"
            onClick={() => onSettle(tokenId)}
            disabled={isSettling}
            className="bg-green-600 hover:bg-green-700 text-white"
          >
            {isSettling ? (
              <>
                <Loader2 className="animate-spin mr-1" size={14} />
                Settling...
              </>
            ) : (
              <>
                <CheckCircle size={14} className="mr-1" />
                Settle
              </>
            )}
          </Button>
        )}
      </div>
    </div>
  )
}
