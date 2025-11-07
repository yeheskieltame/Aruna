// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/vaults/AaveVaultAdapter.sol";
import "../../src/modules/YieldRouter.sol";
import "../../src/modules/OctantDonationModule.sol";
import "../../src/mocks/MockOctantDeposits.sol";
import "../helpers/TestHelpers.sol";

/**
 * @title AaveVaultAdapterTest
 * @notice Comprehensive unit tests for AaveVaultAdapter contract
 * @dev Tests ERC-4626 compliance, yield harvesting, and Aave integration
 */
contract AaveVaultAdapterTest is TestHelpers {
    AaveVaultAdapter public aaveVault;
    YieldRouter public yieldRouter;
    OctantDonationModule public octantModule;
    MockOctantDeposits public mockOctant;

    MockUSDC public usdc;
    MockAavePool public aavePool;
    MockAToken public aToken;

    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 assets, uint256 shares);
    event YieldHarvested(uint256 amount, uint256 timestamp);
    event PauseToggled(bool isPaused);
    event APYUpdated(uint256 oldAPY, uint256 newAPY);

    function setUp() public {
        labelAddresses();

        // Deploy USDC
        usdc = new MockUSDC();

        // Deploy Aave mocks
        aToken = new MockAToken();
        aavePool = new MockAavePool(address(aToken));
        aToken.setPool(address(aavePool));

        // Deploy Octant mock
        mockOctant = new MockOctantDeposits(address(usdc));

        // Deploy modules
        octantModule = new OctantDonationModule(address(mockOctant), address(usdc), owner);
        yieldRouter = new YieldRouter(address(usdc), address(octantModule), treasury, owner);

        // Deploy Aave vault
        aaveVault = new AaveVaultAdapter(
            usdc,
            address(aavePool),
            address(aToken),
            address(yieldRouter),
            owner
        );

        // Authorize vault in YieldRouter
        yieldRouter.addVaultAuthorization(address(aaveVault));

        // Fund Aave pool for withdrawals
        usdc.transfer(address(aavePool), 100_000_000 * 1e6);

        // Fund test users
        usdc.transfer(ALICE, 1_000_000 * 1e6);
        usdc.transfer(BOB, 1_000_000 * 1e6);
        usdc.transfer(CHARLIE, 500_000 * 1e6);
    }

    // ============ Deployment & Initialization Tests ============

    function testDeploymentState() public {
        assertEq(address(aaveVault.asset()), address(usdc));
        assertEq(address(aaveVault.aavePool()), address(aavePool));
        assertEq(address(aaveVault.aToken()), address(aToken));
        assertEq(address(aaveVault.yieldRouter()), address(yieldRouter));
        assertEq(aaveVault.owner(), owner);
        assertEq(aaveVault.getAPY(), 650); // Default 6.5%
        assertEq(aaveVault.totalYieldGenerated(), 0);
        assertFalse(aaveVault.isPaused());
    }

    function testVaultName() public {
        assertEq(aaveVault.name(), "Aruna Aave Vault");
        assertEq(aaveVault.symbol(), "yfAave");
        assertEq(aaveVault.decimals(), 6); // Same as USDC
    }

    // ============ Deposit Tests ============

    function testDeposit() public {
        uint256 depositAmount = 10_000 * 1e6;

        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), depositAmount);

        vm.expectEmit(true, false, false, true);
        emit Deposited(ALICE, depositAmount, depositAmount);

        uint256 shares = aaveVault.deposit(depositAmount, ALICE);

        assertEq(shares, depositAmount, "Should mint 1:1 shares");
        assertEq(aaveVault.balanceOf(ALICE), depositAmount);
        assertEq(aaveVault.totalSupply(), depositAmount);
        assertEq(aaveVault.totalAssets(), depositAmount);

        // Verify YieldRouter updated shares
        assertEq(yieldRouter.vaultShares(ALICE), depositAmount);

        vm.stopPrank();
    }

    function testDepositMultipleUsers() public {
        // ALICE deposits 100k
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        uint256 aliceShares = aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // BOB deposits 50k
        vm.startPrank(BOB);
        usdc.approve(address(aaveVault), 50_000 * 1e6);
        uint256 bobShares = aaveVault.deposit(50_000 * 1e6, BOB);
        vm.stopPrank();

        assertEq(aliceShares, 100_000 * 1e6);
        assertEq(bobShares, 50_000 * 1e6);
        assertEq(aaveVault.totalSupply(), 150_000 * 1e6);
    }

    function testDepositRevertsIfPaused() public {
        aaveVault.togglePause();

        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 10_000 * 1e6);

        vm.expectRevert(AaveVaultAdapter.ContractPaused.selector);
        aaveVault.deposit(10_000 * 1e6, ALICE);

        vm.stopPrank();
    }

    function testDepositRevertsIfZeroAmount() public {
        vm.startPrank(ALICE);
        vm.expectRevert(AaveVaultAdapter.InvalidAmount.selector);
        aaveVault.deposit(0, ALICE);
        vm.stopPrank();
    }

    // ============ Withdraw Tests ============

    function testWithdraw() public {
        // Setup: ALICE deposits 100k
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        aaveVault.deposit(100_000 * 1e6, ALICE);

        uint256 balanceBefore = usdc.balanceOf(ALICE);
        uint256 withdrawAmount = 30_000 * 1e6;

        vm.expectEmit(true, false, false, true);
        emit Withdrawn(ALICE, withdrawAmount, withdrawAmount);

        uint256 sharesBurned = aaveVault.withdraw(withdrawAmount, ALICE, ALICE);

        assertEq(sharesBurned, withdrawAmount);
        assertEq(usdc.balanceOf(ALICE), balanceBefore + withdrawAmount);
        assertEq(aaveVault.balanceOf(ALICE), 70_000 * 1e6);

        // Verify YieldRouter updated
        assertEq(yieldRouter.vaultShares(ALICE), 70_000 * 1e6);

        vm.stopPrank();
    }

    function testWithdrawAll() public {
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 50_000 * 1e6);
        aaveVault.deposit(50_000 * 1e6, ALICE);

        uint256 balanceBefore = usdc.balanceOf(ALICE);

        aaveVault.withdraw(50_000 * 1e6, ALICE, ALICE);

        assertEq(usdc.balanceOf(ALICE), balanceBefore + 50_000 * 1e6);
        assertEq(aaveVault.balanceOf(ALICE), 0);
        assertEq(yieldRouter.vaultShares(ALICE), 0);

        vm.stopPrank();
    }

    function testWithdrawRevertsIfZeroAmount() public {
        vm.expectRevert(AaveVaultAdapter.InvalidAmount.selector);
        aaveVault.withdraw(0, ALICE, ALICE);
    }

    // ============ Redeem Tests ============

    function testRedeem() public {
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        aaveVault.deposit(100_000 * 1e6, ALICE);

        uint256 balanceBefore = usdc.balanceOf(ALICE);
        uint256 sharesToRedeem = 40_000 * 1e6;

        uint256 assetsReceived = aaveVault.redeem(sharesToRedeem, ALICE, ALICE);

        assertEq(assetsReceived, sharesToRedeem); // 1:1 redemption
        assertEq(usdc.balanceOf(ALICE), balanceBefore + assetsReceived);
        assertEq(aaveVault.balanceOf(ALICE), 60_000 * 1e6);

        vm.stopPrank();
    }

    function testRedeemRevertsIfZeroShares() public {
        vm.expectRevert(AaveVaultAdapter.InvalidAmount.selector);
        aaveVault.redeem(0, ALICE, ALICE);
    }

    // ============ Yield Harvesting Tests ============

    function testHarvestYield() public {
        // Setup: ALICE deposits 100k
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // Simulate 1 day passing
        skipDays(1);

        // Simulate yield accrual (1000 USDC)
        uint256 yieldAmount = 1_000 * 1e6;
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), yieldAmount);

        uint256 totalAssetsBefore = aaveVault.totalAssets();
        assertEq(totalAssetsBefore, 101_000 * 1e6); // Principal + yield

        vm.expectEmit(false, false, false, true);
        emit YieldHarvested(yieldAmount, block.timestamp);

        aaveVault.harvestYield();

        // Verify yield was distributed
        assertEq(aaveVault.totalYieldGenerated(), yieldAmount);
        assertTrue(yieldRouter.totalYieldDistributed() > 0);
    }

    function testHarvestYieldRevertsIfTooSoon() public {
        // Deposit and harvest once
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        skipDays(1);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 1_000 * 1e6);
        aaveVault.harvestYield();

        // Try to harvest again immediately
        vm.expectRevert(AaveVaultAdapter.HarvestTooSoon.selector);
        aaveVault.harvestYield();
    }

    function testHarvestYieldWithNoYield() public {
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        skipDays(1);

        // No yield accrued, harvest should succeed but distribute nothing
        aaveVault.harvestYield();

        assertEq(aaveVault.totalYieldGenerated(), 0);
        assertEq(yieldRouter.totalYieldDistributed(), 0);
    }

    function testMultipleHarvests() public {
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        // First harvest
        skipDays(1);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 500 * 1e6);
        aaveVault.harvestYield();

        uint256 firstHarvest = aaveVault.totalYieldGenerated();
        assertEq(firstHarvest, 500 * 1e6);

        // Second harvest
        skipDays(1);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 700 * 1e6);
        aaveVault.harvestYield();

        uint256 totalHarvested = aaveVault.totalYieldGenerated();
        assertEq(totalHarvested, 1_200 * 1e6);
    }

    // ============ ERC-4626 Preview Functions Tests ============

    function testPreviewDeposit() public {
        uint256 assets = 10_000 * 1e6;
        uint256 expectedShares = aaveVault.previewDeposit(assets);

        assertEq(expectedShares, assets); // 1:1 for first deposit
    }

    function testPreviewWithdraw() public {
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        uint256 assets = 30_000 * 1e6;
        uint256 expectedShares = aaveVault.previewWithdraw(assets);

        assertEq(expectedShares, assets); // 1:1 withdrawal
    }

    function testPreviewRedeem() public {
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        uint256 shares = 40_000 * 1e6;
        uint256 expectedAssets = aaveVault.previewRedeem(shares);

        assertEq(expectedAssets, shares); // 1:1 redemption
    }

    function testConvertToShares() public {
        uint256 assets = 25_000 * 1e6;
        uint256 shares = aaveVault.convertToShares(assets);

        assertEq(shares, assets); // 1:1 conversion
    }

    function testConvertToAssets() public {
        uint256 shares = 25_000 * 1e6;
        uint256 assets = aaveVault.convertToAssets(shares);

        assertEq(assets, shares); // 1:1 conversion
    }

    // ============ View Function Tests ============

    function testGetUserYield() public {
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        skipDays(1);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 1_000 * 1e6);
        aaveVault.harvestYield();

        uint256 userYield = aaveVault.getUserYield(ALICE);
        assertTrue(userYield > 0);
    }

    function testGetTotalYieldGenerated() public {
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        aaveVault.deposit(100_000 * 1e6, ALICE);
        vm.stopPrank();

        skipDays(1);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 2_500 * 1e6);
        aaveVault.harvestYield();

        assertEq(aaveVault.getTotalYieldGenerated(), 2_500 * 1e6);
    }

    function testGetAPY() public {
        assertEq(aaveVault.getAPY(), 650); // Default 6.5%
    }

    // ============ Admin Function Tests ============

    function testTogglePause() public {
        assertFalse(aaveVault.isPaused());

        vm.expectEmit(false, false, false, true);
        emit PauseToggled(true);

        aaveVault.togglePause();
        assertTrue(aaveVault.isPaused());

        aaveVault.togglePause();
        assertFalse(aaveVault.isPaused());
    }

    function testTogglePauseRevertsIfNotOwner() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        aaveVault.togglePause();
        vm.stopPrank();
    }

    function testUpdateAPY() public {
        uint256 newAPY = 750; // 7.5%

        vm.expectEmit(false, false, false, true);
        emit APYUpdated(650, newAPY);

        aaveVault.updateAPY(newAPY);
        assertEq(aaveVault.getAPY(), newAPY);
    }

    function testUpdateAPYRevertsIfNotOwner() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        aaveVault.updateAPY(800);
        vm.stopPrank();
    }

    function testEmergencyWithdraw() public {
        // Fund vault with USDC
        usdc.transfer(address(aaveVault), 10_000 * 1e6);

        uint256 ownerBalanceBefore = usdc.balanceOf(owner);

        aaveVault.emergencyWithdraw(address(usdc), 10_000 * 1e6);

        assertEq(usdc.balanceOf(owner), ownerBalanceBefore + 10_000 * 1e6);
    }

    function testEmergencyWithdrawRevertsIfNotOwner() public {
        usdc.transfer(address(aaveVault), 10_000 * 1e6);

        vm.startPrank(ALICE);
        vm.expectRevert();
        aaveVault.emergencyWithdraw(address(usdc), 10_000 * 1e6);
        vm.stopPrank();
    }

    // ============ Integration Tests ============

    function testFullDepositYieldWithdrawCycle() public {
        console.log("\n=== Full Deposit-Yield-Claim Cycle ===\n");

        // 1. ALICE deposits
        vm.startPrank(ALICE);
        usdc.approve(address(aaveVault), 100_000 * 1e6);
        uint256 shares = aaveVault.deposit(100_000 * 1e6, ALICE);
        console.log("1. ALICE deposited: $100,000");
        console.log("   Shares received:", shares / 1e6);
        vm.stopPrank();

        // 2. Time passes, yield accrues
        skipDays(7);
        uint256 weeklyYield = 1_250 * 1e6; // ~1 week at 6.5% APY
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), weeklyYield);
        console.log("\n2. 7 days passed, yield accrued: $", weeklyYield / 1e6);

        // 3. Harvest yield
        aaveVault.harvestYield();
        console.log("3. Yield harvested and distributed");

        // 4. ALICE claims yield
        vm.startPrank(ALICE);
        uint256 claimable = yieldRouter.getClaimableYield(ALICE);
        uint256 claimed = yieldRouter.claimYield();
        console.log("4. ALICE claimed yield: $", claimed / 1e6);
        assertEq(claimed, claimable);
        assertTrue(claimed > 0, "Should have claimed yield");
        console.log("5. Principal remains in vault for continued earning");
        console.log("   Vault balance: $", aaveVault.balanceOf(ALICE) / 1e6);
        vm.stopPrank();

        console.log("\n[pass] Full cycle completed successfully\n");
    }
}
