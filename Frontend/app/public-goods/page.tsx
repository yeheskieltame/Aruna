"use client"

import Navigation from "@/components/navigation"
import PublicGoodsTracker from "@/components/public-goods-tracker"

export default function PublicGoodsPage() {
  return (
    <main className="min-h-screen bg-background">
      <Navigation isConnected={true} />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
        <div className="mb-8">
          <h1 className="text-3xl sm:text-4xl font-bold mb-2">Public Goods Impact</h1>
          <p className="text-muted-foreground">See how Aruna is funding open-source and public goods</p>
        </div>

        <PublicGoodsTracker />
      </div>
    </main>
  )
}
