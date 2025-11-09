"use client"

import { useState } from "react"
import Navigation from "@/components/navigation"
import InvestorDashboard from "@/components/investor-dashboard"
import VaultDeposit from "@/components/vault-deposit"
import VaultWithdraw from "@/components/vault-withdraw"
import { Button } from "@/components/ui/button"
import { Plus, ArrowDownToLine } from "lucide-react"

export default function InvestorPage() {
  const [view, setView] = useState<"dashboard" | "deposit" | "withdraw">("dashboard")

  return (
    <main className="min-h-screen bg-background">
      <Navigation />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
        <div className="mb-8">
          <h1 className="text-3xl sm:text-4xl font-bold mb-2">Investor Dashboard</h1>
          <p className="text-muted-foreground">Earn yield while funding public goods</p>
        </div>

        {view === "dashboard" && (
          <div className="space-y-6">
            <div className="flex gap-3">
              <Button onClick={() => setView("deposit")} className="bg-pink-600 hover:bg-pink-700 text-white" size="lg">
                <Plus size={20} className="mr-2" />
                Deposit to Vault
              </Button>
              <Button onClick={() => setView("withdraw")} variant="outline" size="lg">
                <ArrowDownToLine size={20} className="mr-2" />
                Withdraw
              </Button>
            </div>

            <InvestorDashboard onManageClick={(vault) => setView("withdraw")} />
          </div>
        )}

        {view === "deposit" && (
          <div className="space-y-6">
            <Button onClick={() => setView("dashboard")} variant="outline">
              Back to Dashboard
            </Button>
            <VaultDeposit onSuccess={() => setView("dashboard")} />
          </div>
        )}

        {view === "withdraw" && (
          <div className="space-y-6">
            <Button onClick={() => setView("dashboard")} variant="outline">
              Back to Dashboard
            </Button>
            <VaultWithdraw onSuccess={() => setView("dashboard")} />
          </div>
        )}
      </div>
    </main>
  )
}
