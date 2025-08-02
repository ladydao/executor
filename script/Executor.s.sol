// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Executor} from "../src/Executor.sol";

contract ExecutorScript is Script {
    Executor public executor;
    address public devAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        executor = new Executor(devAddress);

        vm.stopBroadcast();
    }
}
