# Aruna Protocol - Frontend

> Turn invoice payments into sustainable public goods funding

Aruna Protocol Frontend adalah antarmuka web untuk berinteraksi dengan Aruna smart contracts di Base Sepolia. Dibangun dengan Next.js 16, OnchainKit, dan Wagmi untuk pengalaman Web3 yang seamless.

## 🌟 Features

### For Businesses
- **Invoice Financing**: Submit invoice commitments dan dapatkan 3% instant grant
- **Low Collateral**: Hanya 10% collateral requirement (net 7% setelah grant)
- **Reputation System**: Build reputation dengan settle invoices tepat waktu
- **NFT Invoices**: Setiap invoice adalah ERC-721 NFT yang bisa ditransfer

### For Investors
- **Dual Vault Options**:
  - Aave v3 (6.5% APY) - Stable & proven
  - Morpho (8.2% APY) - Optimized yields
- **ERC-4626 Compliant**: Standard vault interface
- **No Lock-up**: Withdraw kapan saja tanpa penalty
- **Yield Sharing**: 70% untuk investor, 25% untuk public goods, 5% protocol fee

### For Public Goods
- **Automatic Funding**: 25% dari semua yield otomatis ke Octant v2
- **Transparent**: Track semua donations dan impact
- **Sustainable**: Ongoing funding dari invoice commitments

## 🚀 Quick Start

```bash
# Install dependencies
pnpm install

# Run development server
pnpm dev

# Build for production
pnpm build
pnpm start
```

Open [http://localhost:3000](http://localhost:3000)

## 📋 Prerequisites

- **Node.js** 18+
- **pnpm** 10.20.0+
- **MetaMask** atau compatible wallet
- **Base Sepolia ETH** ([get from faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet))
- **Base Sepolia USDC** ([get from Circle](https://faucet.circle.com/))

## 🔧 Configuration

Environment variables sudah dikonfigurasi di `.env.local`:

```env
# Network
NEXT_PUBLIC_CHAIN_ID=84532
NEXT_PUBLIC_BASE_SEPOLIA_RPC=https://sepolia.base.org

# OnchainKit (sudah configured)
NEXT_PUBLIC_ONCHAINKIT_API_KEY=eZW3b3iiGj9JfdK6Uui9Hize9Zd3ldoV

# Deployed Contracts (Base Sepolia)
NEXT_PUBLIC_ARUNA_CORE=0xE60dcA6869F072413557769bDFd4e30ceFa6997f
NEXT_PUBLIC_AAVE_VAULT=0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905
NEXT_PUBLIC_MORPHO_VAULT=0x16dea7eE228c0781938E6869c07ceb2EEA7bd564
NEXT_PUBLIC_YIELD_ROUTER=0x124d8F59748860cdD851fB176c7630dD71016e89
NEXT_PUBLIC_OCTANT_MODULE=0xEDc5CeE824215cbeEBC73e508558a955cdD75F00
```

**Semua contract addresses sudah deployed dan verified!** ✅

## 🔗 Deployed Contracts

| Contract | Address | Explorer |
|----------|---------|----------|
| ArunaCore | `0xE60dcA6869F072413557769bDFd4e30ceFa6997f` | [View →](https://sepolia.basescan.org/address/0xE60dcA6869F072413557769bDFd4e30ceFa6997f) |
| AaveVaultAdapter | `0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905` | [View →](https://sepolia.basescan.org/address/0xCE62F26dCAc5Cfc9C1ac03888Dc6D4D1e2e47905) |
| MorphoVaultAdapter | `0x16dea7eE228c0781938E6869c07ceb2EEA7bd564` | [View →](https://sepolia.basescan.org/address/0x16dea7eE228c0781938E6869c07ceb2EEA7bd564) |
| YieldRouter | `0x124d8F59748860cdD851fB176c7630dD71016e89` | [View →](https://sepolia.basescan.org/address/0x124d8F59748860cdD851fB176c7630dD71016e89) |

## 📚 Documentation

- [Setup Guide](./SETUP_GUIDE.md) - Complete setup instructions with testing guide
- [Integration Guide](../INTEGRATION_GUIDE.md) - Contract integration details
- [Smart Contracts](../Aruna-Contract/README.md) - Contract documentation

---

Built with ❤️ for Octant DeFi Hackathon 2025
