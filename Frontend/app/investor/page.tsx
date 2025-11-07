"use client"

import { useState } from "react"
import Navigation from "@/components/navigation"
import InvestorDashboard from "@/components/investor-dashboard"
import VaultDeposit from "@/components/vault-deposit"
import { Button } from "@/components/ui/button"
import { Plus } from "lucide-react"

export default function InvestorPage() {
  const [showDeposit, setShowDeposit] = useState(false)

  return (
    <main className="min-h-screen bg-background">
      <Navigation isConnected={true} />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
        <div className="mb-8">
          <h1 className="text-3xl sm:text-4xl font-bold mb-2">Investor Dashboard</h1>
          <p className="text-muted-foreground">Earn yield while funding public goods</p>
        </div>

        {!showDeposit ? (
          <div className="space-y-6">
            <Button onClick={() => setShowDeposit(true)} className="bg-pink-600 hover:bg-pink-700 text-white" size="lg">
              <Plus size={20} className="mr-2" />
              Deposit to Vault
            </Button>

            <InvestorDashboard />
          </div>
        ) : (
          <div className="space-y-6">
            <Button onClick={() => setShowDeposit(false)} variant="outline">
              Back to Dashboard
            </Button>
            <VaultDeposit />
          </div>
        )}
      </div>
    </main>
  )
}
