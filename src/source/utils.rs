use alloy_primitives::Address;
use bigdecimal::{BigDecimal, ToPrimitive};
use ethers::core::utils::to_checksum;
use ethers::prelude::*;
use std::str::FromStr;

pub const ETHER: U256 = U256([10u64.pow(18), 0, 0, 0]);
pub const GWEI: U256 = U256([10u64.pow(9), 0, 0, 0]);
pub const ETHER_PRICE_USD: f64 = 3800.0;

pub fn get_amount_out(amount_in: U256, reserve_in: U256, reserve_out: U256) -> U256 {
    let amount_in_with_fee = amount_in * U256::from(997_u64); // uniswap fee 0.3%
    let numerator = amount_in_with_fee * reserve_out;
    let denominator = reserve_in * U256::from(1000_u64) + amount_in_with_fee;
    numerator / denominator
}

pub fn eth_to_usd(value: U256) -> f64 {
    let value_dec = BigDecimal::from_str(&value.to_string()).unwrap();
    let one_eth_dec = BigDecimal::from_str(&format!("1e{}", 18)).unwrap();
    let price_dec = BigDecimal::from_str(&ETHER_PRICE_USD.to_string()).unwrap();

    let result = (value_dec / one_eth_dec) * price_dec;
    let result_rounded = result.round(4);

    result_rounded.to_f64().unwrap_or(0.0)
}

pub fn to_addr(h160: H160) -> Address {
    Address::parse_checksummed(to_checksum(&h160, None), None).unwrap()
}
