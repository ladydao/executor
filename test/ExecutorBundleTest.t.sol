// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseExecutorTest.t.sol";

contract ExecutorBundleTest is BaseExecutorTest {
    function testBundleExecute() public {
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(target1);
        targets[1] = address(target2);
        data[0] = abi.encodeWithSelector(target1.setNumber.selector, 42);
        data[1] = abi.encodeWithSelector(target2.setNumber.selector, 99);
        values[0] = 0;
        values[1] = 0;

        vm.prank(OWNER);
        executor.bundleExecute(targets, data, values);

        assertEq(target1.number(), 42);
        assertEq(target2.number(), 99);
    }

    function testBundleExecuteWithEther() public {
        uint256 amount1 = 0.5 ether;
        uint256 amount2 = 0.5 ether;

        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(target1);
        targets[1] = address(target2);
        data[0] = abi.encodeWithSelector(target1.receiveEther.selector);
        data[1] = abi.encodeWithSelector(target2.receiveEther.selector);
        values[0] = amount1;
        values[1] = amount2;

        vm.prank(OWNER);
        vm.deal(OWNER, amount1 + amount2);
        executor.bundleExecute{value: amount1 + amount2}(targets, data, values);

        assertEq(address(target1).balance, amount1);
        assertEq(address(target2).balance, amount2);
    }

    function testBundleExecuteEmitsEvent() public {
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(target1);
        targets[1] = address(target1);
        data[0] = abi.encodeWithSelector(target1.setNumber.selector, 42);
        data[1] = abi.encodeWithSelector(target1.setNumber.selector, 43);
        values[0] = 0;
        values[1] = 0;

        vm.prank(OWNER);
        vm.expectEmit(true, false, false, true);
        bool[] memory expectedResults = new bool[](2);
        expectedResults[0] = true;
        expectedResults[1] = true;
        emit BundleExecuted(targets, data, expectedResults);
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
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(target1);
        targets[1] = address(target2);
        data[0] = abi.encodeWithSelector(target1.setNumber.selector, 42);
        data[1] = abi.encodeWithSelector(target2.setNumber.selector, 99);
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

        targets[0] = address(target1);
        targets[1] = address(target1);
        data[0] = abi.encodeWithSelector(target1.receiveEther.selector);
        data[1] = abi.encodeWithSelector(target1.receiveEther.selector);
        values[0] = 0.5 ether;
        values[1] = 0.5 ether;

        vm.prank(OWNER);
        vm.deal(OWNER, 0.5 ether);
        vm.expectRevert(Executor.IncorectEthValue.selector);
        executor.bundleExecute{value: 0.5 ether}(targets, data, values);
    }

    function testBundleExecuteWithZeroValues() public {
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(target1);
        targets[1] = address(target2);
        data[0] = "";
        data[1] = "";
        values[0] = 0;
        values[1] = 0;

        vm.prank(OWNER);
        executor.bundleExecute(targets, data, values);
    }

    function testBundleExecuteWithSingleCall() public {
        address[] memory targets = new address[](1);
        bytes[] memory data = new bytes[](1);
        uint256[] memory values = new uint256[](1);

        targets[0] = address(target1);
        data[0] = abi.encodeWithSelector(target1.setNumber.selector, 42);
        values[0] = 0;

        vm.prank(OWNER);
        executor.bundleExecute(targets, data, values);
        assertEq(target1.number(), 42);
    }
}
