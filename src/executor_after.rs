use std::env;
use std::sync::Arc;
pub mod source;
use anyhow::Result;
use ethers::prelude::*;
use ethers::utils::Anvil;
use source::{
    copy_bytecode_from, deploy_contract, eth_to_usd, get_amount_out, prepare_data, sushi_pair,
    uni_pair, weth, Addresses, ETHER, ETHER_PRICE_USD, GWEI,
};
use std::ops::{Div, Mul};
use url::Url;

abigen!(IBundleExecutor, "src/abi/bundle-executor-after.json");

#[tokio::main]
async fn main() -> Result<()> {
    env_logger::init();
    let rpc_url: Url = std::env::var("ETH_RPC_URL").unwrap().parse()?;
    let anvil = Anvil::new().fork(rpc_url).block_time(1_u64).spawn();
    let anvil_provider = Ws::connect(anvil.ws_endpoint()).await?;
    let anvil_provider = Arc::new(Provider::new(anvil_provider));

    let executor_template_address =
        deploy_contract("BundleExecutor-after.sol:FlashBotsMultiCall", &anvil).await?;

    let executor_address: H160 = "0x000000000000000012D4Bc56F957B3710216aB12"
        .parse()
        .unwrap();

    copy_bytecode_from(
        executor_template_address,
        executor_address,
        anvil_provider.clone(),
        &anvil,
    )
    .await?;

    let executor = IBundleExecutor::new(executor_address, anvil_provider.clone());
    let uni_pair = uni_pair(anvil_provider.clone());
    let sushi_pair = sushi_pair(anvil_provider.clone());

    prepare_data(&anvil, executor.address()).await?;

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

    let swap1 = uni_pair
        .swap(
            dai_amount_out,
            U256::zero(),
            sushi_pair.address(),
            Bytes::new(),
        )
        .tx;
    let swap1 = swap1.data().unwrap().clone();

    let swap2 = sushi_pair
        .swap(
            U256::zero(),
            weth_amount_out,
            executor.address(),
            Bytes::new(),
        )
        .tx;
    let swap2 = swap2.data().unwrap().clone();

    let client = SignerMiddleware::new(
        anvil_provider.clone(),
        env::var("PRIVATE_KEY")
            .expect("PRIVATE_KEY must be set")
            .parse::<LocalWallet>()
            .unwrap()
            .clone()
            .with_chain_id(1_u64),
    );

    let swap_tx = executor
        .uniswap_weth(
            weth_amount_in,
            U256::from(2062080000000000_i64), // estimated gas cost
            weth_amount_in,
            vec![Addresses::UniPair.addr(), Addresses::SushiPair.addr()],
            vec![swap1, swap2],
        )
        .tx;

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
