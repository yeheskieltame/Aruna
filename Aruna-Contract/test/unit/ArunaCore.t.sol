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
 * @title ArunaCoreTest
 * @notice Comprehensive unit tests for ArunaCore contract
 */
contract ArunaCoreTest is TestHelpers {
    ArunaCore public core;
    MockUSDC public usdc;
    AaveVaultAdapter public aaveVault;
    MorphoVaultAdapter public morphoVault;
    YieldRouter public yieldRouter;
    OctantDonationModule public octantModule;
    MockOctantDeposits public mockOctant;

    MockAavePool public aavePool;
    MockAToken public aToken;
    MockMetaMorpho public metaMorpho;

    event InvoiceCommitted(
        uint256 indexed tokenId,
        address indexed business,
        string customerName,
        uint256 invoiceAmount,
        uint256 collateralAmount,
        uint256 grantAmount,
        uint256 dueDate
    );

    event GrantDistributed(address indexed business, uint256 amount, uint256 indexed tokenId);
    event InvoiceSettled(uint256 indexed tokenId, address indexed business, uint256 collateralReturned);
    event InvoiceLiquidated(uint256 indexed tokenId, address indexed business, uint256 collateralSeized);

    function setUp() public {
        labelAddresses();

        // Deploy USDC
        usdc = new MockUSDC();

        // Deploy core contract
        core = new ArunaCore(address(usdc), owner);

        // Deploy mocks
        aToken = new MockAToken();
        aavePool = new MockAavePool(address(aToken));
        aToken.setPool(address(aavePool));

        metaMorpho = new MockMetaMorpho(usdc, address(0x123)); // Mock Morpho address

        mockOctant = new MockOctantDeposits(address(usdc));

        // Deploy modules
        octantModule = new OctantDonationModule(address(mockOctant), address(usdc), owner);

        yieldRouter = new YieldRouter(address(usdc), address(octantModule), treasury, owner);

        // Deploy vaults
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

        // Initialize core
        core.initialize(
            address(aaveVault),
            address(morphoVault),
            address(yieldRouter),
            address(octantModule)
        );

        // Authorize vaults in YieldRouter
        yieldRouter.addVaultAuthorization(address(aaveVault));
        yieldRouter.addVaultAuthorization(address(morphoVault));

        // Fund aavePool and metaMorpho with USDC for withdrawals
        usdc.transfer(address(aavePool), 10_000_000 * 1e6);
        usdc.transfer(address(metaMorpho), 10_000_000 * 1e6);

        // Fund test users
        usdc.transfer(ALICE, 1_000_000 * 1e6);
        usdc.transfer(BOB, 1_000_000 * 1e6);
        usdc.transfer(CHARLIE, 1_000_000 * 1e6);
    }

    // ============ Invoice Submission Tests ============

    function testSubmitInvoiceCommitment() public {
        uint256 invoiceAmount = 10_000 * 1e6; // $10,000
        uint256 dueDate = getDueDateInFuture(90);

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        uint256 balanceBefore = usdc.balanceOf(ALICE);
        uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", invoiceAmount, dueDate);

        // Verify NFT minted
        assertEq(core.ownerOf(tokenId), ALICE);

        // Verify grant received (3%)
        uint256 expectedGrant = calculateGrant(invoiceAmount);
        uint256 expectedCollateral = calculateCollateral(invoiceAmount);
        uint256 netLocked = expectedCollateral - expectedGrant;

        assertEq(usdc.balanceOf(ALICE), balanceBefore - netLocked);

        // Verify commitment data
        ArunaCore.InvoiceCommitment memory commitment = core.getCommitment(tokenId);
        assertEq(commitment.business, ALICE);
        assertEq(commitment.invoiceAmount, invoiceAmount);
        assertEq(commitment.collateralAmount, expectedCollateral);
        assertEq(commitment.grantAmount, expectedGrant);
        assertEq(commitment.dueDate, dueDate);
        assertFalse(commitment.isSettled);
        assertFalse(commitment.isLiquidated);

        vm.stopPrank();
    }

    function testSubmitInvoiceWithProof() public {
        uint256 invoiceAmount = 10_000 * 1e6;
        uint256 dueDate = getDueDateInFuture(90);
        string memory ipfsHash = "QmTest123...";

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        uint256 tokenId = core.submitInvoiceWithProof("Customer Inc", invoiceAmount, dueDate, ipfsHash);

        ArunaCore.InvoiceCommitment memory commitment = core.getCommitment(tokenId);
        assertEq(commitment.ipfsHash, ipfsHash);

        vm.stopPrank();
    }

    function testSubmitInvoiceEvents() public {
        uint256 invoiceAmount = 10_000 * 1e6;
        uint256 dueDate = getDueDateInFuture(90);

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        vm.expectEmit(false, true, false, true);
        emit InvoiceCommitted(
            1,
            ALICE,
            "Customer Inc",
            invoiceAmount,
            calculateCollateral(invoiceAmount),
            calculateGrant(invoiceAmount),
            dueDate
        );

        vm.expectEmit(true, false, false, true);
        emit GrantDistributed(ALICE, calculateGrant(invoiceAmount), 1);

        core.submitInvoiceCommitment("Customer Inc", invoiceAmount, dueDate);

        vm.stopPrank();
    }

    function testSubmitInvoiceRevertsIfAmountTooSmall() public {
        uint256 tooSmall = 50 * 1e6; // Less than MIN_INVOICE_AMOUNT (100 USDC)
        uint256 dueDate = getDueDateInFuture(90);

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        vm.expectRevert(ArunaCore.InvalidAmount.selector);
        core.submitInvoiceCommitment("Customer Inc", tooSmall, dueDate);

        vm.stopPrank();
    }

    function testSubmitInvoiceRevertsIfAmountTooLarge() public {
        uint256 tooLarge = 200_000 * 1e6; // More than MAX_INVOICE_AMOUNT (100k USDC)
        uint256 dueDate = getDueDateInFuture(90);

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        vm.expectRevert(ArunaCore.InvalidAmount.selector);
        core.submitInvoiceCommitment("Customer Inc", tooLarge, dueDate);

        vm.stopPrank();
    }

    function testSubmitInvoiceRevertsIfDueDateInPast() public {
        // Ensure we have a non-zero timestamp
        vm.warp(1_000_000);

        uint256 invoiceAmount = 10_000 * 1e6;
        uint256 pastDueDate = block.timestamp - 1 days;

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        vm.expectRevert(ArunaCore.InvalidDueDate.selector);
        core.submitInvoiceCommitment("Customer Inc", invoiceAmount, pastDueDate);

        vm.stopPrank();
    }

    function testSubmitInvoiceRevertsIfDueDateTooFar() public {
        uint256 invoiceAmount = 10_000 * 1e6;
        uint256 farFutureDueDate = block.timestamp + 400 days; // More than 1 year

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        vm.expectRevert(ArunaCore.InvalidDueDate.selector);
        core.submitInvoiceCommitment("Customer Inc", invoiceAmount, farFutureDueDate);

        vm.stopPrank();
    }

    function testSubmitInvoiceRevertsIfInsufficientBalance() public {
        uint256 invoiceAmount = 50_000 * 1e6; // $50,000 (within limits but requires more collateral than ALICE has)
        uint256 dueDate = getDueDateInFuture(90);

        // Reduce ALICE's balance to less than required collateral (10% of $50k = $5k)
        vm.startPrank(ALICE);
        uint256 aliceBalance = usdc.balanceOf(ALICE);
        usdc.transfer(address(0xdead), aliceBalance - 3000 * 1e6); // Leave only $3k
        vm.stopPrank();

        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        vm.expectRevert(ArunaCore.InsufficientBalance.selector);
        core.submitInvoiceCommitment("Customer Inc", invoiceAmount, dueDate);

        vm.stopPrank();
    }

    // ============ Invoice Settlement Tests ============

    function testSettleInvoice() public {
        // Submit invoice
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", 10_000 * 1e6, getDueDateInFuture(90));

        uint256 balanceBefore = usdc.balanceOf(ALICE);
        uint256 expectedReturn = calculateCollateral(10_000 * 1e6) - calculateGrant(10_000 * 1e6);

        // Settle invoice
        vm.expectEmit(true, true, false, true);
        emit InvoiceSettled(tokenId, ALICE, expectedReturn);

        core.settleInvoice(tokenId);

        // Verify collateral returned
        assertEq(usdc.balanceOf(ALICE), balanceBefore + expectedReturn);

        // Verify commitment marked as settled
        ArunaCore.InvoiceCommitment memory commitment = core.getCommitment(tokenId);
        assertTrue(commitment.isSettled);
        assertFalse(commitment.isLiquidated);

        // Verify reputation increased
        assertEq(core.getUserReputation(ALICE), 1);

        vm.stopPrank();
    }

    function testSettleInvoiceRevertsIfNotOwner() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", 10_000 * 1e6, getDueDateInFuture(90));
        vm.stopPrank();

        vm.startPrank(BOB);
        vm.expectRevert(ArunaCore.Unauthorized.selector);
        core.settleInvoice(tokenId);
        vm.stopPrank();
    }

    function testSettleInvoiceRevertsIfAlreadySettled() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", 10_000 * 1e6, getDueDateInFuture(90));

        core.settleInvoice(tokenId);

        vm.expectRevert(ArunaCore.InvalidStatus.selector);
        core.settleInvoice(tokenId);
        vm.stopPrank();
    }

    function testSettleMultipleInvoicesIncreasesReputation() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        for (uint256 i = 0; i < 5; i++) {
            uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", 10_000 * 1e6, getDueDateInFuture(90));
            core.settleInvoice(tokenId);
        }

        assertEq(core.getUserReputation(ALICE), 5);
        vm.stopPrank();
    }

    // ============ Invoice Liquidation Tests ============

    function testLiquidateInvoice() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", 10_000 * 1e6, getDueDateInFuture(90));
        vm.stopPrank();

        // Fast forward past due date + 120 days
        skipDays(90 + 120 + 1);

        uint256 remainingCollateral = calculateCollateral(10_000 * 1e6) - calculateGrant(10_000 * 1e6);

        vm.expectEmit(true, true, false, true);
        emit InvoiceLiquidated(tokenId, ALICE, remainingCollateral);

        core.liquidateInvoice(tokenId);

        // Verify commitment marked as liquidated
        ArunaCore.InvoiceCommitment memory commitment = core.getCommitment(tokenId);
        assertFalse(commitment.isSettled);
        assertTrue(commitment.isLiquidated);

        // Verify reputation decreased
        assertEq(core.getUserReputation(ALICE), 0);
    }

    function testLiquidateInvoiceRevertsIfTooEarly() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", 10_000 * 1e6, getDueDateInFuture(90));
        vm.stopPrank();

        // Only 100 days passed (need 90 + 120 = 210 days)
        skipDays(100);

        vm.expectRevert(ArunaCore.InvalidStatus.selector);
        core.liquidateInvoice(tokenId);
    }

    function testLiquidateInvoiceRevertsIfAlreadySettled() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", 10_000 * 1e6, getDueDateInFuture(90));
        core.settleInvoice(tokenId);
        vm.stopPrank();

        skipDays(300);

        vm.expectRevert(ArunaCore.InvalidStatus.selector);
        core.liquidateInvoice(tokenId);
    }

    // ============ NFT Transfer Restriction Tests ============

    function testCannotTransferUnsettledInvoice() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", 10_000 * 1e6, getDueDateInFuture(90));

        vm.expectRevert(ArunaCore.InvalidStatus.selector);
        core.transferFrom(ALICE, BOB, tokenId);
        vm.stopPrank();
    }

    function testCanTransferSettledInvoice() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", 10_000 * 1e6, getDueDateInFuture(90));
        core.settleInvoice(tokenId);

        core.transferFrom(ALICE, BOB, tokenId);

        assertEq(core.ownerOf(tokenId), BOB);
        vm.stopPrank();
    }

    function testCanTransferLiquidatedInvoice() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);
        uint256 tokenId = core.submitInvoiceCommitment("Customer Inc", 10_000 * 1e6, getDueDateInFuture(90));
        vm.stopPrank();

        skipDays(300);
        core.liquidateInvoice(tokenId);

        vm.startPrank(ALICE);
        core.transferFrom(ALICE, BOB, tokenId);
        assertEq(core.ownerOf(tokenId), BOB);
        vm.stopPrank();
    }

    // ============ View Function Tests ============

    function testGetUserCommitments() public {
        vm.startPrank(ALICE);
        usdc.approve(address(core), type(uint256).max);

        uint256 tokenId1 = core.submitInvoiceCommitment("Customer A", 10_000 * 1e6, getDueDateInFuture(90));
        uint256 tokenId2 = core.submitInvoiceCommitment("Customer B", 20_000 * 1e6, getDueDateInFuture(60));
        uint256 tokenId3 = core.submitInvoiceCommitment("Customer C", 15_000 * 1e6, getDueDateInFuture(120));

        vm.stopPrank();

        uint256[] memory commitments = core.getUserCommitments(ALICE);
        assertEq(commitments.length, 3);
        assertEq(commitments[0], tokenId1);
        assertEq(commitments[1], tokenId2);
        assertEq(commitments[2], tokenId3);
    }

    function testGetVaultAddresses() public {
        (address aave, address morpho) = core.getVaultAddresses();
        assertEq(aave, address(aaveVault));
        assertEq(morpho, address(morphoVault));
    }

    // ============ Admin Function Tests ============

    function testUpdateMaxGrantAmount() public {
        uint256 newMax = 5000 * 1e6; // $5,000
        core.updateMaxGrantAmount(newMax);
        assertEq(core.maxGrantAmount(), newMax);
    }

    function testUpdateMaxGrantAmountRevertsIfNotOwner() public {
        vm.startPrank(ALICE);
        vm.expectRevert();
        core.updateMaxGrantAmount(5000 * 1e6);
        vm.stopPrank();
    }

    function testEmergencyWithdraw() public {
        // Fund core contract
        usdc.transfer(address(core), 10_000 * 1e6);

        uint256 ownerBalanceBefore = usdc.balanceOf(owner);
        core.emergencyWithdraw(address(usdc), 10_000 * 1e6);

        assertEq(usdc.balanceOf(owner), ownerBalanceBefore + 10_000 * 1e6);
    }
}
