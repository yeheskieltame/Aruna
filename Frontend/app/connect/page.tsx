"use client"

import Navigation from "@/components/navigation"
import WalletOptions from "@/components/wallet-options"
import { useAccount } from "wagmi"
import { useRouter } from "next/navigation"
import { useEffect } from "react"

export default function ConnectPage() {
  const { isConnected } = useAccount()
  const router = useRouter()

  // Redirect to business dashboard if already connected
  useEffect(() => {
    if (isConnected) {
      router.push("/business")
    }
  }, [isConnected, router])

  return (
    <main className="min-h-screen bg-background">
      <Navigation />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 sm:py-20">
        <WalletOptions />
      </div>
    </main>
  )
}
