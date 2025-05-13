module iap::payment {
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::account;
    use aptos_framework::coin::{Self};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;

    // ======== Errors ========
    const ENOT_AUTHORIZED: u64 = 0;
    const EINVALID_AMOUNT: u64 = 1;
    const ETREASURY_NOT_INITIALIZED: u64 = 2;

    // ======== Constants ========
    const MIN_PAYMENT_AMOUNT: u64 = 1_0_000; // 0.0001 APT (Aptos has 8 decimals)

    // ======== Events ========
    /// Event emitted when a payment is processed
    struct PaymentProcessedEvent has drop, store {
        payment_id: String,
        sender: address,
        amount: u64,
        timestamp: u64,
        additional_data: String,
        treasury: address
    }

    /// Event emitted when treasury address is updated
    struct TreasuryUpdatedEvent has drop, store {
        old_treasury: address,
        new_treasury: address
    }

    // ======== Resources ========
    /// The capability that grants administrative rights
    struct AdminCap has key {
        treasury_address: address
    }

    /// EventStore stores event handles for payment events
    struct EventStore has key {
        payment_processed_events: EventHandle<PaymentProcessedEvent>,
        treasury_updated_events: EventHandle<TreasuryUpdatedEvent>
    }

    // ======== Functions ========
    /// Module initializer creates admin capability
    public entry fun initialize(account: &signer) {
        let account_addr = signer::address_of(account);
        
        // Create AdminCap for the deployer
        move_to(account, AdminCap {
            treasury_address: account_addr
        });
        
        // Initialize event store
        move_to(account, EventStore {
            payment_processed_events: account::new_event_handle<PaymentProcessedEvent>(account),
            treasury_updated_events: account::new_event_handle<TreasuryUpdatedEvent>(account)
        });
    }

    /// Process a payment with payment ID, sending the APT directly to treasury 
    /// and emitting an event with all relevant information
    public entry fun process_payment(
        payer: &signer,
        module_addr: address,
        payment_id: vector<u8>,
        additional_data: vector<u8>,
        amount: u64
    ) acquires AdminCap, EventStore {
        // Get admin cap to retrieve treasury address
        assert!(exists<AdminCap>(module_addr), ETREASURY_NOT_INITIALIZED);
        let admin_cap = borrow_global<AdminCap>(module_addr);
        let treasury_address = admin_cap.treasury_address;
        
        // Verify payment amount is above minimum
        assert!(amount >= MIN_PAYMENT_AMOUNT, EINVALID_AMOUNT);
        
        // Convert byte vectors to strings
        let payment_id_str = string::utf8(payment_id);
        let additional_data_str = string::utf8(additional_data);
        
        // Get current sender (the user who is making the payment)
        let sender = signer::address_of(payer);
        
        // Transfer APT to treasury
        coin::transfer<AptosCoin>(payer, treasury_address, amount);
        
        // Emit event for backend processing
        let event_store = borrow_global_mut<EventStore>(module_addr);
        event::emit_event(
            &mut event_store.payment_processed_events,
            PaymentProcessedEvent {
                payment_id: payment_id_str,
                sender,
                amount,
                timestamp: timestamp::now_seconds(),
                additional_data: additional_data_str,
                treasury: treasury_address
            }
        );
    }

    /// Update treasury address (admin only)
    public entry fun update_treasury(
        admin: &signer,
        module_addr: address,
        new_treasury: address
    ) acquires AdminCap, EventStore {
        let admin_addr = signer::address_of(admin);
        
        // Verify admin is the module owner
        assert!(admin_addr == module_addr, ENOT_AUTHORIZED);
        
        // Get admin cap
        let admin_cap = borrow_global_mut<AdminCap>(module_addr);
        
        // Update treasury address
        let old_treasury = admin_cap.treasury_address;
        admin_cap.treasury_address = new_treasury;
        
        // Emit event
        let event_store = borrow_global_mut<EventStore>(module_addr);
        event::emit_event(
            &mut event_store.treasury_updated_events,
            TreasuryUpdatedEvent {
                old_treasury,
                new_treasury
            }
        );
    }

    #[view]
    /// Get treasury address
    public fun get_treasury(module_addr: address): address acquires AdminCap {
        assert!(exists<AdminCap>(module_addr), ETREASURY_NOT_INITIALIZED);
        borrow_global<AdminCap>(module_addr).treasury_address
    }
    
    #[view]
    /// Get the minimum payment amount
    public fun get_min_payment_amount(): u64 {
        MIN_PAYMENT_AMOUNT
    }

    // ======== Test-only Functions ========
    #[test_only]
    public fun initialize_for_testing(account: &signer) {
        initialize(account);
    }
}