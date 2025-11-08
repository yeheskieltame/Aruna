"use client"

import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { useConnect, useAccount } from "wagmi"
import { Wallet, Link2, Smartphone } from "lucide-react"

export default function WalletOptions() {
  const { connectors, connect, isPending } = useConnect()
  const { isConnected } = useAccount()

  if (isConnected) {
    return null
  }

  return (
    <div className="space-y-4">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold mb-2">Connect Your Wallet</h2>
        <p className="text-muted-foreground">Choose your preferred wallet to get started</p>
      </div>

      <div className="grid grid-cols-1 gap-4 max-w-md mx-auto">
        {connectors.map((connector) => {
          const isCoinbase = connector.name.toLowerCase().includes("coinbase")
          const isMetaMask = connector.name.toLowerCase().includes("metamask")
          const isWalletConnect = connector.name.toLowerCase().includes("walletconnect")

          let icon = <Wallet size={24} />
          let description = "Connect with " + connector.name

          if (isCoinbase) {
            icon = <Wallet size={24} className="text-blue-600" />
            description = "Coinbase Wallet Extension or Smart Wallet"
          } else if (isMetaMask) {
            icon = <Wallet size={24} className="text-orange-600" />
            description = "MetaMask Browser Extension"
          } else if (isWalletConnect) {
            icon = <Link2 size={24} className="text-pink-600" />
            description = "Connect any wallet via WalletConnect"
          }

          return (
            <Card key={connector.uid} className="p-4 hover:shadow-lg transition-shadow">
              <Button
                onClick={() => connect({ connector })}
                disabled={isPending}
                variant="ghost"
                className="w-full h-auto p-4 flex items-start gap-4 hover:bg-muted/50"
              >
                <div className="w-12 h-12 bg-muted rounded-lg flex items-center justify-center flex-shrink-0">
                  {icon}
                </div>
                <div className="flex-1 text-left">
                  <h3 className="font-semibold text-base mb-1">{connector.name}</h3>
                  <p className="text-sm text-muted-foreground">{description}</p>
                </div>
              </Button>
            </Card>
          )
        })}
      </div>

      {/* Coinbase Wallet Extension Instructions */}
      <Card className="p-6 bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800 max-w-md mx-auto mt-6">
        <div className="flex items-start gap-3">
          <Smartphone size={20} className="text-blue-600 mt-1 flex-shrink-0" />
          <div className="space-y-2">
            <h4 className="font-semibold text-blue-900 dark:text-blue-100">Using Coinbase Wallet Extension?</h4>
            <ol className="text-sm text-blue-800 dark:text-blue-200 space-y-1 list-decimal list-inside">
              <li>Install Coinbase Wallet extension from Chrome Web Store</li>
              <li>Create or import your wallet</li>
              <li>Click "Coinbase Wallet" button above</li>
              <li>Approve the connection in the extension popup</li>
            </ol>
            <a
              href="https://www.coinbase.com/wallet/downloads"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center gap-1 mt-2"
            >
              Download Coinbase Wallet Extension
              <Link2 size={14} />
            </a>
          </div>
        </div>
      </Card>
    </div>
  )
}
