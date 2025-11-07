"use client"

import type { ReactNode } from "react"
import { Component } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { AlertCircle } from "lucide-react"

interface Props {
  children: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error) {
    console.error("Error caught by boundary:", error)
  }

  render() {
    if (this.state.hasError) {
      return (
        <Card className="p-6 border-red-200 dark:border-red-800">
          <div className="flex items-start gap-4">
            <AlertCircle className="text-red-600 flex-shrink-0 mt-1" size={24} />
            <div className="flex-1">
              <h3 className="font-semibold text-red-900 dark:text-red-200 mb-2">Something went wrong</h3>
              <p className="text-sm text-red-800 dark:text-red-300 mb-4">{this.state.error?.message}</p>
              <Button onClick={() => this.setState({ hasError: false, error: null })} variant="outline" size="sm">
                Try again
              </Button>
            </div>
          </div>
        </Card>
      )
    }

    return this.props.children
  }
}
