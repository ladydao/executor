// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseExecutorTest.t.sol";

contract ExecutorBundleTest is BaseExecutorTest {
    function testBundleExecute() public {
        Target secondTarget = new Target();

        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(target);
        targets[1] = address(secondTarget);
        data[0] = abi.encodeWithSelector(target.setNumber.selector, 42);
        data[1] = abi.encodeWithSelector(Target.setNumber.selector, 99);
        values[0] = 0;
        values[1] = 0;

        vm.prank(OWNER);
        executor.bundleExecute(targets, data, values);

        assertEq(target.number(), 42);
        assertEq(secondTarget.number(), 99);
    }

    function testBundleExecuteWithEther() public {
        Target secondTarget = new Target();
        uint256 amount1 = 0.5 ether;
        uint256 amount2 = 0.5 ether;

        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(target);
        targets[1] = address(secondTarget);
        data[0] = abi.encodeWithSelector(target.receiveEther.selector);
        data[1] = abi.encodeWithSelector(Target.receiveEther.selector);
        values[0] = amount1;
        values[1] = amount2;

        vm.prank(OWNER);
        vm.deal(OWNER, amount1 + amount2);
        executor.bundleExecute{value: amount1 + amount2}(targets, data, values);

        assertEq(address(target).balance, amount1);
        assertEq(address(secondTarget).balance, amount2);
    }

    function testBundleExecuteEmitsEvent() public {
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(target);
        targets[1] = address(target);
        data[0] = abi.encodeWithSelector(target.setNumber.selector, 42);
        data[1] = abi.encodeWithSelector(target.setNumber.selector, 43);
        values[0] = 0;
        values[1] = 0;

        vm.prank(OWNER);
        vm.expectEmit(true, false, false, true);
        emit BundleExecuted(targets, data);
        executor.bundleExecute(targets, data, values);
    }

    function testCannotBundleExecuteWithMismatchedArrays() public {
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](1);
        uint256[] memory values = new uint256[](2);

        vm.prank(OWNER);
        vm.expectRevert(Executor.MismatchedArrays.selector);
        executor.bundleExecute(targets, data, values);
    }

    function testCannotBundleExecuteWithEmptyArrays() public {
        address[] memory targets = new address[](0);
        bytes[] memory data = new bytes[](0);
        uint256[] memory values = new uint256[](0);

        vm.prank(OWNER);
        vm.expectRevert(Executor.NoTargets.selector);
        executor.bundleExecute(targets, data, values);
    }

    function testBundleExecuteGas() public {
        Target secondTarget = new Target();

        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(target);
        targets[1] = address(secondTarget);
        data[0] = abi.encodeWithSelector(target.setNumber.selector, 42);
        data[1] = abi.encodeWithSelector(Target.setNumber.selector, 99);
        values[0] = 0;
        values[1] = 0;

        uint256 gasBefore = gasleft();
        vm.prank(OWNER);
        executor.bundleExecute(targets, data, values);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Bundle Execute Gas Used", gasUsed);
    }

    function testCannotBundleExecuteWithIncorrectTotalValue() public {
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(target);
        targets[1] = address(target);
        data[0] = abi.encodeWithSelector(target.receiveEther.selector);
        data[1] = abi.encodeWithSelector(target.receiveEther.selector);
        values[0] = 0.5 ether;
        values[1] = 0.5 ether;

        vm.prank(OWNER);
        vm.deal(OWNER, 0.5 ether);
        vm.expectRevert(Executor.IncorectEthValue.selector);
        executor.bundleExecute{value: 0.5 ether}(targets, data, values);
    }
}
