1. List
```
sui client call \
--function list \
--module marketplace \
--package 0xddd21733462c813f3bc621e592fdde869f0d7b16 \
--gas-budget 10000 \
--args \
    0x2a8d2a8b9920bb242498a7fd4a40ded3d1264df6 \
    0x2614213a40bbcb6e88439b7055d3e2e70892057a \
    \"2000000\" \
--type-args \
    0x81f64a0a32a0a413bf74ed915bf6319b5da9acdf::launchpad_nft::NFT
```

1. Delist
```
sui client call \
--function delist \ 
--module marketplace \
--package 0xddd21733462c813f3bc621e592fdde869f0d7b16 \
--gas-budget 10000 \
--args \
    0x2a8d2a8b9920bb242498a7fd4a40ded3d1264df6 \
    0x2614213a40bbcb6e88439b7055d3e2e70892057a \
--type-args \
    0x81f64a0a32a0a413bf74ed915bf6319b5da9acdf::launchpad_nft::NFT
```