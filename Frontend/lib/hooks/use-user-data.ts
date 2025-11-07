"use client"

import { useAccount } from "wagmi"
import { useEffect, useState } from "react"
import { getUserBalance, getUserYield } from "@/lib/web3-utils"

export function useUserData() {
  const { address } = useAccount()
  const [balance, setBalance] = useState("0")
  const [yield_, setYield] = useState("0")
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!address) return

    const fetchData = async () => {
      setLoading(true)
      try {
        const [bal, yld] = await Promise.all([
          getUserBalance(address),
          getUserYield(address, process.env.NEXT_PUBLIC_Aruna_ADDRESS || ""),
        ])
        setBalance(bal)
        setYield(yld)
      } catch (error) {
        console.error("Error fetching user data:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
    const interval = setInterval(fetchData, 30000) // Refresh every 30 seconds

    return () => clearInterval(interval)
  }, [address])

  return { balance, yield: yield_, loading }
}
