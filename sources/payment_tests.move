#[test_only]
module iap::payment_tests {
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    // use aptos_framework::coin::ECOIN_STORE_NOT_PUBLISHED; // Removed the import
    use aptos_framework::timestamp;
    // use aptos_framework::event; // Removed unused import
    
    // use iap::payment; // Removed duplicate import
    use iap::payment::{Self}; // Keep Self, remove unused event types and EventStore

    // Test addresses
    const ADMIN: address = @0xAD;
    const USER: address = @0xB0B;
    const USER2: address = @0xC0C;
    const NEW_TREASURY: address = @0xD0D;

    // Helper function to set up test accounts
    fun setup_accounts(): (signer, signer, signer, signer) {
        // Get signer for @aptos_framework
        let aptos_framework_signer = account::create_account_for_test(@aptos_framework);

        // Initialize timestamp and AptosCoin using @aptos_framework signer first
        timestamp::set_time_has_started_for_testing(&aptos_framework_signer);
        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(&aptos_framework_signer);

        // Create test accounts
        let admin = account::create_account_for_test(ADMIN);
        let user = account::create_account_for_test(USER);
        let user2 = account::create_account_for_test(USER2);
        let new_treasury = account::create_account_for_test(NEW_TREASURY);
        
        // Register CoinStore for accounts that will receive coins
        coin::register<AptosCoin>(&admin);
        coin::register<AptosCoin>(&user); 
        coin::register<AptosCoin>(&user2);

        // Fund user accounts
        let coins = coin::mint<AptosCoin>(50000000, &mint_cap);
        coin::deposit(signer::address_of(&user), coins);
        
        let coins = coin::mint<AptosCoin>(50000000, &mint_cap);
        coin::deposit(signer::address_of(&user2), coins);
        
        // Clean up capabilities
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
        
        (admin, user, user2, new_treasury)
    }

    #[test]
    fun test_init() {
        let (admin, _, _, _) = setup_accounts();
        
        // Initialize the module
        payment::initialize_for_testing(&admin);
        
        // Verify treasury address is set correctly
        assert!(payment::get_treasury(ADMIN) == ADMIN, 0);
    }

    #[test]
    fun test_process_payment() {
        let (admin, user, _, _) = setup_accounts();
        
        // Initialize the module
        payment::initialize_for_testing(&admin);
        
        // Get balance before payment
        let admin_balance_before = coin::balance<AptosCoin>(ADMIN);
        let user_balance_before = coin::balance<AptosCoin>(USER);
        
        // Process payment
        let min_amount = payment::get_min_payment_amount();
        let payment_amount = min_amount + 1000000; // a bit more than minimum
        
        payment::process_payment(
            &user,
            ADMIN, 
            b"test_payment_id",
            b"test_data",
            payment_amount
        );
        
        // Verify balances after payment
        let admin_balance_after = coin::balance<AptosCoin>(ADMIN);
        let user_balance_after = coin::balance<AptosCoin>(USER);
        
        assert!(admin_balance_after == admin_balance_before + payment_amount, 0);
        assert!(user_balance_after == user_balance_before - payment_amount, 1);
    }

    #[test]
    #[expected_failure(abort_code = payment::EINVALID_AMOUNT)]
    fun test_process_payment_below_minimum() {
        let (admin, user, _, _) = setup_accounts();
        
        // Initialize the module
        payment::initialize_for_testing(&admin);
        
        // Try to process payment with amount below minimum
        let min_amount = payment::get_min_payment_amount();
        
        payment::process_payment(
            &user,
            ADMIN, 
            b"test_payment_id",
            b"test_data",
            min_amount - 1
        );
    }

    #[test]
    fun test_update_treasury() {
        let (admin, _, _, _) = setup_accounts();
        
        // Initialize the module
        payment::initialize_for_testing(&admin);
        
        // Update treasury address
        payment::update_treasury(&admin, ADMIN, NEW_TREASURY);
        
        // Verify new treasury address
        assert!(payment::get_treasury(ADMIN) == NEW_TREASURY, 0);
    }

    #[test]
    #[expected_failure(abort_code = payment::ENOT_AUTHORIZED)]
    fun test_update_treasury_unauthorized() {
        let (admin, user, _, _) = setup_accounts();
        
        // Initialize the module
        payment::initialize_for_testing(&admin);
        
        // Try to update treasury address with unauthorized user (should fail)
        payment::update_treasury(&user, ADMIN, NEW_TREASURY);
    }

    #[test]
    fun test_different_payment_ids() {
        let (admin, user, _, _) = setup_accounts();
        
        // Initialize the module
        payment::initialize_for_testing(&admin);
        
        // Process first payment with unique ID
        let min_amount = payment::get_min_payment_amount();
        
        payment::process_payment(
            &user,
            ADMIN, 
            b"payment_id_1",
            b"first_payment",
            min_amount * 2
        );
        
        // Process second payment with different ID
        payment::process_payment(
            &user,
            ADMIN, 
            b"payment_id_2",
            b"second_payment",
            min_amount * 3
        );
    }

    #[test]
    fun test_multiple_users_payments() {
        let (admin, user, user2, _) = setup_accounts();
        
        // Initialize the module
        payment::initialize_for_testing(&admin);
        
        // First payment from USER
        let min_amount = payment::get_min_payment_amount();
        
        payment::process_payment(
            &user,
            ADMIN, 
            b"user1_payment",
            b"data_from_user1",
            min_amount * 2
        );
        
        // Second payment from USER2
        payment::process_payment(
            &user2,
            ADMIN, 
            b"user2_payment",
            b"data_from_user2",
            min_amount * 3
        );
    }

    #[test]
    fun test_payment_with_special_characters() {
        let (admin, user, _, _) = setup_accounts();
        
        // Initialize the module
        payment::initialize_for_testing(&admin);
        
        // Payment with special characters in ID and data
        let min_amount = payment::get_min_payment_amount();
        
        payment::process_payment(
            &user,
            ADMIN, 
            b"payment@#$%^&*()_id+{}[]|:'<>?,./",
            b"additional~!@#$%^&*()_+{}[]|:'<>?,./",
            min_amount * 2
        );
    }

    #[test]
    fun test_process_payment_exact_minimum() {
        let (admin, user, _, _) = setup_accounts();
        
        payment::initialize_for_testing(&admin);
        
        let admin_balance_before = coin::balance<AptosCoin>(ADMIN);
        let user_balance_before = coin::balance<AptosCoin>(USER);
        
        let min_amount = payment::get_min_payment_amount();
        
        payment::process_payment(
            &user,
            ADMIN, 
            b"test_exact_min_payment_id",
            b"test_exact_min_data",
            min_amount 
        );
        
        let admin_balance_after = coin::balance<AptosCoin>(ADMIN);
        let user_balance_after = coin::balance<AptosCoin>(USER);
        
        assert!(admin_balance_after == admin_balance_before + min_amount, 0);
        assert!(user_balance_after == user_balance_before - min_amount, 1);
    }

    #[test]
    #[expected_failure(abort_code = 393221)]
    fun test_process_payment_to_unregistered_treasury() {
        let (admin, user, _, new_treasury_signer) = setup_accounts(); // new_treasury_signer used to get its address
        let new_treasury_addr = signer::address_of(&new_treasury_signer);

        payment::initialize_for_testing(&admin);
        
        // Update treasury to an address that does not have CoinStore<AptosCoin> registered
        // Note: NEW_TREASURY (@0xD0D) is created in setup_accounts but we don't register CoinStore for it.
        payment::update_treasury(&admin, ADMIN, new_treasury_addr);
        assert!(payment::get_treasury(ADMIN) == new_treasury_addr, 0);

        let payment_amount = payment::get_min_payment_amount();
        
        // This payment should fail because new_treasury_addr doesn't have CoinStore
        payment::process_payment(
            &user,
            ADMIN, 
            b"test_unregistered_treasury_payment",
            b"test_data",
            payment_amount
        );
    }

    // ======== Test-only Functions ========
    #[test_only]
    public fun initialize_for_testing(account: &signer) {
        payment::initialize(account);
    }
}