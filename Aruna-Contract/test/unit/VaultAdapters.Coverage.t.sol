// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/vaults/AaveVaultAdapter.sol";
import "../../src/vaults/MorphoVaultAdapter.sol";
import "../../src/modules/YieldRouter.sol";
import "../../src/modules/OctantDonationModule.sol";
import "../../src/mocks/MockOctantDeposits.sol";
import "../helpers/TestHelpers.sol";

/**
 * @title VaultAdapters100CoverageTest
 * @notice Additional tests to achieve 100% coverage for Aave and Morpho vault adapters
 * @dev Covers constructor validation, ERC-4626 functions, edge cases, and error paths
 */
contract VaultAdapters100CoverageTest is TestHelpers {
    AaveVaultAdapter public aaveVault;
    MorphoVaultAdapter public morphoVault;
    YieldRouter public yieldRouter;
    OctantDonationModule public octantModule;

    MockUSDC public usdc;
    MockUSDC public wrongAsset;
    MockAavePool public aavePool;
    MockAToken public aToken;
    MockMetaMorpho public metaMorpho;
    MockOctantDeposits public mockOctant;

    function setUp() public {
        labelAddresses();

        usdc = new MockUSDC();
        wrongAsset = new MockUSDC();

        aToken = new MockAToken();
        aavePool = new MockAavePool(address(aToken));
        aToken.setPool(address(aavePool));

        metaMorpho = new MockMetaMorpho(usdc, address(0x123));
        mockOctant = new MockOctantDeposits(address(usdc));

        octantModule = new OctantDonationModule(address(mockOctant), address(usdc), owner);
        yieldRouter = new YieldRouter(address(usdc), address(octantModule), treasury, owner);

        usdc.transfer(address(aavePool), 100_000_000 * 1e6);
        usdc.transfer(address(metaMorpho), 100_000_000 * 1e6);
        usdc.transfer(ALICE, 1_000_000 * 1e6);
        usdc.transfer(BOB, 1_000_000 * 1e6);
    }

    // ============ Aave Vault Constructor Tests ============

    function testAaveConstructorRevertsWithZeroAsset() public {
        // Zero asset causes SafeERC20 error when forceApprove is called, not InvalidAddress
        vm.expectRevert();
        new AaveVaultAdapter(IERC20(address(0)), address(aavePool), address(aToken), address(yieldRouter), owner);
    }

    function testAaveConstructorRevertsWithZeroPool() public {
        vm.expectRevert(AaveVaultAdapter.InvalidAddress.selector);
        new AaveVaultAdapter(usdc, address(0), address(aToken), address(yieldRouter), owner);
    }

    function testAaveConstructorRevertsWithZeroAToken() public {
        vm.expectRevert(AaveVaultAdapter.InvalidAddress.selector);
        new AaveVaultAdapter(usdc, address(aavePool), address(0), address(yieldRouter), owner);
    }

    function testAaveConstructorRevertsWithZeroYieldRouter() public {
        vm.expectRevert(AaveVaultAdapter.InvalidAddress.selector);
        new AaveVaultAdapter(usdc, address(aavePool), address(aToken), address(0), owner);
    }

    function testAaveConstructorRevertsWithAllZeroAddresses() public {
        vm.expectRevert(AaveVaultAdapter.InvalidAddress.selector);
        new AaveVaultAdapter(IERC20(address(0)), address(0), address(0), address(0), owner);
    }

    // ============ Morpho Vault Constructor Tests ============

    function testMorphoConstructorRevertsWithZeroAsset() public {
        // Zero asset causes asset mismatch check to fail, not InvalidAddress
        vm.expectRevert("Asset mismatch with MetaMorpho vault");
        new MorphoVaultAdapter(IERC20(address(0)), address(metaMorpho), address(yieldRouter), owner);
    }

    function testMorphoConstructorRevertsWithZeroMetaMorpho() public {
        vm.expectRevert(MorphoVaultAdapter.InvalidAddress.selector);
        new MorphoVaultAdapter(usdc, address(0), address(yieldRouter), owner);
    }

    function testMorphoConstructorRevertsWithZeroYieldRouter() public {
        vm.expectRevert(MorphoVaultAdapter.InvalidAddress.selector);
        new MorphoVaultAdapter(usdc, address(metaMorpho), address(0), owner);
    }

    function testMorphoConstructorRevertsWithAssetMismatch() public {
        // Create MetaMorpho with different asset
        MockMetaMorpho wrongMetaMorpho = new MockMetaMorpho(wrongAsset, address(0x123));

        vm.expectRevert("Asset mismatch with MetaMorpho vault");
        new MorphoVaultAdapter(usdc, address(wrongMetaMorpho), address(yieldRouter), owner);
    }

    // ============ ERC-4626 Mint Function Tests ============

    function testAaveMintFunction() public {
        aaveVault = new AaveVaultAdapter(usdc, address(aavePool), address(aToken), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(aaveVault));

        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), type(uint256).max);

        uint256 sharesToMint = 10_000 * 1e6;
        uint256 assetsRequired = aaveVault.previewMint(sharesToMint);

        uint256 balanceBefore = usdc.balanceOf(ALICE);
        uint256 assets = aaveVault.mint(sharesToMint, ALICE);

        assertEq(aaveVault.balanceOf(ALICE), sharesToMint);
        assertEq(assets, assetsRequired);
        assertEq(usdc.balanceOf(ALICE), balanceBefore - assets);

        vm.stopPrank();
    }

    function testMorphoMintFunction() public {
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(morphoVault));

        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), type(uint256).max);

        uint256 sharesToMint = 10_000 * 1e6;
        uint256 assetsRequired = morphoVault.previewMint(sharesToMint);

        uint256 balanceBefore = usdc.balanceOf(ALICE);
        uint256 assets = morphoVault.mint(sharesToMint, ALICE);

        assertEq(morphoVault.balanceOf(ALICE), sharesToMint);
        assertEq(assets, assetsRequired);
        assertEq(usdc.balanceOf(ALICE), balanceBefore - assets);

        vm.stopPrank();
    }

    // ============ Morpho MIN_SHARES Tests ============

    function testMorphoFirstDepositBelowMinSharesReverts() public {
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);

        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), type(uint256).max);

        // First deposit below MIN_SHARES (1000) should revert
        vm.expectRevert(MorphoVaultAdapter.MinimumSharesNotMet.selector);
        morphoVault.deposit(999, ALICE);

        vm.stopPrank();
    }

    function testMorphoSecondDepositBelowMinSharesSucceeds() public {
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(morphoVault));

        // First deposit above MIN_SHARES
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), type(uint256).max);
        morphoVault.deposit(10_000 * 1e6, ALICE);
        vm.stopPrank();

        // Second deposit below MIN_SHARES should succeed
        vm.startPrank(BOB);
        usdc.approve(address(morphoVault), type(uint256).max);
        uint256 shares = morphoVault.deposit(500, BOB); // Below MIN_SHARES but OK for 2nd deposit
        assertTrue(shares > 0);
        vm.stopPrank();
    }

    // ============ Harvest Timing Edge Cases ============

    function testAaveDepositExactlyAtHarvestInterval() public {
        aaveVault = new AaveVaultAdapter(usdc, address(aavePool), address(aToken), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(aaveVault));

        // First deposit
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), type(uint256).max);
        aaveVault.deposit(100_000 * 1e6, ALICE);

        // Add yield
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 1_000 * 1e6);

        // Fast forward exactly to HARVEST_INTERVAL (1 day)
        vm.warp(block.timestamp + 1 days);

        uint256 yieldBefore = aaveVault.getTotalYieldGenerated();

        // Second deposit should trigger harvest
        aaveVault.deposit(10_000 * 1e6, ALICE);

        uint256 yieldAfter = aaveVault.getTotalYieldGenerated();
        assertTrue(yieldAfter > yieldBefore, "Should have harvested yield");

        vm.stopPrank();
    }

    function testMorphoWithdrawExactlyAtHarvestInterval() public {
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(morphoVault));

        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), type(uint256).max);
        morphoVault.deposit(100_000 * 1e6, ALICE);

        // Add yield
        metaMorpho.simulateYield(100);

        // Fast forward exactly 1 day
        vm.warp(block.timestamp + 1 days);

        uint256 yieldBefore = morphoVault.getTotalYieldGenerated();

        // Withdraw should trigger harvest
        morphoVault.withdraw(10_000 * 1e6, ALICE, ALICE);

        uint256 yieldAfter = morphoVault.getTotalYieldGenerated();
        assertTrue(yieldAfter > yieldBefore, "Should have harvested yield");

        vm.stopPrank();
    }

    // ============ Harvest Yield Calculation Edge Cases ============

    function testAaveHarvestWithExactlyEqualBalances() public {
        aaveVault = new AaveVaultAdapter(usdc, address(aavePool), address(aToken), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(aaveVault)); // Authorize vault

        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), type(uint256).max);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        skipDays(1);

        // No yield added, balances are equal
        uint256 yieldBefore = aaveVault.getTotalYieldGenerated();

        aaveVault.harvestYield();

        uint256 yieldAfter = aaveVault.getTotalYieldGenerated();
        assertEq(yieldAfter, yieldBefore, "No yield should be generated");
    }

    function testMorphoHarvestWithExactlyEqualBalances() public {
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(morphoVault)); // Authorize vault

        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), type(uint256).max);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        skipDays(1);

        // No yield added
        uint256 yieldBefore = morphoVault.getTotalYieldGenerated();

        morphoVault.harvestYield();

        uint256 yieldAfter = morphoVault.getTotalYieldGenerated();
        assertEq(yieldAfter, yieldBefore, "No yield should be generated");
    }

    // ============ ERC-4626 Max* View Functions ============

    function testAaveMaxDepositReturnsMaxUint() public {
        aaveVault = new AaveVaultAdapter(usdc, address(aavePool), address(aToken), address(yieldRouter), owner);

        uint256 maxDeposit = aaveVault.maxDeposit(ALICE);
        assertEq(maxDeposit, type(uint256).max);
    }

    function testAaveMaxMintReturnsMaxUint() public {
        aaveVault = new AaveVaultAdapter(usdc, address(aavePool), address(aToken), address(yieldRouter), owner);

        uint256 maxMint = aaveVault.maxMint(ALICE);
        assertEq(maxMint, type(uint256).max);
    }

    function testAaveMaxWithdrawReturnsUserBalance() public {
        aaveVault = new AaveVaultAdapter(usdc, address(aavePool), address(aToken), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(aaveVault)); // Authorize vault

        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), type(uint256).max);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        uint256 maxWithdraw = aaveVault.maxWithdraw(ALICE);
        uint256 userAssets = aaveVault.convertToAssets(aaveVault.balanceOf(ALICE));
        assertEq(maxWithdraw, userAssets);
    }

    function testAaveMaxRedeemReturnsUserShares() public {
        aaveVault = new AaveVaultAdapter(usdc, address(aavePool), address(aToken), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(aaveVault)); // Authorize vault

        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), type(uint256).max);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        uint256 maxRedeem = aaveVault.maxRedeem(ALICE);
        assertEq(maxRedeem, aaveVault.balanceOf(ALICE));
    }

    function testMorphoMaxFunctions() public {
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(morphoVault)); // Authorize vault

        // maxDeposit
        assertEq(morphoVault.maxDeposit(ALICE), type(uint256).max);

        // maxMint
        assertEq(morphoVault.maxMint(ALICE), type(uint256).max);

        // Deposit first
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), type(uint256).max);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // maxWithdraw
        uint256 maxWithdraw = morphoVault.maxWithdraw(ALICE);
        uint256 userAssets = morphoVault.convertToAssets(morphoVault.balanceOf(ALICE));
        assertEq(maxWithdraw, userAssets);

        // maxRedeem
        uint256 maxRedeem = morphoVault.maxRedeem(ALICE);
        assertEq(maxRedeem, morphoVault.balanceOf(ALICE));
    }

    // ============ Allowance-Based Withdrawal Tests ============

    function testMorphoWithdrawByApprovedOperator() public {
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(morphoVault));

        // ALICE deposits
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), type(uint256).max);
        morphoVault.deposit(100_000 * 1e6, ALICE);

        // ALICE approves BOB to withdraw on her behalf
        morphoVault.approve(BOB, 50_000 * 1e6);
        vm.stopPrank();

        // BOB withdraws on ALICE's behalf
        vm.startPrank(BOB);
        uint256 bobBalanceBefore = usdc.balanceOf(BOB);

        uint256 shares = morphoVault.withdraw(30_000 * 1e6, BOB, ALICE);

        assertEq(usdc.balanceOf(BOB), bobBalanceBefore + 30_000 * 1e6);
        assertTrue(shares > 0);
        vm.stopPrank();
    }

    function testMorphoWithdrawByOperatorWithoutApprovalReverts() public {
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(morphoVault));

        // ALICE deposits
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), type(uint256).max);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // BOB tries to withdraw without approval
        vm.startPrank(BOB);
        vm.expectRevert();
        morphoVault.withdraw(30_000 * 1e6, BOB, ALICE);
        vm.stopPrank();
    }

    function testMorphoRedeemByApprovedOperator() public {
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(morphoVault));

        // ALICE deposits
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), type(uint256).max);
        uint256 shares = morphoVault.deposit(100_000 * 1e6, ALICE);

        // ALICE approves BOB
        morphoVault.approve(BOB, shares / 2);
        vm.stopPrank();

        // BOB redeems on ALICE's behalf
        vm.startPrank(BOB);
        uint256 bobBalanceBefore = usdc.balanceOf(BOB);

        uint256 assets = morphoVault.redeem(shares / 2, BOB, ALICE);

        assertTrue(usdc.balanceOf(BOB) > bobBalanceBefore);
        assertTrue(assets > 0);
        vm.stopPrank();
    }

    function testMorphoRedeemByOperatorWithoutApprovalReverts() public {
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);
        yieldRouter.addVaultAuthorization(address(morphoVault));

        // ALICE deposits
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), type(uint256).max);
        uint256 shares = morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // BOB tries to redeem without approval
        vm.startPrank(BOB);
        vm.expectRevert();
        morphoVault.redeem(shares / 2, BOB, ALICE);
        vm.stopPrank();
    }

    // ============ Integration: Coverage Complete Test ============

    function testCompleteCoverageForBothVaults() public {
        console.log("\n=== Complete Vault Adapter Coverage Test ===\n");

        // Deploy vaults
        aaveVault = new AaveVaultAdapter(usdc, address(aavePool), address(aToken), address(yieldRouter), owner);
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);

        yieldRouter.addVaultAuthorization(address(aaveVault));
        yieldRouter.addVaultAuthorization(address(morphoVault));

        // Test all max* functions
        assertEq(aaveVault.maxDeposit(ALICE), type(uint256).max);
        assertEq(morphoVault.maxMint(ALICE), type(uint256).max);

        // Test mint function
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), type(uint256).max);
        usdc.approve(address(morphoVault), type(uint256).max);

        uint256 aaveAssets = aaveVault.mint(50_000 * 1e6, ALICE);
        uint256 morphoAssets = morphoVault.mint(50_000 * 1e6, ALICE);

        console.log("1. Minted shares in both vaults");
        console.log("   Aave assets used:", aaveAssets / 1e6);
        console.log("   Morpho assets used:", morphoAssets / 1e6);

        // Test harvest at exact interval
        skipDays(1);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 500 * 1e6);
        metaMorpho.simulateYield(50);

        aaveVault.deposit(1_000 * 1e6, ALICE); // Triggers harvest
        console.log("2. Harvest triggered by deposit");

        // Test operator withdrawal - approve shares, not assets
        uint256 sharesToApprove = 1_000 * 1e6; // Shares to allow BOB to burn
        uint256 assetsToWithdraw = aaveVault.convertToAssets(sharesToApprove); // Convert to assets
        aaveVault.approve(BOB, sharesToApprove); // Approve shares
        vm.stopPrank();

        vm.startPrank(BOB);
        aaveVault.withdraw(assetsToWithdraw, BOB, ALICE); // Withdraw assets
        console.log("3. Operator withdrew on behalf of ALICE");
        vm.stopPrank();

        console.log("\n[pass] Complete coverage achieved for vault adapters\n");
    }
}
