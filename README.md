C:\Users\PC\Documents\aptos-move-iap-smc> aptos move publish --named-addresses iap=0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46
Compiling, may take a little while to download git dependencies...
UPDATING GIT DEPENDENCY https://github.com/aptos-labs/aptos-framework.git
INCLUDING DEPENDENCY AptosFramework
INCLUDING DEPENDENCY AptosStdlib
INCLUDING DEPENDENCY MoveStdlib
BUILDING iap_payment
package size 3366 bytes
Do you want to submit a transaction for a range of [226300 - 339400] Octas at a gas unit price of 100 Octas? [yes/no] >
yes
Transaction submitted: https://explorer.aptoslabs.com/txn/0x845d6927170855740ddf35ed50b1bb2b464b0654b646c81994f868eb7be7ea45?network=testnet
{
  "Result": {
    "transaction_hash": "0x845d6927170855740ddf35ed50b1bb2b464b0654b646c81994f868eb7be7ea45",
    "gas_used": 2263,
    "gas_unit_price": 100,
    "sender": "b75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46",
    "sequence_number": 3,
    "success": true,
    "timestamp_us": 1747110992074230,
    "version": 6719752244,
    "vm_status": "Executed successfully"
  }
}

PS C:\Users\PC\Documents\aptos-move-iap-smc> aptos move run --function-id 0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46::payment::initialize
Do you want to submit a transaction for a range of [92500 - 138700] Octas at a gas unit price of 100 Octas? [yes/no] >
yes
Transaction submitted: https://explorer.aptoslabs.com/txn/0x98ba12d189907cdee40696e268cb04cc556bb01c1105ded6c5782a1ea2cc3cc9?network=testnet
{
  "Result": {
    "transaction_hash": "0x98ba12d189907cdee40696e268cb04cc556bb01c1105ded6c5782a1ea2cc3cc9",
    "gas_used": 925,
    "gas_unit_price": 100,
    "sender": "b75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46",
    "sequence_number": 4,
    "success": true,
    "timestamp_us": 1747111023055458,
    "version": 6719753177,
    "vm_status": "Executed successfully"
  }
}

PS C:\Users\PC\Documents\aptos-move-iap-smc> aptos config show-profiles
{
  "Result": {
    "default": {
      "network": "Testnet",
      "has_private_key": true,
      "public_key": "ed25519-pub-0x5c96843daabb67c43dd68ddee9aa88cf2b3d63b3f09910aa2d7f4c574afd7796",
      "account": "b75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46",
      "rest_url": "https://fullnode.testnet.aptoslabs.com"
    }
  }
}

PS C:\Users\PC\Documents\aptos-move-iap-smc> aptos move compile --named-addresses iap=0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46

PC@DESKTOP-3J9VRFO MINGW64 ~/Documents/aptos-move-iap-smc
$         aptos move run \
            --function-id 0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46::payment::process_payment \    
            --args address:0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46 string:"low_amount_payment" string:"" u64:1000000
Do you want to submit a transaction for a range of [1600 - 2400] Octas at a gas unit price of 100 Octas? [yes/no] >
yes
Transaction submitted: https://explorer.aptoslabs.com/txn/0xd0d22b5ee35676408b98843cc5c5de858aa6e11bca409915e58e87b4590e06b8?network=testnet
{
  "Result": {
    "transaction_hash": "0xd0d22b5ee35676408b98843cc5c5de858aa6e11bca409915e58e87b4590e06b8",
    "gas_used": 16,
    "gas_unit_price": 100,
    "sender": "b75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46",
    "sequence_number": 7,
    "success": true,
    "timestamp_us": 1747112036666671,
    "version": 6719783239,
    "vm_status": "Executed successfully"
  }
}

PC@DESKTOP-3J9VRFO MINGW64 ~/Documents/aptos-move-iap-smc
$ aptos move view     --function-id 0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46::payment::get_treasury     --args address:0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46
{
  "Result": [
    "0xbb424495ab94d46f42d50aac7b95f87095d82d14707c13a70093c59db946eee2"
  ]
}

PC@DESKTOP-3J9VRFO MINGW64 ~/Documents/aptos-move-iap-smc
$ aptos move run \
    --function-id 0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46::payment::update_treasury \
    --args address:0xb75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46 address:0xbb424495ab94d46f42d50aac7b95f87095d82d14707c13a70093c59db946eee2
Do you want to submit a transaction for a range of [600 - 900] Octas at a gas unit price of 100 Octas? [yes/no] >
yes
Transaction submitted: https://explorer.aptoslabs.com/txn/0xc115a5f233099609e94e83a92b7c542d5a753e738a174b07ab7aa851da83646c?network=testnet
{
  "Result": {
    "transaction_hash": "0xc115a5f233099609e94e83a92b7c542d5a753e738a174b07ab7aa851da83646c",
    "gas_used": 6,
    "gas_unit_price": 100,
    "sender": "b75e963711fc8fe9cd058900bb86dd3a6ec6e5e94c908ca083e04ab2b6337c46",
    "sequence_number": 5,
    "success": true,
    "timestamp_us": 1747111820955414,
    "version": 6719776921,
    "vm_status": "Executed successfully"
  }
}