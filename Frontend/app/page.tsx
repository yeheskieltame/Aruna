"use client"

import Navigation from "@/components/navigation"
import LandingHero from "@/components/landing-hero"
import HowItWorks from "@/components/how-it-works"
import Features from "@/components/features"
import Footer from "@/components/footer"

export default function Home() {
  return (
    <main className="min-h-screen bg-background">
      <Navigation />
      <LandingHero />
      <HowItWorks />
      <Features />
      <Footer />
    </main>
  )
}
