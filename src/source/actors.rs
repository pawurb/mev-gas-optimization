use std::{env, sync::Arc};

use ethers::prelude::*;

abigen!(IERC20, "src/abi/erc20.json");
abigen!(IUniV2Pair, "src/abi/uniswap_v2_pair.json");

pub enum Addresses {
    WETH,
    DAI,
    UniPair,
    SushiPair,
    Me,
}

impl Addresses {
    pub fn addr(&self) -> H160 {
        match self {
            Addresses::WETH => "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
                .parse()
                .unwrap(),
            Addresses::DAI => "0x6b175474e89094c44da98b954eedeac495271d0f"
                .parse()
                .unwrap(),
            Addresses::SushiPair => "0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f"
                .parse()
                .unwrap(),
            Addresses::UniPair => "0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11"
                .parse()
                .unwrap(),
            Addresses::Me => env::var("ACCOUNT")
                .expect("ACCOUNT must be set")
                .parse()
                .unwrap(),
        }
    }

    pub fn addr_str(&self) -> String {
        let addr = format!("{:?}", self.addr());
        addr.chars().skip(2).collect::<String>()
    }
}

pub fn weth(provider: Arc<Provider<Ws>>) -> IERC20<Provider<Ws>> {
    IERC20::new(Addresses::WETH.addr(), provider.clone())
}

pub fn dai(provider: Arc<Provider<Ws>>) -> IERC20<Provider<Ws>> {
    IERC20::new(Addresses::DAI.addr(), provider.clone())
}

pub fn uni_pair(provider: Arc<Provider<Ws>>) -> IUniV2Pair<Provider<Ws>> {
    IUniV2Pair::new(Addresses::UniPair.addr(), provider.clone())
}

pub fn sushi_pair(provider: Arc<Provider<Ws>>) -> IUniV2Pair<Provider<Ws>> {
    IUniV2Pair::new(Addresses::SushiPair.addr(), provider.clone())
}
