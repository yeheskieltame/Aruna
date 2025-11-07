import { ethers } from "ethers"
import { CONTRACTS, ERC20_ABI, AAVE_POOL_ABI, Aruna_ABI } from "./contracts"

export async function getProvider() {
  if (typeof window !== "undefined" && window.ethereum) {
    return new ethers.BrowserProvider(window.ethereum)
  }
  throw new Error("No Ethereum provider found")
}

export async function getSigner() {
  const provider = await getProvider()
  return provider.getSigner()
}

export async function getUserBalance(userAddress: string): Promise<string> {
  try {
    const provider = await getProvider()
    const contract = new ethers.Contract(CONTRACTS.USDC.address, ERC20_ABI, provider)
    const balance = await contract.balanceOf(userAddress)
    return ethers.formatUnits(balance, CONTRACTS.USDC.decimals)
  } catch (error) {
    console.error("Error getting balance:", error)
    return "0"
  }
}

export async function approveUSDC(amount: string): Promise<string> {
  try {
    const signer = await getSigner()
    const contract = new ethers.Contract(CONTRACTS.USDC.address, ERC20_ABI, signer)
    const amountWei = ethers.parseUnits(amount, CONTRACTS.USDC.decimals)

    const tx = await contract.approve(CONTRACTS.AAVE_POOL.address, amountWei)
    const receipt = await tx.wait()
    return receipt?.transactionHash || ""
  } catch (error) {
    console.error("Error approving USDC:", error)
    throw error
  }
}

export async function depositToAave(amount: string, userAddress: string): Promise<string> {
  try {
    const signer = await getSigner()
    const contract = new ethers.Contract(CONTRACTS.AAVE_POOL.address, AAVE_POOL_ABI, signer)
    const amountWei = ethers.parseUnits(amount, CONTRACTS.USDC.decimals)

    const tx = await contract.supply(CONTRACTS.USDC.address, amountWei, userAddress, 0)
    const receipt = await tx.wait()
    return receipt?.transactionHash || ""
  } catch (error) {
    console.error("Error depositing to Aave:", error)
    throw error
  }
}

export async function submitInvoice(
  customerName: string,
  amount: string,
  dueDate: number,
  ArunaAddress: string,
): Promise<string> {
  try {
    const signer = await getSigner()
    const contract = new ethers.Contract(ArunaAddress, Aruna_ABI, signer)
    const amountWei = ethers.parseUnits(amount, CONTRACTS.USDC.decimals)

    const tx = await contract.submitInvoiceCommitment(customerName, amountWei, dueDate)
    const receipt = await tx.wait()
    return receipt?.transactionHash || ""
  } catch (error) {
    console.error("Error submitting invoice:", error)
    throw error
  }
}

export async function settleInvoice(tokenId: number, ArunaAddress: string): Promise<string> {
  try {
    const signer = await getSigner()
    const contract = new ethers.Contract(ArunaAddress, Aruna_ABI, signer)

    const tx = await contract.settleInvoice(tokenId)
    const receipt = await tx.wait()
    return receipt?.transactionHash || ""
  } catch (error) {
    console.error("Error settling invoice:", error)
    throw error
  }
}

export async function getUserYield(userAddress: string, ArunaAddress: string): Promise<string> {
  try {
    const provider = await getProvider()
    const contract = new ethers.Contract(ArunaAddress, Aruna_ABI, provider)
    const yield_ = await contract.getUserYield(userAddress)
    return ethers.formatUnits(yield_, CONTRACTS.USDC.decimals)
  } catch (error) {
    console.error("Error getting user yield:", error)
    return "0"
  }
}
