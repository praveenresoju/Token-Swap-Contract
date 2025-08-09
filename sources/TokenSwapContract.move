module praveen_addr::TokenSwap {
    use aptos_framework::coin;
    use std::signer::address_of;

    /// Struct representing a token swap pool
    struct SwapPool<phantom TokenA, phantom TokenB> has store, key {
        token_a_reserve: u64,  // Reserve of Token A in the pool
        token_b_reserve: u64,  // Reserve of Token B in the pool
        total_swaps: u64,      // Total number of swaps performed
    }

    /// Function to initialize a new token swap pool with initial reserves
    public fun initialize_pool<TokenA, TokenB>(
        owner: &signer, 
        initial_a: u64, 
        initial_b: u64
    ) {
        let pool = SwapPool<TokenA, TokenB> {
            token_a_reserve: initial_a,
            token_b_reserve: initial_b,
            total_swaps: 0,
        };
        move_to(owner, pool);
    }

    /// Function to perform 1:1 token swap from Token A to Token B
    public fun swap_a_to_b<TokenA, TokenB>(
        user: &signer,
        pool_owner: &signer,
        amount: u64
    ) acquires SwapPool {
        let pool_address = address_of(pool_owner);
        let pool = borrow_global_mut<SwapPool<TokenA, TokenB>>(pool_address);
        
        // Ensure pool has enough Token B reserves
        assert!(pool.token_b_reserve >= amount, 1);
        
        // Withdraw Token A from user and deposit to pool owner
        let token_a = coin::withdraw<TokenA>(user, amount);
        coin::deposit<TokenA>(pool_address, token_a);
        
        // Withdraw Token B from pool owner and give to user (1:1 ratio)
        let token_b = coin::withdraw<TokenB>(pool_owner, amount);
        coin::deposit<TokenB>(address_of(user), token_b);
        
        // Update reserves and swap count
        pool.token_a_reserve = pool.token_a_reserve + amount;
        pool.token_b_reserve = pool.token_b_reserve - amount;
        pool.total_swaps = pool.total_swaps + 1;
    }
}