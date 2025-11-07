"use client"

import type { ReactNode } from "react"

interface ResponsiveGridProps {
  children: ReactNode
  cols?: {
    mobile: number
    tablet: number
    desktop: number
  }
}

export function ResponsiveGrid({ children, cols = { mobile: 1, tablet: 2, desktop: 3 } }: ResponsiveGridProps) {
  const gridClass = `grid grid-cols-${cols.mobile} md:grid-cols-${cols.tablet} lg:grid-cols-${cols.desktop} gap-4 sm:gap-6`

  return <div className={gridClass}>{children}</div>
}
