"use client"

import { useState } from "react"
import Navigation from "@/components/navigation"
import BusinessDashboard from "@/components/business-dashboard"
import InvoiceForm from "@/components/invoice-form"
import { Button } from "@/components/ui/button"
import { Plus } from "lucide-react"

export default function BusinessPage() {
  const [showForm, setShowForm] = useState(false)
  const [refreshTrigger, setRefreshTrigger] = useState(0)

  const handleInvoiceSubmitted = () => {
    console.log("✅ Invoice submitted - triggering dashboard refresh")
    setShowForm(false)
    setRefreshTrigger(Date.now())
  }

  return (
    <main className="min-h-screen bg-background">
      <Navigation />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
        <div className="mb-8">
          <h1 className="text-3xl sm:text-4xl font-bold mb-2">Business Dashboard</h1>
          <p className="text-muted-foreground">Manage your invoices and track grants</p>
        </div>

        {!showForm ? (
          <div className="space-y-6">
            <Button onClick={() => setShowForm(true)} className="bg-blue-600 hover:bg-blue-700 text-white" size="lg">
              <Plus size={20} className="mr-2" />
              Submit New Invoice
            </Button>

            <BusinessDashboard refreshTrigger={refreshTrigger} />
          </div>
        ) : (
          <div className="space-y-6">
            <Button onClick={() => setShowForm(false)} variant="outline">
              Back to Dashboard
            </Button>
            <InvoiceForm onSubmit={handleInvoiceSubmitted} />
          </div>
        )}
      </div>
    </main>
  )
}
