// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

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

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function execute(address target, bytes memory data) public payable onlyOwner returns (bytes memory) {
        if (target == address(0)) revert InvalidTarget();
        if (msg.value == 0 && data.length == 0) revert NoTransactionData();

        (bool success, bytes memory result) = target.call{value: msg.value}(data);
        if (!success) revert ExecutionFailed(0);

        emit Executed(target, data, result);
        return result;
    }

    function bundleExecute(address[] memory targets, bytes[] memory data) public payable onlyOwner {
        if (targets.length != data.length) revert MismatchedArrays();
        

        uint256 remainingBalance = address(this).balance;

        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] == address(0)) revert InvalidTarget();

            uint256 callValue = i == targets.length - 1 ? remainingBalance : 0;
            (bool success,) = targets[i].call{value: callValue}(data[i]);
            if (!success) revert ExecutionFailed(i);
        }

        emit BundleExecuted(targets, data);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    function withdrawETH(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
    }

    function withdrawERC20(address token, uint256 amount, address to) public onlyOwner {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(address(this)) >= amount, "Insufficient token balance");
        require(erc20.transfer(to, amount), "Token transfer failed");
    }
}
