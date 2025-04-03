# Create a native segwit address and get the public key from the address.
addr=$(bitcoin-cli -regtest getnewaddress "" bech32)
bitcoin-cli -regtest getaddressinfo addr | jq -r '.pubkey'
