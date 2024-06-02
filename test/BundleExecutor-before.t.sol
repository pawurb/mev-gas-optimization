// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FlashBotsMultiCall} from "../src/BundleExecutor-before.sol";
import {IUniV2Pair, IERC20} from "./shared.sol";

contract ExecutorTest is Test {
    address constant me = address(1);
    IUniV2Pair uniPool = IUniV2Pair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);
    IUniV2Pair sushiPool =
        IUniV2Pair(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f);
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    FlashBotsMultiCall public executor;

    function setUp() public {
        executor = new FlashBotsMultiCall(me);
        uint256 wethAmountIn = 0.1 ether;
        (uint112 uniDaiReserve, uint112 uniWethReserve, ) = uniPool
            .getReserves();
        (uint112 sushiDaiReserve, uint112 sushiWethReserve, ) = sushiPool
            .getReserves();

        uint256 daiAmountOut = getAmountOut(
            wethAmountIn,
            sushiWethReserve,
            sushiDaiReserve
        );

        uint256 wethAmountOut = getAmountOut(
            daiAmountOut,
            uniDaiReserve,
            uniWethReserve
        );

        console.log(daiAmountOut);
        console.log(wethAmountOut);
    }

    function test_uniswapWeth() public {
        console.log("dupa1");
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
        return amountOut;
    }
}
