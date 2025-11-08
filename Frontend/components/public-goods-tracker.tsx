"use client"

import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts"
import { Heart, TrendingUp, Users } from "lucide-react"
import { useAccount } from "wagmi"
import { useTotalDonations, useBusinessContribution, formatUSDC } from "@/hooks/useContracts"

const projectsData = [
  {
    id: 1,
    name: "Octant",
    category: "Public Goods Allocation",
    funded: 3450,
    description: "Decentralized public goods funding mechanism",
    impact: "Supports 50+ open-source projects",
    color: "#3b82f6",
  },
  {
    id: 2,
    name: "Ethereum Foundation",
    category: "Core Infrastructure",
    funded: 2100,
    description: "Supporting Ethereum protocol development",
    impact: "Funds critical research and development",
    color: "#ec4899",
  },
  {
    id: 3,
    name: "Open Source Collective",
    category: "Developer Tools",
    funded: 1850,
    description: "Supporting open-source software projects",
    impact: "Enables 100+ developer projects",
    color: "#06b6d4",
  },
  {
    id: 4,
    name: "Protocol Labs",
    category: "Infrastructure",
    funded: 1620,
    description: "IPFS and distributed web infrastructure",
    impact: "Powers decentralized storage",
    color: "#10b981",
  },
  {
    id: 5,
    name: "Gitcoin",
    category: "Developer Community",
    funded: 1240,
    description: "Funding open-source developers",
    impact: "Supports 200+ developers monthly",
    color: "#f59e0b",
  },
]

const monthlyData = [
  { month: "Jan", amount: 450 },
  { month: "Feb", amount: 620 },
  { month: "Mar", amount: 580 },
  { month: "Apr", amount: 890 },
  { month: "May", amount: 1200 },
  { month: "Jun", amount: 1350 },
]

const categoryData = [
  { name: "Public Goods", value: 3450 },
  { name: "Infrastructure", value: 3720 },
  { name: "Developer Tools", value: 1850 },
  { name: "Community", value: 1240 },
]

const COLORS = ["#3b82f6", "#ec4899", "#06b6d4", "#f59e0b"]

export default function PublicGoodsTracker() {
  const { address } = useAccount()

  // Fetch total donations from blockchain
  const { data: totalDonationsData } = useTotalDonations()
  const { data: businessContributionData } = useBusinessContribution(address)

  // Format the data
  const totalFunded = totalDonationsData ? Number(formatUSDC(totalDonationsData as bigint)) : 0
  const yourContribution = businessContributionData ? Number(formatUSDC(businessContributionData as bigint)) : 0

  const totalDonations = monthlyData.reduce((sum, m) => sum + m.amount, 0)

  return (
    <div className="space-y-6">
      {/* Impact Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Total Funded</p>
              <p className="text-2xl sm:text-3xl font-bold">${totalFunded.toLocaleString()}</p>
            </div>
            <div className="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
              <Heart size={24} className="text-green-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Your Contribution</p>
              <p className="text-2xl sm:text-3xl font-bold">${yourContribution.toFixed(2)}</p>
            </div>
            <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
              <Users size={24} className="text-blue-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Projects Supported</p>
              <p className="text-2xl sm:text-3xl font-bold">{projectsData.length}</p>
            </div>
            <div className="w-12 h-12 bg-pink-100 dark:bg-pink-900/30 rounded-lg flex items-center justify-center">
              <TrendingUp size={24} className="text-pink-600" />
            </div>
          </div>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="p-6">
          <h3 className="font-semibold text-lg mb-4">Funding Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={monthlyData}>
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
              <Bar dataKey="amount" fill="#3b82f6" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>

        <Card className="p-6">
          <h3 className="font-semibold text-lg mb-4">Funding by Category</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={categoryData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, value }) => `${name}: $${value}`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {categoryData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{
                  backgroundColor: "var(--card)",
                  border: "1px solid var(--border)",
                  borderRadius: "8px",
                }}
              />
            </PieChart>
          </ResponsiveContainer>
        </Card>
      </div>

      {/* Projects List */}
      <Card className="p-6">
        <h3 className="font-semibold text-lg mb-6">Supported Projects</h3>

        <div className="space-y-4">
          {projectsData.map((project) => (
            <div key={project.id} className="p-4 border border-border rounded-lg hover:bg-muted/50 transition">
              <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <div className="w-3 h-3 rounded-full" style={{ backgroundColor: project.color }}></div>
                    <h4 className="font-semibold text-lg">{project.name}</h4>
                    <Badge variant="outline" className="text-xs">
                      {project.category}
                    </Badge>
                  </div>
                  <p className="text-sm text-muted-foreground mb-2">{project.description}</p>
                  <p className="text-sm text-green-600 font-medium">{project.impact}</p>
                </div>
                <div className="text-right">
                  <p className="text-2xl font-bold text-transparent bg-gradient-to-r from-blue-600 to-pink-600 bg-clip-text">
                    ${project.funded.toLocaleString()}
                  </p>
                  <p className="text-xs text-muted-foreground">Total Funded</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </Card>

      {/* Impact Statement */}
      <Card className="p-6 sm:p-8 bg-gradient-to-r from-blue-50 to-pink-50 dark:from-blue-900/20 dark:to-pink-900/20 border-0">
        <h3 className="font-semibold text-lg mb-4">Your Impact</h3>
        <div className="space-y-3 text-sm">
          <p>
            By participating in Aruna, you're not just earning yield—you're funding the future of open-source
            software and public goods.
          </p>
          <p>
            Every deposit automatically contributes 25% of yield to projects that benefit the entire ecosystem.
            Together, we're building a sustainable funding model for public goods.
          </p>
          <p className="font-semibold text-blue-600 dark:text-blue-400">Thank you for making a difference.</p>
        </div>
      </Card>
    </div>
  )
}
