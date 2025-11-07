"use client"

import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { TrendingUp, Calendar, DollarSign } from "lucide-react"

interface Invoice {
  id: string
  amount: number
  dueDate: string
  customerName: string
  status: "pending" | "paid" | "settled"
  grant: number
}

export default function BusinessDashboard({ invoices }: { invoices: Invoice[] }) {
  const totalGrants = invoices.reduce((sum, inv) => sum + inv.grant, 0)
  const activeInvoices = invoices.filter((inv) => inv.status === "pending").length

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Total Grants</p>
              <p className="text-2xl sm:text-3xl font-bold">${totalGrants.toFixed(2)}</p>
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
              <p className="text-2xl sm:text-3xl font-bold">{activeInvoices}</p>
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
              <p className="text-2xl sm:text-3xl font-bold">85%</p>
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

        {invoices.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-muted-foreground mb-4">No invoices yet</p>
            <p className="text-sm text-muted-foreground">Submit your first invoice to get started</p>
          </div>
        ) : (
          <div className="space-y-3">
            {invoices.map((invoice) => (
              <div key={invoice.id} className="flex items-center justify-between p-4 bg-muted/50 rounded-lg">
                <div className="flex-1">
                  <p className="font-medium">{invoice.customerName}</p>
                  <p className="text-sm text-muted-foreground">Due: {invoice.dueDate}</p>
                </div>
                <div className="text-right mr-4">
                  <p className="font-semibold">${invoice.amount.toFixed(2)}</p>
                  <p className="text-sm text-green-600">+${invoice.grant.toFixed(2)} grant</p>
                </div>
                <Badge
                  className={
                    invoice.status === "pending"
                      ? "badge-blue"
                      : invoice.status === "paid"
                        ? "badge-green"
                        : "badge-pink"
                  }
                >
                  {invoice.status}
                </Badge>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  )
}
