"use client"

import { Card } from "@/components/ui/card"
import { Shield, Zap, BarChart3, Users } from "lucide-react"

const features = [
  {
    icon: Shield,
    title: "Secure & Transparent",
    description: "Smart contracts handle all transactions. Your funds are always in your control.",
    color: "from-blue-500 to-blue-600",
  },
  {
    icon: Zap,
    title: "Instant Liquidity",
    description: "Get working capital in seconds, not weeks. No lengthy approval processes.",
    color: "from-pink-500 to-pink-600",
  },
  {
    icon: BarChart3,
    title: "Optimized Yield",
    description: "Your collateral earns the best rates through Aave and Morpho integration.",
    color: "from-cyan-500 to-cyan-600",
  },
  {
    icon: Users,
    title: "Impact Tracking",
    description: "See exactly how your participation funds public goods and open-source projects.",
    color: "from-green-500 to-green-600",
  },
]

export default function Features() {
  return (
    <section id="features" className="py-16 sm:py-24">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12 sm:mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">Why Aruna</h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">
            Built for businesses and investors who care about impact
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 sm:gap-8">
          {features.map((feature, index) => {
            const Icon = feature.icon
            return (
              <Card key={index} className="p-6 sm:p-8 card-hover">
                <div
                  className={`w-12 h-12 rounded-lg bg-gradient-to-br ${feature.color} flex items-center justify-center mb-4`}
                >
                  <Icon size={24} className="text-white" />
                </div>
                <h3 className="font-semibold text-lg mb-2">{feature.title}</h3>
                <p className="text-muted-foreground">{feature.description}</p>
              </Card>
            )
          })}
        </div>
      </div>
    </section>
  )
}
