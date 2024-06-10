// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./shared.sol";

contract FlashBotsMultiCall {
    address private immutable owner;
    address private immutable executor;
    IWETH private constant WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _executor) payable {
        owner = msg.sender;
        executor = _executor;
        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
        }
    }

    receive() external payable {}

    // _wethAmountToFirstMarket: uint64
    // _wethBalanceBefore: uint64
    // _gasCost: uint64
    // _target1: address
    // _target2: address
    // _token0_amountOut: u128
    // _token0_amountOutIndex: u16
    // _token1_amountOut: u128
    // _token1_amountOutIndex: u16
    fallback() external payable onlyExecutor {
        assembly {
            // transfer weth to first market
            mstore(
                0x0,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(0x04, shr(0x60, calldataload(0x18))) // _target1
            mstore(0x24, shr(0xc0, calldataload(0x0))) // _wethAmountToFirstMarket
            pop(
                call(
                    gas(),
                    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                    0x0,
                    0x0,
                    0x44,
                    0x0,
                    0x20
                )
            )

            // swap1
            mstore(
                0x0,
                0x022c0d9f00000000000000000000000000000000000000000000000000000000
            )
            let amoutOut1Index := shr(0xF0, calldataload(0x50)) // arg7
            let amountOut1 := shr(0x80, calldataload(0x40)) // arg6

            switch amoutOut1Index
            case 0x0 {
                mstore(0x04, amountOut1)
                mstore(0x24, 0x0)
            }
            default {
                mstore(0x04, 0x0)
                mstore(0x24, amountOut1)
            }

            mstore(0x44, shr(0x60, calldataload(0x2c))) // arg5 target2
            mstore(
                0x64,
                0x0000000000000000000000000000000000000000000000000000000000000080
            ) // empty bytes
            pop(
                call(
                    gas(),
                    shr(0x60, calldataload(0x18)),
                    0x0,
                    0x0,
                    0xa4,
                    0x0,
                    0x0
                )
            )

            // swap2
            // skip storing swap sig it's still there
            let amoutOut2Index := shr(0xF0, calldataload(0x62)) // arg9
            let amountOut2 := shr(0x80, calldataload(0x52)) // arg8

            switch amoutOut2Index
            case 0x0 {
                mstore(0x04, amountOut2)
                mstore(0x24, 0x0)
            }
            default {
                mstore(0x04, 0x0)
                mstore(0x24, amountOut2)
            }

            mstore(0x44, address())
            // skip storing empty _data, it's still there
            pop(
                call(
                    gas(),
                    shr(0x60, calldataload(0x2c)),
                    0x0,
                    0x0,
                    0xa4,
                    0x0,
                    0x0
                )
            )

            // check profit
            mstore(
                0x0,
                0x70a0823100000000000000000000000000000000000000000000000000000000
            ) // balanceOf Sig
            mstore(0x04, address())
            pop(
                call(
                    gas(),
                    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                    0x0,
                    0x0,
                    0x24,
                    0x0,
                    0x20
                )
            ) // get current balance
            let balanceBefore := shr(0xc0, calldataload(0x08))
            let currentBalance := mload(0x0)
            let wethProfit := sub(currentBalance, balanceBefore)
            let gasCost := shr(0xc0, calldataload(0x10))

            if lt(wethProfit, gasCost) {
                mstore(0x0, 0x03)
                revert(0x0, 0x20)
            }

            stop()
        }
    }

    function c() public {}

    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}
