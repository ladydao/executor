// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title Executor Contract
 * @notice Enables secure execution of arbitrary contract calls by an authorized owner
 * @dev Implements a simple ownership model with ETH and ERC20 management capabilities
 */
contract Executor {
    address public immutable owner;

    event Executed(address indexed target, bytes data, bytes result);
    event BundleExecuted(address[] indexed targets, bytes[] data);

    error NotOwner();
    error InvalidTarget();
    error ExecutionFailed(uint256 index);
    error MismatchedArrays();
    error NoTransactionData();
    error NoTargets();

    /**
     * @notice Initializes the contract with an owner address
     * @param _owner The address that will have execution privileges
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @notice Restricts function access to the contract owner
     */
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /**
     * @notice Executes a single transaction
     * @param target The address of the contract to call
     * @param data The calldata to send
     * @return The returned data from the call
     * @dev Can include ETH value in the call
     */
    function execute(address target, bytes memory data) public payable onlyOwner returns (bytes memory) {
        if (target == address(0)) revert InvalidTarget();
        if (msg.value == 0 && data.length == 0) revert NoTransactionData();

        (bool success, bytes memory result) = target.call{value: msg.value}(data);
        if (!success) revert ExecutionFailed(0);

        emit Executed(target, data, result);
        return result;
    }

    /**
     * @notice Executes multiple transactions in sequence
     * @param targets Array of contract addresses to call
     * @param data Array of calldata for each target
     * @dev Any attached ETH value is sent to the last target in the sequence
     */
    function bundleExecute(address[] memory targets, bytes[] memory data) public payable onlyOwner {
        if (targets.length != data.length) revert MismatchedArrays();
        if (targets.length == 0) revert NoTargets();

        uint256 remainingBalance = address(this).balance;

        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] == address(0)) revert InvalidTarget();

            uint256 callValue = i == targets.length - 1 ? remainingBalance : 0;
            (bool success,) = targets[i].call{value: callValue}(data[i]);
            if (!success) revert ExecutionFailed(i);
        }

        emit BundleExecuted(targets, data);
    }

    /**
     * @notice Checks if an address is the contract owner
     * @param account The address to check
     * @return bool True if the account is the owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * @notice Returns the contract's ETH balance
     * @return uint256 The balance in wei
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Allows the contract to receive ETH
     */
    receive() external payable {}

    /**
     * @notice Withdraws ETH from the contract
     * @param amount The amount of ETH to withdraw in wei
     * @param to The recipient address
     */
    function withdrawETH(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
    }

    /**
     * @notice Withdraws ERC20 tokens from the contract
     * @param token The token contract address
     * @param amount The amount of tokens to withdraw
     * @param to The recipient address
     */
    function withdrawERC20(address token, uint256 amount, address to) public onlyOwner {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(address(this)) >= amount, "Insufficient token balance");
        require(erc20.transfer(to, amount), "Token transfer failed");
    }
}
