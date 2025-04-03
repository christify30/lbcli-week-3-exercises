# Create a partially signed transaction from the details below

# Amount of 20,000,000 satoshis to this address: 2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP 
# Use the UTXOs from the transaction below
# Set parameters
WALLET_NAME="psbt_wallet"
TARGET_ADDRESS="2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP"
AMOUNT_SATS=20000000  # 20,000,000 satoshis
FEE_SATS=1000         # 1,000 satoshis

# Create the wallet if it doesn't exist
if ! bitcoin-cli -regtest listwallets | grep -q "$WALLET_NAME"; then
  bitcoin-cli -regtest createwallet "$WALLET_NAME" >/dev/null
fi

# Get a new address for change
TARGET_ADDRESS=$(bitcoin-cli -regtest getnewaddress "" "p2sh-segwit")

# Define the raw transaction
transaction="01000000000101c8b0928edebbec5e698d5f86d0474595d9f6a5b2e4e3772cd9d1005f23bdef772500000000ffffffff0276b4fa0000000000160014f848fe5267491a8a5d32423de4b0a24d1065c6030e9c6e000000000016001434d14a23d2ba08d3e3edee9172f0c97f046266fb0247304402205fee57960883f6d69acf283192785f1147a3e11b97cf01a210cf7e9916500c040220483de1c51af5027440565caead6c1064bac92cb477b536e060f004c733c45128012102d12b6b907c5a1ef025d0924a29e354f6d7b1b11b5a7ddff94710d6f0042f3da800000000"

# Decode the raw transaction to extract inputs and outputs
decoded_tx=$(bitcoin-cli -regtest decoderawtransaction "$transaction")
txid=$(echo "$decoded_tx" | jq -r '.txid')

# Extract the outputs
vout0=$(echo "$decoded_tx" | jq '.vout[0]')
vout1=$(echo "$decoded_tx" | jq '.vout[1]')

# Calculate amount and address for both outputs
amount0_sats=$(echo "$vout0" | jq '.value' | awk '{printf "%d", $1 * 100000000}')
address0=$(echo "$vout0" | jq -r '.scriptPubKey.address')
amount1_sats=$(echo "$vout1" | jq '.value' | awk '{printf "%d", $1 * 100000000}')
address1=$(echo "$vout1" | jq -r '.scriptPubKey.address')

# Calculate total input and change amount
total_input=$(awk "BEGIN {print $amount0_sats + $amount1_sats}")
change=$(awk "BEGIN {print $total_input - $AMOUNT_SATS - $FEE_SATS}")

# Convert amounts to BTC
amount_btc=$(awk "BEGIN {printf \"%.8f\", $AMOUNT_SATS/100000000}")
change_btc=$(awk "BEGIN {printf \"%.8f\", $change/100000000}")

# Create raw transaction with the specified outputs
raw_tx=$(bitcoin-cli -regtest createrawtransaction \
  "[{\"txid\":\"$txid\", \"vout\":0}, {\"txid\":\"$txid\", \"vout\":1}]" \
  "{\"$TARGET_ADDRESS\": $amount_btc, \"$address0\": $change_btc}")

# Convert the raw transaction to PSBT
psbt=$(bitcoin-cli -regtest converttopsbt "$raw_tx")
echo "$psbt"

