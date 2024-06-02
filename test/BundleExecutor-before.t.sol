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
    IERC20 weth = IERC20(0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2);
    IERC20 dai = IERC20(0x6b175474e89094c44da98b954eedeac495271d0f);
    FlashBotsMultiCall public executor;

    function setUp() public {
        executor = new FlashBotsMultiCall(me);
    }

    function test_uniswapWeth() public {}

    function getAmountOut(
        address pool,
        uint256 amountIn
    ) internal view returns (uint256) {
        return 0;
    }
}
