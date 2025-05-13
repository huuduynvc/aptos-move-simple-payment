# Aptos Move IAP Smart Contract

This project contains an Aptos Move smart contract for handling In-App Purchases (IAP) or similar payment flows.

## Prerequisites

-   [Aptos CLI](https://aptos.dev/cli-tools/aptos-cli/use-aptos-cli) installed.
-   An Aptos wallet/account for deployment and interaction, with funds for Testnet.

## Development

### Named Addresses

This contract uses a named address `iap`.

-   For local development and testing, `iap` can be a placeholder or a specific dev account address defined in `Move.toml` under `[dev-addresses]`.
    Example `Move.toml` snippet:
    ```toml
    [addresses]
    # iap = "_" # Ensure this is commented out or set to a placeholder if not using a fixed address for compilation

    [dev-addresses]
    iap = "0xCAFE" # Or any other test address
    test_admin = "0xAD"
    test_user = "0xUS"
    test_user2 = "0xU2"
    ```
-   For deployment to Testnet or Mainnet, `iap` **must** be replaced with the actual account address that will deploy and own the module.

### 1. Compile the Smart Contract

To compile the contract locally, navigate to the project root directory and run:

```bash
aptos move compile --named-addresses iap=YOUR_ACCOUNT_ADDRESS
```

Replace `YOUR_ACCOUNT_ADDRESS` with the address you intend to use or the one defined in `[dev-addresses]` if you have `iap = "_"` in `[addresses]`. If `iap` is hardcoded in `[addresses]` in `Move.toml` (e.g., `iap = "0xCAFE"`), you might not need to specify it in the command, but it's good practice for clarity, especially when preparing for deployment.

**Note:** If you have `iap = "YOUR_ACTUAL_ADDRESS"` in the `[addresses]` section of your `Move.toml`, you can simply run `aptos move compile`. However, for flexibility between local testing and deployment, it's common to use a placeholder or comment out the `iap` line in `[addresses]` and provide it at compile/publish time.

### 2. Run Unit Tests

To execute the unit tests defined in the `tests/` directory:

```bash
aptos move test
```

Ensure your `Move.toml` is configured correctly with any necessary `[dev-addresses]` for the tests to run.

## Deploying to Testnet

Follow these steps to deploy your smart contract to the Aptos Testnet.

### 1. Configure Aptos CLI for Testnet (if not already done)

If you don't have a profile for Testnet, create one:

```bash
aptos init --network testnet --profile your_testnet_profile
```

Replace `your_testnet_profile` with a name you prefer (e.g., `testnet-default`). This will guide you through creating or importing an account for Testnet. Make sure this account has some Testnet APT for gas fees. You can get Testnet APT from the [Aptos Faucet](https://aptoslabs.com/testnet-faucet).

Let's say your Testnet profile is named `testnet` and your Testnet account address is `0xYOUR_TESTNET_ACCOUNT_ADDRESS`.

### 2. Get Your Testnet Account Address

If you need to find your Testnet account address for the configured profile:
```bash
aptos config show-current-network --profile your_testnet_profile
```
Or, if it's your default profile or you only have one Testnet profile set up:
```bash
aptos account lookup-address --profile your_testnet_profile
```
(The `aptos account list --profile your_testnet_profile` command can also show addresses associated with profiles).

Let `YOUR_TESTNET_DEPLOYER_ADDRESS` be this address.

### 3. Compile for Testnet Deployment

Before deploying, compile the contract, explicitly setting the `iap` named address to your Testnet deployer address. **Important:** Ensure that the `iap` line in the `[addresses]` section of your `Move.toml` is either commented out or uses a placeholder like `_`.

```bash
aptos move compile --named-addresses iap=YOUR_TESTNET_DEPLOYER_ADDRESS --profile your_testnet_profile
```

### 4. Publish to Testnet

Publish the compiled module to Testnet:

```bash
aptos move publish --named-addresses iap=YOUR_TESTNET_DEPLOYER_ADDRESS --profile your_testnet_profile
```

This command will also prompt you to confirm the gas fees.

### 5. Initialize the Module on Testnet (if applicable)

If your module has an initialization function (e.g., `payment::initialize`), run it using your Testnet deployer account:

```bash
aptos move run \
  --function-id YOUR_TESTNET_DEPLOYER_ADDRESS::payment::initialize \
  --profile your_testnet_profile
```

(Adjust `payment::initialize` if your module name or initialize function name is different).

After these steps, your smart contract should be live on Testnet at `YOUR_TESTNET_DEPLOYER_ADDRESS`.

## Interacting with the Deployed Contract (Examples)

### View a function

```bash
aptos move view \
  --function-id YOUR_TESTNET_DEPLOYER_ADDRESS::payment::get_treasury \
  --args address:YOUR_TESTNET_DEPLOYER_ADDRESS \
  --profile your_testnet_profile
```

### Call an entry function (e.g., process_payment)

You would typically do this via a script or application, but for CLI:

```bash
aptos move run \
  --function-id YOUR_TESTNET_DEPLOYER_ADDRESS::payment::process_payment \
  --args address:YOUR_TESTNET_DEPLOYER_ADDRESS string:"test_payment_001" string:"some_data" u64:1000000 \
  --profile your_testnet_profile 
```
This assumes the `process_payment` function is called by the `payer` who is also the account associated with `your_testnet_profile`. The first `address:` argument is `module_addr`.
