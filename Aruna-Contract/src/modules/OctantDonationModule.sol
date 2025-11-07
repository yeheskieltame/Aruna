// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IOctantDeposits.sol";

/**
 * @title OctantDonationModule
 * @notice Handles automatic donations to public goods via Octant v2
 * @dev Routes 25% of protocol yield to Octant for public goods funding
 */
contract OctantDonationModule is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    IOctantDeposits public octantDeposits;
    IERC20 public donationToken; // Token used for donations (e.g., USDC converted to GLM/ETH)

    // Public goods allocation percentage (25% = 2500 basis points)
    uint256 public constant PUBLIC_GOODS_PERCENTAGE = 2500;
    uint256 public constant BASIS_POINTS = 10000;

    // Tracking
    uint256 public totalDonated;
    uint256 public currentEpochDonations;
    mapping(uint256 => uint256) public donationsPerEpoch;
    mapping(address => uint256) public businessContributions; // Track which businesses contributed

    // Supported public goods projects (for transparency)
    string[] public supportedProjects;

    // Events
    event DonationMade(
        uint256 indexed epoch,
        uint256 amount,
        address indexed contributor,
        uint256 timestamp
    );

    event EpochFinalized(
        uint256 indexed epoch,
        uint256 totalDonations
    );

    event ProjectAdded(string projectName);

    // Errors
    error InvalidAmount();
    error InvalidAddress();
    error DonationFailed();

    /**
     * @dev Constructor
     * @param _octantDeposits Address of Octant Deposits contract
     * @param _donationToken Token to use for donations
     * @param _owner Owner address
     */
    constructor(
        address _octantDeposits,
        address _donationToken,
        address _owner
    ) Ownable(_owner) {
        if (_octantDeposits == address(0) || _donationToken == address(0)) {
            revert InvalidAddress();
        }

        octantDeposits = IOctantDeposits(_octantDeposits);
        donationToken = IERC20(_donationToken);

        // Initialize with common public goods projects
        supportedProjects.push("Ethereum Foundation");
        supportedProjects.push("Gitcoin");
        supportedProjects.push("Protocol Guild");
        supportedProjects.push("OpenZeppelin");
        supportedProjects.push("EFF");
    }

    /**
     * @notice Donate to public goods via Octant
     * @param amount Amount to donate
     * @param contributor Address of the business/user contributing
     * @dev Called by YieldRouter when distributing yield
     */
    function donate(uint256 amount, address contributor) external nonReentrant {
        if (amount == 0) revert InvalidAmount();

        // Transfer donation token from caller (YieldRouter)
        donationToken.safeTransferFrom(msg.sender, address(this), amount);

        // Update tracking
        totalDonated += amount;
        currentEpochDonations += amount;
        businessContributions[contributor] += amount;

        // Get current epoch
        uint256 currentEpoch = octantDeposits.getCurrentEpoch();
        donationsPerEpoch[currentEpoch] += amount;

        emit DonationMade(currentEpoch, amount, contributor, block.timestamp);

        // Note: Actual lock to Octant would happen here in production
        // For MVP, we'll accumulate and allow manual forwarding
        // octantDeposits.lock(amount);
    }

    /**
     * @notice Forward accumulated donations to Octant (manual for MVP)
     * @dev In production, this could be automated via Chainlink Keeper
     */
    function forwardToOctant() external onlyOwner nonReentrant {
        if (currentEpochDonations == 0) revert InvalidAmount();

        uint256 amount = currentEpochDonations;
        uint256 currentEpoch = octantDeposits.getCurrentEpoch();

        // Approve Octant contract to spend tokens
        donationToken.safeIncreaseAllowance(address(octantDeposits), amount);

        // Lock funds for current epoch
        // Note: This is simplified - actual Octant integration might need GLM conversion
        try octantDeposits.lock(amount) {
            currentEpochDonations = 0;
            emit EpochFinalized(currentEpoch, amount);
        } catch {
            revert DonationFailed();
        }
    }

    /**
     * @notice Add a public goods project to supported list
     * @param projectName Name of the project
     */
    function addSupportedProject(string memory projectName) external onlyOwner {
        supportedProjects.push(projectName);
        emit ProjectAdded(projectName);
    }

    /**
     * @notice Get all supported projects
     * @return Array of project names
     */
    function getSupportedProjects() external view returns (string[] memory) {
        return supportedProjects;
    }

    /**
     * @notice Get donation stats for a specific business
     * @param business Address of the business
     * @return Total amount contributed by this business
     */
    function getBusinessContribution(address business) external view returns (uint256) {
        return businessContributions[business];
    }

    /**
     * @notice Get donations for a specific epoch
     * @param epoch Epoch number
     * @return Total donations for that epoch
     */
    function getEpochDonations(uint256 epoch) external view returns (uint256) {
        return donationsPerEpoch[epoch];
    }

    /**
     * @notice Get current epoch from Octant
     * @return Current epoch number
     */
    function getCurrentEpoch() external view returns (uint256) {
        return octantDeposits.getCurrentEpoch();
    }

    /**
     * @notice Emergency withdraw (only owner, only if funds stuck)
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }
}
