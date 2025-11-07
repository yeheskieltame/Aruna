"use client"

import { Button } from "@/components/ui/button"

import { Card } from "@/components/ui/card"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from "recharts"
import { TrendingUp, Gift, Zap } from "lucide-react"

const yieldData = [
  { month: "Jan", aave: 450, morpho: 520 },
  { month: "Feb", aave: 520, morpho: 580 },
  { month: "Mar", aave: 480, morpho: 610 },
  { month: "Apr", aave: 650, morpho: 720 },
]

const publicGoodsData = [
  { name: "Octant", value: 1200 },
  { name: "Other", value: 800 },
]

export default function InvestorDashboard() {
  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Total Deposited</p>
              <p className="text-2xl sm:text-3xl font-bold">$50,000</p>
            </div>
            <div className="w-12 h-12 bg-pink-100 dark:bg-pink-900/30 rounded-lg flex items-center justify-center">
              <Zap size={24} className="text-pink-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Yield Earned</p>
              <p className="text-2xl sm:text-3xl font-bold">$2,450</p>
            </div>
            <div className="w-12 h-12 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg flex items-center justify-center">
              <TrendingUp size={24} className="text-cyan-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Public Goods Funded</p>
              <p className="text-2xl sm:text-3xl font-bold">$612</p>
            </div>
            <div className="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
              <Gift size={24} className="text-green-600" />
            </div>
          </div>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="p-6">
          <h3 className="font-semibold text-lg mb-4">Yield Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={yieldData}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
              <XAxis dataKey="month" stroke="var(--muted-foreground)" />
              <YAxis stroke="var(--muted-foreground)" />
              <Tooltip
                contentStyle={{
                  backgroundColor: "var(--card)",
                  border: "1px solid var(--border)",
                  borderRadius: "8px",
                }}
              />
              <Line type="monotone" dataKey="aave" stroke="#3b82f6" strokeWidth={2} name="Aave" />
              <Line type="monotone" dataKey="morpho" stroke="#ec4899" strokeWidth={2} name="Morpho" />
            </LineChart>
          </ResponsiveContainer>
        </Card>

        <Card className="p-6">
          <h3 className="font-semibold text-lg mb-4">Public Goods Distribution</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={publicGoodsData}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
              <XAxis dataKey="name" stroke="var(--muted-foreground)" />
              <YAxis stroke="var(--muted-foreground)" />
              <Tooltip
                contentStyle={{
                  backgroundColor: "var(--card)",
                  border: "1px solid var(--border)",
                  borderRadius: "8px",
                }}
              />
              <Bar dataKey="value" fill="#06b6d4" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>
      </div>

      {/* Vault Options */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card className="p-6 card-hover">
          <h3 className="font-semibold text-lg mb-2">Aave v3 Vault</h3>
          <p className="text-sm text-muted-foreground mb-4">Stable, proven yield source</p>
          <div className="space-y-2 mb-4">
            <div className="flex justify-between text-sm">
              <span>Current APY</span>
              <span className="font-semibold text-blue-600">6.5%</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Your Balance</span>
              <span className="font-semibold">$25,000</span>
            </div>
          </div>
          <Button className="w-full bg-blue-600 hover:bg-blue-700 text-white" size="sm">
            Manage
          </Button>
        </Card>

        <Card className="p-6 card-hover">
          <h3 className="font-semibold text-lg mb-2">Morpho Vault</h3>
          <p className="text-sm text-muted-foreground mb-4">Optimized for higher yields</p>
          <div className="space-y-2 mb-4">
            <div className="flex justify-between text-sm">
              <span>Current APY</span>
              <span className="font-semibold text-pink-600">8.2%</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Your Balance</span>
              <span className="font-semibold">$25,000</span>
            </div>
          </div>
          <Button className="w-full bg-pink-600 hover:bg-pink-700 text-white" size="sm">
            Manage
          </Button>
        </Card>
      </div>
    </div>
  )
}
