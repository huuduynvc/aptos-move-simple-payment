import { Aptos, AptosConfig, Network, AptosApiError, AccountAddress, type GetEventsResponse } from "@aptos-labs/ts-sdk";
import cron from "node-cron";
import dotenv from "dotenv";

dotenv.config({ path: '../../.env' }); // Load .env file from root

// --- Configuration ---
const MODULE_ADDRESS_RAW = "0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46";
const APTOS_NODE_URL = process.env.APTOS_NODE_URL || "https://fullnode.testnet.aptoslabs.com/v1";
const CRON_SCHEDULE = "*/10 * * * * *"; // Run every 30 seconds for testing
const MAX_EVENTS_PER_FETCH = 100; // Increased for debugging

// MODULE_ADDRESS_RAW is already a full hex string with 0x
// const MODULE_ADDRESS = AccountAddress.from(MODULE_ADDRESS_RAW); // Not strictly needed if using RAW string directly for event type

const aptosConfig = new AptosConfig({ network: Network.TESTNET, fullnode: APTOS_NODE_URL });
const aptos = new Aptos(aptosConfig);

// --- State ---
// For debugging, set to undefined to fetch all available events initially, or a specific low SN
let lastProcessedSequenceNumber: bigint | undefined = undefined; 
console.log(`Initial lastProcessedSequenceNumber: ${lastProcessedSequenceNumber}`);

// --- Event Structure (ensure this matches your Move event) ---
interface PaymentProcessedEvent {
    payment_id: string;
    sender: string; // address
    amount: string; // u64 as string
    timestamp: string; // u64 as string
    additional_data: string;
    treasury: string; // address
}

// Construct the fully qualified event type using the raw module address string (which includes 0x)
const EVENT_TYPE = `${MODULE_ADDRESS_RAW}::payment::PaymentProcessedEvent` as const;

console.log(`Starting backend cron job...`);
console.log(` - Module Address (Raw for Event Type): ${MODULE_ADDRESS_RAW}`);
console.log(` - Account Address for API Query: ${AccountAddress.from(MODULE_ADDRESS_RAW).toString()}`); // For querying account events
console.log(` - Listening for event: ${EVENT_TYPE}`);
console.log(` - Network: ${Network.TESTNET}`);
console.log(` - Cron Schedule: ${CRON_SCHEDULE}`);
console.log(` - MAX_EVENTS_PER_FETCH: ${MAX_EVENTS_PER_FETCH}`);

async function fetchAndProcessEvents() {
    console.log(`\n[${new Date().toISOString()}] Running event fetch task. Current lastProcessedSN: ${lastProcessedSequenceNumber}`);

    try {
        const events: GetEventsResponse = await aptos.getAccountEventsByEventType({
            accountAddress: AccountAddress.from(MODULE_ADDRESS_RAW), // API needs AccountAddress object here
            eventType: EVENT_TYPE,
            options: {
                limit: MAX_EVENTS_PER_FETCH,
            },
        });

        // Log raw events received from API before any filtering
        console.log(`  Raw events received from API (${events.length}):`, JSON.stringify(events.map(e => ({ sn: e.sequence_number, type: e.type })), null, 2));

        if (events.length === 0) {
            console.log("  No new events found in this batch from API.");
            return;
        }

        let newEventsProcessed = 0;
        // Process in ascending order of sequence number (API returns newest first)
        for (const event of events.reverse()) { 
            const currentSequenceNumber = BigInt(event.sequence_number);

            if (lastProcessedSequenceNumber === undefined || currentSequenceNumber > lastProcessedSequenceNumber) {
                console.log(`  Processing event #${currentSequenceNumber} (data: ${JSON.stringify(event.data)})...`);
                newEventsProcessed++;

                const eventData = event.data as PaymentProcessedEvent;
                console.log(`    - Payment ID: ${eventData.payment_id}`);
                console.log(`    - Sender: ${eventData.sender}`);
                console.log(`    - Amount: ${eventData.amount} Octa`);
                console.log(`    - Treasury: ${eventData.treasury}`);
                console.log(`    - Timestamp: ${new Date(parseInt(eventData.timestamp) * 1000).toISOString()}`);
                console.log(`    - Additional Data: ${eventData.additional_data}`);

                lastProcessedSequenceNumber = currentSequenceNumber; // Update here after successful processing intent
            } 
        }
        if (newEventsProcessed > 0) {
             console.log(`  Processed ${newEventsProcessed} new event(s). New lastProcessedSN: ${lastProcessedSequenceNumber}`);
        } else {
            console.log("  No new events after filtering logic based on sequence number.");
        }

    } catch (error: any) {
        if (error instanceof AptosApiError && error.status === 404) {
            console.error(`  Error fetching events: Event type ${EVENT_TYPE} not found or EventStore not initialized at ${MODULE_ADDRESS_RAW}. Ensure the module is deployed and initialized.`);
        } else {
            console.error(`  Error fetching or processing events:`, error.message || error);
            if (error.response?.data) {
                console.error("  Aptos API Error details:", JSON.stringify(error.response.data, null, 2));
            }
        }
    }
}

// Schedule the task
cron.schedule(CRON_SCHEDULE, fetchAndProcessEvents, {
    scheduled: true,
    timezone: "Etc/UTC" // Optional: Set your timezone
});

// Run once immediately on startup
fetchAndProcessEvents();

console.log(`\nCron job scheduled. Waiting for the next run...`); 