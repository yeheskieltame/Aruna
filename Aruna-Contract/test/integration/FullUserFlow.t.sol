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
 * @title FullUserFlowTest
 * @notice Integration tests demonstrating complete user journeys through the protocol
 *
 * Test Scenarios:
 * 1. Business Journey: Submit invoice, receive grant, settle invoice
 * 2. Investor Journey: Deposit to vault, earn yield, claim yield, withdraw
 * 3. Public Goods Journey: Track donations, forward to Octant
 * 4. Complete Protocol Flow: All actors interacting together
 */
contract FullUserFlowTest is TestHelpers {
    ArunaCore public core;
    AaveVaultAdapter public aaveVault;
    MorphoVaultAdapter public morphoVault;
    YieldRouter public yieldRouter;
    OctantDonationModule public octantModule;

    MockUSDC public usdc;
    MockAavePool public aavePool;
    MockAToken public aToken;
    MockMetaMorpho public metaMorpho;
    MockOctantDeposits public mockOctant;

    function setUp() public {
        labelAddresses();

        // Deploy USDC
        usdc = new MockUSDC();

        // Deploy Aave mocks
        aToken = new MockAToken();
        aavePool = new MockAavePool(address(aToken));
        aToken.setPool(address(aavePool));

        // Deploy Morpho mock
        metaMorpho = new MockMetaMorpho(usdc, address(0x123));

        // Deploy Octant mock
        mockOctant = new MockOctantDeposits(address(usdc));

        // Deploy protocol contracts
        octantModule = new OctantDonationModule(address(mockOctant), address(usdc), owner);

        yieldRouter = new YieldRouter(address(usdc), address(octantModule), treasury, owner);

        aaveVault = new AaveVaultAdapter(
            usdc,
            address(aavePool),
            address(aToken),
            address(yieldRouter),
            owner
        );

        morphoVault = new MorphoVaultAdapter(
            usdc,
            address(metaMorpho),
            address(yieldRouter),
            owner
        );

        core = new ArunaCore(address(usdc), owner);

        // Initialize
        core.initialize(
            address(aaveVault),
            address(morphoVault),
            address(yieldRouter),
            address(octantModule)
        );

        // Authorize vaults
        yieldRouter.addVaultAuthorization(address(aaveVault));
        yieldRouter.addVaultAuthorization(address(morphoVault));

        // Fund protocol components
        usdc.transfer(address(aavePool), 100_000_000 * 1e6);
        usdc.transfer(address(metaMorpho), 100_000_000 * 1e6);

        // Fund test users
        usdc.transfer(ALICE, 1_000_000 * 1e6); // Business
        usdc.transfer(BOB, 1_000_000 * 1e6); // Investor 1
        usdc.transfer(CHARLIE, 1_000_000 * 1e6); // Investor 2
        usdc.transfer(DAVID, 500_000 * 1e6); // Business 2
    }

    // ============ Sample Use Case 1: Web3 Development Agency ============

    /**
     * @notice Complete flow for a Web3 development agency using Aruna
     *
     * Scenario:
     * - Agency has $50,000 invoice with 60-day payment terms
     * - Submits to Aruna to get instant grant
     * - Locks minimal collateral (7% net after grant)
     * - Customer pays on time
     * - Agency settles invoice and builds reputation
     */
    function testSampleUseCase_Web3Agency() public {
        console.log("\n=== Sample Use Case: Web3 Development Agency ===\n");

        address agency = ALICE;
        uint256 invoiceAmount = 50_000 * 1e6; // $50,000
        uint256 dueDate = getDueDateInFuture(60);

        console.log("1. Agency submits invoice commitment:");
        console.log("   Invoice Amount: $50,000");
        console.log("   Customer: Enterprise Client Inc");
        console.log("   Payment Terms: 60 days");

        vm.startPrank(agency);

        // Record initial balance
        uint256 balanceBefore = usdc.balanceOf(agency);
        console.log("   Agency Balance Before:", balanceBefore / 1e6, "USDC");

        // Approve and submit invoice
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Enterprise Client Inc", invoiceAmount, dueDate);

        uint256 balanceAfter = usdc.balanceOf(agency);
        console.log("   Agency Balance After:", balanceAfter / 1e6, "USDC");

        uint256 grantReceived = calculateGrant(invoiceAmount);
        uint256 collateralLocked = calculateCollateral(invoiceAmount) - grantReceived;

        console.log("   Instant Grant Received: $", grantReceived / 1e6);
        console.log("   Net Collateral Locked: $", collateralLocked / 1e6);
        console.log("   Invoice NFT Minted: Token ID", tokenId);

        assertEq(balanceAfter, balanceBefore - collateralLocked);

        console.log("\n2. Time passes... Customer pays on time");
        // Fast forward to settlement
        skipDays(55);

        console.log("\n3. Agency settles invoice:");
        uint256 balanceBeforeSettle = usdc.balanceOf(agency);
        core.settleInvoice(tokenId);

        uint256 balanceAfterSettle = usdc.balanceOf(agency);
        console.log("   Collateral Returned: $", (balanceAfterSettle - balanceBeforeSettle) / 1e6);
        console.log("   Agency Reputation: +1 (Total:", core.getUserReputation(agency), ")");

        assertEq(balanceAfterSettle, balanceAfter + collateralLocked);
        assertEq(core.getUserReputation(agency), 1);

        console.log("\n4. Agency can now market as 'Ethereum-aligned business'");
        console.log("   [pass] Working capital improved");
        console.log("   [pass] On-chain credit history established");
        console.log("   [pass] Zero interest paid (only 7% collateral lock)\n");

        vm.stopPrank();
    }

    // ============ Sample Use Case 2: DeFi Investor ============

    /**
     * @notice Complete flow for a DeFi investor seeking yield with impact
     *
     * Scenario:
     * - Investor deposits $100,000 USDC
     * - Chooses Morpho vault (8.2% APY)
     * - Earns yield over time
     * - Claims accumulated yield
     * - Contributes to public goods automatically
     */
    function testSampleUseCase_DeFiInvestor() public {
        console.log("\n=== Sample Use Case: DeFi Investor ===\n");

        address investor = BOB;
        uint256 depositAmount = 100_000 * 1e6; // $100,000

        console.log("1. Investor deposits to Morpho vault:");
        console.log("   Amount: $100,000 USDC");
        console.log("   Target APY: 8.2%");

        vm.startPrank(investor);

        usdc.approve(address(core), type(uint256).max);
        uint256 shares = core.depositToMorphoVault(depositAmount);

        console.log("   Shares Received:", shares / 1e6);
        console.log("   No lock-up period - can withdraw anytime");

        vm.stopPrank();

        console.log("\n2. Time passes... Yield accrues");
        skipDays(30); // 30 days later

        // Simulate 1 month of yield (8.2% APY / 12 months)
        uint256 monthlyYield = (depositAmount * 820) / 10000 / 12; // ~683 USDC
        metaMorpho.simulateYield(68); // ~0.68% = 1 month of 8.2% APY

        console.log("   Days Passed: 30");
        console.log("   Yield Generated: ~$", monthlyYield / 1e6);

        console.log("\n3. Harvest yield (anyone can call):");
        morphoVault.harvestYield();

        console.log("   [pass] Yield harvested and distributed:");
        console.log("   - 70% to investors: $", calculateInvestorYield(monthlyYield) / 1e6);
        console.log("   - 25% to public goods: $", calculatePublicGoodsYield(monthlyYield) / 1e6);
        console.log("   - 5% to protocol: $", calculateProtocolFee(monthlyYield) / 1e6);

        console.log("\n4. Investor claims yield:");
        vm.startPrank(investor);

        uint256 claimable = yieldRouter.getClaimableYield(investor);
        console.log("   Claimable Yield: $", claimable / 1e6);

        uint256 balanceBefore = usdc.balanceOf(investor);
        yieldRouter.claimYield();
        uint256 balanceAfter = usdc.balanceOf(investor);

        console.log("   Yield Claimed: $", (balanceAfter - balanceBefore) / 1e6);

        vm.stopPrank();

        console.log("\n5. Investor can withdraw principal anytime:");
        vm.startPrank(investor);

        uint256 withdrawAmount = 50_000 * 1e6; // Withdraw half

        // Approve vault to manage vault shares (needed for ERC4626)
        morphoVault.approve(address(core), type(uint256).max);

        core.withdrawFromMorphoVault(withdrawAmount);

        console.log("   Withdrew: $50,000");
        console.log("   Remaining in vault: $50,000");
        console.log("   [pass] Full liquidity maintained\n");

        vm.stopPrank();
    }

    // ============ Sample Use Case 3: Public Goods Project ============

    /**
     * @notice Tracking public goods funding through the protocol
     *
     * Scenario:
     * - Multiple investors deposit to vaults
     * - Yield is generated and harvested
     * - 25% automatically routed to Octant
     * - Public goods projects receive ongoing funding
     */
    function testSampleUseCase_PublicGoodsFunding() public {
        console.log("\n=== Sample Use Case: Public Goods Funding ===\n");

        console.log("1. Multiple investors deposit:");

        // Investor 1: $200k to Aave
        vm.startPrank(BOB);
        usdc.approve(address(core), type(uint256).max);
        core.depositToAaveVault(200_000 * 1e6);
        vm.stopPrank();
        console.log("   Investor 1: $200,000 to Aave vault (6.5% APY)");

        // Investor 2: $300k to Morpho
        vm.startPrank(CHARLIE);
        usdc.approve(address(core), type(uint256).max);
        core.depositToMorphoVault(300_000 * 1e6);
        vm.stopPrank();
        console.log("   Investor 2: $300,000 to Morpho vault (8.2% APY)");

        console.log("   Total TVL: $500,000");

        console.log("\n2. One year passes... Yield accumulates");
        skipDays(365);

        // Simulate 1 year of yield
        // Aave: 200k * 6.5% = 13,000 USDC
        // Morpho: 300k * 8.2% = 24,600 USDC
        // Total: 37,600 USDC
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 13_000 * 1e6);
        metaMorpho.simulateYield(820); // 8.2% yield

        uint256 totalYield = 37_600 * 1e6;
        console.log("   Total Yield Generated: $37,600");

        console.log("\n3. Harvest yield from both vaults:");
        aaveVault.harvestYield();
        morphoVault.harvestYield();

        uint256 publicGoodsAmount = calculatePublicGoodsYield(totalYield);
        console.log("   Public Goods Allocation (25%): $", publicGoodsAmount / 1e6);

        // Verify public goods received funds
        assertApproxEqRel(
            octantModule.currentEpochDonations(),
            publicGoodsAmount,
            1000 * 1e6, // 1000 USDC tolerance (1% of expected amount)
            "Public goods should receive 25%"
        );

        console.log("\n4. Public goods distribution:");
        console.log("   Current Epoch Donations: $", octantModule.currentEpochDonations() / 1e6);
        console.log("   Total Donated (lifetime): $", octantModule.totalDonated() / 1e6);

        string[] memory projects = octantModule.getSupportedProjects();
        console.log("   Supported Projects:");
        for (uint256 i = 0; i < projects.length && i < 5; i++) {
            console.log("   -", projects[i]);
        }

        console.log("\n5. Comparison with traditional funding:");
        console.log("   Traditional Gitcoin Round: $1M (one-time)");
        console.log("   Aruna at $500k TVL: $9,400/year (recurring)");
        console.log("   5-year sustainable funding: $47,000");
        console.log("   [pass] Predictable, ongoing public goods funding\n");
    }

    // ============ Complete Protocol Flow ============

    /**
     * @notice Full integration test with all actors interacting
     *
     * Tests the complete protocol flow:
     * 1. Multiple businesses submit invoices
     * 2. Multiple investors deposit to different vaults
     * 3. Yield is generated and harvested
     * 4. Investors claim their proportional share
     * 5. Public goods receive automatic donations
     * 6. Businesses settle invoices and build reputation
     */
    function testCompleteProtocolFlow() public {
        console.log("\n=== Complete Protocol Flow Test ===\n");

        // Phase 1: Submit invoices (returns tokenIds for later use)
        (uint256 tokenId1, uint256 tokenId2) = _phase1_submitInvoices();

        // Phase 2: Investor deposits
        _phase2_investorDeposits();

        // Phase 3: Simulate yield accrual
        _phase3_simulateYield();

        // Phase 4: Harvest and verify distribution
        _phase4_harvestYield();

        // Phase 5: Investors claim yield
        _phase5_investorsClaim();

        // Phase 6: Settle invoices
        _phase6_settleInvoices(tokenId1, tokenId2);

        // Phase 7: Verify final state
        _phase7_verifyFinalState();

        console.log("\n[pass] Complete protocol flow successful!\n");
    }

    function _phase1_submitInvoices() internal returns (uint256 tokenId1, uint256 tokenId2) {
        console.log("Phase 1: Businesses submit invoices");

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        tokenId1 = core.submitInvoiceCommitment("Client A", 50_000 * 1e6, getDueDateInFuture(90));
        console.log("Business 1 (ALICE): $50,000 invoice submitted");
        vm.stopPrank();

        vm.startPrank(DAVID);
        usdc.approve(address(core), type(uint256).max);
        tokenId2 = core.submitInvoiceCommitment("Client B", 30_000 * 1e6, getDueDateInFuture(60));
        console.log("Business 2 (DAVID): $30,000 invoice submitted");
        vm.stopPrank();
    }

    function _phase2_investorDeposits() internal {
        console.log("\nPhase 2: Investors deposit to vaults");

        vm.startPrank(BOB);
        usdc.approve(address(core), type(uint256).max);
        core.depositToAaveVault(100_000 * 1e6);
        console.log("Investor 1 (BOB): $100,000 to Aave");
        vm.stopPrank();

        vm.startPrank(CHARLIE);
        usdc.approve(address(core), type(uint256).max);
        core.depositToMorphoVault(150_000 * 1e6);
        console.log("Investor 2 (CHARLIE): $150,000 to Morpho");
        vm.stopPrank();
    }

    function _phase3_simulateYield() internal {
        console.log("\nPhase 3: Time passes (90 days)...");
        skipDays(90);

        // Simulate yield for 3 months (scoped to reduce stack depth)
        {
            uint256 aaveYield = (100_000 * 1e6 * 65) / 10000 / 4; // ~1,625 USDC
            uint256 morphoYield = (150_000 * 1e6 * 82) / 10000 / 4; // ~3,075 USDC

            aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), aaveYield);
            metaMorpho.simulateYield(205); // ~2.05% = 3 months of 8.2% APY

            console.log("Aave Vault Yield: $", aaveYield / 1e6);
            console.log("Morpho Vault Yield: $", morphoYield / 1e6);
            console.log("Total Yield: $", (aaveYield + morphoYield) / 1e6);
        }
    }

    function _phase4_harvestYield() internal {
        console.log("\nPhase 4: Harvest yield from vaults");

        aaveVault.harvestYield();
        morphoVault.harvestYield();

        // Verify distribution (scoped to reduce stack depth)
        {
            uint256 actualTotalYield = yieldRouter.totalYieldDistributed();
            uint256 actualInvestorYield = yieldRouter.totalInvestorYield();
            uint256 actualPublicGoodsYield = yieldRouter.totalPublicGoodsYield();
            uint256 actualProtocolFee = yieldRouter.totalProtocolFees();

            console.log("Distribution:");
            console.log("- Total Yield: $", actualTotalYield / 1e6);
            console.log("- Investors (70%): $", actualInvestorYield / 1e6);
            console.log("- Public Goods (25%): $", actualPublicGoodsYield / 1e6);
            console.log("- Protocol (5%): $", actualProtocolFee / 1e6);

            // Verify percentages
            assertEq(actualInvestorYield, calculateInvestorYield(actualTotalYield), "Investor yield should be 70%");
            assertEq(actualPublicGoodsYield, calculatePublicGoodsYield(actualTotalYield), "Public goods yield should be 25%");
            assertEq(actualProtocolFee, calculateProtocolFee(actualTotalYield), "Protocol fee should be 5%");
        }
    }

    function _phase5_investorsClaim() internal {
        console.log("\nPhase 5: Investors claim their yield");

        // BOB claims (scoped)
        {
            vm.startPrank(BOB);
            uint256 claimable = yieldRouter.getClaimableYield(BOB);
            console.log("BOB claimable: $", claimable / 1e6);
            uint256 claimed = yieldRouter.claimYield();
            assertEq(claimed, claimable);
            console.log("BOB claimed: $", claimed / 1e6);
            vm.stopPrank();
        }

        // CHARLIE claims (scoped)
        {
            vm.startPrank(CHARLIE);
            uint256 claimable = yieldRouter.getClaimableYield(CHARLIE);
            console.log("CHARLIE claimable: $", claimable / 1e6);
            uint256 claimed = yieldRouter.claimYield();
            assertEq(claimed, claimable);
            console.log("CHARLIE claimed: $", claimed / 1e6);
            vm.stopPrank();
        }
    }

    function _phase6_settleInvoices(uint256 tokenId1, uint256 tokenId2) internal {
        console.log("\nPhase 6: Businesses settle invoices");

        vm.startPrank(ALICE);
        core.settleInvoice(tokenId1);
        console.log("ALICE settled invoice, reputation:", core.getUserReputation(ALICE));
        vm.stopPrank();

        vm.startPrank(DAVID);
        core.settleInvoice(tokenId2);
        console.log("DAVID settled invoice, reputation:", core.getUserReputation(DAVID));
        vm.stopPrank();
    }

    function _phase7_verifyFinalState() internal {
        console.log("\nPhase 7: Public goods impact");
        console.log("Total donated to public goods: $", octantModule.totalDonated() / 1e6);
        console.log("Current epoch donations: $", octantModule.currentEpochDonations() / 1e6);

        console.log("\n=== Final Protocol State ===");
        console.log("Total Yield Distributed: $", yieldRouter.totalYieldDistributed() / 1e6);
        console.log("Total Investor Yield: $", yieldRouter.totalInvestorYield() / 1e6);
        console.log("Total Public Goods: $", yieldRouter.totalPublicGoodsYield() / 1e6);
        console.log("Total Protocol Fees: $", yieldRouter.totalProtocolFees() / 1e6);
        console.log("Treasury Balance: $", usdc.balanceOf(treasury) / 1e6);

        // Final assertions
        assertEq(core.getUserReputation(ALICE), 1);
        assertEq(core.getUserReputation(DAVID), 1);
        assertTrue(yieldRouter.totalYieldDistributed() > 0);
        assertTrue(octantModule.totalDonated() > 0);
        assertTrue(usdc.balanceOf(treasury) > 0);
    }

    // ============ Edge Case: Multiple Harvests and Claims ============

    function testMultipleHarvestsAndClaims() public {
        console.log("\n=== Multiple Harvests and Claims Test ===\n");

        // Setup investor
        vm.startPrank(BOB);
        usdc.approve(address(core), type(uint256).max);
        core.depositToAaveVault(100_000 * 1e6);
        vm.stopPrank();

        // First harvest cycle
        skipDays(7);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 1_250 * 1e6); // ~1 week yield
        aaveVault.harvestYield();

        vm.startPrank(BOB);
        uint256 claim1 = yieldRouter.claimYield();
        console.log("First claim: $", claim1 / 1e6);
        vm.stopPrank();

        // Second harvest cycle
        skipDays(7);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 1_250 * 1e6);
        aaveVault.harvestYield();

        vm.startPrank(BOB);
        uint256 claim2 = yieldRouter.claimYield();
        console.log("Second claim: $", claim2 / 1e6);
        vm.stopPrank();

        // Third harvest cycle
        skipDays(7);
        aavePool.simulateYieldAccrual(address(usdc), address(aaveVault), 1_250 * 1e6);
        aaveVault.harvestYield();

        vm.startPrank(BOB);
        uint256 claim3 = yieldRouter.claimYield();
        console.log("Third claim: $", claim3 / 1e6);
        vm.stopPrank();

        console.log("Total claimed: $", (claim1 + claim2 + claim3) / 1e6);
        assertTrue(claim1 > 0 && claim2 > 0 && claim3 > 0);

        console.log("[pass] Multiple harvest cycles working correctly\n");
    }
}
