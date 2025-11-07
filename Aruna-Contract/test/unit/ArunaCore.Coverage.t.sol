// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/ArunaCore.sol";
import "../../src/vaults/AaveVaultAdapter.sol";
import "../../src/vaults/MorphoVaultAdapter.sol";
import "../../src/modules/YieldRouter.sol";
import "../../src/modules/OctantDonationModule.sol";
import "../../src/mocks/MockOctantDeposits.sol";
import "../helpers/TestHelpers.sol";

/**
 * @title ArunaCore100CoverageTest
 * @notice Additional tests to achieve 100% coverage for ArunaCore
 * @dev Covers all missing branches, edge cases, and error conditions
 */
contract ArunaCore100CoverageTest is TestHelpers {
    ArunaCore public core;
    MockUSDC public usdc;
    AaveVaultAdapter public aaveVault;
    MorphoVaultAdapter public morphoVault;
    YieldRouter public yieldRouter;
    OctantDonationModule public octantModule;

    MockAavePool public aavePool;
    MockAToken public aToken;
    MockMetaMorpho public metaMorpho;
    MockOctantDeposits public mockOctant;

    function setUp() public {
        labelAddresses();

        // Deploy USDC
        usdc = new MockUSDC();

        // Deploy mocks
        aToken = new MockAToken();
        aavePool = new MockAavePool(address(aToken));
        aToken.setPool(address(aavePool));

        metaMorpho = new MockMetaMorpho(usdc, address(0x123));
        mockOctant = new MockOctantDeposits(address(usdc));

        // Deploy modules
        octantModule = new OctantDonationModule(address(mockOctant), address(usdc), owner);
        yieldRouter = new YieldRouter(address(usdc), address(octantModule), treasury, owner);

        // Deploy vaults
        aaveVault = new AaveVaultAdapter(usdc, address(aavePool), address(aToken), address(yieldRouter), owner);
        morphoVault = new MorphoVaultAdapter(usdc, address(metaMorpho), address(yieldRouter), owner);

        // Deploy core
        core = new ArunaCore(address(usdc), owner);

        // Initialize
        core.initialize(address(aaveVault), address(morphoVault), address(yieldRouter), address(octantModule));

        // Authorize vaults
        yieldRouter.addVaultAuthorization(address(aaveVault));
        yieldRouter.addVaultAuthorization(address(morphoVault));

        // Fund pools
        usdc.transfer(address(aavePool), 10_000_000 * 1e6);
        usdc.transfer(address(metaMorpho), 10_000_000 * 1e6);

        // Fund users
        usdc.transfer(ALICE, 1_000_000 * 1e6);
        usdc.transfer(BOB, 1_000_000 * 1e6);
    }

    // ============ Constructor Tests ============

    function testConstructorRevertsWithZeroAddress() public {
        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        new ArunaCore(address(0), owner);
    }

    function testConstructorSetsOwnerAndUSDC() public {
        ArunaCore newCore = new ArunaCore(address(usdc), ALICE);
        assertEq(newCore.owner(), ALICE);
        assertEq(address(newCore.USDC()), address(usdc));
    }

    // ============ Initialize Tests ============

    function testInitializeRevertsWithZeroAaveVault() public {
        ArunaCore newCore = new ArunaCore(address(usdc), owner);

        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        newCore.initialize(address(0), address(morphoVault), address(yieldRouter), address(octantModule));
    }

    function testInitializeRevertsWithZeroMorphoVault() public {
        ArunaCore newCore = new ArunaCore(address(usdc), owner);

        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        newCore.initialize(address(aaveVault), address(0), address(yieldRouter), address(octantModule));
    }

    function testInitializeRevertsWithZeroYieldRouter() public {
        ArunaCore newCore = new ArunaCore(address(usdc), owner);

        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        newCore.initialize(address(aaveVault), address(morphoVault), address(0), address(octantModule));
    }

    function testInitializeRevertsWithZeroOctantModule() public {
        ArunaCore newCore = new ArunaCore(address(usdc), owner);

        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        newCore.initialize(address(aaveVault), address(morphoVault), address(yieldRouter), address(0));
    }

    function testInitializeRevertsWithAllZeroAddresses() public {
        ArunaCore newCore = new ArunaCore(address(usdc), owner);

        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        newCore.initialize(address(0), address(0), address(0), address(0));
    }

    function testInitializeCanBeCalledMultipleTimes() public {
        // Note: Contract doesn't have double-init protection, this documents current behavior
        ArunaCore newCore = new ArunaCore(address(usdc), owner);

        newCore.initialize(address(aaveVault), address(morphoVault), address(yieldRouter), address(octantModule));

        // Second initialization succeeds (no protection currently)
        newCore.initialize(address(aaveVault), address(morphoVault), address(yieldRouter), address(octantModule));

        // Verify last initialization took effect
        (address aave, address morpho) = newCore.getVaultAddresses();
        assertEq(aave, address(aaveVault));
        assertEq(morpho, address(morphoVault));
    }

    function testInitializeByNonOwner() public {
        ArunaCore newCore = new ArunaCore(address(usdc), owner);

        vm.startPrank(ALICE);
        vm.expectRevert();
        newCore.initialize(address(aaveVault), address(morphoVault), address(yieldRouter), address(octantModule));
        vm.stopPrank();
    }

    // ============ Grant Limit Tests ============

    function testSubmitInvoiceWithGrantAtMaxLimit() public {
        // Test with maximum invoice amount (100,000 USDC)
        // This generates exactly 3,000 USDC grant (100,000 * 3%)
        // Set max grant to exactly 3,000 USDC to test at the limit
        core.updateMaxGrantAmount(3_000 * 1e6);

        uint256 invoiceAmount = 100_000 * 1e6; // MAX_INVOICE_AMOUNT

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        uint256 tokenId = core.submitInvoiceCommitment("Customer", invoiceAmount, getDueDateInFuture(90));

        ArunaCore.InvoiceCommitment memory commitment = core.getCommitment(tokenId);
        // Grant should be exactly 3,000 USDC (100,000 * 3%)
        assertEq(commitment.grantAmount, 3_000 * 1e6);

        vm.stopPrank();
    }

    function testSubmitInvoiceRevertsWhenGrantExceedsMaxLimit() public {
        // Set max grant to 2500 USDC
        core.updateMaxGrantAmount(2_500 * 1e6);

        // Invoice that would generate 3000 USDC grant (100,000 * 3% = 3,000)
        // This is exactly at MAX_INVOICE_AMOUNT and exceeds the 2500 grant limit
        uint256 invoiceAmount = 100_000 * 1e6;

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        vm.expectRevert(ArunaCore.GrantLimitExceeded.selector);
        core.submitInvoiceCommitment("Customer", invoiceAmount, getDueDateInFuture(90));

        vm.stopPrank();
    }

    // ============ Invalid TokenId Tests ============

    function testSettleInvoiceRevertsWithInvalidTokenId() public {
        // Try to settle token that was never minted
        vm.expectRevert(ArunaCore.InvoiceNotFound.selector);
        core.settleInvoice(999);
    }

    function testLiquidateInvoiceRevertsWithInvalidTokenId() public {
        // Try to liquidate token that was never minted
        vm.expectRevert(ArunaCore.InvoiceNotFound.selector);
        core.liquidateInvoice(999);
    }

    function testSettleLiquidatedInvoiceReverts() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer", 10_000 * 1e6, getDueDateInFuture(90));
        vm.stopPrank();

        // Fast forward past liquidation period
        skipDays(90 + 120 + 1);

        // Liquidate invoice
        core.liquidateInvoice(tokenId);

        // Try to settle liquidated invoice
        vm.startPrank(ALICE);
        vm.expectRevert(ArunaCore.InvalidStatus.selector);
        core.settleInvoice(tokenId);
        vm.stopPrank();
    }

    function testLiquidateAlreadyLiquidatedInvoiceReverts() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer", 10_000 * 1e6, getDueDateInFuture(90));
        vm.stopPrank();

        skipDays(300);

        core.liquidateInvoice(tokenId);

        // Try to liquidate again
        vm.expectRevert(ArunaCore.InvalidStatus.selector);
        core.liquidateInvoice(tokenId);
    }

    // ============ Liquidation Timing Tests ============

    function testLiquidateExactlyAt120Days() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 dueDate = getDueDateInFuture(90);
        uint256 tokenId = core.submitInvoiceCommitment("Customer", 10_000 * 1e6, dueDate);
        vm.stopPrank();

        // Fast forward to exactly 120 days after due date
        vm.warp(dueDate + 120 days);

        // Should succeed
        core.liquidateInvoice(tokenId);

        ArunaCore.InvoiceCommitment memory commitment = core.getCommitment(tokenId);
        assertTrue(commitment.isLiquidated);
    }

    function testLiquidateJustBeforeDeadlineFails() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 dueDate = getDueDateInFuture(90);
        uint256 tokenId = core.submitInvoiceCommitment("Customer", 10_000 * 1e6, dueDate);
        vm.stopPrank();

        // Fast forward to 1 second before liquidation deadline
        vm.warp(dueDate + 120 days - 1);

        vm.expectRevert(ArunaCore.InvalidStatus.selector);
        core.liquidateInvoice(tokenId);
    }

    // ============ Reputation Edge Cases ============

    function testLiquidateWithZeroReputationDoesNotUnderflow() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer", 10_000 * 1e6, getDueDateInFuture(90));
        vm.stopPrank();

        // Verify reputation is 0
        assertEq(core.getUserReputation(ALICE), 0);

        skipDays(300);
        core.liquidateInvoice(tokenId);

        // Reputation should still be 0 (not underflow)
        assertEq(core.getUserReputation(ALICE), 0);
    }

    function testLiquidateWithPositiveReputationDecreases() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        // Build reputation first
        uint256 tokenId1 = core.submitInvoiceCommitment("Customer A", 10_000 * 1e6, getDueDateInFuture(90));
        core.settleInvoice(tokenId1);
        assertEq(core.getUserReputation(ALICE), 1);

        // Submit and liquidate another invoice
        uint256 tokenId2 = core.submitInvoiceCommitment("Customer B", 10_000 * 1e6, getDueDateInFuture(90));
        vm.stopPrank();

        skipDays(300);
        core.liquidateInvoice(tokenId2);

        // Reputation should decrease
        assertEq(core.getUserReputation(ALICE), 0);
    }

    // ============ Vault Operations Not Initialized Tests ============

    function testDepositToAaveWhenNotInitializedReverts() public {
        ArunaCore uninitCore = new ArunaCore(address(usdc), owner);

        vm.startPrank(ALICE);
        usdc.approve(address(uninitCore), 10_000 * 1e6);

        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        uninitCore.depositToAaveVault(10_000 * 1e6);

        vm.stopPrank();
    }

    function testDepositToMorphoWhenNotInitializedReverts() public {
        ArunaCore uninitCore = new ArunaCore(address(usdc), owner);

        vm.startPrank(ALICE);
        usdc.approve(address(uninitCore), 10_000 * 1e6);

        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        uninitCore.depositToMorphoVault(10_000 * 1e6);

        vm.stopPrank();
    }

    function testWithdrawFromAaveWhenNotInitializedReverts() public {
        ArunaCore uninitCore = new ArunaCore(address(usdc), owner);

        vm.startPrank(ALICE);

        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        uninitCore.withdrawFromAaveVault(10_000 * 1e6);

        vm.stopPrank();
    }

    function testWithdrawFromMorphoWhenNotInitializedReverts() public {
        ArunaCore uninitCore = new ArunaCore(address(usdc), owner);

        vm.startPrank(ALICE);

        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        uninitCore.withdrawFromMorphoVault(10_000 * 1e6);

        vm.stopPrank();
    }

    function testDepositZeroAmountReverts() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), 1e6);

        vm.expectRevert(ArunaCore.InvalidAmount.selector);
        core.depositToAaveVault(0);

        vm.expectRevert(ArunaCore.InvalidAmount.selector);
        core.depositToMorphoVault(0);

        vm.stopPrank();
    }

    function testWithdrawZeroAmountReverts() public {
        vm.startPrank(ALICE);

        vm.expectRevert(ArunaCore.InvalidAmount.selector);
        core.withdrawFromAaveVault(0);

        vm.expectRevert(ArunaCore.InvalidAmount.selector);
        core.withdrawFromMorphoVault(0);

        vm.stopPrank();
    }

    // ============ Yield Operations Tests ============

    function testClaimYieldWhenNotInitializedReverts() public {
        ArunaCore uninitCore = new ArunaCore(address(usdc), owner);

        vm.startPrank(ALICE);
        vm.expectRevert(ArunaCore.InvalidAddress.selector);
        uninitCore.claimYield();
        vm.stopPrank();
    }

    function testClaimYieldSuccessfully() public {
        // Setup: ALICE deposits and generates yield
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        core.depositToAaveVault(100_000 * 1e6);
        vm.stopPrank();

        // Generate yield
        skipDays(7);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 1_000 * 1e6);
        aaveVault.harvestYield();

        // Claim yield - call yieldRouter directly, not through core
        vm.startPrank(ALICE);
        uint256 claimable = core.getUserYield(ALICE);
        assertTrue(claimable > 0, "Should have yield to claim");

        uint256 balanceBefore = usdc.balanceOf(ALICE);
        uint256 claimed = yieldRouter.claimYield(); // Call yieldRouter directly

        assertEq(claimed, claimable);
        assertEq(usdc.balanceOf(ALICE), balanceBefore + claimed);
        vm.stopPrank();
    }

    function testGetUserYieldWhenNotInitializedReturnsZero() public {
        ArunaCore uninitCore = new ArunaCore(address(usdc), owner);

        uint256 yield = uninitCore.getUserYield(ALICE);
        assertEq(yield, 0);
    }

    function testGetUserYieldWhenNoYieldReturnsZero() public {
        uint256 yield = core.getUserYield(ALICE);
        assertEq(yield, 0);
    }

    // ============ Token URI Tests ============

    function testTokenURIWithValidToken() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceWithProof(
            "Customer",
            10_000 * 1e6,
            getDueDateInFuture(90),
            "QmTestIPFSHash123"
        );
        vm.stopPrank();

        string memory uri = core.tokenURI(tokenId);

        // Token URI should contain IPFS hash
        assertEq(uri, "QmTestIPFSHash123");
    }

    function testTokenURIWithInvalidTokenReverts() public {
        vm.expectRevert(ArunaCore.InvoiceNotFound.selector);
        core.tokenURI(999);
    }

    function testTokenURIWithEmptyIPFSHash() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment(
            "Customer",
            10_000 * 1e6,
            getDueDateInFuture(90)
        );
        vm.stopPrank();

        string memory uri = core.tokenURI(tokenId);

        // Should return empty string if no IPFS hash
        assertEq(bytes(uri).length, 0);
    }

    // ============ Integration: Full Coverage Tests ============

    function testCompleteFlowWithAllEdgeCases() public {
        console.log("\n=== Complete Coverage Test ===\n");

        // 1. Submit invoice at grant limit
        core.updateMaxGrantAmount(3_000 * 1e6);
        uint256 exactLimitInvoice = 100_000 * 1e6; // 3% of 100k = 3k

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer", exactLimitInvoice, getDueDateInFuture(90));
        console.log("1. Invoice submitted at exact grant limit");

        // 2. Deposit to vaults
        core.depositToAaveVault(50_000 * 1e6);
        core.depositToMorphoVault(50_000 * 1e6);
        console.log("2. Deposited to both vaults");
        vm.stopPrank();

        // 3. Generate and harvest yield
        skipDays(7);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 500 * 1e6);
        metaMorpho.simulateYield(100);

        aaveVault.harvestYield();
        morphoVault.harvestYield();
        console.log("3. Yield harvested");

        // 4. Claim yield
        vm.startPrank(ALICE);
        uint256 claimed = core.claimYield();
        console.log("4. Yield claimed:", claimed / 1e6, "USDC");

        // 5. Settle invoice (build reputation)
        core.settleInvoice(tokenId);
        assertEq(core.getUserReputation(ALICE), 1);
        console.log("5. Invoice settled, reputation:", core.getUserReputation(ALICE));
        vm.stopPrank();

        console.log("\n[pass] Complete coverage test successful\n");
    }
}
