module marketplace::marketplace {
    use sui::transfer;
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use std::vector;
    use sui::event;
    use sui::coin::{Self, Coin};
    use sui::pay;
    use sui::sui::SUI;
    use sui::dynamic_object_field as ofield;
    use sui::test_scenario;
    use sui::devnet_nft;

    // Capabilites
    struct AdminCap has key {
        id: UID 
    }

    // ===== Structs =====
    struct Marketplace has key {
        id: UID,
        wallet: address
    }

    struct Listing has key, store {
        id: UID,
        price: u64,
        owner: address,
    }

    // ===== Events =====
    struct ListEvent has copy, drop {
        item_id: ID,
        price: u64,
        actor: address,
    }

    struct DelistEvent has copy, drop {
        item_id: ID,
        actor: address,
    }

    struct BuyEvent has copy, drop {
        item_id: ID,
        actor: address,
    }

    // ===== Error =========
    const E_INSUFFICIENT_FUNDS: u64 = 100;
    const E_NOT_OWNER: u64 = 101;

    // ===== Functions =====
    fun initialize(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        transfer::share_object(Marketplace {
            id: object::new(ctx),
            wallet: @marketplace_owner
        });
    }

    fun init(ctx: &mut TxContext) {
        initialize(ctx);
    }

    fun merge_and_split<T>(coins: vector<Coin<T>>, amount: u64, ctx: &mut TxContext): (Coin<T>, Coin<T>) {
        let base = vector::pop_back(&mut coins);
        pay::join_vec(&mut base, coins);
        assert!(coin::value(&base) > amount, E_INSUFFICIENT_FUNDS);
        (coin::split(&mut base, amount, ctx), base)
    }

    fun do_delist<T: key + store> (
        marketplace: &mut Marketplace,
        item_id: ID,
        ctx: &mut TxContext
    ): T {
        let Listing {
            id,
            owner,
            price: _,
        } = ofield::remove(&mut marketplace.id, item_id);

        assert!(tx_context::sender(ctx) == owner, E_NOT_OWNER);

        let item = ofield::remove(&mut id, true);
        object::delete(id);
        return item
    }

    fun do_buy<T: key + store> (
        marketplace: &mut Marketplace,
        item_id: ID,
        sui_coins: vector<Coin<SUI>>,
        ctx: &mut TxContext
    ): T {
        let Listing {
            id,
            owner: _,
            price,
        } = ofield::remove(&mut marketplace.id, item_id);

        // Change fee
        let sender = tx_context::sender(ctx);
        let (target, remaining) = merge_and_split(sui_coins, price, ctx);
        transfer::transfer(remaining, sender);
        transfer::transfer(target, marketplace.wallet);

        // Delete item
        let item = ofield::remove(&mut id, true);
        object::delete(id);

        return item
    }

    // ===== Entries =====
    public entry fun set_marketplace_wallet (
        _: &AdminCap,
        marketplace: &mut Marketplace,
        wallet: address,
        _ctx: &mut TxContext
    ) {
        marketplace.wallet = wallet;
    }

    public entry fun buy<T: key + store> (
        marketplace: &mut Marketplace,
        item_id: ID,
        sui_coins: vector<Coin<SUI>>,
        ctx: &mut TxContext
    ) {
        let item = do_buy<T>(marketplace, item_id, sui_coins, ctx);
        transfer::transfer(item, tx_context::sender(ctx));
        event::emit(BuyEvent {
            item_id: item_id,
            actor: tx_context::sender(ctx),
        });
    }

    public entry fun list<T: key + store> (
        marketplace: &mut Marketplace,
        item: T,
        price: u64,
        ctx: &mut TxContext
    ) {
        let item_id = object::id(&item);
        let listing = Listing {
            id: object::new(ctx),
            price: price,
            owner: tx_context::sender(ctx),
        };
        ofield::add(&mut listing.id, true, item);
        ofield::add(&mut marketplace.id, item_id, listing);

        event::emit(ListEvent {
            item_id: item_id,
            price: price,
            actor: tx_context::sender(ctx),
        });
    }

    public entry fun delist<T: key + store>(
        marketplace: &mut Marketplace,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let item = do_delist<T>(marketplace, item_id, ctx);
        transfer::transfer(item, tx_context::sender(ctx));
        
        event::emit(DelistEvent {
            item_id: item_id,
            actor: tx_context::sender(ctx),
        });
    }

    // ############ TESTING #####################
    #[test]
    public fun test_list_success() {
        let admin = @0xA;
        let scenario_val = test_scenario::begin(admin);
        let nft_id: ID;

        // init package
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, admin);
        {
            let ctx = test_scenario::ctx(scenario);
            initialize(ctx);
        };

        // mint nft
        test_scenario::next_tx(scenario, admin);
        {
            // arrange
            let ctx = test_scenario::ctx(scenario);
            devnet_nft::mint(
                b"M1",
                b"M1 description",
                b"https://images.theconversation.com/files/417198/original/file-20210820-25-1j3afhs.jpeg?ixlib=rb-1.1.0&q=45&auto=format&w=926&fit=clip",
                ctx
            );
        };

        // list
        test_scenario::next_tx(scenario, admin);
        {
            // arrange
            let marketplace_obj = test_scenario::take_shared<Marketplace>(scenario);
            let nft = test_scenario::take_from_sender<devnet_nft::DevNetNFT>(scenario);
            nft_id = object::id(&nft);
            let ctx = test_scenario::ctx(scenario);
            
            // action
            list<devnet_nft::DevNetNFT>(
                &mut marketplace_obj,
                nft,
                1_000_000_0,
                ctx
            );

            // assert
            let Listing {
                id: _,
                owner,
                price
            } = ofield::borrow(&marketplace_obj.id, nft_id);
            assert!(*price == 1_000_000_0, 1);
            assert!(*owner == tx_context::sender(ctx), 2);

            // clean
            test_scenario::return_shared<Marketplace>(marketplace_obj);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure]
    public fun test_delist_success() {
        let admin = @0xA;
        let scenario_val = test_scenario::begin(admin);
        let nft_id: ID;

        // init package
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, admin);
        {
            let ctx = test_scenario::ctx(scenario);
            initialize(ctx);
        };

        // mint nft
        test_scenario::next_tx(scenario, admin);
        {
            // arrange
            let ctx = test_scenario::ctx(scenario);
            devnet_nft::mint(
                b"M1",
                b"M1 description",
                b"https://images.theconversation.com/files/417198/original/file-20210820-25-1j3afhs.jpeg?ixlib=rb-1.1.0&q=45&auto=format&w=926&fit=clip",
                ctx
            );
        };

        // list
        test_scenario::next_tx(scenario, admin);
        {
            // arrange
            let marketplace_obj = test_scenario::take_shared<Marketplace>(scenario);
            let nft = test_scenario::take_from_sender<devnet_nft::DevNetNFT>(scenario);
            nft_id = object::id(&nft);
            let ctx = test_scenario::ctx(scenario);
            
            // action
            list<devnet_nft::DevNetNFT>(
                &mut marketplace_obj,
                nft,
                1_000_000_0,
                ctx
            );

            // assert
            let Listing {
                id: _,
                owner,
                price
            } = ofield::borrow(&marketplace_obj.id, nft_id);
            assert!(*price == 1_000_000_0, 1);
            assert!(*owner == tx_context::sender(ctx), 2);

            // clean
            test_scenario::return_shared<Marketplace>(marketplace_obj);
        };

        // delist
        test_scenario::next_tx(scenario, admin);
        {
            // arrange
            let marketplace_obj = test_scenario::take_shared<Marketplace>(scenario);
            let ctx = test_scenario::ctx(scenario);
            
            // action
            delist<devnet_nft::DevNetNFT>(
                &mut marketplace_obj,
                nft_id,
                ctx
            );

            let Listing {
                id: _, 
                owner: _, 
                price: _
            } = ofield::borrow(
                &marketplace_obj.id,
                nft_id
            );

            // clean
            test_scenario::return_shared<Marketplace>(marketplace_obj);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    public fun test_buy_success() {
        let admin = @0xA;
        let buyer = @0xcafe;
        let mkpl_wallet = @0xC;
        let scenario_val = test_scenario::begin(admin);
        let nft_id: ID;

        // init package
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            initialize(ctx);
        };

        // mint nft
        test_scenario::next_tx(scenario, admin);
        {
            // arrange
            let ctx = test_scenario::ctx(scenario);
            devnet_nft::mint(
                b"M1",
                b"M1 description",
                b"https://images.theconversation.com/files/417198/original/file-20210820-25-1j3afhs.jpeg?ixlib=rb-1.1.0&q=45&auto=format&w=926&fit=clip",
                ctx
            );
        };

        // list
        test_scenario::next_tx(scenario, admin);
        {
            // arrange
            let marketplace_obj = test_scenario::take_shared<Marketplace>(scenario);
            let nft = test_scenario::take_from_sender<devnet_nft::DevNetNFT>(scenario);
            nft_id = object::id(&nft);
            let ctx = test_scenario::ctx(scenario);
            
            // action
            list<devnet_nft::DevNetNFT>(
                &mut marketplace_obj,
                nft,
                1_000_000_000,
                ctx
            );

            // assert
            let Listing {
                id: _,
                owner,
                price
            } = ofield::borrow(&marketplace_obj.id, nft_id);
            assert!(*price == 1_000_000_000, 1);
            assert!(*owner == tx_context::sender(ctx), 2);

            // clean
            test_scenario::return_shared<Marketplace>(marketplace_obj);
        };

        // mint coin
        test_scenario::next_tx(scenario, admin);
        {
            // arrange
            let ctx = test_scenario::ctx(scenario);
            let coin = coin::mint_for_testing<SUI>(1_300_000_000, ctx);
            transfer::transfer(coin, buyer);
        };

        // set wallet
        test_scenario::next_tx(scenario, admin);
        {
            // arrange
            let marketplace_obj = test_scenario::take_shared<Marketplace>(scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            set_marketplace_wallet (
                &admin_cap,
                &mut marketplace_obj,
                mkpl_wallet,
                test_scenario::ctx(scenario)
            );
            test_scenario::return_shared<Marketplace>(marketplace_obj);
            test_scenario::return_to_sender<AdminCap>(scenario, admin_cap);
        };

        // buy
        test_scenario::next_tx(scenario, buyer);
        {
            // arrange
            let marketplace_obj = test_scenario::take_shared<Marketplace>(scenario);
            let coin = test_scenario::take_from_sender<Coin<SUI>>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let payments = vector::empty<Coin<SUI>>();
            vector::push_back(&mut payments, coin);

            // action
            buy<devnet_nft::DevNetNFT>(
                &mut marketplace_obj,
                nft_id,
                payments,
                ctx
            );

            // clean
            test_scenario::return_shared<Marketplace>(marketplace_obj);
        };

        // verify nft in buyer
        test_scenario::next_tx(scenario, buyer);
        {
            // arrange
            let nft = test_scenario::take_from_sender<devnet_nft::DevNetNFT>(scenario);
            assert!(object::id(&nft) == nft_id, 1);
            test_scenario::return_to_sender<devnet_nft::DevNetNFT>(scenario, nft);
        };

        // verify balance in mkpl wallet
        test_scenario::next_tx(scenario, mkpl_wallet);
        {
            // arrange
            let coin = test_scenario::take_from_sender<Coin<SUI>>(scenario);
            assert!(coin::value(&coin) == 1_000_000_000, 1);
            test_scenario::return_to_sender<Coin<SUI>>(scenario, coin);
        };
        test_scenario::end(scenario_val);
    }

}
