// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseExecutorTest.t.sol";

contract ExecutorOwnerTest is BaseExecutorTest {
    function testCorrectOwnerAtDeployment() public view {
        assertEq(executor.owner(), OWNER);
    }

    function testGetOwnerMatchesOwner() public view {
        assertEq(executor.getOwner(), executor.owner());
    }

    function testCannotDeployWithZeroAddress() public {
        vm.expectRevert();
        new Executor(address(0));
    }
}
