"use client"

import { Card } from "@/components/ui/card"
import { FileText, Zap, TrendingUp, Gift } from "lucide-react"

const steps = [
  {
    icon: FileText,
    title: "Submit Invoice",
    description: "Upload your invoice details and expected payment date",
    color: "text-blue-600",
  },
  {
    icon: Zap,
    title: "Get Instant Grant",
    description: "Receive 3% of invoice value in USDC immediately",
    color: "text-pink-600",
  },
  {
    icon: TrendingUp,
    title: "Earn Yield",
    description: "Your collateral earns yield in Aave or Morpho",
    color: "text-cyan-600",
  },
  {
    icon: Gift,
    title: "Fund Public Goods",
    description: "25% of yield automatically supports public goods",
    color: "text-green-600",
  },
]

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="py-16 sm:py-24 bg-muted/30">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12 sm:mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">How It Works</h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">Simple, transparent, and designed for everyone</p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
          {steps.map((step, index) => {
            const Icon = step.icon
            return (
              <div key={index} className="relative">
                <Card className="p-6 h-full card-hover">
                  <div
                    className={`w-12 h-12 rounded-lg bg-gradient-to-br from-blue-100 to-pink-100 dark:from-blue-900/30 dark:to-pink-900/30 flex items-center justify-center mb-4`}
                  >
                    <Icon size={24} className={step.color} />
                  </div>
                  <h3 className="font-semibold text-lg mb-2">{step.title}</h3>
                  <p className="text-sm text-muted-foreground">{step.description}</p>
                </Card>
                {index < steps.length - 1 && (
                  <div className="hidden lg:block absolute top-1/2 -right-3 w-6 h-0.5 bg-gradient-to-r from-blue-400 to-pink-400"></div>
                )}
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
