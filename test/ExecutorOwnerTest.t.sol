// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseExecutorTest.t.sol";

contract ExecutorOwnerTest is BaseExecutorTest {
    function testCorrectOwnerAtDeployment() public view {
        assertEq(executor.owner(), OWNER);
        assertTrue(executor.isOwner(OWNER));
        assertFalse(executor.isOwner(ALICE));
    }

    function testNonOwnerChecks() public view {
        // Test with zero address
        assertFalse(executor.isOwner(address(0)));

        // Test with random addresses
        assertFalse(executor.isOwner(address(0xdead)));
        assertFalse(executor.isOwner(address(0xbeef)));

        // Test with contract addresses
        assertFalse(executor.isOwner(address(target)));
        assertFalse(executor.isOwner(address(token)));
        assertFalse(executor.isOwner(address(executor)));
    }
}
