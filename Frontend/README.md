# Aruna

Turn future invoice payments into sustainable public goods funding.

## Overview

Aruna connects three key players:
- **Businesses**: Get instant working capital (3% grant) without collateral
- **Investors**: Earn yield on stablecoins while funding public goods
- **Public Goods**: Receive sustainable funding from yield distribution

## Features

- Invoice commitment system with instant grants
- Aave v3 and Morpho vault integration for optimized yields
- Automatic public goods funding (25% of yield)
- Mobile-responsive design for all users
- Built on Base Sepolia with OnchainKit integration
- Non-custodial smart contracts

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- MetaMask or compatible Web3 wallet

### Installation

1. Clone the repository
2. Install dependencies:
\`\`\`bash
npm install
\`\`\`

3. Set up environment variables:
\`\`\`bash
cp .env.example .env.local
\`\`\`

4. Add your WalletConnect Project ID and contract addresses to `.env.local`

5. Run the development server:
\`\`\`bash
npm run dev
\`\`\`

6. Open [http://localhost:3000](http://localhost:3000) in your browser

## Usage

### For Businesses

1. Connect your wallet
2. Navigate to `/business`
3. Click "Submit New Invoice"
4. Enter invoice details (customer name, amount, due date)
5. Deposit 10% collateral in USDC
6. Receive 3% instant grant
7. When paid, yield is distributed to public goods

### For Investors

1. Connect your wallet
2. Navigate to `/investor`
3. Click "Deposit to Vault"
4. Choose Aave v3 or Morpho vault
5. Select token (USDC, DAI, or USDT)
6. Enter deposit amount
7. Earn yield while supporting public goods

### Track Impact

1. Navigate to `/public-goods`
2. View total funding and projects supported
3. See your contribution to public goods

## Smart Contracts

The protocol uses:
- **Aave v3**: For stable yield generation
- **Morpho**: For optimized peer-to-peer yields
- **Octant**: For automatic public goods distribution
- **ERC-721**: For invoice commitment NFTs

## Architecture

\`\`\`
Aruna Protocol
├── Invoice Commitment System
│   ├── Submit invoice details
│   ├── Mint NFT commitment
│   └── Receive instant grant
├── Vault System
│   ├── Aave v3 Vault
│   ├── Morpho Vault
│   └── Yield Distribution
└── Public Goods Integration
    ├── Octant Allocation
    └── Impact Tracking
\`\`\`

## Configuration

Edit `lib/config.ts` to customize:
- Grant percentage (default: 3%)
- Collateral requirement (default: 10%)
- Public goods allocation (default: 25%)
- Protocol fee (default: 5%)

## Deployment

### Deploy to Vercel

1. Push code to GitHub
2. Connect repository to Vercel
3. Add environment variables in Vercel dashboard
4. Deploy

\`\`\`bash
vercel deploy
\`\`\`

## Development

### Build

\`\`\`bash
npm run build
\`\`\`

### Lint

\`\`\`bash
npm run lint
\`\`\`

## Security

- All smart contracts are non-custodial
- Funds held in Aave/Morpho vaults
- Row-level security for user data
- No private keys stored on servers

## Support

For issues or questions:
- Open an issue on GitHub
- Check documentation at `/docs`
- Visit our website for more info

## License

MIT

## Acknowledgments

Built with:
- Next.js 16
- Tailwind CSS
- Recharts
- RainbowKit & Wagmi
- Ethers.js
