// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/modules/OctantDonationModule.sol";
import "../../src/mocks/MockOctantDeposits.sol";
import "../helpers/TestHelpers.sol";

/**
 * @title OctantDonationModuleTest
 * @notice Comprehensive unit tests for OctantDonationModule contract
 * @dev Tests donation tracking, epoch management, and Octant integration
 */
contract OctantDonationModuleTest is TestHelpers {
    OctantDonationModule public octantModule;
    MockOctantDeposits public mockOctant;
    MockUSDC public usdc;

    address public mockYieldRouter = address(0x7001);

    event DonationMade(
        uint256 indexed epoch,
        uint256 amount,
        address indexed contributor,
        uint256 timestamp
    );

    event EpochFinalized(uint256 indexed epoch, uint256 totalDonations);
    event ProjectAdded(string projectName);

    function setUp() public {
        labelAddresses();

        // Deploy USDC
        usdc = new MockUSDC();

        // Deploy Octant mock
        mockOctant = new MockOctantDeposits(address(usdc));

        // Deploy Octant donation module
        octantModule = new OctantDonationModule(address(mockOctant), address(usdc), owner);

        // Fund test addresses
        usdc.transfer(ALICE, 1_000_000 * 1e6);
        usdc.transfer(BOB, 500_000 * 1e6);
        usdc.transfer(mockYieldRouter, 10_000_000 * 1e6);

        vm.label(mockYieldRouter, "MockYieldRouter");
    }

    // ============ Deployment & Initialization Tests ============

    function testDeploymentState() public {
        assertEq(address(octantModule.octantDeposits()), address(mockOctant));
        assertEq(address(octantModule.donationToken()), address(usdc));
        assertEq(octantModule.owner(), owner);
        assertEq(octantModule.totalDonated(), 0);
        assertEq(octantModule.currentEpochDonations(), 0);
        assertEq(octantModule.PUBLIC_GOODS_PERCENTAGE(), 2500); // 25%
        assertEq(octantModule.BASIS_POINTS(), 10000);
    }

    function testDefaultSupportedProjects() public {
        string[] memory projects = octantModule.getSupportedProjects();
        assertEq(projects.length, 5);
        assertEq(projects[0], "Ethereum Foundation");
        assertEq(projects[1], "Gitcoin");
        assertEq(projects[2], "Protocol Guild");
        assertEq(projects[3], "OpenZeppelin");
        assertEq(projects[4], "EFF");
    }

    // ============ Donation Tests ============

    function testDonate() public {
        uint256 donationAmount = 1_000 * 1e6;
        uint256 currentEpoch = mockOctant.getCurrentEpoch();

        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), donationAmount);

        vm.expectEmit(true, false, false, true);
        emit DonationMade(currentEpoch, donationAmount, ALICE, block.timestamp);

        octantModule.donate(donationAmount, ALICE);

        // Verify tracking
        assertEq(octantModule.totalDonated(), donationAmount);
        assertEq(octantModule.currentEpochDonations(), donationAmount);
        assertEq(octantModule.getBusinessContribution(ALICE), donationAmount);
        assertEq(octantModule.getEpochDonations(currentEpoch), donationAmount);

        vm.stopPrank();
    }

    function testDonateMultipleTimes() public {
        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), type(uint256).max);

        // First donation
        octantModule.donate(1_000 * 1e6, ALICE);

        // Second donation
        octantModule.donate(500 * 1e6, ALICE);

        // Third donation
        octantModule.donate(750 * 1e6, BOB);

        vm.stopPrank();

        // Verify cumulative tracking
        assertEq(octantModule.totalDonated(), 2_250 * 1e6);
        assertEq(octantModule.currentEpochDonations(), 2_250 * 1e6);
        assertEq(octantModule.getBusinessContribution(ALICE), 1_500 * 1e6);
        assertEq(octantModule.getBusinessContribution(BOB), 750 * 1e6);
    }

    function testDonateMultipleEpochs() public {
        uint256 epoch1 = mockOctant.getCurrentEpoch();

        // Donations in epoch 1
        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), type(uint256).max);
        octantModule.donate(1_000 * 1e6, ALICE);
        vm.stopPrank();

        assertEq(octantModule.getEpochDonations(epoch1), 1_000 * 1e6);

        // Advance to next epoch
        mockOctant.advanceEpoch();
        uint256 epoch2 = mockOctant.getCurrentEpoch();
        assertEq(epoch2, epoch1 + 1);

        // Donations in epoch 2
        vm.startPrank(mockYieldRouter);
        octantModule.donate(2_000 * 1e6, BOB);
        vm.stopPrank();

        // Verify per-epoch tracking
        assertEq(octantModule.getEpochDonations(epoch1), 1_000 * 1e6);
        assertEq(octantModule.getEpochDonations(epoch2), 2_000 * 1e6);
        assertEq(octantModule.totalDonated(), 3_000 * 1e6);
    }

    function testDonateRevertsIfZeroAmount() public {
        vm.startPrank(mockYieldRouter);
        vm.expectRevert(OctantDonationModule.InvalidAmount.selector);
        octantModule.donate(0, ALICE);
        vm.stopPrank();
    }

    function testDonateTransfersTokens() public {
        uint256 donationAmount = 5_000 * 1e6;
        uint256 routerBalanceBefore = usdc.balanceOf(mockYieldRouter);
        uint256 moduleBalanceBefore = usdc.balanceOf(address(octantModule));

        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), donationAmount);
        octantModule.donate(donationAmount, ALICE);
        vm.stopPrank();

        assertEq(usdc.balanceOf(mockYieldRouter), routerBalanceBefore - donationAmount);
        assertEq(usdc.balanceOf(address(octantModule)), moduleBalanceBefore + donationAmount);
    }

    // ============ Forward to Octant Tests ============

    function testForwardToOctant() public {
        // Setup: Make donations
        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), 10_000 * 1e6);
        octantModule.donate(10_000 * 1e6, ALICE);
        vm.stopPrank();

        uint256 currentEpoch = mockOctant.getCurrentEpoch();
        uint256 octantBalanceBefore = usdc.balanceOf(address(mockOctant));

        vm.expectEmit(true, false, false, true);
        emit EpochFinalized(currentEpoch, 10_000 * 1e6);

        octantModule.forwardToOctant();

        // Verify donations were forwarded
        assertEq(octantModule.currentEpochDonations(), 0);
        assertEq(usdc.balanceOf(address(mockOctant)), octantBalanceBefore + 10_000 * 1e6);
    }

    function testForwardToOctantRevertsIfZeroDonations() public {
        vm.expectRevert(OctantDonationModule.InvalidAmount.selector);
        octantModule.forwardToOctant();
    }

    function testForwardToOctantRevertsIfNotOwner() public {
        // Setup: Make donations
        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), 1_000 * 1e6);
        octantModule.donate(1_000 * 1e6, ALICE);
        vm.stopPrank();

        // Try to forward as non-owner
        vm.startPrank(ALICE);
        vm.expectRevert();
        octantModule.forwardToOctant();
        vm.stopPrank();
    }

    function testForwardToOctantMultipleTimes() public {
        // First donation and forward
        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), type(uint256).max);
        octantModule.donate(5_000 * 1e6, ALICE);
        vm.stopPrank();

        octantModule.forwardToOctant();
        assertEq(octantModule.currentEpochDonations(), 0);

        // Second donation and forward
        vm.startPrank(mockYieldRouter);
        octantModule.donate(3_000 * 1e6, BOB);
        vm.stopPrank();

        octantModule.forwardToOctant();
        assertEq(octantModule.currentEpochDonations(), 0);

        // Total should accumulate
        assertEq(octantModule.totalDonated(), 8_000 * 1e6);
    }

    // ============ Business Contribution Tracking Tests ============

    function testGetBusinessContribution() public {
        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), type(uint256).max);

        octantModule.donate(1_000 * 1e6, ALICE);
        octantModule.donate(500 * 1e6, ALICE);
        octantModule.donate(2_000 * 1e6, BOB);

        vm.stopPrank();

        assertEq(octantModule.getBusinessContribution(ALICE), 1_500 * 1e6);
        assertEq(octantModule.getBusinessContribution(BOB), 2_000 * 1e6);
        assertEq(octantModule.getBusinessContribution(CHARLIE), 0);
    }

    function testBusinessContributionPersistsAcrossEpochs() public {
        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), type(uint256).max);

        // Donate in epoch 1
        octantModule.donate(1_000 * 1e6, ALICE);

        // Advance epoch
        mockOctant.advanceEpoch();

        // Donate in epoch 2
        octantModule.donate(500 * 1e6, ALICE);

        vm.stopPrank();

        // Total contribution should accumulate
        assertEq(octantModule.getBusinessContribution(ALICE), 1_500 * 1e6);
    }

    // ============ Epoch Tracking Tests ============

    function testGetEpochDonations() public {
        uint256 epoch1 = mockOctant.getCurrentEpoch();

        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), type(uint256).max);
        octantModule.donate(3_000 * 1e6, ALICE);
        vm.stopPrank();

        assertEq(octantModule.getEpochDonations(epoch1), 3_000 * 1e6);

        // Advance epoch
        mockOctant.advanceEpoch();
        uint256 epoch2 = mockOctant.getCurrentEpoch();

        vm.startPrank(mockYieldRouter);
        octantModule.donate(5_000 * 1e6, BOB);
        vm.stopPrank();

        assertEq(octantModule.getEpochDonations(epoch1), 3_000 * 1e6);
        assertEq(octantModule.getEpochDonations(epoch2), 5_000 * 1e6);
    }

    function testGetCurrentEpoch() public {
        uint256 epoch1 = octantModule.getCurrentEpoch();
        assertEq(epoch1, 0);

        mockOctant.advanceEpoch();

        uint256 epoch2 = octantModule.getCurrentEpoch();
        assertEq(epoch2, 1);
    }

    // ============ Supported Projects Tests ============

    function testGetSupportedProjects() public {
        string[] memory projects = octantModule.getSupportedProjects();

        assertEq(projects.length, 5);
        assertEq(projects[0], "Ethereum Foundation");
        assertEq(projects[1], "Gitcoin");
        assertEq(projects[2], "Protocol Guild");
        assertEq(projects[3], "OpenZeppelin");
        assertEq(projects[4], "EFF");
    }

    function testAddSupportedProject() public {
        string memory newProject = "Uniswap Foundation";

        vm.expectEmit(false, false, false, true);
        emit ProjectAdded(newProject);

        octantModule.addSupportedProject(newProject);

        string[] memory projects = octantModule.getSupportedProjects();
        assertEq(projects.length, 6);
        assertEq(projects[5], newProject);
    }

    function testAddMultipleProjects() public {
        octantModule.addSupportedProject("Project A");
        octantModule.addSupportedProject("Project B");
        octantModule.addSupportedProject("Project C");

        string[] memory projects = octantModule.getSupportedProjects();
        assertEq(projects.length, 8); // 5 default + 3 new
        assertEq(projects[5], "Project A");
        assertEq(projects[6], "Project B");
        assertEq(projects[7], "Project C");
    }

    function testAddSupportedProjectRevertsIfNotOwner() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        octantModule.addSupportedProject("New Project");
        vm.stopPrank();
    }

    // ============ Emergency Withdraw Tests ============

    function testEmergencyWithdraw() public {
        // Fund module
        usdc.transfer(address(octantModule), 10_000 * 1e6);

        uint256 ownerBalanceBefore = usdc.balanceOf(owner);

        octantModule.emergencyWithdraw(address(usdc), 10_000 * 1e6);

        assertEq(usdc.balanceOf(owner), ownerBalanceBefore + 10_000 * 1e6);
        assertEq(usdc.balanceOf(address(octantModule)), 0);
    }

    function testEmergencyWithdrawRevertsIfNotOwner() public {
        usdc.transfer(address(octantModule), 10_000 * 1e6);

        vm.startPrank(ALICE);
        vm.expectRevert();
        octantModule.emergencyWithdraw(address(usdc), 10_000 * 1e6);
        vm.stopPrank();
    }

    // ============ Integration Tests ============

    function testFullDonationCycle() public {
        console.log("\n=== Full Donation Cycle Test ===\n");

        uint256 epoch1 = mockOctant.getCurrentEpoch();
        console.log("Starting epoch:", epoch1);

        // Phase 1: Multiple donations
        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), type(uint256).max);

        octantModule.donate(1_000 * 1e6, ALICE);
        console.log("1. ALICE contributed: $1,000");

        octantModule.donate(2_000 * 1e6, BOB);
        console.log("2. BOB contributed: $2,000");

        octantModule.donate(500 * 1e6, CHARLIE);
        console.log("3. CHARLIE contributed: $500");

        vm.stopPrank();

        console.log("\nTotal donations in epoch", epoch1, ": $", octantModule.currentEpochDonations() / 1e6);

        // Phase 2: Forward to Octant
        uint256 octantBalanceBefore = usdc.balanceOf(address(mockOctant));
        octantModule.forwardToOctant();
        uint256 forwarded = usdc.balanceOf(address(mockOctant)) - octantBalanceBefore;

        console.log("\nForwarded to Octant: $", forwarded / 1e6);
        assertEq(forwarded, 3_500 * 1e6);
        assertEq(octantModule.currentEpochDonations(), 0);

        // Phase 3: New epoch, new donations
        mockOctant.advanceEpoch();
        uint256 epoch2 = mockOctant.getCurrentEpoch();
        console.log("\nAdvanced to epoch:", epoch2);

        vm.startPrank(mockYieldRouter);
        octantModule.donate(5_000 * 1e6, ALICE);
        console.log("4. ALICE contributed in epoch 2: $5,000");
        vm.stopPrank();

        // Verify tracking
        console.log("\nFinal Statistics:");
        console.log("- Total donated (lifetime): $", octantModule.totalDonated() / 1e6);
        console.log("- ALICE total contribution: $", octantModule.getBusinessContribution(ALICE) / 1e6);
        console.log("- BOB total contribution: $", octantModule.getBusinessContribution(BOB) / 1e6);
        console.log("- Epoch 1 donations: $", octantModule.getEpochDonations(epoch1) / 1e6);
        console.log("- Epoch 2 donations: $", octantModule.getEpochDonations(epoch2) / 1e6);

        assertEq(octantModule.totalDonated(), 8_500 * 1e6);
        assertEq(octantModule.getBusinessContribution(ALICE), 6_000 * 1e6);
        assertEq(octantModule.getBusinessContribution(BOB), 2_000 * 1e6);

        console.log("\n[pass] Full donation cycle successful!\n");
    }

    function testPublicGoodsImpactProjection() public {
        console.log("\n=== Public Goods Impact Projection ===\n");

        uint256 yearlyYield = 37_600 * 1e6; // Example: $500k TVL at 7.8% APY
        uint256 publicGoodsShare = (yearlyYield * 2500) / 10000; // 25%

        console.log("Scenario: $500,000 TVL");
        console.log("Yearly yield at 7.8% APY: $", yearlyYield / 1e6);
        console.log("Public goods allocation (25%): $", publicGoodsShare / 1e6);

        // Simulate donations
        vm.startPrank(mockYieldRouter);
        usdc.approve(address(octantModule), publicGoodsShare);
        octantModule.donate(publicGoodsShare, address(this));
        vm.stopPrank();

        console.log("\nComparison:");
        console.log("- Traditional Gitcoin Round: $1,000,000 (one-time)");
        console.log("- Aruna at $500k TVL: $", publicGoodsShare / 1e6, "/year (recurring)");
        console.log("- 5-year sustainable funding: $", (publicGoodsShare * 5) / 1e6);

        assertTrue(publicGoodsShare > 0);

        console.log("\n[pass] Predictable public goods funding achieved\n");
    }
}
