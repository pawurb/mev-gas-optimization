use alloy_sol_types::SolValue;
use source::{set_bytecode, weth};
use std::env;
use std::sync::Arc;
pub mod source;
use anyhow::Result;
use ethers::prelude::*;
use ethers::utils::Anvil;
use source::{
    eth_to_usd, get_amount_out, prepare_data, sushi_pair, to_addr, uni_pair, Addresses, ETHER,
    ETHER_PRICE_USD, GWEI,
};
use std::ops::{Div, Mul};
use std::str::FromStr;
use url::Url;

#[tokio::main]
async fn main() -> Result<()> {
    env_logger::init();
    let rpc_url: Url = std::env::var("ETH_RPC_URL").unwrap().parse()?;
    let anvil = Anvil::new().fork(rpc_url).block_time(1_u64).spawn();
    let anvil_provider = Ws::connect(anvil.ws_endpoint()).await?;
    let anvil_provider = Arc::new(Provider::new(anvil_provider));

    let executor_address: H160 = "0x000000000000000012D4Bc56F957B3710216aB12"
        .parse()
        .unwrap();

    let bytecode = include_str!("../bytecode/BundleExecutor-huff.hex");
    let bytecode = Bytes::from_str(bytecode)?;

    set_bytecode(bytecode, executor_address, &anvil).await?;

    let uni_pair = uni_pair(anvil_provider.clone());
    let sushi_pair = sushi_pair(anvil_provider.clone());

    prepare_data(&anvil, executor_address).await?;

    let weth_amount_in = ETHER.div(10);
    let (uni_dai_reserve, uni_weth_reserve, _): (u128, u128, _) =
        uni_pair.get_reserves().call().await?;
    let (sushi_dai_reserve, sushi_weth_reserve, _): (u128, u128, _) =
        sushi_pair.get_reserves().call().await?;

    let dai_amount_out = get_amount_out(
        weth_amount_in,
        U256::from(uni_weth_reserve),
        U256::from(uni_dai_reserve),
    );

    let weth_amount_out = get_amount_out(
        dai_amount_out,
        U256::from(sushi_dai_reserve),
        U256::from(sushi_weth_reserve),
    );

    let client = SignerMiddleware::new(
        anvil_provider.clone(),
        env::var("PRIVATE_KEY")
            .expect("PRIVATE_KEY must be set")
            .parse::<LocalWallet>()
            .unwrap()
            .clone()
            .with_chain_id(1_u64),
    );

    let packed = (
        weth_amount_in.as_u64(),
        weth_amount_in.as_u64(),
        2062080000000000_u64, // gasCost
        to_addr(Addresses::UniPair.addr()),
        to_addr(Addresses::SushiPair.addr()),
        dai_amount_out.as_u128(),
        0_u16,
        weth_amount_out.as_u128(),
        1_u16,
    )
        .abi_encode_packed();

    let packed = Bytes::from(packed);

    let gas_price = anvil_provider.get_gas_price().await?;

    let swap_tx = TransactionRequest {
        from: Some(Addresses::Me.addr()),
        to: Some(executor_address.into()),
        chain_id: Some(1.into()),
        gas_price: Some(gas_price),
        data: Some(packed.clone()),
        gas: Some(U256::from(1_000_000_u64)),
        ..Default::default()
    };

    let receipt = client.send_transaction(swap_tx, None).await?;
    let receipt = receipt.await?;
    let weth_balance_after = weth(anvil_provider.clone())
        .balance_of(executor_address)
        .call()
        .await?;

    let gas_price_gwei = 15;
    let gas_price_wei = GWEI.mul(gas_price_gwei);

    println!("ETH price: ${}", ETHER_PRICE_USD);
    println!("WETH amount in: {}", weth_amount_in);
    println!("WETH amount out: {}", weth_balance_after);
    let full_profit = weth_balance_after - weth_amount_in;
    println!("Total WETH profit: {}", full_profit);
    println!("Total USD profit: ${:.2}", eth_to_usd(full_profit));
    println!("Gas price GWEI: {}", gas_price_gwei);
    let gas_used = receipt.unwrap().cumulative_gas_used;

    println!("Gas used: {}", gas_used);
    let gas_cost = gas_used * gas_price_wei;
    println!("Gas cost: {}", gas_cost);
    println!("Gas cost USD: ${:.2}", eth_to_usd(gas_cost));
    let real_profit = full_profit - gas_cost;
    println!("Real WETH profit: {}", real_profit);
    println!("Real USD profit: ${:.2}", eth_to_usd(real_profit));

    Ok(())
}
