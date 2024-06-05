// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {FlashBotsMultiCall} from "../src/BundleExecutor-yulsol.sol";
import {BaseTest} from "./shared.sol";
import {BytecodeDeployer} from "./BytecodeDeployer.sol";

contract ExecutorBeforeTest is BaseTest {
    BytecodeDeployer bytecodeDeployer = new BytecodeDeployer();

    function test_uniswapWeth() public {
        vm.prank(me);
        FlashBotsMultiCall executorTemplate = new FlashBotsMultiCall(me);
        bytes memory executorCode = address(executorTemplate).code;
        address executorAddr = address(
            0x000000000000000002D4Bc56F957B3710216aB00
        );
        vm.etch(executorAddr, executorCode);
        FlashBotsMultiCall executor = FlashBotsMultiCall(
            payable(address(0x000000000000000002D4Bc56F957B3710216aB00))
        );

        deal(address(weth), address(executor), 0.1 ether);

        uint8 _amountOut1IndexArg = 0;
        uint8 _amountOut2IndexArg = 1;

        bytes memory swapData = abi.encodePacked(
            uint64(wethAmountIn),
            uint64(0.1 ether),
            uint64(130000000000000), // estimated gas cost
            address(uniPool),
            address(sushiPool),
            uint192(daiAmountOut),
            _amountOut1IndexArg,
            uint192(wethAmountOut),
            _amountOut2IndexArg
        );

        console.logBytes(swapData);

        vm.prank(me);
        (bool success, ) = address(executor).call(swapData);
        require(success, "Call failed");

        uint256 wethBalanceAfter = weth.balanceOf(address(executor));
        console.log("wethBalanceAfter");
        console.log(wethBalanceAfter);
        uint256 wethProfit = wethBalanceAfter - wethAmountIn;
        console.log("wethProfit");
        console.log(wethProfit);
    }
}
