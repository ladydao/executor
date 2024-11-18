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
    bool private locked;

    event Executed(address indexed target, bytes data, bytes result);
    event BundleExecuted(address[] indexed targets, bytes[] data);

    error NotOwner();
    error InvalidTarget();
    error ExecutionFailed(uint256 index);
    error MismatchedArrays();
    error NoTransactionData();
    error NoTargets();
    error IncorectEthValue();
    error ZeroAddress();
    error ReentrancyGuard();

    modifier nonReentrant() {
        if (locked) revert ReentrancyGuard();
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address _owner) {
        if (_owner == address(0)) revert ZeroAddress();
        owner = _owner;
    }

    /**
     * @notice Executes a single transaction
     * @param target The address of the contract to call
     * @param data The calldata to send
     * @return The returned data from the call
     * @dev Can include ETH value in the call
     */
    function execute(address target, bytes memory data) public payable onlyOwner nonReentrant returns (bytes memory) {
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
    function bundleExecute(address[] memory targets, bytes[] memory data, uint256[] memory values)
        public
        payable
        onlyOwner
        nonReentrant
    {
        if (targets.length != data.length || data.length != values.length) revert MismatchedArrays();
        if (targets.length == 0) revert NoTargets();

        uint256 totalValue = 0;
        for (uint256 i = 0; i < values.length; i++) {
            totalValue += values[i];
        }
        if (totalValue != msg.value) revert IncorectEthValue();

        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] == address(0)) revert InvalidTarget();
            (bool success,) = targets[i].call{value: values[i]}(data[i]);
            if (!success) revert ExecutionFailed(i);
        }

        emit BundleExecuted(targets, data);
    }

    /**
     * @notice Withdraws ETH from the contract
     * @param amount The amount of ETH to withdraw in wei
     * @param to The recipient address
     */
    function withdrawETH(uint256 amount, address payable to) public onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
    }

    /**
     * @notice Withdraws ERC20 tokens from the contract
     * @param token The token contract address
     * @param amount The amount of tokens to withdraw
     * @param to The recipient address
     */
    function withdrawERC20(address token, uint256 amount, address to) public onlyOwner nonReentrant {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(address(this)) >= amount, "Insufficient token balance");
        require(erc20.transfer(to, amount), "Token transfer failed");
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
