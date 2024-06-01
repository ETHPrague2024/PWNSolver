from web3 import Web3, HTTPProvider
from web3.middleware import geth_poa_middleware

import time
from datetime import datetime

chain_contract_abi = [{"anonymous":False,"inputs":[{"indexed":False,"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"LoanFilled","type":"event"},{"anonymous":False,"inputs":[{"indexed":False,"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"LoanOfferRevoked","type":"event"},{"anonymous":False,"inputs":[{"indexed":False,"internalType":"uint256","name":"loanID","type":"uint256"},{"indexed":False,"internalType":"uint256","name":"chainId","type":"uint256"},{"indexed":False,"internalType":"address","name":"tokenCollateralAddress","type":"address"},{"indexed":False,"internalType":"uint256","name":"tokenCollateralAmount","type":"uint256"},{"indexed":False,"internalType":"uint256","name":"tokenCollateralIndex","type":"uint256"},{"indexed":False,"internalType":"address","name":"tokenLoanAddress","type":"address"},{"indexed":False,"internalType":"uint256","name":"tokenLoanAmount","type":"uint256"},{"indexed":False,"internalType":"uint256","name":"tokenLoanIndex","type":"uint256"},{"indexed":False,"internalType":"uint256","name":"durationOfLoanSeconds","type":"uint256"}],"name":"NewLoanAdvertised","type":"event"},{"inputs":[{"internalType":"address","name":"tokenCollateralAddress","type":"address"},{"internalType":"uint256","name":"tokenCollateralAmount","type":"uint256"},{"internalType":"uint256","name":"tokenCollateralIndex","type":"uint256"},{"internalType":"address","name":"tokenLoanAddress","type":"address"},{"internalType":"uint256","name":"tokenLoanAmount","type":"uint256"},{"internalType":"uint256","name":"tokenLoanIndex","type":"uint256"},{"internalType":"uint256","name":"durationOfLoanSeconds","type":"uint256"},{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"advertiseNewLoan","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"fulfillLoan","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"loans","outputs":[{"internalType":"address","name":"tokenCollateralAddress","type":"address"},{"internalType":"uint256","name":"tokenCollateralAmount","type":"uint256"},{"internalType":"uint256","name":"tokenCollateralIndex","type":"uint256"},{"internalType":"address","name":"tokenLoanAddress","type":"address"},{"internalType":"uint256","name":"tokenLoanAmount","type":"uint256"},{"internalType":"uint256","name":"tokenLoanIndex","type":"uint256"},{"internalType":"uint256","name":"durationOfLoanSeconds","type":"uint256"},{"internalType":"address","name":"advertiser","type":"address"},{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"},{"internalType":"enum PWNLoan.LoanState","name":"state","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"revokeLoanOffer","outputs":[],"stateMutability":"nonpayable","type":"function"}]
rpc_url_sepolia = "https://sepolia.infura.io/v3/791e2242a4194fb4aa2e431c350b8bf3"

contract_address_sepolia = Web3.to_checksum_address("0x2b40c96d55e32B94cD5DcD112eE07FAbd4D1419F")

sepolia_testnet_chainid = 11155111

wallet_sepolia_user_pub = "0x347D03041d4Dbb2b61144275E28FDc31ACb89722"
wallet_sepolia_user_prv = "e894145ac0c444e3c43b131f6771bac1da08824e8a451ed3e800ed4ff97a8452"

pending_loan_claims = []

def handle_event(event):
    print(f"🌟 Event detected: {event['event']} ")
    return event['args']

def watch_for_new_loan_intent():
    print("🤖 SOLVER: Watching for new loan intent event..")
    contract_address = contract_address_sepolia

    w3 = Web3(HTTPProvider(rpc_url_sepolia))

    contract = w3.eth.contract(address=contract_address, abi=chain_contract_abi)

    filter_from_block = 6013408#"latest"
    
    event_name = "NewLoanAdvertised"
    event_filter = contract.events[event_name].create_filter(fromBlock=filter_from_block)

    while True:
        for event in event_filter.get_new_entries():
            return handle_event(event)
        
def decide_whether_to_loan_funds(args):
    print(f"🌟 Loan chain [{args['chainId']}] time [{args['durationOfLoanSeconds']}]s")
    print(f"▶️ Collateral token [{args['tokenCollateralAddress']}] amount [{args['tokenCollateralAmount']}]")
    print(f"◀️ Loan token [{args['tokenLoanAddress']}] amount [{args['tokenLoanAmount']}]")

    if args['tokenCollateralAddress'] != args['tokenLoanAddress']:
        print("❌ Tokens are different, loan not accepted")
        return False
    
    if args['tokenCollateralAmount'] < args['tokenLoanAmount']:
        print("❌ Loan not attractively priced")
        return False

    return True

def set_allowance(web3, account, private_key, args, spender):
    token_contract_address = args['tokenLoanAddress']
    allowance_amount = args['tokenLoanAmount']
    
    erc20_abi = [{"constant": False,"inputs": [{"name": "_spender","type": "address"},{"name": "_value","type": "uint256"}],"name": "approve","outputs": [{"name": "","type": "bool"}],"type": "function"}]
    token_contract = web3.eth.contract(address=token_contract_address, abi=erc20_abi)
    
    nonce = web3.eth.getTransactionCount(account)
    tx = token_contract.functions.approve(spender, allowance_amount).buildTransaction({
        'chainId': 1,  # Mainnet chain ID; change if using testnet
        'gas': 2000000,
        'gasPrice': web3.toWei('20', 'gwei'),
        'nonce': nonce
    })
    
    signed_tx = web3.eth.account.sign_transaction(tx, private_key=private_key)
    tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)
    receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    print(f"✅ Allowance transaction sent. Transaction Hash: {receipt.hex()}")

def submit_loan_fill(args):
    print("🤖 SOLVER: Submitting loan fill bid for intent..")

    w3 = Web3(HTTPProvider(rpc_url_sepolia))

    contract = w3.eth.contract(address=contract_address_sepolia, abi=chain_contract_abi)
    account_address = wallet_sepolia_user_pub

    nonce = w3.eth.get_transaction_count(account_address)

    value_to_send = 0
    if args['tokenLoanAddress'] == "0x0000000000000000000000000000000000000000":
        value_to_send = args['tokenLoanAmount']
    else:
        # set allowance on ERC20 tokens so the contract can take the funds
        set_allowance(w3, contract_address_sepolia, wallet_sepolia_user_prv, args, contract_address_sepolia)

    # TODO handle the case where the loan is an NFT

    transaction_data = contract.functions.fulfillLoan(
        args['chainId'],
        args['loanID']
    ).build_transaction({
        'from': account_address,
        'gas': 2000000,
        'gasPrice': w3.to_wei('20', 'gwei'),
        'nonce': nonce,
        'value': value_to_send
    })

    signed_transaction = w3.eth.account.sign_transaction(transaction_data, wallet_sepolia_user_prv)
    transaction_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)

    pending_loan = {
        "claimed": False,
        "claim_timestamp": 0,
        "chain_id":0,
        "loan_id":0
    }

    pending_loan_claims.append(pending_loan)
    args['durationOfLoanSeconds']

    print(f"✅ Transaction sent. Transaction Hash: {transaction_hash.hex()}")

def claim_loan(args):
    # Assumed we are waiting to begin with
    num_waiting_claims = 1
    while num_waiting_claims > 0:
        time.sleep(2)
        num_waiting_claims = 0

        for pending_loan_claim in pending_loan_claims:
            if pending_loan_claim['claimed'] is True:
                continue
            if pending_loan_claim['claim_timestamp'] > datetime.now():
                print(f"⌛ loan [{args['loanID']}] not yet claimable")
                num_waiting_claims += 1
                continue

            # Else claim
            print(f"⌛ Attempting to claim loan that has expired..")
            w3 = Web3(HTTPProvider(rpc_url_sepolia))

            contract = w3.eth.contract(address=contract_address_sepolia, abi=chain_contract_abi)

            account_address = wallet_sepolia_user_pub
            nonce = w3.eth.get_transaction_count(account_address)

            transaction_data = contract.functions.claimLoan(
                args['chainId'],
                args['loanID']
            ).build_transaction({
                'from': account_address,
                'gas': 2000000,
                'gasPrice': w3.to_wei('20', 'gwei'),
                'nonce': nonce,
                'value': 0
            })

            signed_transaction = w3.eth.account.sign_transaction(transaction_data, wallet_sepolia_user_prv)
            transaction_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)

            print(f"✅ Claim transaction sent. Transaction Hash: {transaction_hash.hex()}")
        

def main():
    print("")
    print("PWNly Fans Intent filler")
    print("----------------------------------------------")
    print("")

    while True:
        args = watch_for_new_loan_intent()
        should_loan = decide_whether_to_loan_funds(args)
        if should_loan:
            print("🤖 SOLVER: decided to loan funds ✅")
            submit_loan_fill(args)
            claim_loan(args)
        else:
            print("🤖 SOLVER: decided NOT to loan funds ❌")
        print("")

if __name__ == "__main__":
    main()