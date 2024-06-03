// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {FlashBotsMultiCall} from "../src/BundleExecutor-before.sol";
import {IUniV2Pair, IERC20} from "./shared.sol";

// ETH PRICE $3800.0
contract ExecutorTest is Test {
    address constant me = address(1);
    IUniV2Pair uniPool = IUniV2Pair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);
    IUniV2Pair sushiPool =
        IUniV2Pair(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f);
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    FlashBotsMultiCall public executor;

    function setUp() public {
        vm.prank(me);
        executor = new FlashBotsMultiCall(me);

        vm.store(
            address(uniPool),
            bytes32(uint256(8)), // getReserves slot
            0x665c6fc30000000000726da71f957be90350000000069edd451a8cac85b3f053
        );

        vm.store(
            address(sushiPool),
            bytes32(uint256(8)), // getReserves slot
            0x665c6fcf00000000004d4a487a40a07d962e0000000461F5535113259E306380
        );

        vm.deal(me, 0.1 ether);
        deal(address(weth), address(uniPool), 2110830143201023165264);
        deal(address(dai), address(uniPool), 8003770531868479419838547);
        deal(address(weth), address(sushiPool), 1425751956250754389550);
        deal(address(dai), address(sushiPool), 5298298283195761674969984);
        deal(address(weth), address(executor), 0.1 ether);
    }

    function test_uniswapWeth() public {
        uint256 wethAmountIn = 0.1 ether;
        (uint112 uniDaiReserve, uint112 uniWethReserve, ) = uniPool
            .getReserves();
        (uint112 sushiDaiReserve, uint112 sushiWethReserve, ) = sushiPool
            .getReserves();

        uint256 daiAmountOut = getAmountOut(
            wethAmountIn,
            uniWethReserve,
            uniDaiReserve
        );

        uint256 wethAmountOut = getAmountOut(
            daiAmountOut,
            sushiDaiReserve,
            sushiWethReserve
        );

        uint256 uniWethBalance = weth.balanceOf(address(uniPool));
        uint256 uniDaiBalance = dai.balanceOf(address(uniPool));
        uint256 sushiWethBalance = weth.balanceOf(address(sushiPool));
        uint256 sushiDaiBalance = dai.balanceOf(address(sushiPool));
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
