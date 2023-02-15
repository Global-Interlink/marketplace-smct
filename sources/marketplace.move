module marketplace::marketplace {
    use sui::transfer;
    use sui::object::{Self, ID, UID};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use std::vector;
    use sui::event;
    use std::ascii;
    use sui::coin::{Self, Coin, CoinMetadata};
    use sui::pay;
    use std::option::{Option};
    use sui::sui::SUI;
    use sui::url::{Url};
    use sui::balance::{Self, Balance};
    use sui::math;
    use sui::address as module_address;
    use sui::dynamic_object_field as dof;
    use sui::vec_set;
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


    // ===== Error =========
    const E_INSUFFICIENT_FUNDS: u64 = 100;
    const E_NOT_OWNER: u64 = 101;

    // ===== Functions =====
    fun init(ctx: &mut TxContext) {
        transfer::share_object(Marketplace {
            id: object::new(ctx),
        });
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
        item
    }

    // ===== Entries =====
    public entry fun buy (
        ctx: &mut TxContext
    ) {

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
