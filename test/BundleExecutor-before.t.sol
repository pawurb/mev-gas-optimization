// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {FlashBotsMultiCall} from "../src/BundleExecutor-before.sol";
import {BaseTest} from "./shared.sol";

contract ExecutorBeforeTest is BaseTest {
    function test_uniswapWeth() public {
        vm.prank(me);
        FlashBotsMultiCall executor = new FlashBotsMultiCall(me);

        deal(address(weth), address(executor), 0.1 ether);

        bytes memory payload1 = abi.encodeWithSignature(
            "swap(uint256,uint256,address,bytes)",
            daiAmountOut,
            0,
            address(sushiPool),
            ""
        );

        bytes memory payload2 = abi.encodeWithSignature(
            "swap(uint256,uint256,address,bytes)",
            0,
            wethAmountOut,
            address(executor),
            ""
        );

        address[] memory targets = new address[](2);
        targets[0] = address(uniPool);
        targets[1] = address(sushiPool);

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = payload1;
        payloads[1] = payload2;

        vm.prank(me);
        executor.uniswapWeth(wethAmountIn, 100000000000000, targets, payloads);

        uint256 wethBalanceAfter = weth.balanceOf(address(executor));
        console.log("wethBalanceAfter");
        console.log(wethBalanceAfter);
        uint256 wethProfit = wethBalanceAfter - wethAmountIn;
        console.log("wethProfit");
        console.log(wethProfit);
    }
}
