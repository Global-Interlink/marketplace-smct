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

    // ===== Structs =====
    struct Marketplace has key {
        id: UID,
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
    fun init(ctx: &mut TxContext) {
        transfer::share_object(Marketplace {
            id: object::new(ctx),
        });
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
        transfer::transfer(target, @marketplace_owner);

        // Delete item
        let item = ofield::remove(&mut id, true);
        object::delete(id);

        return item
    }

    // ===== Entries =====
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
}
