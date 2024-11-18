// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title Executor
 * @notice Smart contract for executing arbitrary calls with access control
 * @dev Implements ownership, reentrancy protection, and asset management
 * @custom:security-contact security@example.com
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

    /**
     * @dev Prevents reentrancy attacks
     */
    modifier nonReentrant() {
        if (locked) revert ReentrancyGuard();
        locked = true;
        _;
        locked = false;
    }

    /**
     * @dev Restricts function access to contract owner
     */
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /**
     * @dev Sets the contract owner
     * @param _owner Address of the contract owner
     */
    constructor(address _owner) {
        if (_owner == address(0)) revert ZeroAddress();
        owner = _owner;
    }

    /**
     * @notice Executes a single transaction with optional ETH value
     * @dev Reverts if target is zero address or if call fails
     * @param target Address of contract to call
     * @param data Function call data
     * @return result The raw bytes returned from the call
     */
    function execute(address target, bytes memory data)
        public
        payable
        onlyOwner
        nonReentrant
        returns (bytes memory result)
    {
        if (target == address(0)) revert InvalidTarget();
        if (msg.value == 0 && data.length == 0) revert NoTransactionData();

        bool success;
        (success, result) = target.call{value: msg.value}(data);
        if (!success) revert ExecutionFailed(0);

        emit Executed(target, data, result);
    }

    /**
     * @notice Executes multiple transactions in sequence
     * @dev Reverts if array lengths mismatch or any call fails
     * @param targets Array of contract addresses to call
     * @param data Array of call data for each target
     * @param values Array of ETH values for each call
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
     * @notice Withdraws ETH from contract
     * @dev Reverts if insufficient balance
     * @param amount Amount of ETH in wei
     * @param to Recipient address
     */
    function withdrawETH(uint256 amount, address payable to) public onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
    }

    /**
     * @notice Withdraws ERC20 tokens from contract
     * @dev Reverts if insufficient balance
     * @param token ERC20 token contract address
     * @param amount Token amount in smallest unit
     * @param to Recipient address
     */
    function withdrawERC20(address token, uint256 amount, address to) public onlyOwner nonReentrant {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(address(this)) >= amount, "Insufficient token balance");
        require(erc20.transfer(to, amount), "Token transfer failed");
    }

    /**
     * @notice Gets contract owner address
     * @return Address of contract owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }

    /**
     * @notice Gets contract's ETH balance
     * @return Balance in wei
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
