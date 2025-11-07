// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleAruna.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1000000 * 1e6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract SimpleArunaTest is Test {
    SimpleAruna public simpleAruna;
    MockUSDC public usdc;

    address public owner = address(0x1);
    address public business = address(0x2);

    function setUp() public {
        vm.startPrank(owner);
        usdc = new MockUSDC();
        simpleAruna = new SimpleAruna(address(usdc), owner);
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(address(simpleAruna.USDC()), address(usdc));
        assertEq(simpleAruna.GRANT_PERCENTAGE(), 300);
        assertEq(simpleAruna.COLLATERAL_PERCENTAGE(), 1000);
    }

    function testCommitInvoice() public {
        vm.startPrank(owner);
        // Fund contract for grants
        usdc.transfer(address(simpleAruna), 10000 * 1e6);
        vm.stopPrank();

        vm.startPrank(business);

        uint256 invoiceAmount = 10000 * 1e6; // $10,000
        uint256 dueDate = block.timestamp + 90 days;
        string memory ipfsHash = "QmTest123";

        uint256 tokenId = simpleAruna.submitInvoiceCommitment(
            business,
            "Test Customer",
            invoiceAmount,
            dueDate,
            ipfsHash
        );

        // Verify token was minted
        assertEq(simpleAruna.ownerOf(tokenId), business);

        // Verify grant was distributed
        uint256 expectedGrant = (invoiceAmount * 300) / 10000; // 3%
        assertEq(usdc.balanceOf(business), expectedGrant);

        vm.stopPrank();
    }

    function testDepositCollateral() public {
        uint256 tokenId = _createTestInvoice();
        uint256 collateralAmount = 1000 * 1e6; // 10% of $10,000

        // Business already got grant from _createTestInvoice, need to add collateral only
        vm.startPrank(owner);
        usdc.transfer(business, collateralAmount);
        vm.stopPrank();

        uint256 initialContractBalance = usdc.balanceOf(address(simpleAruna));

        vm.startPrank(business);
        usdc.approve(address(simpleAruna), collateralAmount);

        simpleAruna.depositCollateral(tokenId);

        // Check contract USDC balance increased by collateral amount
        assertEq(usdc.balanceOf(address(simpleAruna)), initialContractBalance + collateralAmount);

        vm.stopPrank();
    }

    function testSettleInvoice() public {
        uint256 tokenId = _createTestInvoice();
        uint256 collateralAmount = 1000 * 1e6;

        // Business already got grant from _createTestInvoice, need to add collateral only
        vm.startPrank(owner);
        usdc.transfer(business, collateralAmount);
        vm.stopPrank();

        vm.startPrank(business);
        usdc.approve(address(simpleAruna), collateralAmount);
        simpleAruna.depositCollateral(tokenId);

        uint256 balanceBeforeSettle = usdc.balanceOf(business);

        // Settle invoice
        simpleAruna.settleInvoice(tokenId);

        // Verify collateral returned
        assertEq(usdc.balanceOf(business), balanceBeforeSettle + collateralAmount);

        vm.stopPrank();
    }

    function _createTestInvoice() internal returns (uint256) {
        vm.startPrank(owner);
        usdc.transfer(address(simpleAruna), 10000 * 1e6);
        vm.stopPrank();

        vm.startPrank(business);

        uint256 invoiceAmount = 10000 * 1e6;
        uint256 dueDate = block.timestamp + 90 days;
        string memory ipfsHash = "QmTest123";

        uint256 tokenId = simpleAruna.submitInvoiceCommitment(
            business,
            "Test Customer",
            invoiceAmount,
            dueDate,
            ipfsHash
        );

        vm.stopPrank();
        return tokenId;
    }

    function testDepositToAaveVault() public {
        address investor = address(0x3);
        uint256 depositAmount = 1000 * 1e6;

        // Give investor some USDC
        vm.startPrank(owner);
        usdc.transfer(investor, depositAmount);
        vm.stopPrank();

        uint256 initialYield = simpleAruna.getUserYield(investor);

        vm.startPrank(investor);
        usdc.approve(address(simpleAruna), depositAmount);

        simpleAruna.depositToAaveVault(depositAmount);

        // Check deposit was recorded
        assertEq(simpleAruna.aaveDeposits(investor), depositAmount);

        // Check yield was calculated (6.5% of 1000 = 65)
        assertEq(simpleAruna.getUserYield(investor), initialYield + 65 * 1e6);

        vm.stopPrank();
    }

    function testDepositToMorphoVault() public {
        address investor = address(0x4);
        uint256 depositAmount = 1000 * 1e6;

        // Give investor some USDC
        vm.startPrank(owner);
        usdc.transfer(investor, depositAmount);
        vm.stopPrank();

        uint256 initialYield = simpleAruna.getUserYield(investor);

        vm.startPrank(investor);
        usdc.approve(address(simpleAruna), depositAmount);

        simpleAruna.depositToMorphoVault(depositAmount);

        // Check deposit was recorded
        assertEq(simpleAruna.morphoDeposits(investor), depositAmount);

        // Check yield was calculated (8.2% of 1000 = 82)
        assertEq(simpleAruna.getUserYield(investor), initialYield + 82 * 1e6);

        vm.stopPrank();
    }

    function testGetUserYield() public {
        address investor = address(0x5);

        // Initially yield should be 0
        assertEq(simpleAruna.getUserYield(investor), 0);
    }
}