1. List
```
sui client call \
--function list \
--module marketplace \
--package 0x6eacc58fc4150c968b8aa7982713715769e72850 \
--gas-budget 10000 \
--args \
    0x4801437fcc5b3950c76137fa06e21fcc4dfd5b4a \
    0xdceb1fc316e865cf3796340bce02ad1cd4c0c0c5 \
    \"2000000\" \
--type-args \
    0x2::devnet_nft::DevNetNFT
```

2. Delist
```
sui client call --function delist --module marketplace --package 0x6eacc58fc4150c968b8aa7982713715769e72850 --gas-budget 10000 --args 0x4801437fcc5b3950c76137fa06e21fcc4dfd5b4a 0xdceb1fc316e865cf3796340bce02ad1cd4c0c0c5 --type-args 0x2::devnet_nft::DevNetNFT
```

3. Buy
```
sui client call --function buy --module marketplace --package 0x6eacc58fc4150c968b8aa7982713715769e72850 --gas-budget 10000 --args 0x4801437fcc5b3950c76137fa06e21fcc4dfd5b4a 0xdceb1fc316e865cf3796340bce02ad1cd4c0c0c5 '["0x1fbb34d7af8d1a684b735eed241cb8e4450add17"]'  --type-args 0x2::devnet_nft::DevNetNFT
```