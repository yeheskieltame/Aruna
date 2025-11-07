// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MockOctantDeposits
 * @notice Mock contract for testing Octant v2 integration
 * @dev Simulates Octant Deposits contract behavior
 */
contract MockOctantDeposits {
    using SafeERC20 for IERC20;

    IERC20 public immutable donationToken;
    uint256 public currentEpoch;
    uint256 public constant EPOCH_DURATION = 30 days;
    uint256 public epochStartTime;

    mapping(uint256 => uint256) public epochDeposits;
    mapping(uint256 => bool) public epochFinalized;
    mapping(address => mapping(uint256 => uint256)) public userDeposits;

    event EpochStarted(uint256 indexed epoch, uint256 startTime);
    event Locked(address indexed user, uint256 amount, uint256 indexed epoch);
    event EpochFinalized(uint256 indexed epoch, uint256 totalDeposits);

    constructor(address _donationToken) {
        donationToken = IERC20(_donationToken);
        currentEpoch = 0;
        epochStartTime = block.timestamp;
        emit EpochStarted(currentEpoch, epochStartTime);
    }

    /**
     * @notice Lock funds for current epoch
     * @param amount Amount to lock
     */
    function lock(uint256 amount) external payable {
        require(amount > 0, "Amount must be > 0");

        // Transfer tokens from sender
        donationToken.safeTransferFrom(msg.sender, address(this), amount);

        // Record deposit
        epochDeposits[currentEpoch] += amount;
        userDeposits[msg.sender][currentEpoch] += amount;

        emit Locked(msg.sender, amount, currentEpoch);

        // Auto-advance epoch if duration passed
        if (block.timestamp >= epochStartTime + EPOCH_DURATION) {
            _finalizeEpoch();
            _startNewEpoch();
        }
    }

    /**
     * @notice Get current epoch number
     * @return Current epoch
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Check if epoch is finalized
     * @param epoch Epoch number
     * @return Whether epoch is finalized
     */
    function isEpochFinalized(uint256 epoch) external view returns (bool) {
        return epochFinalized[epoch];
    }

    /**
     * @notice Manually finalize current epoch (for testing)
     */
    function finalizeEpoch() external {
        _finalizeEpoch();
        _startNewEpoch();
    }

    /**
     * @notice Manually advance to next epoch (for testing)
     * @dev Alias for finalizeEpoch() with clearer naming
     */
    function advanceEpoch() external {
        _finalizeEpoch();
        _startNewEpoch();
    }

    /**
     * @notice Internal function to finalize epoch
     */
    function _finalizeEpoch() internal {
        epochFinalized[currentEpoch] = true;
        emit EpochFinalized(currentEpoch, epochDeposits[currentEpoch]);
    }

    /**
     * @notice Internal function to start new epoch
     */
    function _startNewEpoch() internal {
        currentEpoch++;
        epochStartTime = block.timestamp;
        emit EpochStarted(currentEpoch, epochStartTime);
    }

    /**
     * @notice Get total deposits for an epoch
     * @param epoch Epoch number
     * @return Total deposits
     */
    function getEpochDeposits(uint256 epoch) external view returns (uint256) {
        return epochDeposits[epoch];
    }

    /**
     * @notice Get user deposits for an epoch
     * @param user User address
     * @param epoch Epoch number
     * @return User's deposits
     */
    function getUserEpochDeposits(address user, uint256 epoch) external view returns (uint256) {
        return userDeposits[user][epoch];
    }
}
