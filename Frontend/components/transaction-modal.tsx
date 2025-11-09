"use client"

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { CheckCircle, XCircle, Loader2, ExternalLink, AlertCircle } from "lucide-react"
import { getTxExplorerUrl, formatTxHash } from "@/lib/utils/transaction-helpers"

export type TransactionStep = "idle" | "approving" | "confirming" | "pending" | "success" | "error"

interface TransactionModalProps {
  isOpen: boolean
  onClose: () => void
  step: TransactionStep
  txHash?: string
  error?: string
  title: string
  approvalMessage?: string
  confirmMessage?: string
  pendingMessage?: string
  successMessage?: string
  successDetails?: React.ReactNode
  onSuccess?: () => void
}

export function TransactionModal({
  isOpen,
  onClose,
  step,
  txHash,
  error,
  title,
  approvalMessage = "Approve the transaction in your wallet",
  confirmMessage = "Confirming your transaction...",
  pendingMessage = "Transaction is being processed on the blockchain...",
  successMessage = "Transaction completed successfully!",
  successDetails,
  onSuccess,
}: TransactionModalProps) {
  const handleClose = () => {
    if (step === "success" && onSuccess) {
      onSuccess()
    }
    onClose()
  }

  const canClose = step === "success" || step === "error" || step === "idle"

  return (
    <Dialog open={isOpen} onOpenChange={canClose ? handleClose : undefined}>
      <DialogContent className="sm:max-w-md" onPointerDownOutside={(e) => !canClose && e.preventDefault()}>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          <DialogDescription>
            {step === "approving" && "Waiting for your approval"}
            {step === "confirming" && "Confirming transaction"}
            {step === "pending" && "Processing transaction"}
            {step === "success" && "Transaction successful"}
            {step === "error" && "Transaction failed"}
          </DialogDescription>
        </DialogHeader>

        <div className="py-6">
          {/* APPROVING STATE */}
          {step === "approving" && (
            <div className="flex flex-col items-center text-center space-y-4">
              <div className="w-16 h-16 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center">
                <Loader2 className="animate-spin text-blue-600" size={32} />
              </div>
              <div>
                <h3 className="font-semibold text-lg mb-2">Approve Transaction</h3>
                <p className="text-sm text-muted-foreground">{approvalMessage}</p>
                <p className="text-xs text-muted-foreground mt-2">Check your wallet for the approval request</p>
              </div>
            </div>
          )}

          {/* CONFIRMING STATE */}
          {step === "confirming" && (
            <div className="flex flex-col items-center text-center space-y-4">
              <div className="w-16 h-16 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center">
                <Loader2 className="animate-spin text-blue-600" size={32} />
              </div>
              <div>
                <h3 className="font-semibold text-lg mb-2">Confirming Transaction</h3>
                <p className="text-sm text-muted-foreground">{confirmMessage}</p>
                <p className="text-xs text-muted-foreground mt-2">Please wait while we confirm your transaction</p>
              </div>
            </div>
          )}

          {/* PENDING STATE */}
          {step === "pending" && (
            <div className="flex flex-col items-center text-center space-y-4">
              <div className="w-16 h-16 bg-cyan-100 dark:bg-cyan-900/30 rounded-full flex items-center justify-center">
                <Loader2 className="animate-spin text-cyan-600" size={32} />
              </div>
              <div>
                <h3 className="font-semibold text-lg mb-2">Processing Transaction</h3>
                <p className="text-sm text-muted-foreground">{pendingMessage}</p>
                {txHash && (
                  <div className="mt-4 p-3 bg-muted rounded-lg">
                    <p className="text-xs text-muted-foreground mb-1">Transaction Hash:</p>
                    <p className="text-xs font-mono">{formatTxHash(txHash, 16)}</p>
                    <a
                      href={getTxExplorerUrl(txHash)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-blue-600 hover:underline flex items-center justify-center gap-1 mt-2"
                    >
                      View on BaseScan
                      <ExternalLink size={12} />
                    </a>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* SUCCESS STATE */}
          {step === "success" && (
            <div className="flex flex-col items-center text-center space-y-4">
              <div className="w-16 h-16 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center">
                <CheckCircle className="text-green-600" size={32} />
              </div>
              <div>
                <h3 className="font-semibold text-lg mb-2 text-green-600">Success!</h3>
                <p className="text-sm text-muted-foreground">{successMessage}</p>
                {successDetails && <div className="mt-4">{successDetails}</div>}
                {txHash && (
                  <div className="mt-4 p-3 bg-green-50 dark:bg-green-900/10 rounded-lg border border-green-200 dark:border-green-900">
                    <p className="text-xs text-muted-foreground mb-1">Transaction Hash:</p>
                    <p className="text-xs font-mono break-all">{formatTxHash(txHash, 16)}</p>
                    <a
                      href={getTxExplorerUrl(txHash)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-blue-600 hover:underline flex items-center justify-center gap-1 mt-2"
                    >
                      View on BaseScan
                      <ExternalLink size={12} />
                    </a>
                  </div>
                )}
              </div>
              <Button onClick={handleClose} className="w-full bg-green-600 hover:bg-green-700">
                Close
              </Button>
            </div>
          )}

          {/* ERROR STATE */}
          {step === "error" && (
            <div className="flex flex-col items-center text-center space-y-4">
              <div className="w-16 h-16 bg-red-100 dark:bg-red-900/30 rounded-full flex items-center justify-center">
                <XCircle className="text-red-600" size={32} />
              </div>
              <div>
                <h3 className="font-semibold text-lg mb-2 text-red-600">Transaction Failed</h3>
                <p className="text-sm text-muted-foreground mb-2">Something went wrong with your transaction</p>
                {error && (
                  <div className="mt-3 p-3 bg-red-50 dark:bg-red-900/10 rounded-lg border border-red-200 dark:border-red-900">
                    <div className="flex items-start gap-2">
                      <AlertCircle size={16} className="text-red-600 mt-0.5 flex-shrink-0" />
                      <p className="text-xs text-red-600 text-left break-words">{error}</p>
                    </div>
                  </div>
                )}
              </div>
              <div className="flex gap-2 w-full">
                <Button onClick={handleClose} variant="outline" className="flex-1">
                  Close
                </Button>
                <Button
                  onClick={() => window.location.reload()}
                  variant="default"
                  className="flex-1 bg-red-600 hover:bg-red-700"
                >
                  Try Again
                </Button>
              </div>
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}

/**
 * Success Details Components for different transaction types
 */

export function InvoiceSuccessDetails({
  customerName,
  invoiceAmount,
  grantAmount,
  collateralAmount,
}: {
  customerName: string
  invoiceAmount: number
  grantAmount: number
  collateralAmount: number
}) {
  return (
    <div className="bg-gradient-to-r from-blue-50 to-cyan-50 dark:from-blue-950/20 dark:to-cyan-950/20 p-4 rounded-lg border border-blue-200 dark:border-blue-900 text-left">
      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-muted-foreground">Customer:</span>
          <span className="font-semibold">{customerName}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-muted-foreground">Invoice Amount:</span>
          <span className="font-semibold">${invoiceAmount.toFixed(2)}</span>
        </div>
        <div className="flex justify-between border-t border-blue-200 dark:border-blue-800 pt-2">
          <span className="text-green-600">Grant Received:</span>
          <span className="font-semibold text-green-600">+${grantAmount.toFixed(2)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-muted-foreground">Collateral Locked:</span>
          <span className="font-semibold">${collateralAmount.toFixed(2)}</span>
        </div>
      </div>
    </div>
  )
}

export function VaultDepositSuccessDetails({
  vaultName,
  depositAmount,
  sharesReceived,
  apy,
  estimatedYield,
}: {
  vaultName: string
  depositAmount: number
  sharesReceived: string
  apy: number
  estimatedYield: number
}) {
  return (
    <div className="bg-gradient-to-r from-pink-50 to-purple-50 dark:from-pink-950/20 dark:to-purple-950/20 p-4 rounded-lg border border-pink-200 dark:border-pink-900 text-left">
      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-muted-foreground">Vault:</span>
          <span className="font-semibold">{vaultName}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-muted-foreground">Deposited:</span>
          <span className="font-semibold">${depositAmount.toFixed(2)} USDC</span>
        </div>
        <div className="flex justify-between">
          <span className="text-muted-foreground">Shares Received:</span>
          <span className="font-semibold">{sharesReceived}</span>
        </div>
        <div className="flex justify-between border-t border-pink-200 dark:border-pink-800 pt-2">
          <span className="text-muted-foreground">APY:</span>
          <span className="font-semibold text-pink-600">{(apy * 100).toFixed(2)}%</span>
        </div>
        <div className="flex justify-between">
          <span className="text-green-600">Est. Annual Yield:</span>
          <span className="font-semibold text-green-600">~${estimatedYield.toFixed(2)}</span>
        </div>
      </div>
    </div>
  )
}

export function WithdrawSuccessDetails({
  vaultName,
  withdrawAmount,
  sharesBurned,
}: {
  vaultName: string
  withdrawAmount: number
  sharesBurned: string
}) {
  return (
    <div className="bg-gradient-to-r from-cyan-50 to-blue-50 dark:from-cyan-950/20 dark:to-blue-950/20 p-4 rounded-lg border border-cyan-200 dark:border-cyan-900 text-left">
      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-muted-foreground">Vault:</span>
          <span className="font-semibold">{vaultName}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-green-600">USDC Received:</span>
          <span className="font-semibold text-green-600">+${withdrawAmount.toFixed(2)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-muted-foreground">Shares Burned:</span>
          <span className="font-semibold">{sharesBurned}</span>
        </div>
      </div>
    </div>
  )
}

export function YieldClaimSuccessDetails({
  claimedAmount,
  publicGoodsAmount,
  protocolFeeAmount,
}: {
  claimedAmount: number
  publicGoodsAmount: number
  protocolFeeAmount: number
}) {
  return (
    <div className="bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-950/20 dark:to-emerald-950/20 p-4 rounded-lg border border-green-200 dark:border-green-900 text-left">
      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-green-600 font-semibold">Your Yield (70%):</span>
          <span className="font-bold text-green-600 text-lg">+${claimedAmount.toFixed(2)}</span>
        </div>
        <div className="border-t border-green-200 dark:border-green-800 pt-2 space-y-1">
          <div className="flex justify-between text-xs">
            <span className="text-muted-foreground">To Public Goods (25%):</span>
            <span className="font-semibold text-pink-600">${publicGoodsAmount.toFixed(2)}</span>
          </div>
          <div className="flex justify-between text-xs">
            <span className="text-muted-foreground">Protocol Fee (5%):</span>
            <span className="font-semibold">${protocolFeeAmount.toFixed(2)}</span>
          </div>
        </div>
      </div>
    </div>
  )
}

export function SettlementSuccessDetails({
  invoiceAmount,
  collateralReturned,
  reputationGain,
}: {
  invoiceAmount: number
  collateralReturned: number
  reputationGain: number
}) {
  return (
    <div className="bg-gradient-to-r from-green-50 to-cyan-50 dark:from-green-950/20 dark:to-cyan-950/20 p-4 rounded-lg border border-green-200 dark:border-green-900 text-left">
      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-muted-foreground">Invoice Settled:</span>
          <span className="font-semibold">${invoiceAmount.toFixed(2)}</span>
        </div>
        <div className="flex justify-between border-t border-green-200 dark:border-green-800 pt-2">
          <span className="text-green-600">Collateral Returned:</span>
          <span className="font-semibold text-green-600">+${collateralReturned.toFixed(2)}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-cyan-600">Reputation Gained:</span>
          <span className="font-semibold text-cyan-600">+{reputationGain}</span>
        </div>
      </div>
    </div>
  )
}
