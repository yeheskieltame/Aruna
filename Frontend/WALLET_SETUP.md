# Wallet Setup Guide for Aruna Protocol

This guide will help you connect your wallet to Aruna Protocol on Base Sepolia testnet.

## Supported Wallets

Aruna Protocol supports the following wallets:

1. **Coinbase Wallet** (Recommended)
   - Smart Wallet (gasless transactions)
   - Browser Extension

2. **MetaMask**
   - Browser Extension

3. **WalletConnect**
   - Any wallet that supports WalletConnect v2

## Option 1: Coinbase Wallet Extension (Recommended)

### Installation

1. Visit [Coinbase Wallet Downloads](https://www.coinbase.com/wallet/downloads)
2. Click "Download" for Chrome/Brave/Edge browser
3. Install the extension from Chrome Web Store
4. Create a new wallet or import existing one

### Connecting to Aruna

1. Go to [Aruna Protocol](http://localhost:3000) or your deployment URL
2. Click "Connect Wallet" button on the homepage
3. Select "Coinbase Wallet" from the options
4. A popup will appear from the Coinbase Wallet extension
5. Review and approve the connection request
6. You're connected! 🎉

### Getting Test Funds

To use Aruna on Base Sepolia testnet, you'll need:

1. **Base Sepolia ETH** (for gas fees)
   - Visit [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-sepolia-faucet)
   - Enter your wallet address
   - Claim free testnet ETH

2. **Base Sepolia USDC** (for transactions)
   - Use [Circle's Testnet Faucet](https://faucet.circle.com/)
   - Select Base Sepolia network
   - Enter your wallet address
   - Receive test USDC

## Option 2: Coinbase Smart Wallet

Coinbase Smart Wallet provides gasless transactions and better UX:

1. Click "Connect Wallet" on Aruna
2. Select "Coinbase Wallet"
3. Choose "Create Smart Wallet" option
4. Follow the on-screen instructions
5. No extension installation needed!

## Option 3: MetaMask

1. Install [MetaMask Extension](https://metamask.io/download/)
2. Create or import your wallet
3. Add Base Sepolia network:
   - Network Name: Base Sepolia
   - RPC URL: `https://sepolia.base.org`
   - Chain ID: `84532`
   - Currency Symbol: ETH
   - Block Explorer: `https://sepolia.basescan.org`
4. Click "Connect Wallet" on Aruna
5. Select "MetaMask"
6. Approve the connection

## Option 4: WalletConnect

1. Use any wallet that supports WalletConnect (Trust Wallet, Rainbow, etc.)
2. Click "Connect Wallet" on Aruna
3. Select "WalletConnect"
4. Scan the QR code with your mobile wallet
5. Approve the connection

## Troubleshooting

### "Wallet not detected"
- Make sure your wallet extension is installed and unlocked
- Refresh the page and try again
- Check if you're using a supported browser (Chrome, Brave, Edge, Firefox)

### "Wrong network"
- Aruna Protocol runs on Base Sepolia (Chain ID: 84532)
- Switch your wallet to Base Sepolia network
- The app may prompt you to switch automatically

### "Insufficient balance"
- Make sure you have Base Sepolia ETH for gas fees
- Get free testnet ETH from the Base Sepolia faucet (see above)
- For USDC transactions, get test USDC from Circle's faucet

### "Transaction failed"
- Check if you have enough ETH for gas
- Try increasing gas limit in wallet settings
- Wait a few seconds and try again

## Need Help?

If you encounter any issues:

1. Check the [Base Sepolia Block Explorer](https://sepolia.basescan.org)
2. Verify your wallet is connected to Base Sepolia
3. Make sure you have sufficient testnet tokens
4. Open browser console (F12) to see detailed errors

## Security Tips

⚠️ **Important**: This is a testnet. Do NOT use real funds.

- Never share your seed phrase/private keys
- Always verify the contract addresses
- This is Base Sepolia TESTNET - tokens have no real value
- Do not send real ETH or USDC to testnet addresses

## Contract Addresses

**Aruna Protocol Contracts (Base Sepolia):**
- ArunaCore: `0x5ee04F6377e03b47F5e932968e87ad5599664Cf2`
- AaveVault: `0x8E9F6B3230800B781e461fce5F7F118152FeD969`
- MorphoVault: `0xc4388Fe5A3057eE1fc342a8018015f32f6aF6A7d`
- YieldRouter: `0x9721ee37de0F289A99f8EA2585293575AE2654CC`
- OctantModule: `0xB745282F0FCe7a669F9EbD50B403e895090b1b24`

All contracts are verified on [BaseScan](https://sepolia.basescan.org).
