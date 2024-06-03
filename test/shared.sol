//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IUniV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract BaseTest is Test {
    address me = address(1);
    IUniV2Pair uniPool = IUniV2Pair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);
    IUniV2Pair sushiPool =
        IUniV2Pair(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f);
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    uint256 constant wethAmountIn = 0.1 ether;
    uint256 daiAmountOut = 0;
    uint256 wethAmountOut = 0;

    function setUp() public {
        vm.store(
            address(uniPool),
            bytes32(uint256(8)), // getReserves slot
            0x665c6fc30000000000726da71f957be90350000000069edd451a8cac85b3f053
        );

        vm.store(
            address(sushiPool),
            bytes32(uint256(8)), // getReserves slot
            0x665c6fcf00000000004d4a487a40a07d962e0000000453229E2B8F0ABE706380
        );

        deal(address(weth), address(uniPool), 2110830143201023165264);
        deal(address(dai), address(uniPool), 8003770531868479419838547);
        deal(address(weth), address(sushiPool), 1425751956250754389550);
        deal(address(dai), address(sushiPool), 5228298283195761674969984);

        console.log("wethAmountIn");
        console.log(wethAmountIn);

        (uint112 uniDaiReserve, uint112 uniWethReserve, ) = uniPool
            .getReserves();
        (uint112 sushiDaiReserve, uint112 sushiWethReserve, ) = sushiPool
            .getReserves();

        daiAmountOut = UniswapHelper.getAmountOut(
            wethAmountIn,
            uniWethReserve,
            uniDaiReserve
        );

        wethAmountOut = UniswapHelper.getAmountOut(
            daiAmountOut,
            sushiDaiReserve,
            sushiWethReserve
        );
        console.log("wethAmountOut");
        console.log(wethAmountOut);
    }
}

library UniswapHelper {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
        return amountOut;
    }
}
