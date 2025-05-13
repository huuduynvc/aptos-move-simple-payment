import { Aptos, AptosConfig, Network, Account, Ed25519PrivateKey, TransactionWorkerEventsEnum } from "@aptos-labs/ts-sdk";
import dotenv from "dotenv";

dotenv.config();

// Load environment variables
const privateKeyString = process.env.PRIVATE_KEY;
const moduleAddress = "0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46";
const minPaymentAmountStr = 1000000;
const aptosNodeUrl = process.env.APTOS_NODE_URL || "https://fullnode.testnet.aptoslabs.com/v1";

if (!privateKeyString) {
  throw new Error("PRIVATE_KEY is not set in the .env file");
}
if (!moduleAddress) {
  throw new Error("MODULE_ADDRESS is not set in the .env file");
}
if (!minPaymentAmountStr) {
    throw new Error("MIN_PAYMENT_AMOUNT is not set in the .env file");
}

const minPaymentAmount = BigInt(minPaymentAmountStr);

// --- Configuration ---
const PAYMENT_ID = `test-payment-${Date.now()}`; // Example dynamic payment ID
const ADDITIONAL_DATA = "client_script_test";
const PAYMENT_AMOUNT = minPaymentAmount; // Send the minimum required amount

// Initialize Aptos SDK
const config = new AptosConfig({ network: Network.TESTNET, fullnode: aptosNodeUrl }); // Use TESTNET
const aptos = new Aptos(config);

// Create Account object from private key
const privateKey = new Ed25519PrivateKey(privateKeyString);
const account = Account.fromPrivateKey({ privateKey });

console.log(`Using account: ${account.accountAddress.toString()}`);
console.log(`Using module address: ${moduleAddress}`);
console.log(`Using Testnet node: ${aptosNodeUrl}`);
console.log(`Minimum payment amount: ${minPaymentAmount.toString()} Octa`);
console.log(`Sending payment ID: ${PAYMENT_ID}`);
console.log(`Sending amount: ${PAYMENT_AMOUNT.toString()} Octa`);

async function sendPayment() {
  console.log("\nSending payment transaction...");

  if (PAYMENT_AMOUNT < minPaymentAmount) {
      console.error(`Error: Payment amount ${PAYMENT_AMOUNT} is less than the minimum required amount ${minPaymentAmount}.`);
      return;
  }

  try {
    // Convert strings to Uint8Array for vector<u8> arguments
    const paymentIdBytes = new TextEncoder().encode(PAYMENT_ID);
    const additionalDataBytes = new TextEncoder().encode(ADDITIONAL_DATA);


    const transaction = await aptos.transaction.build.simple({
        sender: account.accountAddress,
        data: {
            // Function name is `${moduleAddress}::${moduleName}::${functionName}`
            function: `${moduleAddress}::payment::process_payment`,
            functionArguments: [
                moduleAddress, // module_addr: address
                paymentIdBytes, // payment_id: vector<u8>
                additionalDataBytes, // additional_data: vector<u8>
                PAYMENT_AMOUNT.toString(), // amount: u64 (pass as string)
            ],
        },
    });

    console.log("  Transaction built. Simulating...");

    // Simulate the transaction (optional but recommended)
    const simulation = await aptos.transaction.simulate.simple({
        signerPublicKey: account.publicKey,
        transaction: transaction,
    });

    // Check simulation results
    if (!simulation[0].success) {
        console.error(`  Transaction simulation failed: ${simulation[0].vm_status}`);
        // Log detailed simulation result if needed
        // console.error(JSON.stringify(simulation[0], null, 2));
        return;
    }
    console.log(`  Simulation successful. Estimated gas used: ${simulation[0].gas_used}`);

    console.log("  Submitting transaction...");
    const submittedTxn = await aptos.transaction.submit.simple({
        transaction: transaction,
        senderAuthenticator: aptos.transaction.sign({ signer: account, transaction }),
    });

    console.log(`  Transaction submitted with hash: ${submittedTxn.hash}`);
    console.log("  Waiting for transaction confirmation...");

    const executedTxn = await aptos.transaction.waitForTransaction({ transactionHash: submittedTxn.hash });

    console.log("\nTransaction confirmed:");
    console.log(`  Hash: ${executedTxn.hash}`);
    console.log(`  Version: ${executedTxn.version}`);
    console.log(`  Gas used: ${executedTxn.gas_used}`);
    console.log(`  Status: ${executedTxn.vm_status}`);
    console.log(`  Success: ${executedTxn.success}`);
    console.log(`  Explorer URL: https://explorer.aptoslabs.com/txn/${executedTxn.hash}?network=testnet`);

  } catch (error: any) {
    console.error("\nError sending payment:", error.message || error);
    if (error.response?.data) {
        console.error("Aptos API Error:", JSON.stringify(error.response.data, null, 2));
    }
  }
}

sendPayment(); 