// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseExecutorTest.t.sol";

contract ExecutorBalanceTest is BaseExecutorTest {
    function testGetBalance() public {
        assertEq(executor.getBalance(), 0);
        uint256 amount = 1 ether;
        (bool success, ) = address(executor).call{value: amount}("");
        require(success, "Transfer failed");
        assertEq(executor.getBalance(), amount);
    }

    function testWithdrawETH() public {
        uint256 amount = 1 ether;

        // First fund the executor
        vm.deal(address(executor), amount);
        assertEq(address(executor).balance, amount);

        // Test withdrawal
        vm.prank(OWNER);
        executor.withdrawETH(amount, payable(OWNER));

        assertEq(address(executor).balance, 0);
        assertEq(OWNER.balance, INITIAL_BALANCE + amount);
    }

    function testCannotWithdrawETHAsNonOwner() public {
        uint256 amount = 1 ether;
        vm.deal(address(executor), amount);

        vm.prank(ALICE);
        vm.expectRevert(Executor.NotOwner.selector);
        executor.withdrawETH(amount, payable(ALICE));
    }

    function testCannotWithdrawMoreThanBalance() public {
        uint256 amount = 1 ether;
        vm.deal(address(executor), amount);

        vm.prank(OWNER);
        vm.expectRevert("Insufficient balance");
        executor.withdrawETH(amount + 1, payable(ALICE));
    }
}
