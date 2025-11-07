// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IOctantDeposits
 * @notice Interface for Octant v2 Deposits contract
 * @dev This interface allows protocols to donate to public goods via Octant
 */
interface IOctantDeposits {
    /**
     * @notice Lock funds for current epoch to be allocated to public goods
     * @param amount Amount of GLM or ETH to lock
     */
    function lock(uint256 amount) external payable;

    /**
     * @notice Get current epoch number
     * @return Current epoch number
     */
    function getCurrentEpoch() external view returns (uint256);

    /**
     * @notice Check if an epoch is finalized
     * @param epoch Epoch number to check
     * @return Whether the epoch is finalized
     */
    function isEpochFinalized(uint256 epoch) external view returns (bool);
}
