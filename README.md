# PWNly Fans

Reversing the polarity of Banks with x-chain Intents. Made with ❤️ in Prague for 🇨🇿 ETH Prague 2024 by [Konrad](https://github.com/konradstrachan), [David](https://github.com/davd-ops), [Daniel](https://github.com/DanielHighETH) and [Andrei](https://github.com/Yazep).

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

A sumamry of system interactions by time is shown below using colour coding and terms defined by the [CAKE framework](https://medium.com/@wunderlichvalentin/introducing-the-cake-framework-5a442b9cc725) proposed by Ankit Chiplunkar and Stephane Gosselin.

