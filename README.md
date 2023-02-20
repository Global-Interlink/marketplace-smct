1. List
```
sui client call \
--function list \
--module marketplace \
--package 0xd7d856a2db39a0ef4907c2a7b705d12593033a1a \
--gas-budget 10000 \
--args \
    0xd31a62c65d21cb5bb5695cf76ebd50d7b4e139ba \    # marketplace object ID
    0xdceb1fc316e865cf3796340bce02ad1cd4c0c0c5 \    # nft object id
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
sui client call \
--function buy \
--module marketplace \
--package 0xd7d856a2db39a0ef4907c2a7b705d12593033a1a \
--gas-budget 10000 \
--args 
    0xd31a62c65d21cb5bb5695cf76ebd50d7b4e139ba   \   # marketplace object ID
    0xdceb1fc316e865cf3796340bce02ad1cd4c0c0c5    \  # nft object ID
    '["0x1fbb34d7af8d1a684b735eed241cb8e4450add17"]'   \     # list sui coin object
--type-args 0x2::devnet_nft::DevNetNFT
```