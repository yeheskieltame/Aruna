"use client"

export function LoadingSkeleton() {
  return (
    <div className="space-y-4 animate-pulse">
      <div className="h-12 bg-muted rounded-lg"></div>
      <div className="h-32 bg-muted rounded-lg"></div>
      <div className="h-12 bg-muted rounded-lg"></div>
    </div>
  )
}

export function CardSkeleton() {
  return (
    <div className="p-6 space-y-4 animate-pulse">
      <div className="h-6 bg-muted rounded w-1/3"></div>
      <div className="h-4 bg-muted rounded w-2/3"></div>
      <div className="h-4 bg-muted rounded w-1/2"></div>
    </div>
  )
}
