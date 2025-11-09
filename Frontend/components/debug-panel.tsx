"use client"

import { useAccount, useReadContract } from "wagmi"
import { Card } from "@/components/ui/card"
import { CONTRACTS, ABIS } from "@/lib/contracts"
import { formatUSDC } from "@/hooks/useContracts"
import { Badge } from "@/components/ui/badge"

/**
 * Debug Panel untuk troubleshooting transaction issues
 * Tambahkan ke page untuk melihat status wallet, balances, dan allowances
 */
export function DebugPanel() {
  const { address, isConnected, chain } = useAccount()

  // Check USDC balance
  const { data: usdcBalance } = useReadContract({
    address: CONTRACTS.USDC.address,
    abi: ABIS.ERC20,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
  })

  // Check USDC allowance for ArunaCore
  const { data: arunaCoreAllowance } = useReadContract({
    address: CONTRACTS.USDC.address,
    abi: ABIS.ERC20,
    functionName: "allowance",
    args: address ? [address, CONTRACTS.ARUNA_CORE.address] : undefined,
  })

  // Check USDC allowance for AaveVault
  const { data: aaveVaultAllowance } = useReadContract({
    address: CONTRACTS.USDC.address,
    abi: ABIS.ERC20,
    functionName: "allowance",
    args: address ? [address, CONTRACTS.AAVE_VAULT.address] : undefined,
  })

  // Check USDC allowance for MorphoVault
  const { data: morphoVaultAllowance } = useReadContract({
    address: CONTRACTS.USDC.address,
    abi: ABIS.ERC20,
    functionName: "allowance",
    args: address ? [address, CONTRACTS.MORPHO_VAULT.address] : undefined,
  })

  if (!isConnected) {
    return (
      <Card className="p-4 bg-yellow-50 dark:bg-yellow-900/20 border-yellow-200 dark:border-yellow-900">
        <p className="text-sm">⚠️ Wallet not connected</p>
      </Card>
    )
  }

  const isCorrectNetwork = chain?.id === 84532

  return (
    <Card className="p-6">
      <h3 className="font-bold text-lg mb-4">🔍 Debug Panel</h3>

      <div className="space-y-4 text-sm font-mono">
        {/* Network Status */}
        <div>
          <p className="text-muted-foreground mb-1">Network:</p>
          <div className="flex items-center gap-2">
            <Badge variant={isCorrectNetwork ? "default" : "destructive"}>
              {chain?.name || "Unknown"} ({chain?.id})
            </Badge>
            {!isCorrectNetwork && (
              <span className="text-red-600 text-xs">❌ Should be Base Sepolia (84532)</span>
            )}
          </div>
        </div>

        {/* Wallet Address */}
        <div>
          <p className="text-muted-foreground mb-1">Wallet:</p>
          <p className="text-xs break-all">{address}</p>
        </div>

        {/* USDC Balance */}
        <div>
          <p className="text-muted-foreground mb-1">USDC Balance:</p>
          <p className="text-lg font-bold">
            {usdcBalance ? formatUSDC(usdcBalance as bigint) : "0"} USDC
          </p>
          {usdcBalance && Number(formatUSDC(usdcBalance as bigint)) < 10 && (
            <p className="text-xs text-yellow-600 mt-1">
              ⚠️ Low balance - Get USDC from https://faucet.circle.com/
            </p>
          )}
        </div>

        {/* Allowances */}
        <div>
          <p className="text-muted-foreground mb-2">USDC Allowances:</p>
          <div className="space-y-2 pl-4">
            <div>
              <p className="text-xs text-muted-foreground">ArunaCore:</p>
              <p className={arunaCoreAllowance && BigInt(arunaCoreAllowance.toString()) > 0n ? "text-green-600" : "text-red-600"}>
                {arunaCoreAllowance ? formatUSDC(arunaCoreAllowance as bigint) : "0"} USDC
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Aave Vault:</p>
              <p className={aaveVaultAllowance && BigInt(aaveVaultAllowance.toString()) > 0n ? "text-green-600" : "text-red-600"}>
                {aaveVaultAllowance ? formatUSDC(aaveVaultAllowance as bigint) : "0"} USDC
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Morpho Vault:</p>
              <p className={morphoVaultAllowance && BigInt(morphoVaultAllowance.toString()) > 0n ? "text-green-600" : "text-red-600"}>
                {morphoVaultAllowance ? formatUSDC(morphoVaultAllowance as bigint) : "0"} USDC
              </p>
            </div>
          </div>
        </div>

        {/* Contract Addresses */}
        <div>
          <p className="text-muted-foreground mb-2">Contract Addresses:</p>
          <div className="space-y-1 pl-4 text-xs">
            <div>
              <span className="text-muted-foreground">USDC:</span>{" "}
              <a
                href={`https://sepolia.basescan.org/address/${CONTRACTS.USDC.address}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:underline"
              >
                {CONTRACTS.USDC.address}
              </a>
            </div>
            <div>
              <span className="text-muted-foreground">ArunaCore:</span>{" "}
              <a
                href={`https://sepolia.basescan.org/address/${CONTRACTS.ARUNA_CORE.address}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:underline"
              >
                {CONTRACTS.ARUNA_CORE.address}
              </a>
            </div>
          </div>
        </div>

        {/* Instructions */}
        <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded">
          <p className="text-xs text-blue-900 dark:text-blue-200">
            💡 <strong>Debugging Tips:</strong>
            <br />
            1. Check browser console for errors (F12)
            <br />
            2. Verify network is Base Sepolia (84532)
            <br />
            3. Ensure USDC balance sufficient
            <br />
            4. Check MetaMask activity tab for pending transactions
            <br />
            5. Look for console logs starting with 🔍, ✅, ❌
          </p>
        </div>
      </div>
    </Card>
  )
}
