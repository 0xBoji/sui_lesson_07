module game_hero::sea_hero_helper {
    use game_hero::sea_hero::{Self, SeaMonster, RUM};
    use game_hero::hero::Hero;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct HelpMeSlayThisMonster has key {
        id: UID,
        monster: SeaMonster,
        monster_owner: address,
        helper_reward: u64,
    }

    const EINVALID_HELPER_REWARD: u64 = 0;

    public fun create(
        monster: SeaMonster,
        helper_reward: u64,
        helper: address,
        ctx: &mut TxContext,
    ) {
        assert!(sea_hero::monster_reward(&monster) > helper_reward, EINVALID_HELPER_REWARD);
        transfer::transfer(
            HelpMeSlayThisMonster {
                id: object::new(ctx),
                monster,
                monster_owner: tx_context::sender(ctx),
                helper_reward
            },
            helper
        )
    }

    public fun slay(
        hero: &Hero, wrapper: HelpMeSlayThisMonster, ctx: &mut TxContext,
    ): Coin<RUM> {
        let HelpMeSlayThisMonster {
            id,
            monster,
            monster_owner,
            helper_reward
        } = wrapper;
        object::delete(id);
        let owner_reward = sea_hero::slay(hero, monster);
        let helper_reward = coin::take(&mut owner_reward, helper_reward, ctx);
        transfer::public_transfer(coin::from_balance(owner_reward, ctx), monster_owner);
        helper_reward
    }

    public fun return_to_owner(wrapper: HelpMeSlayThisMonster) {
        let HelpMeSlayThisMonster {
            id,
            monster,
            monster_owner,
            helper_reward: _
        } = wrapper;
        object::delete(id);
        transfer::public_transfer(monster, monster_owner)
    }

    public fun owner_reward(wrapper: &HelpMeSlayThisMonster): u64 {
        sea_hero::monster_reward(&wrapper.monster) - wrapper.helper_reward
    }
}
