module game_hero::sea_hero {
    use game_hero::hero::{Self, Hero};

    use sui::balance::{Self, Balance, Supply};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct SeaHeroAdmin has key {
        id: UID,
        supply: Supply<RUM>,
        monsters_created: u64,
        token_supply_max: u64,
        monster_max: u64
    }

    struct SeaMonster has key, store {
        id: UID,
        reward: Balance<RUM>
    }

    struct RUM has drop {}

    const EHERO_NOT_STRONG_ENOUGH: u64 = 0;
    const EINVALID_TOKEN_SUPPLY: u64 = 1;
    const EINVALID_MONSTER_SUPPLY: u64 = 2;

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            SeaHeroAdmin {
                id: object::new(ctx),
                supply: balance::create_supply<RUM>(RUM {}),
                monsters_created: 0,
                token_supply_max: 1000000,
                monster_max: 10,
            },
            tx_context::sender(ctx)
        )
    }

    // --- Gameplay ---
    public fun slay(hero: &Hero, monster: SeaMonster): Balance<RUM> {
        let SeaMonster { id, reward } = monster;
        object::delete(id);
        assert!(
            hero::hero_strength(hero) >= balance::value(&reward),
            EHERO_NOT_STRONG_ENOUGH
        );

        reward
    }

    // --- Object and coin creation ---
    public entry fun create_monster(
        admin: &mut SeaHeroAdmin,
        reward_amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let current_coin_supply = balance::supply_value(&admin.supply);
        let token_supply_max = admin.token_supply_max;
        assert!(reward_amount < token_supply_max, 0);
        assert!(token_supply_max - reward_amount >= current_coin_supply, 1);
        assert!(admin.monster_max - 1 >= admin.monsters_created, 2);

        let monster = SeaMonster {
            id: object::new(ctx),
            reward: balance::increase_supply(&mut admin.supply, reward_amount),
        };
        admin.monsters_created = admin.monsters_created + 1;

        transfer::public_transfer(monster, recipient)
    }

    public fun monster_reward(monster: &SeaMonster): u64 {
        balance::value(&monster.reward)
    }
}
