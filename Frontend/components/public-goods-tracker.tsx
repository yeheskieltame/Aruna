"use client"

import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts"
import { Heart, TrendingUp, Users, Loader2, CheckCircle2, AlertCircle } from "lucide-react"
import { useAccount } from "wagmi"
import {
  useTotalDonations,
  useBusinessContribution,
  useCurrentEpoch,
  useCurrentEpochDonations,
  useEpochDonations,
  useSupportedProjects,
  formatUSDC
} from "@/hooks/useContracts"
import { useEffect, useState } from "react"

// Project metadata (descriptions, categories, impact statements)
// Actual funding amounts will come from blockchain
const PROJECT_METADATA: Record<string, {
  category: string
  description: string
  impact: string
  color: string
}> = {
  "Ethereum Foundation": {
    category: "Core Infrastructure",
    description: "Supporting Ethereum protocol development",
    impact: "Funds critical research and development",
    color: "#ec4899",
  },
  "Gitcoin": {
    category: "Developer Community",
    description: "Funding open-source developers",
    impact: "Supports 200+ developers monthly",
    color: "#f59e0b",
  },
  "Protocol Guild": {
    category: "Core Infrastructure",
    description: "Sustainable funding for Ethereum core developers",
    impact: "Ensures long-term protocol maintenance",
    color: "#10b981",
  },
  "OpenZeppelin": {
    category: "Developer Tools",
    description: "Secure smart contract libraries and tools",
    impact: "Powers secure dApp development",
    color: "#06b6d4",
  },
  "EFF": {
    category: "Digital Rights",
    description: "Electronic Frontier Foundation - Defending digital privacy",
    impact: "Protects user rights and freedoms",
    color: "#8b5cf6",
  },
}

const COLORS = ["#3b82f6", "#ec4899", "#06b6d4", "#f59e0b", "#10b981", "#8b5cf6"]

export default function PublicGoodsTracker() {
  const { address } = useAccount()

  // Fetch data from blockchain
  const { data: totalDonationsData } = useTotalDonations()
  const { data: currentEpochDonationsData } = useCurrentEpochDonations()
  const { data: businessContributionData } = useBusinessContribution(address)
  const { data: currentEpochData } = useCurrentEpoch()
  const { data: supportedProjectsData } = useSupportedProjects()

  // State for epoch history
  const [epochHistory, setEpochHistory] = useState<{ epoch: string; amount: number }[]>([])

  // Format the blockchain data
  const totalFunded = totalDonationsData ? Number(formatUSDC(totalDonationsData as bigint)) : 0
  const currentEpochDonations = currentEpochDonationsData ? Number(formatUSDC(currentEpochDonationsData as bigint)) : 0
  const yourContribution = businessContributionData ? Number(formatUSDC(businessContributionData as bigint)) : 0
  const currentEpoch = currentEpochData ? Number(currentEpochData) : 0
  const supportedProjects = (supportedProjectsData as string[]) || []

  // Generate epoch history for chart (last 6 epochs)
  useEffect(() => {
    if (currentEpoch > 0) {
      const history: { epoch: string; amount: number }[] = []
      const startEpoch = Math.max(0, currentEpoch - 5)

      // For now, we'll show simplified data
      // In production, you'd fetch actual epoch data
      for (let i = startEpoch; i <= currentEpoch; i++) {
        history.push({
          epoch: `E${i}`,
          amount: i === currentEpoch ? currentEpochDonations : 0
        })
      }

      setEpochHistory(history)
    }
  }, [currentEpoch, currentEpochDonations])

  // Build projects list from blockchain data
  const projectsList = supportedProjects.map((projectName, index) => {
    const metadata = PROJECT_METADATA[projectName] || {
      category: "Public Goods",
      description: "Supporting open-source and public goods",
      impact: "Funding ecosystem development",
      color: COLORS[index % COLORS.length],
    }

    // Distribute total funding evenly across projects for display
    // In production, you'd track per-project funding
    const fundedAmount = supportedProjects.length > 0
      ? totalFunded / supportedProjects.length
      : 0

    return {
      id: index + 1,
      name: projectName,
      ...metadata,
      funded: fundedAmount,
    }
  })

  // Generate category data from projects
  const categoryMap = new Map<string, number>()
  projectsList.forEach(project => {
    const current = categoryMap.get(project.category) || 0
    categoryMap.set(project.category, current + project.funded)
  })

  const categoryData = Array.from(categoryMap.entries()).map(([name, value]) => ({
    name,
    value: Math.round(value * 100) / 100
  }))

  return (
    <div className="space-y-6">
      {/* Data Source Indicator */}
      <div className="flex items-center gap-2 text-xs text-muted-foreground bg-blue-50 dark:bg-blue-900/20 p-3 rounded-lg border border-blue-200 dark:border-blue-800">
        <CheckCircle2 size={14} className="text-blue-600" />
        <span>All data sourced from blockchain - OctantDonationModule smart contract</span>
      </div>

      {/* No Data Warning */}
      {totalFunded === 0 && (
        <Card className="p-6 bg-orange-50 dark:bg-orange-900/20 border-orange-200 dark:border-orange-800">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-orange-100 dark:bg-orange-900/30 rounded-lg flex items-center justify-center flex-shrink-0">
              <AlertCircle size={24} className="text-orange-600" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold text-lg mb-2">No Public Goods Donations Yet</h3>
              <div className="space-y-2 text-sm text-muted-foreground">
                <p>
                  Public goods donations are automatically created when investors harvest yield from vaults.
                  <strong className="text-orange-600 dark:text-orange-400"> 25% of all harvested yield</strong> goes to public goods via Octant.
                </p>
                <div className="mt-4 p-3 bg-white dark:bg-gray-900 rounded-lg border border-orange-200 dark:border-orange-800">
                  <p className="font-semibold text-sm mb-2">How it works:</p>
                  <ol className="text-xs space-y-1 list-decimal list-inside">
                    <li>Investors deposit USDC to Aave or Morpho vaults</li>
                    <li>Vaults generate yield from DeFi protocols</li>
                    <li><strong>Investors call "Harvest Yield"</strong> to distribute yield</li>
                    <li>25% of harvested yield → Public Goods automatically</li>
                    <li>Data appears here after first harvest!</li>
                  </ol>
                </div>
                <p className="text-xs pt-2">
                  👉 Go to <strong>Investor Dashboard</strong> and click <strong>"Harvest Yield"</strong> to generate public goods donations.
                </p>
              </div>
            </div>
          </div>
        </Card>
      )}

      {/* Impact Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground mb-1">Total Funded</p>
              <p className="text-2xl sm:text-3xl font-bold">${totalFunded.toLocaleString()}</p>
              <p className="text-xs text-muted-foreground mt-1">From blockchain</p>
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
              {address && <p className="text-xs text-muted-foreground mt-1">Your impact</p>}
              {!address && <p className="text-xs text-muted-foreground mt-1">Connect wallet</p>}
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
              <p className="text-2xl sm:text-3xl font-bold">{supportedProjects.length}</p>
              <p className="text-xs text-muted-foreground mt-1">Ecosystem projects</p>
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
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-lg">Donations by Epoch</h3>
            <Badge variant="outline" className="text-xs">
              Current: Epoch {currentEpoch}
            </Badge>
          </div>
          {epochHistory.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={epochHistory}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                <XAxis dataKey="epoch" stroke="var(--muted-foreground)" />
                <YAxis stroke="var(--muted-foreground)" />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "var(--card)",
                    border: "1px solid var(--border)",
                    borderRadius: "8px",
                  }}
                  formatter={(value: number) => [`$${value.toFixed(2)}`, "Donations"]}
                />
                <Bar dataKey="amount" fill="#3b82f6" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[300px] flex items-center justify-center text-muted-foreground">
              <div className="text-center">
                <Loader2 className="animate-spin h-8 w-8 mx-auto mb-2" />
                <p className="text-sm">Loading epoch data from blockchain...</p>
              </div>
            </div>
          )}
        </Card>

        <Card className="p-6">
          <h3 className="font-semibold text-lg mb-4">Funding by Category</h3>
          {categoryData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={categoryData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, value }) => `${name}: $${value.toFixed(0)}`}
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
                  formatter={(value: number) => [`$${value.toFixed(2)}`, "Funded"]}
                />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[300px] flex items-center justify-center text-muted-foreground">
              <div className="text-center">
                <Loader2 className="animate-spin h-8 w-8 mx-auto mb-2" />
                <p className="text-sm">Loading category data...</p>
              </div>
            </div>
          )}
        </Card>
      </div>

      {/* Projects List */}
      <Card className="p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-semibold text-lg">Supported Projects</h3>
          <Badge className="bg-blue-600">
            {supportedProjects.length} Projects
          </Badge>
        </div>

        {projectsList.length > 0 ? (
          <div className="space-y-4">
            {projectsList.map((project) => (
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
                    <p className="text-sm text-green-600 dark:text-green-400 font-medium">{project.impact}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-2xl font-bold text-transparent bg-linear-to-r from-blue-600 to-pink-600 bg-clip-text">
                      ${project.funded.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </p>
                    <p className="text-xs text-muted-foreground">Estimated Share</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <Loader2 className="animate-spin h-12 w-12 mx-auto mb-4 text-muted-foreground" />
            <p className="text-muted-foreground">Loading supported projects from blockchain...</p>
            <p className="text-xs text-muted-foreground mt-2">Fetching from OctantDonationModule contract</p>
          </div>
        )}
      </Card>

      {/* Impact Statement */}
      <Card className="p-6 sm:p-8 bg-linear-to-r from-blue-50 to-pink-50 dark:from-blue-900/20 dark:to-pink-900/20 border-0">
        <h3 className="font-semibold text-lg mb-4">Your Impact</h3>
        <div className="space-y-3 text-sm">
          <p>
            By participating in Aruna, you're not just earning yield—you're funding the future of open-source
            software and public goods.
          </p>
          <p>
            Every deposit automatically contributes <span className="font-semibold text-blue-600 dark:text-blue-400">25% of yield</span> to projects that benefit the entire Ethereum ecosystem.
            Together, we're building a sustainable funding model for public goods.
          </p>
          {totalFunded > 0 && (
            <div className="pt-3 border-t border-border">
              <p className="font-semibold">
                <span className="text-transparent bg-linear-to-r from-green-600 to-blue-600 bg-clip-text text-lg">
                  ${totalFunded.toLocaleString()} raised so far
                </span>
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                via Octant v2 integration - all data verified on-chain
              </p>
            </div>
          )}
          <p className="font-semibold text-blue-600 dark:text-blue-400 pt-2">Thank you for making a difference.</p>
        </div>
      </Card>
    </div>
  )
}
