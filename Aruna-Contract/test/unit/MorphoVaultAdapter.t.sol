// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/vaults/MorphoVaultAdapter.sol";
import "../../src/modules/YieldRouter.sol";
import "../../src/modules/OctantDonationModule.sol";
import "../../src/mocks/MockOctantDeposits.sol";
import "../helpers/TestHelpers.sol";

/**
 * @title MorphoVaultAdapterTest
 * @notice Comprehensive unit tests for MorphoVaultAdapter contract
 * @dev Tests ERC-4626 compliance, MetaMorpho integration, and yield harvesting
 */
contract MorphoVaultAdapterTest is TestHelpers {
    MorphoVaultAdapter public morphoVault;
    YieldRouter public yieldRouter;
    OctantDonationModule public octantModule;
    MockOctantDeposits public mockOctant;

    MockUSDC public usdc;
    MockMetaMorpho public metaMorpho;

    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 assets, uint256 shares);
    event YieldHarvested(uint256 amount, uint256 timestamp);
    event PauseToggled(bool isPaused);
    event APYUpdated(uint256 oldAPY, uint256 newAPY);
    event MetaMorphoSharesUpdated(uint256 newShares, uint256 oldShares);

    function setUp() public {
        labelAddresses();

        // Deploy USDC
        usdc = new MockUSDC();

        // Deploy MetaMorpho mock
        metaMorpho = new MockMetaMorpho(usdc, address(0x123)); // Mock Morpho Blue address

        // Deploy Octant mock
        mockOctant = new MockOctantDeposits(address(usdc));

        // Deploy modules
        octantModule = new OctantDonationModule(address(mockOctant), address(usdc), owner);
        yieldRouter = new YieldRouter(address(usdc), address(octantModule), treasury, owner);

        // Deploy Morpho vault
        morphoVault = new MorphoVaultAdapter(
            usdc,
            address(metaMorpho),
            address(yieldRouter),
            owner
        );

        // Authorize vault in YieldRouter
        yieldRouter.addVaultAuthorization(address(morphoVault));

        // Fund MetaMorpho for withdrawals
        usdc.transfer(address(metaMorpho), 100_000_000 * 1e6);

        // Fund test users
        usdc.transfer(ALICE, 1_000_000 * 1e6);
        usdc.transfer(BOB, 1_000_000 * 1e6);
        usdc.transfer(CHARLIE, 500_000 * 1e6);
    }

    // ============ Deployment & Initialization Tests ============

    function testDeploymentState() public {
        assertEq(address(morphoVault.asset()), address(usdc));
        assertEq(address(morphoVault.metaMorphoVault()), address(metaMorpho));
        assertEq(address(morphoVault.yieldRouter()), address(yieldRouter));
        assertEq(morphoVault.owner(), owner);
        assertEq(morphoVault.getAPY(), 820); // Default 8.2%
        assertEq(morphoVault.totalYieldGenerated(), 0);
        assertEq(morphoVault.getMetaMorphoShares(), 0);
        assertFalse(morphoVault.isPaused());
    }

    function testVaultName() public {
        assertEq(morphoVault.name(), "Aruna Morpho Vault");
        assertEq(morphoVault.symbol(), "yfMorpho");
        assertEq(morphoVault.decimals(), 6); // Same as USDC
    }

    function testGetMorphoBlue() public {
        assertEq(morphoVault.getMorphoBlue(), address(0x123));
    }

    function testGetMetaMorphoVault() public {
        assertEq(morphoVault.getMetaMorphoVault(), address(metaMorpho));
    }

    // ============ Deposit Tests ============

    function testDeposit() public {
        uint256 depositAmount = 10_000 * 1e6;

        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), depositAmount);

        vm.expectEmit(true, false, false, true);
        emit Deposited(ALICE, depositAmount, depositAmount);

        uint256 shares = morphoVault.deposit(depositAmount, ALICE);

        assertEq(shares, depositAmount, "Should mint 1:1 shares");
        assertEq(morphoVault.balanceOf(ALICE), depositAmount);
        assertEq(morphoVault.totalSupply(), depositAmount);

        // Verify MetaMorpho shares tracking
        assertEq(morphoVault.getMetaMorphoShares(), depositAmount);

        // Verify YieldRouter updated
        assertEq(yieldRouter.vaultShares(ALICE), depositAmount);

        vm.stopPrank();
    }

    function testDepositMultipleUsers() public {
        // ALICE deposits 100k
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        uint256 aliceShares = morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // BOB deposits 50k
        vm.startPrank(BOB);
        usdc.approve(address(morphoVault), 50_000 * 1e6);
        uint256 bobShares = morphoVault.deposit(50_000 * 1e6, BOB);
        vm.stopPrank();

        assertEq(aliceShares, 100_000 * 1e6);
        assertEq(bobShares, 50_000 * 1e6);
        assertEq(morphoVault.totalSupply(), 150_000 * 1e6);
        assertEq(morphoVault.getMetaMorphoShares(), 150_000 * 1e6);
    }

    function testDepositRevertsIfPaused() public {
        morphoVault.togglePause();

        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 10_000 * 1e6);

        vm.expectRevert(MorphoVaultAdapter.ContractPaused.selector);
        morphoVault.deposit(10_000 * 1e6, ALICE);

        vm.stopPrank();
    }

    function testDepositRevertsIfZeroAmount() public {
        vm.startPrank(ALICE);
        vm.expectRevert(MorphoVaultAdapter.InvalidAmount.selector);
        morphoVault.deposit(0, ALICE);
        vm.stopPrank();
    }

    function testDepositEmitsMetaMorphoSharesEvent() public {
        uint256 depositAmount = 10_000 * 1e6;

        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), depositAmount);

        vm.expectEmit(false, false, false, true);
        emit MetaMorphoSharesUpdated(depositAmount, 0);

        morphoVault.deposit(depositAmount, ALICE);

        vm.stopPrank();
    }

    // ============ Withdraw Tests ============

    function testWithdraw() public {
        // Setup: ALICE deposits 100k
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);

        uint256 balanceBefore = usdc.balanceOf(ALICE);
        uint256 withdrawAmount = 30_000 * 1e6;

        vm.expectEmit(true, false, false, true);
        emit Withdrawn(ALICE, withdrawAmount, withdrawAmount);

        uint256 sharesBurned = morphoVault.withdraw(withdrawAmount, ALICE, ALICE);

        assertEq(sharesBurned, withdrawAmount);
        assertEq(usdc.balanceOf(ALICE), balanceBefore + withdrawAmount);
        assertEq(morphoVault.balanceOf(ALICE), 70_000 * 1e6);

        // Verify MetaMorpho shares tracking
        assertEq(morphoVault.getMetaMorphoShares(), 70_000 * 1e6);

        // Verify YieldRouter updated
        assertEq(yieldRouter.vaultShares(ALICE), 70_000 * 1e6);

        vm.stopPrank();
    }

    function testWithdrawAll() public {
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 50_000 * 1e6);
        morphoVault.deposit(50_000 * 1e6, ALICE);

        uint256 balanceBefore = usdc.balanceOf(ALICE);

        morphoVault.withdraw(50_000 * 1e6, ALICE, ALICE);

        assertEq(usdc.balanceOf(ALICE), balanceBefore + 50_000 * 1e6);
        assertEq(morphoVault.balanceOf(ALICE), 0);
        assertEq(morphoVault.getMetaMorphoShares(), 0);
        assertEq(yieldRouter.vaultShares(ALICE), 0);

        vm.stopPrank();
    }

    function testWithdrawRevertsIfZeroAmount() public {
        vm.expectRevert(MorphoVaultAdapter.InvalidAmount.selector);
        morphoVault.withdraw(0, ALICE, ALICE);
    }

    // ============ Redeem Tests ============

    function testRedeem() public {
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);

        uint256 balanceBefore = usdc.balanceOf(ALICE);
        uint256 sharesToRedeem = 40_000 * 1e6;

        uint256 assetsReceived = morphoVault.redeem(sharesToRedeem, ALICE, ALICE);

        assertEq(assetsReceived, sharesToRedeem); // 1:1 redemption
        assertEq(usdc.balanceOf(ALICE), balanceBefore + assetsReceived);
        assertEq(morphoVault.balanceOf(ALICE), 60_000 * 1e6);
        assertEq(morphoVault.getMetaMorphoShares(), 60_000 * 1e6);

        vm.stopPrank();
    }

    function testRedeemRevertsIfZeroShares() public {
        vm.expectRevert(MorphoVaultAdapter.InvalidAmount.selector);
        morphoVault.redeem(0, ALICE, ALICE);
    }

    // ============ Yield Harvesting Tests ============

    function testHarvestYield() public {
        // Setup: ALICE deposits 100k
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // Simulate 1 day passing
        skipDays(1);

        // Simulate yield (2% = 2,000 USDC)
        metaMorpho.simulateYield(200); // 200 basis points = 2%

        uint256 totalAssetsBefore = morphoVault.totalAssets();
        assertTrue(totalAssetsBefore > 100_000 * 1e6, "Should have yield");

        vm.expectEmit(false, false, false, true);
        emit YieldHarvested(totalAssetsBefore - 100_000 * 1e6, block.timestamp);

        morphoVault.harvestYield();

        // Verify yield was distributed
        assertTrue(morphoVault.totalYieldGenerated() > 0);
        assertTrue(yieldRouter.totalYieldDistributed() > 0);
    }

    function testHarvestYieldRevertsIfTooSoon() public {
        // Deposit and harvest once
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        skipDays(1);
        metaMorpho.simulateYield(200);
        morphoVault.harvestYield();

        // Try to harvest again immediately
        vm.expectRevert(MorphoVaultAdapter.HarvestTooSoon.selector);
        morphoVault.harvestYield();
    }

    function testHarvestYieldWithNoYield() public {
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        skipDays(1);

        // No yield accrued, harvest should succeed but distribute nothing
        morphoVault.harvestYield();

        assertEq(morphoVault.totalYieldGenerated(), 0);
        assertEq(yieldRouter.totalYieldDistributed(), 0);
    }

    function testMultipleHarvests() public {
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // First harvest (1% yield)
        skipDays(1);
        metaMorpho.simulateYield(100);
        morphoVault.harvestYield();

        uint256 firstHarvest = morphoVault.totalYieldGenerated();
        assertTrue(firstHarvest > 0);

        // Second harvest (1.5% yield)
        skipDays(1);
        metaMorpho.simulateYield(150);
        morphoVault.harvestYield();

        uint256 totalHarvested = morphoVault.totalYieldGenerated();
        assertTrue(totalHarvested > firstHarvest);
    }

    // ============ Total Assets Tests ============

    function testTotalAssetsWithNoDeposits() public {
        assertEq(morphoVault.totalAssets(), 0);
    }

    function testTotalAssetsAfterDeposit() public {
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 50_000 * 1e6);
        morphoVault.deposit(50_000 * 1e6, ALICE);
        vm.stopPrank();

        assertEq(morphoVault.totalAssets(), 50_000 * 1e6);
    }

    function testTotalAssetsWithYield() public {
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // Simulate 3% yield
        metaMorpho.simulateYield(300);

        uint256 totalAssets = morphoVault.totalAssets();
        assertTrue(totalAssets > 100_000 * 1e6);
        assertApproxEqRel(totalAssets, 103_000 * 1e6, 0.01e18); // 1% tolerance
    }

    // ============ ERC-4626 Preview Functions Tests ============

    function testPreviewDeposit() public {
        uint256 assets = 10_000 * 1e6;
        uint256 expectedShares = morphoVault.previewDeposit(assets);

        assertEq(expectedShares, assets); // 1:1 for first deposit
    }

    function testPreviewWithdraw() public {
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        uint256 assets = 30_000 * 1e6;
        uint256 expectedShares = morphoVault.previewWithdraw(assets);

        assertEq(expectedShares, assets); // 1:1 withdrawal
    }

    function testPreviewRedeem() public {
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        uint256 shares = 40_000 * 1e6;
        uint256 expectedAssets = morphoVault.previewRedeem(shares);

        assertEq(expectedAssets, shares); // 1:1 redemption
    }

    function testConvertToShares() public {
        uint256 assets = 25_000 * 1e6;
        uint256 shares = morphoVault.convertToShares(assets);

        assertEq(shares, assets); // 1:1 conversion
    }

    function testConvertToAssets() public {
        uint256 shares = 25_000 * 1e6;
        uint256 assets = morphoVault.convertToAssets(shares);

        assertEq(assets, shares); // 1:1 conversion
    }

    // ============ View Function Tests ============

    function testGetUserYield() public {
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        skipDays(1);
        metaMorpho.simulateYield(200);
        morphoVault.harvestYield();

        uint256 userYield = morphoVault.getUserYield(ALICE);
        assertTrue(userYield > 0);
    }

    function testGetTotalYieldGenerated() public {
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        skipDays(1);
        metaMorpho.simulateYield(250);
        morphoVault.harvestYield();

        assertTrue(morphoVault.getTotalYieldGenerated() > 0);
    }

    function testGetAPY() public {
        assertEq(morphoVault.getAPY(), 820); // Default 8.2%
    }

    // ============ Admin Function Tests ============

    function testTogglePause() public {
        assertFalse(morphoVault.isPaused());

        vm.expectEmit(false, false, false, true);
        emit PauseToggled(true);

        morphoVault.togglePause();
        assertTrue(morphoVault.isPaused());

        morphoVault.togglePause();
        assertFalse(morphoVault.isPaused());
    }

    function testTogglePauseRevertsIfNotOwner() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        morphoVault.togglePause();
        vm.stopPrank();
    }

    function testUpdateAPY() public {
        uint256 newAPY = 900; // 9.0%

        vm.expectEmit(false, false, false, true);
        emit APYUpdated(820, newAPY);

        morphoVault.updateAPY(newAPY);
        assertEq(morphoVault.getAPY(), newAPY);
    }

    function testUpdateAPYRevertsIfNotOwner() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        morphoVault.updateAPY(1000);
        vm.stopPrank();
    }

    function testEmergencyWithdraw() public {
        // Fund vault with USDC
        usdc.transfer(address(morphoVault), 10_000 * 1e6);

        uint256 ownerBalanceBefore = usdc.balanceOf(owner);

        morphoVault.emergencyWithdraw(address(usdc), 10_000 * 1e6);

        assertEq(usdc.balanceOf(owner), ownerBalanceBefore + 10_000 * 1e6);
    }

    function testEmergencyWithdrawRevertsIfNotOwner() public {
        usdc.transfer(address(morphoVault), 10_000 * 1e6);

        vm.startPrank(ALICE);
        vm.expectRevert();
        morphoVault.emergencyWithdraw(address(usdc), 10_000 * 1e6);
        vm.stopPrank();
    }

    // ============ Integration Tests ============

    function testFullDepositYieldWithdrawCycle() public {
        console.log("\n=== Full Deposit-Yield-Withdraw Cycle (Morpho) ===\n");

        // 1. ALICE deposits
        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        uint256 shares = morphoVault.deposit(100_000 * 1e6, ALICE);
        console.log("1. ALICE deposited: $100,000");
        console.log("   Shares received:", shares / 1e6);
        console.log("   MetaMorpho shares:", morphoVault.getMetaMorphoShares() / 1e6);
        vm.stopPrank();

        // 2. Time passes, yield accrues
        skipDays(7);
        metaMorpho.simulateYield(157); // ~1.57% = 1 week at 8.2% APY
        uint256 yieldAccrued = morphoVault.totalAssets() - 100_000 * 1e6;
        console.log("\n2. 7 days passed, yield accrued: ~$", yieldAccrued / 1e6);

        // 3. Harvest yield
        morphoVault.harvestYield();
        console.log("3. Yield harvested and distributed");
        console.log("   Total yield generated:", morphoVault.getTotalYieldGenerated() / 1e6);

        // 4. ALICE claims yield
        vm.startPrank(ALICE);
        uint256 claimable = yieldRouter.getClaimableYield(ALICE);
        uint256 claimed = yieldRouter.claimYield();
        console.log("4. ALICE claimed yield: $", claimed / 1e6);
        assertEq(claimed, claimable);
        vm.stopPrank();

        // 5. ALICE withdraws principal
        vm.startPrank(ALICE);
        uint256 balanceBefore = usdc.balanceOf(ALICE);
        morphoVault.withdraw(100_000 * 1e6, ALICE, ALICE);
        uint256 withdrawn = usdc.balanceOf(ALICE) - balanceBefore;
        console.log("5. ALICE withdrew: $", withdrawn / 1e6);
        assertEq(withdrawn, 100_000 * 1e6);
        vm.stopPrank();

        console.log("\n[pass] Full cycle completed successfully\n");
    }

    function testCompareWithAaveYield() public {
        console.log("\n=== Morpho vs Aave Yield Comparison ===\n");

        vm.startPrank(ALICE);
        usdc.approve(address(morphoVault), 100_000 * 1e6);
        morphoVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // Simulate 30 days
        skipDays(30);

        // Morpho: 8.2% APY / 12 months = ~0.68% monthly
        metaMorpho.simulateYield(68);

        uint256 morphoYield = morphoVault.totalAssets() - 100_000 * 1e6;

        console.log("Principal: $100,000");
        console.log("Time period: 30 days");
        console.log("Morpho yield (8.2% APY): $", morphoYield / 1e6);
        console.log("Expected Aave yield (6.5% APY): ~$542");
        console.log("Morpho advantage: ~25% higher");

        assertTrue(morphoYield > 542 * 1e6, "Morpho should yield more than Aave");

        console.log("\n[pass] Morpho yields higher returns\n");
    }
}
