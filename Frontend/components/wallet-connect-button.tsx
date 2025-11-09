"use client"

import { useState } from "react"
import { useAccount, useConnect, useDisconnect } from "wagmi"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  WalletDropdown,
  WalletDropdownBasename,
  WalletDropdownDisconnect,
  WalletDropdownLink,
  Wallet as WalletWrapper,
} from "@coinbase/onchainkit/wallet"
import { Address, Avatar, Name, Identity, EthBalance } from "@coinbase/onchainkit/identity"
import { Wallet, Link2, Smartphone } from "lucide-react"

export function WalletConnectButton() {
  const [open, setOpen] = useState(false)
  const { isConnected, address } = useAccount()
  const { connectors, connect, isPending } = useConnect()
  const { disconnect } = useDisconnect()

  const handleConnect = (connector: any) => {
    connect({ connector })
    setOpen(false)
  }

  // If connected, show the wallet dropdown
  if (isConnected && address) {
    return (
      <WalletWrapper>
        <Button variant="outline" className="gap-2">
          <Avatar address={address} className="h-6 w-6" />
          <Name address={address} />
        </Button>
        <WalletDropdown>
          <Identity className="px-4 pt-3 pb-2" address={address} hasCopyAddressOnClick>
            <Avatar />
            <Name />
            <Address />
            <EthBalance />
          </Identity>
          <WalletDropdownBasename />
          <WalletDropdownLink icon="wallet" href="https://keys.coinbase.com">
            Wallet
          </WalletDropdownLink>
          <WalletDropdownDisconnect />
        </WalletDropdown>
      </WalletWrapper>
    )
  }

  // If not connected, show the connect button with modal
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="default" className="gap-2">
          <Wallet size={16} />
          Connect Wallet
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Connect Your Wallet</DialogTitle>
          <DialogDescription>Choose your preferred wallet to get started</DialogDescription>
        </DialogHeader>

        <div className="space-y-3 mt-4">
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
              <Card key={connector.uid} className="p-3 hover:shadow-md transition-shadow cursor-pointer">
                <button
                  onClick={() => handleConnect(connector)}
                  disabled={isPending}
                  className="w-full flex items-center gap-3 text-left disabled:opacity-50"
                >
                  <div className="w-12 h-12 bg-muted rounded-lg flex items-center justify-center flex-shrink-0">
                    {icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-sm mb-0.5">{connector.name}</h3>
                    <p className="text-xs text-muted-foreground truncate">{description}</p>
                  </div>
                </button>
              </Card>
            )
          })}
        </div>

        {/* Coinbase Wallet Extension Instructions */}
        <Card className="p-4 bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800 mt-4">
          <div className="flex items-start gap-2">
            <Smartphone size={18} className="text-blue-600 mt-0.5 flex-shrink-0" />
            <div className="space-y-2">
              <h4 className="font-semibold text-sm text-blue-900 dark:text-blue-100">
                Don't have a wallet yet?
              </h4>
              <p className="text-xs text-blue-800 dark:text-blue-200">
                Download Coinbase Wallet or MetaMask extension from your browser's extension store
              </p>
              <div className="flex gap-2 mt-2">
                <a
                  href="https://www.coinbase.com/wallet/downloads"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-xs text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center gap-1"
                >
                  Coinbase Wallet
                  <Link2 size={12} />
                </a>
                <span className="text-blue-400">•</span>
                <a
                  href="https://metamask.io/download/"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-xs text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center gap-1"
                >
                  MetaMask
                  <Link2 size={12} />
                </a>
              </div>
            </div>
          </div>
        </Card>
      </DialogContent>
    </Dialog>
  )
}
