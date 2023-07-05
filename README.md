# Deploy

```
sui client publish  --gas-budget 100000000
```

1. List
```
sui client call \
--function list \
--module marketplace \
--package 0x56aae252182977d4041042a053d4bb3a751dd38f \
--gas-budget 10000 \
--args \
    0xe457863a9f3023573cdcc3b16adc77e975caa138 \
    0x79aff55b4b0f74b5524ba4b37a17d3ee34780c61 \
    \"2000000\" \
--type-args \
    0x2::devnet_nft::DevNetNFT
```

2. Delist
```
sui client call \
--function delist \
--module marketplace \
--package 0xd7d856a2db39a0ef4907c2a7b705d12593033a1a \
--gas-budget 10000 \
--args \
    0xd31a62c65d21cb5bb5695cf76ebd50d7b4e139ba  \# marketplace object ID
    0xdceb1fc316e865cf3796340bce02ad1cd4c0c0c5  \# nft object id
--type-args 0x2::devnet_nft::DevNetNFT
```

3. Buy
```
sui client call --function buy --module marketplace --package 0x56aae252182977d4041042a053d4bb3a751dd38f --gas-budget 10000 --args 0xe457863a9f3023573cdcc3b16adc77e975caa138 0x79aff55b4b0f74b5524ba4b37a17d3ee34780c61 '["0x2059919f4b6467584c78ebba11755c13b1774260"]' --type-args 0x2::devnet_nft::DevNetNFT
```
