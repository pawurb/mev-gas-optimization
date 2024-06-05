// SPDX-License-Identifier: MIT

object "Token" {
    code {
        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            let isOwner := eq(0x0000000000000000000000000000000000000001, caller()) // only owner
            if iszero(isOwner) {
                revert(0x0, 0x0)
            }

            switch callvalue() 
            case 0x1 { //efdin
                // weth to first markket
                mstore(0x0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) 
                mstore(0x04, shr(0x60, calldataload(0x18))) // arg4 target1
                mstore(0x24, shr(0xc0, calldataload(0x0))) // arg1 _wethAmountToFirstMarket
                pop(call(gas(), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x0, 0x0, 0x44, 0x0, 0x20))

                // swap1 
                mstore(0x0, 0x022c0d9f00000000000000000000000000000000000000000000000000000000)
                let amoutOut1Index := shr(0xF8, calldataload(0x58)) // arg7 
                let amountOut1 := shr(0x40, calldataload(0x40)) // arg6

                switch amoutOut1Index
                case 0x0 {
                    mstore(0x04, amountOut1)
                    mstore(0x24, 0x0)
                } default {
                    mstore(0x04, 0x0)
                    mstore(0x24, amountOut1)
                }

                mstore(0x44, shr(0x60, calldataload(0x2c))) // target2
                mstore(0x64, 0x0000000000000000000000000000000000000000000000000000000000000080) // empty bytes
                pop(call(gas(), shr(0x60, calldataload(0x18)), 0x0, 0x0, 0xa4, 0x0, 0x0))

                // swap2 
                // skip storing swap sig it's still there

                let amoutOut2Index := shr(0xF8, calldataload(0x71))
                let amountOut2 := shr(0x40, calldataload(0x59))

                switch amoutOut2Index
                case 0x0 {
                    mstore(0x04, amountOut2)
                    mstore(0x24, 0x0)
                } default {
                    mstore(0x04, 0x0)
                    mstore(0x24, amountOut2)
                }

                mstore(0x44, address())
                // skip storing empty _data, it's still there
                pop(call(gas(), shr(0x60, calldataload(0x2c)), 0x0, 0x0, 0xa4, 0x0, 0x0))

                // check profit
                mstore(0x0, 0x70a0823100000000000000000000000000000000000000000000000000000000) // balanceOf Sig
                mstore(0x04, address())
                pop(call(gas(), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x0, 0x0, 0x24, 0x0, 0x20)) // get current balance
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
            case 0x2 { //withdraw token
                mstore(0x0, 0x70a0823100000000000000000000000000000000000000000000000000000000) // balanceOfSig
                mstore(0x04, address())
                let tokenAddr := shr(0x60, calldataload(0x0))
                pop(call(gas(), tokenAddr, 0x0, 0x0, 0x24, 0x0, 0x20)) // get current balance
                let currentBalance := mload(0x0)
                mstore(0x0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // transferSig
                mstore(0x04, 0x00000014b2a66142178807e370ae83830697DeC6)
                mstore(0x24, currentBalance)
                pop(call(gas(), tokenAddr, 0x0, 0x0, 0x44, 0x0, 0x20)) // transfer all to owner
                return(0x0, 0x0)    

            }
            default {
                mstore(0x00, 0x194)
                revert(0x0, 0x20)
            }
        }
    }
}
