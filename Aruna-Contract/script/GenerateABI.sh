#!/bin/bash

# Generate ABI files for frontend integration
# This script extracts ABIs from compiled contracts and formats them for frontend use

echo "Generating ABI files for Aruna Protocol..."

# Create output directory
mkdir -p abis

# Extract ABIs from compiled contracts
forge build --silent

# ArunaCore ABI
jq '.abi' out/ArunaCore.sol/ArunaCore.json > abis/ArunaCore.json

# AaveVaultAdapter ABI
jq '.abi' out/AaveVaultAdapter.sol/AaveVaultAdapter.json > abis/AaveVaultAdapter.json

# MorphoVaultAdapter ABI
jq '.abi' out/MorphoVaultAdapter.sol/MorphoVaultAdapter.json > abis/MorphoVaultAdapter.json

# YieldRouter ABI
jq '.abi' out/YieldRouter.sol/YieldRouter.json > abis/YieldRouter.json

# OctantDonationModule ABI
jq '.abi' out/OctantDonationModule.sol/OctantDonationModule.json > abis/OctantDonationModule.json

# IERC20 ABI (for USDC)
jq '.abi' lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol/IERC20.json > abis/IERC20.json 2>/dev/null || echo "[]" > abis/IERC20.json

echo "✅ ABI files generated in ./abis/"
echo ""
echo "Files created:"
ls -lh abis/
echo ""
echo "To copy ABIs to frontend, run:"
echo "cp -r abis ../Frontend/lib/"
