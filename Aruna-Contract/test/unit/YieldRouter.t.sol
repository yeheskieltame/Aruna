// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/modules/YieldRouter.sol";
import "../../src/modules/OctantDonationModule.sol";
import "../../src/mocks/MockOctantDeposits.sol";
import "../helpers/TestHelpers.sol";

/**
 * @title YieldRouterTest
 * @notice Comprehensive tests for YieldRouter yield distribution logic
 */
contract YieldRouterTest is TestHelpers {
    YieldRouter public yieldRouter;
    OctantDonationModule public octantModule;
    MockOctantDeposits public mockOctant;
    MockUSDC public usdc;

    address public mockVault = address(0x7001);
    address public mockVault2 = address(0x7002);

    event YieldDistributed(
        uint256 totalAmount,
        uint256 investorAmount,
        uint256 publicGoodsAmount,
        uint256 protocolFeeAmount,
        uint256 timestamp
    );

    event YieldClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event SharesUpdated(address indexed user, uint256 newShares, uint256 totalShares);
    event VaultAuthorized(address indexed vault);
    event VaultDeauthorized(address indexed vault);

    function setUp() public {
        labelAddresses();

        usdc = new MockUSDC();
        mockOctant = new MockOctantDeposits(address(usdc));

        octantModule = new OctantDonationModule(address(mockOctant), address(usdc), owner);

        yieldRouter = new YieldRouter(address(usdc), address(octantModule), treasury, owner);

        // Fund test addresses
        usdc.transfer(ALICE, 1_000_000 * 1e6);
        usdc.transfer(BOB, 1_000_000 * 1e6);
        usdc.transfer(CHARLIE, 1_000_000 * 1e6);
        usdc.transfer(mockVault, 1_000_000 * 1e6);
        usdc.transfer(mockVault2, 1_000_000 * 1e6);

        vm.label(mockVault, "MockVault");
        vm.label(mockVault2, "MockVault2");
    }

    // ============ Vault Authorization Tests ============

    function testAddVaultAuthorization() public {
        vm.expectEmit(true, false, false, false);
        emit VaultAuthorized(mockVault);

        yieldRouter.addVaultAuthorization(mockVault);

        assertTrue(yieldRouter.isVaultAuthorized(mockVault));
    }

    function testAddMultipleVaultAuthorizations() public {
        yieldRouter.addVaultAuthorization(mockVault);
        yieldRouter.addVaultAuthorization(mockVault2);

        assertTrue(yieldRouter.isVaultAuthorized(mockVault));
        assertTrue(yieldRouter.isVaultAuthorized(mockVault2));
    }

    function testRemoveVaultAuthorization() public {
        yieldRouter.addVaultAuthorization(mockVault);
        assertTrue(yieldRouter.isVaultAuthorized(mockVault));

        vm.expectEmit(true, false, false, false);
        emit VaultDeauthorized(mockVault);

        yieldRouter.removeVaultAuthorization(mockVault);

        assertFalse(yieldRouter.isVaultAuthorized(mockVault));
    }

    function testAddVaultAuthorizationRevertsIfNotOwner() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        yieldRouter.addVaultAuthorization(mockVault);
        vm.stopPrank();
    }

    function testAddVaultAuthorizationRevertsIfZeroAddress() public {
        vm.expectRevert(YieldRouter.InvalidAddress.selector);
        yieldRouter.addVaultAuthorization(address(0));
    }

    // ============ Share Management Tests ============

    function testUpdateUserShares() public {
        yieldRouter.addVaultAuthorization(mockVault);

        vm.startPrank(mockVault);

        vm.expectEmit(true, false, false, true);
        emit SharesUpdated(ALICE, 1000, 1000);

        yieldRouter.updateUserShares(ALICE, 1000);

        assertEq(yieldRouter.vaultShares(ALICE), 1000);
        assertEq(yieldRouter.totalVaultShares(), 1000);

        vm.stopPrank();
    }

    function testUpdateUserSharesMultipleUsers() public {
        yieldRouter.addVaultAuthorization(mockVault);

        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 1000);
        yieldRouter.updateUserShares(BOB, 2000);
        yieldRouter.updateUserShares(CHARLIE, 1500);
        vm.stopPrank();

        assertEq(yieldRouter.vaultShares(ALICE), 1000);
        assertEq(yieldRouter.vaultShares(BOB), 2000);
        assertEq(yieldRouter.vaultShares(CHARLIE), 1500);
        assertEq(yieldRouter.totalVaultShares(), 4500);
    }

    function testUpdateUserSharesCanDecrease() public {
        yieldRouter.addVaultAuthorization(mockVault);

        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 1000);
        assertEq(yieldRouter.totalVaultShares(), 1000);

        yieldRouter.updateUserShares(ALICE, 500);
        assertEq(yieldRouter.vaultShares(ALICE), 500);
        assertEq(yieldRouter.totalVaultShares(), 500);
        vm.stopPrank();
    }

    function testUpdateUserSharesRevertsIfUnauthorized() public {
        vm.startPrank(ALICE);
        vm.expectRevert(YieldRouter.Unauthorized.selector);
        yieldRouter.updateUserShares(ALICE, 1000);
        vm.stopPrank();
    }

    function testOwnerCanUpdateShares() public {
        // Owner can update shares even without vault authorization
        yieldRouter.updateUserShares(ALICE, 1000);
        assertEq(yieldRouter.vaultShares(ALICE), 1000);
    }

    // ============ Yield Distribution Tests ============

    function testDistributeYield() public {
        yieldRouter.addVaultAuthorization(mockVault);

        // Setup: Give users shares
        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 1000);
        yieldRouter.updateUserShares(BOB, 1000);
        vm.stopPrank();

        // Distribute yield
        uint256 totalYield = 10_000 * 1e6; // $10,000
        uint256 expectedInvestor = calculateInvestorYield(totalYield); // 70%
        uint256 expectedPublicGoods = calculatePublicGoodsYield(totalYield); // 25%
        uint256 expectedProtocol = calculateProtocolFee(totalYield); // 5%

        vm.startPrank(mockVault);
        usdc.approve(address(yieldRouter), totalYield);

        vm.expectEmit(false, false, false, true);
        emit YieldDistributed(totalYield, expectedInvestor, expectedPublicGoods, expectedProtocol, block.timestamp);

        yieldRouter.distributeYield(totalYield, mockVault);
        vm.stopPrank();

        // Verify totals
        assertEq(yieldRouter.totalYieldDistributed(), totalYield);
        assertEq(yieldRouter.totalInvestorYield(), expectedInvestor);
        assertEq(yieldRouter.totalPublicGoodsYield(), expectedPublicGoods);
        assertEq(yieldRouter.totalProtocolFees(), expectedProtocol);

        // Verify treasury received protocol fees
        assertEq(usdc.balanceOf(treasury), expectedProtocol);
    }

    function testDistributeYieldMultipleTimes() public {
        yieldRouter.addVaultAuthorization(mockVault);

        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 1000);
        vm.stopPrank();

        // First distribution
        vm.startPrank(mockVault);
        usdc.approve(address(yieldRouter), 10_000 * 1e6);
        yieldRouter.distributeYield(10_000 * 1e6, mockVault);

        // Second distribution
        usdc.approve(address(yieldRouter), 5_000 * 1e6);
        yieldRouter.distributeYield(5_000 * 1e6, mockVault);
        vm.stopPrank();

        // Verify cumulative totals
        assertEq(yieldRouter.totalYieldDistributed(), 15_000 * 1e6);
        assertEq(yieldRouter.totalInvestorYield(), calculateInvestorYield(15_000 * 1e6));
    }

    function testDistributeYieldRevertsIfUnauthorized() public {
        vm.startPrank(ALICE);
        vm.expectRevert(YieldRouter.Unauthorized.selector);
        yieldRouter.distributeYield(10_000 * 1e6, ALICE);
        vm.stopPrank();
    }

    function testDistributeYieldRevertsIfZeroAmount() public {
        yieldRouter.addVaultAuthorization(mockVault);

        vm.startPrank(mockVault);
        vm.expectRevert(YieldRouter.InvalidAmount.selector);
        yieldRouter.distributeYield(0, mockVault);
        vm.stopPrank();
    }

    // ============ Yield Claiming Tests ============

    function testClaimYield() public {
        yieldRouter.addVaultAuthorization(mockVault);

        // Setup: ALICE has 100% of shares
        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 1000);
        usdc.approve(address(yieldRouter), 10_000 * 1e6);
        yieldRouter.distributeYield(10_000 * 1e6, mockVault);
        vm.stopPrank();

        // ALICE should be able to claim 70% of yield
        uint256 expectedClaim = calculateInvestorYield(10_000 * 1e6);

        vm.startPrank(ALICE);
        uint256 balanceBefore = usdc.balanceOf(ALICE);

        vm.expectEmit(true, false, false, true);
        emit YieldClaimed(ALICE, expectedClaim, block.timestamp);

        uint256 claimed = yieldRouter.claimYield();

        assertEq(claimed, expectedClaim);
        assertEq(usdc.balanceOf(ALICE), balanceBefore + expectedClaim);
        assertEq(yieldRouter.userTotalClaimed(ALICE), expectedClaim);

        vm.stopPrank();
    }

    function testClaimYieldProportionalShares() public {
        yieldRouter.addVaultAuthorization(mockVault);

        // Setup: ALICE has 25%, BOB has 75%
        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 250);
        yieldRouter.updateUserShares(BOB, 750);

        usdc.approve(address(yieldRouter), 10_000 * 1e6);
        yieldRouter.distributeYield(10_000 * 1e6, mockVault);
        vm.stopPrank();

        uint256 totalInvestorYield = calculateInvestorYield(10_000 * 1e6); // 7000 USDC

        // ALICE should get 25% of investor yield
        vm.startPrank(ALICE);
        uint256 aliceExpected = (totalInvestorYield * 250) / 1000;
        uint256 aliceClaimed = yieldRouter.claimYield();
        assertEq(aliceClaimed, aliceExpected);
        vm.stopPrank();

        // BOB should get 75% of investor yield
        vm.startPrank(BOB);
        uint256 bobExpected = (totalInvestorYield * 750) / 1000;
        uint256 bobClaimed = yieldRouter.claimYield();
        assertEq(bobClaimed, bobExpected);
        vm.stopPrank();

        // Total claimed should equal total investor yield
        assertApproxEqRel(aliceClaimed + bobClaimed, totalInvestorYield, 1, "Total claimed should equal investor yield");
    }

    function testClaimYieldMultipleTimes() public {
        yieldRouter.addVaultAuthorization(mockVault);

        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 1000);

        // First distribution
        usdc.approve(address(yieldRouter), 10_000 * 1e6);
        yieldRouter.distributeYield(10_000 * 1e6, mockVault);
        vm.stopPrank();

        // ALICE claims first time
        vm.startPrank(ALICE);
        uint256 firstClaim = yieldRouter.claimYield();
        assertEq(firstClaim, calculateInvestorYield(10_000 * 1e6));

        // Try to claim again without new yield (should return 0, not revert)
        uint256 secondClaim = yieldRouter.claimYield();
        assertEq(secondClaim, 0, "Second claim should return 0 when no yield available");
        vm.stopPrank();

        // Second distribution
        vm.startPrank(mockVault);
        usdc.approve(address(yieldRouter), 5_000 * 1e6);
        yieldRouter.distributeYield(5_000 * 1e6, mockVault);
        vm.stopPrank();

        // ALICE can claim again after new yield
        vm.startPrank(ALICE);
        uint256 thirdClaim = yieldRouter.claimYield();
        assertEq(thirdClaim, calculateInvestorYield(5_000 * 1e6));
        vm.stopPrank();
    }

    function testClaimYieldRevertsIfNoShares() public {
        yieldRouter.addVaultAuthorization(mockVault);

        // Distribute yield without ALICE having shares
        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(BOB, 1000);
        usdc.approve(address(yieldRouter), 10_000 * 1e6);
        yieldRouter.distributeYield(10_000 * 1e6, mockVault);
        vm.stopPrank();

        // ALICE tries to claim but has no shares
        vm.startPrank(ALICE);
        uint256 claimable = yieldRouter.getClaimableYield(ALICE);
        assertEq(claimable, 0);
        vm.stopPrank();
    }

    function testClaimYieldAfterSharesChange() public {
        yieldRouter.addVaultAuthorization(mockVault);

        // Setup: ALICE starts with 100% shares
        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 1000);

        // First distribution (ALICE is the only holder)
        usdc.approve(address(yieldRouter), 10_000 * 1e6);
        yieldRouter.distributeYield(10_000 * 1e6, mockVault);

        // BOB enters with 50% shares AFTER distribution
        yieldRouter.updateUserShares(BOB, 1000);
        vm.stopPrank();

        // ALICE claims (should get 100% of yield since she was the only holder during distribution)
        // This is TIME-WEIGHTED yield - Alice earned the yield before Bob joined
        vm.startPrank(ALICE);
        uint256 aliceClaim = yieldRouter.claimYield();
        // ALICE gets 100% of investor yield because she was solo when it was distributed
        uint256 expectedAlice = calculateInvestorYield(10_000 * 1e6);
        assertEq(aliceClaim, expectedAlice);
        vm.stopPrank();

        // BOB should have ZERO claimable since he joined after distribution
        uint256 bobClaimable = yieldRouter.getClaimableYield(BOB);
        assertEq(bobClaimable, 0, "Bob should have zero yield - joined after distribution");
    }

    // ============ View Function Tests ============

    function testGetClaimableYield() public {
        yieldRouter.addVaultAuthorization(mockVault);

        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 1000);
        usdc.approve(address(yieldRouter), 10_000 * 1e6);
        yieldRouter.distributeYield(10_000 * 1e6, mockVault);
        vm.stopPrank();

        uint256 claimable = yieldRouter.getClaimableYield(ALICE);
        assertEq(claimable, calculateInvestorYield(10_000 * 1e6));
    }

    function testGetClaimableYieldAfterClaim() public {
        yieldRouter.addVaultAuthorization(mockVault);

        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 1000);
        usdc.approve(address(yieldRouter), 10_000 * 1e6);
        yieldRouter.distributeYield(10_000 * 1e6, mockVault);
        vm.stopPrank();

        vm.startPrank(ALICE);
        yieldRouter.claimYield();
        vm.stopPrank();

        // After claiming, claimable should be 0
        uint256 claimable = yieldRouter.getClaimableYield(ALICE);
        assertEq(claimable, 0);
    }

    function testGetUserTotalYield() public {
        yieldRouter.addVaultAuthorization(mockVault);

        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 500);
        yieldRouter.updateUserShares(BOB, 500);
        usdc.approve(address(yieldRouter), 10_000 * 1e6);
        yieldRouter.distributeYield(10_000 * 1e6, mockVault);
        vm.stopPrank();

        uint256 aliceTotal = yieldRouter.getUserTotalYield(ALICE);
        uint256 bobTotal = yieldRouter.getUserTotalYield(BOB);

        // Each should have 50% of investor yield
        uint256 expectedEach = calculateInvestorYield(10_000 * 1e6) / 2;
        assertEq(aliceTotal, expectedEach);
        assertEq(bobTotal, expectedEach);
    }

    function testGetDistributionBreakdown() public {
        uint256 amount = 10_000 * 1e6;

        (uint256 investorAmount, uint256 publicGoodsAmount, uint256 protocolFeeAmount) =
            yieldRouter.getDistributionBreakdown(amount);

        assertEq(investorAmount, calculateInvestorYield(amount));
        assertEq(publicGoodsAmount, calculatePublicGoodsYield(amount));
        assertEq(protocolFeeAmount, calculateProtocolFee(amount));

        // Sum should equal total
        assertEq(investorAmount + publicGoodsAmount + protocolFeeAmount, amount);
    }

    // ============ Treasury Management Tests ============

    function testUpdateTreasury() public {
        address newTreasury = address(0x888);

        yieldRouter.updateTreasury(newTreasury);

        assertEq(yieldRouter.protocolTreasury(), newTreasury);
    }

    function testUpdateTreasuryRevertsIfZeroAddress() public {
        vm.expectRevert(YieldRouter.InvalidAddress.selector);
        yieldRouter.updateTreasury(address(0));
    }

    function testUpdateTreasuryRevertsIfNotOwner() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        yieldRouter.updateTreasury(address(0x888));
        vm.stopPrank();
    }

    // ============ Edge Case Tests ============

    function testZeroSharesReturnsZeroYield() public {
        uint256 claimable = yieldRouter.getClaimableYield(ALICE);
        assertEq(claimable, 0);

        uint256 totalYield = yieldRouter.getUserTotalYield(ALICE);
        assertEq(totalYield, 0);
    }

    function testMultipleVaultsCanDistribute() public {
        yieldRouter.addVaultAuthorization(mockVault);
        yieldRouter.addVaultAuthorization(mockVault2);

        vm.startPrank(mockVault);
        yieldRouter.updateUserShares(ALICE, 1000);
        vm.stopPrank();

        // Vault 1 distributes
        vm.startPrank(mockVault);
        usdc.approve(address(yieldRouter), 10_000 * 1e6);
        yieldRouter.distributeYield(10_000 * 1e6, mockVault);
        vm.stopPrank();

        // Vault 2 distributes
        vm.startPrank(mockVault2);
        usdc.approve(address(yieldRouter), 5_000 * 1e6);
        yieldRouter.distributeYield(5_000 * 1e6, mockVault2);
        vm.stopPrank();

        // Total should be cumulative
        assertEq(yieldRouter.totalYieldDistributed(), 15_000 * 1e6);
    }
}
