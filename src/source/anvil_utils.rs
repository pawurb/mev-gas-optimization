use std::process::Command;
use std::sync::Arc;

use crate::source::Addresses;
use anyhow::Result;
use ethers::prelude::*;
use ethers::utils::hex;
use ethers::utils::keccak256;
use ethers::utils::AnvilInstance;
use reqwest::Client;
use serde_json::{json, Value};

pub async fn deploy_contract(name: &str, anvil: &AnvilInstance) -> Result<H160> {
    let output = Command::new("forge")
        .arg("create")
        .arg(format!("contracts/{}", name))
        .arg("--rpc-url")
        .arg(anvil.endpoint())
        .arg("--private-key")
        .arg(std::env::var("PRIVATE_KEY").expect("PRIVATE_KEY not set!"))
        .arg("--json")
        .arg("--optimize")
        .arg("--optimizer-runs")
        .arg("1000000")
        .arg("--constructor-args")
        .arg(std::env::var("ACCOUNT").expect("ACCOUNT not set!"))
        .output()?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    let deployment_json: Value = serde_json::from_str(&stdout).unwrap();

    let executor_address: H160 = deployment_json["deployedTo"]
        .as_str()
        .unwrap()
        .parse()
        .unwrap();
    println!("Deployed {} to {:?}", name, &executor_address);
    Ok(executor_address)
}

pub async fn copy_bytecode_from(
    from: H160,
    to: H160,
    provider: Arc<Provider<Ws>>,
    anvil: &AnvilInstance,
) -> Result<()> {
    let bytecode = provider.get_code(from, None).await?;
    set_bytecode(bytecode, to, anvil).await?;
    Ok(())
}

pub async fn set_bytecode(bytecode: Bytes, to: H160, anvil: &AnvilInstance) -> Result<()> {
    let call_data = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "anvil_setCode",
        "params": [format!("{:?}",to), bytecode]
    });

    let json_client = Client::new();
    json_client
        .post(anvil.endpoint())
        .json(&call_data)
        .send()
        .await?;

    Ok(())
}

pub async fn prepare_data(anvil: &AnvilInstance, executor_addr: H160) -> Result<()> {
    mock_storage_slot(
        anvil,
        Addresses::SushiPair.addr(),
        "0x8", // getReserves slot
        "0x665c6fcf00000000004d4a487a40a07d962e0000000453229E2B8F0ABE706380",
    )
    .await?;

    mock_storage_slot(
        anvil,
        Addresses::UniPair.addr(),
        "0x8", // getReserves slot
        "0x665c6fc30000000000726da71f957be90350000000069edd451a8cac85b3f053",
    )
    .await?;

    let executor_addr = format!("{:?}", executor_addr);
    let executor_addr = executor_addr.chars().skip(2).collect::<String>();

    let weth_executor_balance_slot = hex::decode(format!("000000000000000000000000{}0000000000000000000000000000000000000000000000000000000000000003", executor_addr)).unwrap();
    let weth_executor_balance_slot = hex::encode(keccak256(&weth_executor_balance_slot));
    mock_storage_slot(
        anvil,
        Addresses::WETH.addr(),
        &format!("0x{}", weth_executor_balance_slot),
        "0x000000000000000000000000000000000000000000000000016345785D8A0000",
    )
    .await?;

    let weth_sushi_balance_slot = hex::decode(format!("000000000000000000000000{}0000000000000000000000000000000000000000000000000000000000000003", Addresses::SushiPair.addr_str())).unwrap();
    let weth_sushi_balance_slot = hex::encode(keccak256(&weth_sushi_balance_slot));

    mock_storage_slot(
        anvil,
        Addresses::WETH.addr(),
        &format!("0x{}", weth_sushi_balance_slot),
        "0x00000000000000000000000000000000000000000000004D4A487A40A07D962E",
    )
    .await?;

    let weth_uni_balance_slot = hex::decode(format!("000000000000000000000000{}0000000000000000000000000000000000000000000000000000000000000003", Addresses::UniPair.addr_str())).unwrap();
    let weth_uni_balance_slot = hex::encode(keccak256(&weth_uni_balance_slot));

    mock_storage_slot(
        anvil,
        Addresses::WETH.addr(),
        &format!("0x{}", weth_uni_balance_slot),
        "0x0000000000000000000000000000000000000000000000726DA71F957BE90350",
    )
    .await?;

    let dai_sushi_balance_slot = hex::decode(format!("000000000000000000000000{}0000000000000000000000000000000000000000000000000000000000000002", Addresses::SushiPair.addr_str())).unwrap();
    let dai_sushi_balance_slot = hex::encode(keccak256(&dai_sushi_balance_slot));

    mock_storage_slot(
        anvil,
        Addresses::DAI.addr(),
        &format!("0x{}", dai_sushi_balance_slot),
        "0x0000000000000000000000000000000000000000000453229E2B8F0ABE706380",
    )
    .await?;

    let dai_uni_balance_slot = hex::decode(format!("000000000000000000000000{}0000000000000000000000000000000000000000000000000000000000000002", Addresses::UniPair.addr_str())).unwrap();
    let dai_uni_balance_slot = hex::encode(keccak256(&dai_uni_balance_slot));

    mock_storage_slot(
        anvil,
        Addresses::DAI.addr(),
        &format!("0x{}", dai_uni_balance_slot),
        "0x000000000000000000000000000000000000000000069EDD451A8CAC85B3F053",
    )
    .await?;

    Ok(())
}

async fn mock_storage_slot(
    anvil: &AnvilInstance,
    address: H160,
    slot: &str,
    value: &str,
) -> Result<()> {
    let call_data = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "anvil_setStorageAt",
        "params": [format!("{:?}",address), slot, value]
    });

    let json_client = Client::new();
    json_client
        .post(anvil.endpoint())
        .json(&call_data)
        .send()
        .await?;
    Ok(())
}
