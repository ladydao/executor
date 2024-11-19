// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Executor.sol";

contract Target {
    uint256 public number;

    function setNumber(uint256 _number) external {
        number = _number;
    }

    function receiveEther() external payable {}
}

contract MockERC20 {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }
}

contract FailingTarget {
    function alwaysRevert() external pure {
        revert("Custom revert message");
    }
}

contract BaseExecutorTest is Test {
    Executor public executor;
    Target public target1;
    Target public target2;
    MockERC20 public token;

    address constant ALICE = address(0x1);
    address constant BOB = address(0x2);
    address constant OWNER = address(0xabc);
    uint256 constant INITIAL_BALANCE = 100 ether;

    event Executed(address indexed target, bytes data, bytes result);
    event BundleExecuted(address[] indexed targets, bytes[] data);

    function setUp() public virtual {
        executor = new Executor(OWNER);
        target1 = new Target();
        target2 = new Target();
        token = new MockERC20();

        // Fund test addresses
        vm.deal(ALICE, INITIAL_BALANCE);
        vm.deal(BOB, INITIAL_BALANCE);
        vm.deal(address(this), INITIAL_BALANCE);
        vm.deal(OWNER, INITIAL_BALANCE);
    }
}
