"use client"

import Link from "next/link"
import { Button } from "@/components/ui/button"
import { ArrowRight, Zap } from "lucide-react"

export default function LandingHero() {
  return (
    <section className="relative overflow-hidden py-12 sm:py-20 lg:py-28">
      {/* Background decoration */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-20 right-10 w-72 h-72 bg-blue-100 rounded-full mix-blend-multiply filter blur-3xl opacity-20 dark:opacity-10"></div>
        <div className="absolute bottom-20 left-10 w-72 h-72 bg-pink-100 rounded-full mix-blend-multiply filter blur-3xl opacity-20 dark:opacity-10"></div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center space-y-6 sm:space-y-8">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-50 dark:bg-blue-900/30 rounded-full border border-blue-200 dark:border-blue-800">
            <Zap size={16} className="text-blue-600 dark:text-blue-400" />
            <span className="text-sm font-medium text-blue-600 dark:text-blue-400">Now live on Base Sepolia</span>
          </div>

          {/* Main heading */}
          <div className="space-y-4">
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-balance leading-tight">
              Turn Invoice Payments Into{" "}
              <span className="bg-gradient-to-r from-blue-600 to-pink-600 bg-clip-text text-transparent">
                Public Goods Funding
              </span>
            </h1>
            <p className="text-lg sm:text-xl text-muted-foreground max-w-2xl mx-auto text-balance">
              Get instant working capital for your business while automatically funding public goods. No collateral. No
              credit checks. Just yield.
            </p>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center pt-4">
            <Link href="/connect">
              <Button size="lg" className="w-full sm:w-auto bg-blue-600 hover:bg-blue-700 text-white">
                Connect Wallet
                <ArrowRight size={18} className="ml-2" />
              </Button>
            </Link>
            <Link href="/business">
              <Button
                size="lg"
                variant="outline"
                className="w-full sm:w-auto"
              >
                For Businesses
              </Button>
            </Link>
            <Link href="/investor">
              <Button
                size="lg"
                variant="outline"
                className="w-full sm:w-auto border-pink-300 text-pink-600 hover:bg-pink-50 dark:border-pink-700 dark:text-pink-400 dark:hover:bg-pink-900/20 bg-transparent"
              >
                For Investors
              </Button>
            </Link>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 pt-8 sm:pt-12">
            <div className="space-y-1">
              <p className="text-2xl sm:text-3xl font-bold text-blue-600">$0</p>
              <p className="text-xs sm:text-sm text-muted-foreground">Collateral Required</p>
            </div>
            <div className="space-y-1">
              <p className="text-2xl sm:text-3xl font-bold text-pink-600">3%</p>
              <p className="text-xs sm:text-sm text-muted-foreground">Instant Grant</p>
            </div>
            <div className="space-y-1">
              <p className="text-2xl sm:text-3xl font-bold text-cyan-600">25%</p>
              <p className="text-xs sm:text-sm text-muted-foreground">To Public Goods</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
