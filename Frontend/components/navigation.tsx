"use client"

import Link from "next/link"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import { Menu, X } from "lucide-react"
import { useState } from "react"

export default function Navigation({ isConnected }: { isConnected: boolean }) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  return (
    <nav className="sticky top-0 z-50 bg-background/95 backdrop-blur border-b border-border">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 flex-shrink-0">
            <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-pink-500 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">YF</span>
            </div>
            <span className="font-bold text-lg hidden sm:inline">Aruna</span>
          </Link>

          {/* Desktop Menu */}
          <div className="hidden md:flex items-center gap-8">
            <Link href="/#how-it-works" className="text-sm text-muted-foreground hover:text-foreground transition">
              How It Works
            </Link>
            <Link href="/#features" className="text-sm text-muted-foreground hover:text-foreground transition">
              Features
            </Link>
            <Link href="/public-goods" className="text-sm text-muted-foreground hover:text-foreground transition">
              Impact
            </Link>
          </div>

          {/* Connect Button */}
          <div className="hidden md:block">
            <ConnectButton />
          </div>

          {/* Mobile Menu Button */}
          <button className="md:hidden p-2" onClick={() => setMobileMenuOpen(!mobileMenuOpen)} aria-label="Toggle menu">
            {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="md:hidden pb-4 space-y-3 border-t border-border pt-4">
            <Link
              href="/#how-it-works"
              className="block text-sm text-muted-foreground hover:text-foreground py-2"
              onClick={() => setMobileMenuOpen(false)}
            >
              How It Works
            </Link>
            <Link
              href="/#features"
              className="block text-sm text-muted-foreground hover:text-foreground py-2"
              onClick={() => setMobileMenuOpen(false)}
            >
              Features
            </Link>
            <Link
              href="/public-goods"
              className="block text-sm text-muted-foreground hover:text-foreground py-2"
              onClick={() => setMobileMenuOpen(false)}
            >
              Impact
            </Link>
            <div className="pt-2">
              <ConnectButton />
            </div>
          </div>
        )}
      </div>
    </nav>
  )
}
