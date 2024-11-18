// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseExecutorTest.t.sol";

contract ExecutorBundleTest is BaseExecutorTest {
    function testBundleExecute() public {
        Target secondTarget = new Target();

        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);

        targets[0] = address(target);
        targets[1] = address(secondTarget);
        data[0] = abi.encodeWithSelector(target.setNumber.selector, 42);
        data[1] = abi.encodeWithSelector(Target.setNumber.selector, 99);

        vm.prank(OWNER);
        executor.bundleExecute(targets, data);

        assertEq(target.number(), 42);
        assertEq(secondTarget.number(), 99);
    }

    function testBundleExecuteWithEther() public {
        Target secondTarget = new Target();
        uint256 amount = 1 ether;

        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);

        targets[0] = address(target);
        targets[1] = address(secondTarget);
        data[0] = abi.encodeWithSelector(target.receiveEther.selector);
        data[1] = abi.encodeWithSelector(Target.receiveEther.selector);

        vm.prank(OWNER);
        vm.deal(OWNER, amount);
        executor.bundleExecute{value: amount}(targets, data);

        // In the current implementation, all ETH goes to the last call
        assertEq(address(target).balance, 0);
        assertEq(address(secondTarget).balance, amount);
    }

    function testCannotBundleExecuteWithMismatchedArrays() public {
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](1);

        vm.prank(OWNER);
        vm.expectRevert(Executor.MismatchedArrays.selector);
        executor.bundleExecute(targets, data);
    }

    function testCannotBundleExecuteWithEmptyArrays() public {
        address[] memory targets = new address[](0);
        bytes[] memory data = new bytes[](0);

        vm.prank(OWNER);
        vm.expectRevert(Executor.NoTargets.selector);
        executor.bundleExecute(targets, data);
    }

    function testBundleExecuteGas() public {
        Target secondTarget = new Target();

        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);

        targets[0] = address(target);
        targets[1] = address(secondTarget);
        data[0] = abi.encodeWithSelector(target.setNumber.selector, 42);
        data[1] = abi.encodeWithSelector(Target.setNumber.selector, 99);

        uint256 gasBefore = gasleft();
        vm.prank(OWNER);
        executor.bundleExecute(targets, data);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Bundle Execute Gas Used", gasUsed);
    }

    function testBundleExecuteEmitsEvent() public {
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);

        targets[0] = address(target);
        targets[1] = address(target);
        data[0] = abi.encodeWithSelector(target.setNumber.selector, 42);
        data[1] = abi.encodeWithSelector(target.setNumber.selector, 43);

        vm.prank(OWNER);
        vm.expectEmit(true, false, false, true);
        emit BundleExecuted(targets, data);
        executor.bundleExecute(targets, data);
    }
}
