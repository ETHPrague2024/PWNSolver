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

* Mechanism for assessing credit worthiness of borrowers based on chain activity and collateral supplied
    - using The Graph to index PWN contracts to assess credit history of portolio and calculate credit metrics probability of default, loss exposure default and loss given default, taking these methodologies from traditional financial system best practicies

# Overview

Intent centric approaches to web3 design create big unlocks for UX and can simplify cross chain execution by redefining the interactions users have  with web3 protocols. Rather than requiring a user to precisely specifify  what they want to do and exactly how which can present a high barrier of entry, they simply need to sign a high level description of what they want to achieve. This trustlessly delegates the execution to a third party that is incentivised to find the optimal pathway to accomplish the desired user outcome.

We have wrapped the PWN protocol in an intent centric wrapper which enables this improved UX when loans are communicated directly on chain by the protocol or via an observer that queries the API and supplies the matchable loans to the intent adaptor contract. The mechanism by which Solvers compete to underwrite a loan also greatly simplifies implementing cross chain execution by removing the need for an explicit underlying synchronisation mechanism created by using a message passing bridge.

A summary of system interactions by time is shown below using colour coding and terms defined by the [CAKE framework](https://medium.com/@wunderlichvalentin/introducing-the-cake-framework-5a442b9cc725) proposed by Ankit Chiplunkar and Stephane Gosselin.

IMG

## Borrower requesting a loan / mortgage

IMG from pwn

* A borrower will visit the PWN app and select the collateral and loan terms going through the existing flow
* Once a loan request has been created a watcher picks up the details from the API and records it in the PWN intent adaptor contract by calling `advertiseNewLoan`. This raises an event on-chain `NewLoanAdvertised` which serves as an intent expression.
* Within this event are all the terms of the loan including collateral types and amounts, maturity dates and requested loan details including which chain the loan is being requested on.

## Credit risker evaluates risk of loan

Section about how this works

## Solver assessing risk and underwriting loan

* Solvers are constantly watching new blocks for `NewLoanAdvertised`, when a new loan request is detected, they will run logic to determine whether the loan is acceptable to them based on the terms and the risk scoring provided by the Credit Risker.
* If a solver chooses to supply inventory for a loan, it will call fulfillLoan on the PWN intent adaptor contract.
* Within the same transaction, the PWN intent adaptor (assuming the loan is open, hasn't been cancelled or already fulfilled) will transfer the inventory required to satisfy the loan and forward this to the PWN contract by calling `createLOAN`.
* Depending on the destination chain requested in the loan, the Solver will execute the fulfilment call on whichever chain is required directly without requiring a bridge or relying on a cross chain message passing mechanism.

## User repaying or defaulting

* When the borrower repays the loan, the repayment is made directly to the PWN intent adaptor which permits the Solver to call `claimLoan` on the PWN intent adaptor contract and receive their inventory and any extra in return for their loan.
* Should the borrower not repay the loan, the Solver will still call `claimLoan` on the PWN intent adaptor contract, however in this case it will trigger a process to reclaim the collateral from PWN by calling `claimLOAN`.
* For a single chain loan, the same contract is used for both repaying and claiming. For cross chain loans, it's anticipated (since this isn't supported in PWN yet) that claiming of returned inventory will occur on the loan / destination chain whereas reclaiming the collateral will be performed on the source chain. There will likely need to be some attestation as to the state of the loan provided to enable cross chain synchornisation of state within PWN contracts.

# Partners / bounties

## PWN

[Mortgage solution on PWN](https://ducttapeevents.notion.site/PWN-dcc9d2c5ec8c43a6a080997b92a56ce7)

Intent adaptor contracts:
* Sepolia :
* Holsky :

(other chains) ..

## Polygon 
[Polygon Cardona Bounty](https://ducttapeevents.notion.site/Polygon-f9931bc76a1d4701b52a59ff5edc223e)

Polygon Cardona : XXX

## Linea
[Build a dapp on Linea](https://ducttapeevents.notion.site/Linea-5b99a158b4744716a1d446b669e65f55)

Linea : XXX

## Mantle
[Best DeFi project](https://ducttapeevents.notion.site/Mantle-46e53bc8290242d897a1337cfabded62)

Mantle : XXX

## The Graph

[Best New Subgraph](https://ducttapeevents.notion.site/The-Graph-081ed2db024e4d80b133da9965616552)

Deployed subgraph: XXX
Subgraph code: XXX
How the subgraph is used:

Indexed PWN contracts to calculate and assess credit history of address requesting a loan portfolio. Calculation of credit metrics probability of default, loss exposure default and loss given default, taking these methodologies from traditional financial system best practicies to drive decision making within the Solver as to which loans to underwrite.