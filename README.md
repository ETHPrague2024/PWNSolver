# PWNly Fans

Core features

* PWN loans now support intent centric counterparty discovery with Solvers able to source and supply inventory to facilitate loans they wish to underwrite
    - Using PWN finance contracts to facilitate loans whilst building all new Intent expression and advertising layer along with example Solver to fill orders

* Support for supplying PWN loans cross chain
    - NOTE: this extends the base functionality assuming PWN emits loan offers with loan token requests on different chains, for now this part is simulated in the code to work around this limitation

* Mechanism for assessing credit worthiness of borrowers based on chain activity and collateral supplied
    - using The Graph to index PWN contracts to assess credit history of portolio and calculate credit metrics probability of default, loss exposure default and loss given default, taking these methodologies from traditional financial system best practicies