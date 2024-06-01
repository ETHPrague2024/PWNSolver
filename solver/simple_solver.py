from web3 import Web3, HTTPProvider
from web3.middleware import geth_poa_middleware

import time
import requests

chain_contract_abi = [{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":False,"inputs":[{"indexed":False,"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"LoanClaimed","type":"event"},{"anonymous":False,"inputs":[{"indexed":False,"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"LoanFilled","type":"event"},{"anonymous":False,"inputs":[{"indexed":False,"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"LoanOfferRevoked","type":"event"},{"anonymous":False,"inputs":[{"indexed":False,"internalType":"address","name":"borrowerAddress","type":"address"},{"indexed":False,"internalType":"uint256","name":"loanID","type":"uint256"},{"indexed":False,"internalType":"uint256","name":"chainIdLoan","type":"uint256"},{"indexed":False,"internalType":"address","name":"tokenCollateralAddress","type":"address"},{"indexed":False,"internalType":"uint256","name":"tokenCollateralAmount","type":"uint256"},{"indexed":False,"internalType":"uint256","name":"tokenCollateralIndex","type":"uint256"},{"indexed":False,"internalType":"address","name":"tokenLoanAddress","type":"address"},{"indexed":False,"internalType":"uint256","name":"tokenLoanAmount","type":"uint256"},{"indexed":False,"internalType":"uint256","name":"tokenLoanIndex","type":"uint256"},{"indexed":False,"internalType":"uint256","name":"tokenLoanRepaymentAmount","type":"uint256"},{"indexed":False,"internalType":"uint256","name":"durationOfLoanSeconds","type":"uint256"}],"name":"NewLoanAdvertised","type":"event"},{"inputs":[{"internalType":"address","name":"borrowerAddress","type":"address"},{"internalType":"address","name":"tokenCollateralAddress","type":"address"},{"internalType":"uint256","name":"tokenCollateralAmount","type":"uint256"},{"internalType":"uint256","name":"tokenCollateralIndex","type":"uint256"},{"internalType":"address","name":"tokenLoanAddress","type":"address"},{"internalType":"uint256","name":"tokenLoanAmount","type":"uint256"},{"internalType":"uint256","name":"tokenLoanIndex","type":"uint256"},{"internalType":"uint256","name":"tokenLoanRepaymentAmount","type":"uint256"},{"internalType":"uint256","name":"durationOfLoanSeconds","type":"uint256"},{"internalType":"uint256","name":"chainIdLoan","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"advertiseNewLoan","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"chainIdCollateral","type":"uint256"},{"internalType":"uint256","name":"chainIdLoan","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"claimLoan","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"chainIdCollateral","type":"uint256"},{"internalType":"uint256","name":"chainIdLoan","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"},{"internalType":"bytes","name":"signature","type":"bytes"},{"internalType":"bytes","name":"loanTermsData","type":"bytes"}],"name":"fulfillLoan","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"getLoan","outputs":[{"components":[{"internalType":"address","name":"tokenCollateralAddress","type":"address"},{"internalType":"uint256","name":"tokenCollateralAmount","type":"uint256"},{"internalType":"uint256","name":"tokenCollateralIndex","type":"uint256"},{"internalType":"address","name":"tokenLoanAddress","type":"address"},{"internalType":"uint256","name":"tokenLoanAmount","type":"uint256"},{"internalType":"uint256","name":"tokenLoanIndex","type":"uint256"},{"internalType":"uint256","name":"tokenLoanRepaymentAmount","type":"uint256"},{"internalType":"uint256","name":"durationOfLoanSeconds","type":"uint256"},{"internalType":"address","name":"advertiser","type":"address"},{"internalType":"address","name":"filler","type":"address"},{"internalType":"uint256","name":"chainIdLoan","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"},{"internalType":"enum PWNLoan.LoanState","name":"state","type":"uint8"}],"internalType":"struct PWNLoan.Loan","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"loans","outputs":[{"internalType":"address","name":"tokenCollateralAddress","type":"address"},{"internalType":"uint256","name":"tokenCollateralAmount","type":"uint256"},{"internalType":"uint256","name":"tokenCollateralIndex","type":"uint256"},{"internalType":"address","name":"tokenLoanAddress","type":"address"},{"internalType":"uint256","name":"tokenLoanAmount","type":"uint256"},{"internalType":"uint256","name":"tokenLoanIndex","type":"uint256"},{"internalType":"uint256","name":"tokenLoanRepaymentAmount","type":"uint256"},{"internalType":"uint256","name":"durationOfLoanSeconds","type":"uint256"},{"internalType":"address","name":"advertiser","type":"address"},{"internalType":"address","name":"filler","type":"address"},{"internalType":"uint256","name":"chainIdLoan","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"},{"internalType":"enum PWNLoan.LoanState","name":"state","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"address","name":"from","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"onERC721Received","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"pwnSimpleLoan","outputs":[{"internalType":"contract IPWNSimpleLoan","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"chainIdCollateral","type":"uint256"},{"internalType":"uint256","name":"loanId","type":"uint256"}],"name":"revokeLoanOffer","outputs":[],"stateMutability":"nonpayable","type":"function"}]

wallet_sepolia_user_pub = "0x347D03041d4Dbb2b61144275E28FDc31ACb89722"
wallet_sepolia_user_prv = "e894145ac0c444e3c43b131f6771bac1da08824e8a451ed3e800ed4ff97a8452"

chain_details = { 
    11155111: {
        "name": "Sepolia",
        "contract" : Web3.to_checksum_address("0x3c05f4027a670d82f3a372b77abb01c2be727332"),
        "rpc": "https://sepolia.infura.io/v3/791e2242a4194fb4aa2e431c350b8bf3"
    },
    17000: {
        "name": "Holsky",
        "contract" : Web3.to_checksum_address("0xE2246Fc87b4E6dac9EA97C0965b03D74DBFBaeF4"),
        "rpc": "https://holesky.infura.io/v3/791e2242a4194fb4aa2e431c350b8bf3"
    }
}

chain_to_watch_for_events = 11155111

pending_loan_claims = []

def handle_event(event):
    print(f"🌟 Event detected: {event['event']} ")
    return event['args']

def watch_for_new_loan_intent():
    print(F"🤖 SOLVER: Watching for new loan intent on chain [{chain_to_watch_for_events}]..")
    contract_address = chain_details[chain_to_watch_for_events]['contract']
    w3 = Web3(HTTPProvider(chain_details[chain_to_watch_for_events]['rpc']))

    contract = w3.eth.contract(address=contract_address, abi=chain_contract_abi)

    filter_from_block = "latest"
    
    event_name = "NewLoanAdvertised"
    event_filter = contract.events[event_name].create_filter(fromBlock=filter_from_block)

    while True:
        for event in event_filter.get_new_entries():
            return handle_event(event)
        
def decide_whether_to_loan_funds(args):
    print(f"🌟 Loan chain [{args['chainIdLoan']}] time [{args['durationOfLoanSeconds']}]s")
    print(f"▶️ Collateral token [{args['tokenCollateralAddress']}] amount [{args['tokenCollateralAmount']}]")
    print(f"◀️ Loan token [{args['tokenLoanAddress']}] amount [{args['tokenLoanAmount']}]")

    if args['tokenCollateralAddress'] != args['tokenLoanAddress']:
        print("❌ Tokens are different, loan not accepted")
        return False
    
    if args['tokenCollateralAmount'] < args['tokenLoanAmount']:
        print("❌ Loan not attractively priced")
        return False
    # Call the rating API
    user_address = args['borrowerAddress']
    rating_response = requests.get(f"http://localhost:8000/rating/{user_address}")
    if rating_response.status_code != 200:
        print(f"❌ Failed to fetch rating for address {user_address}")
        return False
    
    rating = rating_response.json()['rating']
    print(f"⭐️ Rating for user {user_address}: {rating}")

    # Decide based on rating
    if rating > 4:
        print("❌ User rating too low, loan not accepted")
        return False

    return True

def set_allowance(w3, private_key, args, spender, destination_chain):
    token_contract_address = args['tokenLoanAddress']
    allowance_amount = args['tokenLoanAmount']
    
    erc20_abi = [{"constant": False,"inputs": [{"name": "_spender","type": "address"},{"name": "_value","type": "uint256"}],"name": "approve","outputs": [{"name": "","type": "bool"}],"type": "function"}]
    token_contract = w3.eth.contract(address=token_contract_address, abi=erc20_abi)
    
    account_address = wallet_sepolia_user_pub
    nonce = w3.eth.get_transaction_count(account_address)

    tx = token_contract.functions.approve(spender, allowance_amount).build_transaction({
        'gas': 5000000,
        'gasPrice': w3.to_wei('60', 'gwei'),
        'nonce': nonce
    })
    
    signed_transaction = w3.eth.account.sign_transaction(tx, private_key=private_key)
    tx_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"✅ Allowance tx sent chain [{destination_chain}]. Transaction Hash: {receipt['transactionHash'].hex()}")

def submit_loan_fill(args):
    destination_chain = args['chainIdLoan']
    w3 = Web3(HTTPProvider(chain_details[destination_chain]['rpc']))

    contract = w3.eth.contract(address=chain_details[destination_chain]['contract'], abi=chain_contract_abi)
    account_address = wallet_sepolia_user_pub

    value_to_send = 0
    if args['tokenLoanAddress'] == "0x0000000000000000000000000000000000000000":
        value_to_send = args['tokenLoanAmount']
    else:
        # set allowance on ERC20 tokens so the contract can take the funds
        print("🤖 SOLVER: Setting token allowance for fill..")
        set_allowance(w3, wallet_sepolia_user_prv, args, chain_details[destination_chain]['contract'], destination_chain)

    # TODO handle the case where the loan is an NFT

    print("🤖 SOLVER: Submitting loan fill bid for intent..")

    # TODO Construct paramters for function
    signature = bytes()
    loanTermsData = bytes()

    # Assume the chain we are watching for events is also the collateral (source) chain
    chainIdCollateral = chain_to_watch_for_events

    transaction_data = contract.functions.fulfillLoan(
        chainIdCollateral,
        args['chainIdLoan'],
        args['loanID'],
        signature,
        loanTermsData
    ).build_transaction({
        'from': account_address,
        'gas': 2000000,
        'gasPrice': w3.to_wei('60', 'gwei'),
        'nonce': w3.eth.get_transaction_count(account_address),
        'value': value_to_send
    })

    signed_transaction = w3.eth.account.sign_transaction(transaction_data, wallet_sepolia_user_prv)
    transaction_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(transaction_hash)

    pending_loan = {
        "claimed": False,
        "claim_timestamp": time.time() + args['durationOfLoanSeconds'],
        "chain_id": chainIdCollateral,
        "loan_id": args['loanID']
    }

    pending_loan_claims.append(pending_loan)

    print(f"✅ Tx sent chain [{destination_chain}]. Transaction Hash: {receipt['transactionHash'].hex()}")

def claim_loan(args):
    # Assumed we are waiting to begin with
    num_waiting_claims = 1
    while num_waiting_claims > 0:
        time.sleep(2)
        num_waiting_claims = 0

        for pending_loan_claim in pending_loan_claims:
            if pending_loan_claim['claimed'] is True:
                continue
            if pending_loan_claim['claim_timestamp'] > time.time():
                print(f"⌛ loan [{args['loanID']}] not yet claimable..")
                num_waiting_claims += 1
                continue

            # Else claim
            print(f"⌛ Attempting to claim loan that has expired..")
            w3 = Web3(HTTPProvider(chain_details[args['chainIdLoan']]['rpc']))

            contract = w3.eth.contract(address=chain_details[args['chainIdLoan']]['contract'], abi=chain_contract_abi)

            account_address = wallet_sepolia_user_pub

            # Assume the chain we are watching for events is also the collateral (source) chain
            chainIdCollateral = chain_to_watch_for_events

            transaction_data = contract.functions.claimLoan(
                chainIdCollateral,
                args['chainIdLoan'],
                args['loanID']
            ).build_transaction({
                'from': account_address,
                'gas': 2000000,
                'gasPrice': w3.to_wei('60', 'gwei'),
                'nonce': w3.eth.get_transaction_count(account_address),
                'value': 0
            })

            signed_transaction = w3.eth.account.sign_transaction(transaction_data, wallet_sepolia_user_prv)
            transaction_hash = w3.eth.send_raw_transaction(signed_transaction.rawTransaction)

            print(f"✅ Claim tx sent chain [{chainIdCollateral}]. Transaction Hash: {transaction_hash.hex()}")
        

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

    #115792089237316195423570985008687907853269984665640564039457584007913129639935