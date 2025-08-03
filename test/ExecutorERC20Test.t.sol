// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseExecutorTest.t.sol";

contract ExecutorERC20Test is BaseExecutorTest {
    function testWithdrawERC20() public {
        uint256 amount = 1000;

        // Fund the executor with tokens
        token.mint(address(executor), amount);
        assertEq(token.balanceOf(address(executor)), amount);

        // Test withdrawal
        vm.prank(OWNER);
        executor.withdrawERC20(address(token), amount, ALICE);

        assertEq(token.balanceOf(address(executor)), 0);
        assertEq(token.balanceOf(ALICE), amount);
    }

    function testCannotWithdrawERC20AsNonOwner() public {
        uint256 amount = 1000;
        token.mint(address(executor), amount);

        vm.prank(ALICE);
        vm.expectRevert(Executor.NotOwner.selector);
        executor.withdrawERC20(address(token), amount, ALICE);
    }

    function testCannotWithdrawMoreERC20ThanBalance() public {
        uint256 amount = 1000;
        token.mint(address(executor), amount);

        vm.prank(OWNER);
        vm.expectRevert("Insufficient token balance");
        executor.withdrawERC20(address(token), amount + 1, ALICE);
    }

    function testRevertOnFailedERC20Transfer() public {
        uint256 amount = 1000;

        // Fund the executor
        token.mint(address(executor), amount);

        // Make transfers fail
        token.setTransferShouldFail(true);

        // Test withdrawal
        vm.prank(OWNER);
        vm.expectRevert(Executor.ERC20TransferFailed.selector);
        executor.withdrawERC20(address(token), amount, ALICE);

        // Verify balances didn't change
        assertEq(token.balanceOf(address(executor)), amount);
        assertEq(token.balanceOf(ALICE), 0);
    }
}
