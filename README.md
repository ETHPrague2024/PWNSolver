# PWNly Fans

Reversing the polarity of Banks with x-chain Intents. Made with ❤️ in Prague for 🇨🇿 ETH Prague 2024 by [Konrad](https://github.com/konradstrachan), [David](https://github.com/davd-ops), [Daniel](https://github.com/DanielHighETH) and [Andrei](https://github.com/Yazep).

# Problem solved

* Rather than having to rely on banks or traditional lenders, PWN allows anyone to request a loan for any purpose
* Loans are currently only P2P which requires a borrower to organise (or wait for) someone to lend them the funds
* By making PWN an intent centric protocol, loan requests can be sent to solver networks who already have inventory and will compete to fulfil orders
* Matching borrowers with lenders with inventory solves a key issue of counter party discovery

# Core features

* PWN loans now support intent centric counterparty discovery with Solvers able to source and supply inventory to facilitate loans they wish to underwrite
    - Using PWN finance contracts to facilitate loans whilst building all new Intent expression and advertising layer along with example Solver to fill orders

* Support for supplying PWN loans cross chain
    - NOTE: this extends the base functionality assuming PWN emits loan offers with loan token requests on different chains, for now this part is simulated in the code to work around this limitation

* Mechanism for assessing credit risk of borrowers and whole portfolio based on chain activity and collateral supplied
    - using The Graph to index PWN contracts to assess credit history of portolio and calculate credit risk metrics, based on traditional financial system best practicies, plus developed logistic regression model to predict default probabilities (trained on real data) and create credit scores expert model for better lending decisions

# Overview

Intent centric approaches to web3 design create big unlocks for UX and can simplify cross chain execution by redefining the interactions users have  with web3 protocols. Rather than requiring a user to precisely specifify  what they want to do and exactly how which can present a high barrier of entry, they simply need to sign a high level description of what they want to achieve. This trustlessly delegates the execution to a third party that is incentivised to find the optimal pathway to accomplish the desired user outcome.

We have wrapped the PWN protocol in an intent centric wrapper which enables this improved UX when loans are communicated directly on chain by the protocol or via an observer that queries the API and supplies the matchable loans to the intent adaptor contract. The mechanism by which Solvers compete to underwrite a loan also greatly simplifies implementing cross chain execution by removing the need for an explicit underlying synchronisation mechanism created by using a message passing bridge.

A summary of system interactions by time is shown below using colour coding and terms defined by the [CAKE framework](https://medium.com/@wunderlichvalentin/introducing-the-cake-framework-5a442b9cc725) proposed by Ankit Chiplunkar and Stephane Gosselin.

<img width="1364" alt="image" src="https://github.com/ETHPrague2024/PWNSolver/assets/21056525/cb4f21e2-c5b5-44f8-8a6c-b7ae01965e1a">

## Borrower requesting a loan / mortgage

<img width="932" alt="image" src="https://github.com/ETHPrague2024/PWNSolver/assets/21056525/c85f7b58-8076-475d-8e02-999d96ae5e29">

* A borrower will visit the PWN app and select the collateral and loan terms going through the existing flow
* Once a loan request has been created a watcher picks up the details from the API and records it in the PWN intent adaptor contract by calling `advertiseNewLoan`. This raises an event on-chain `NewLoanAdvertised` which serves as an intent expression.
* Within this event are all the terms of the loan including collateral types and amounts, maturity dates and requested loan details including which chain the loan is being requested on.

## Credit risker evaluates risk of loan

To calculate loan risk, we've incorporated traditional finance metrics and added three core features:
 - Portfolio Credit Risk Metrics: Using The Graph to gather the entire transaction history, we calculate metrics to monitor and manage the risk of **existed loans**, providing valuable insights for LPs.
 - PD Model for New Loans: We trained a logistic regression model on historical data to evaluate the probability of default (PD) for **new loans**, offering LPs a clearer understanding of loan risk.
 - On-Chain Credit Scores: By analyzing on-chain data, we calculate credit scores to facilitate data-driven decisions for **new loan** funding.

Using The Graph, we indexed the entire history of loans. This data allows us to calculate crucial risk metrics such as observed default rate, loss given default, and exposure at default. In traditional finance, these metrics are essential for risk management of a portfolio and for calculating capital and provisions. They provide a deeper understanding of the risk and potential losses for liquidity providers (LPs).

![image](https://github.com/ETHPrague2024/PWNSolver/assets/70756146/9e4754cb-027c-4dac-8a1d-8a93df0c28b3)

With this indexed data, we developed a model to calculate the probability of default for potential loans using logistic regression. This model, trained on historical data, helps predict the likelihood of default for each loan. This information enables LPs to better understand and assess the potential risk of loans before making decisions.

Additionally, we created an expert model to calculate a credit score for loan applicants, which aids the solver in making more data-driven decisions. The risk parameters considered include the user's on-chain data such as the first transaction date, the number of tokens held, the current value of holdings, the total value of transactions, and NFTs. Accounts with more activity and funds receive higher ratings. This data is obtained from Etherscan. Customers with the lowest rating (5) will unfortunately be rejected for loans. In the future, we plan to incorporate more advanced credit scoring models.

## Solver assessing risk and underwriting loan

* Solvers are constantly watching new blocks for `NewLoanAdvertised`, when a new loan request is detected, they will run logic to determine whether the loan is acceptable to them based on the terms and the risk scoring provided by the Credit Risker.
* If a solver chooses to supply inventory for a loan, it will call fulfillLoan on the PWN intent adaptor contract.
* Within the same transaction, the PWN intent adaptor (assuming the loan is open, hasn't been cancelled or already fulfilled) will transfer the inventory required to satisfy the loan and forward this to the PWN contract by calling `createLOAN`.
* Depending on the destination chain requested in the loan, the Solver will execute the fulfilment call on whichever chain is required directly without requiring a bridge or relying on a cross chain message passing mechanism.


![image](https://github.com/ETHPrague2024/PWNSolver/assets/21056525/32516c4a-638a-4bb0-874b-8f1f16b4365c)
Example of how the exanple Solver detects and fills a loan across multiple chains.

## User repaying or defaulting

* When the borrower repays the loan, the repayment is made directly to the PWN intent adaptor which permits the Solver to call `claimLoan` on the PWN intent adaptor contract and receive their inventory and any extra in return for their loan.
* Should the borrower not repay the loan, the Solver will still call `claimLoan` on the PWN intent adaptor contract, however in this case it will trigger a process to reclaim the collateral from PWN by calling `claimLOAN`.
* For a single chain loan, the same contract is used for both repaying and claiming. For cross chain loans, it's anticipated (since this isn't supported in PWN yet) that claiming of returned inventory will occur on the loan / destination chain whereas reclaiming the collateral will be performed on the source chain. There will likely need to be some attestation as to the state of the loan provided to enable cross chain synchornisation of state within PWN contracts.

# Partners / bounties

## PWN

[Mortgage solution on PWN](https://ducttapeevents.notion.site/PWN-dcc9d2c5ec8c43a6a080997b92a56ce7)

Intent adaptor contracts:
* Sepolia : [0x0cb8f458ee463674ccc190dda4067f136ada69c2](https://sepolia.etherscan.io/address/0x0cb8f458ee463674ccc190dda4067f136ada69c2)
* Holsky : [0xa93f9e2ca26af5dbc1538e56b031c367bd200c89](https://holesky.beaconcha.in/address/0xa93f9e2ca26af5dbc1538e56b031c367bd200c89)

(other chains) ..

## Polygon 
[Polygon Cardona Bounty](https://ducttapeevents.notion.site/Polygon-f9931bc76a1d4701b52a59ff5edc223e)

Polygon Cardona : [0x7b6aceC5eA36DD5ef5b0639B8C1d0Dab59DdcF03](https://cardona-zkevm.polygonscan.com/address/0x7b6aceC5eA36DD5ef5b0639B8C1d0Dab59DdcF03)

## Linea
[Build a dapp on Linea](https://ducttapeevents.notion.site/Linea-5b99a158b4744716a1d446b669e65f55)

Linea : [0x4dc36fcc192c042fc49fe934d86e8942d79c4e93](https://sepolia.lineascan.build/address/0x4dc36fcc192c042fc49fe934d86e8942d79c4e93)

## Mantle
[Best DeFi project](https://ducttapeevents.notion.site/Mantle-46e53bc8290242d897a1337cfabded62)

Mantle : [0x4DC36FCc192c042fC49Fe934D86E8942D79c4e93](https://explorer.sepolia.mantle.xyz/address/0x4DC36FCc192c042fC49Fe934D86E8942D79c4e93)

## Optimism
[Prototype a Superchain Superpower](https://ducttapeevents.notion.site/Optimism-9ea2a5d799764ec7b49bbda3a890fd62)

Optimism : [0x0E293e65a871Bf3bdF6DB2924407DC94D0410BFB](https://sepolia-optimism.etherscan.io/address/0x0e293e65a871bf3bdf6db2924407dc94d0410bfb)

## The Graph

![image](https://github.com/ETHPrague2024/PWNSolver/assets/70756146/3640fb91-b9c9-48f3-9223-820ece632fee)

[Best New Subgraph](https://ducttapeevents.notion.site/The-Graph-081ed2db024e4d80b133da9965616552)

Deployed subgraph: https://testnet.thegraph.com/explorer/subgraphs/GWRoHvkHuuih5ims2RraW4TH5Vn2cnftifv1FLWF2dvE?view=Overview&chain=arbitrum-sepolia

Subgraph code: https://github.com/ETHPrague2024/thegraph/tree/main/pwn-graph

How the subgraph is used:
The subgraph indexes the entire history of loans from PWN contracts, serving two key purposes:
- Portfolio Credit Risk Assessment: Historical data from The Graph is used to calculate traditional risk metrics such as probability of default, loss given default, and exposure at default, following best practices from the traditional financial system.
- PD Model Training: Historical data is utilized to train a model that predicts the probability of default for potential new loans, enhancing risk assessment capabilities.


