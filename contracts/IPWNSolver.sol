// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PWNLoan {

    uint256 constant NON_NFT = type(uint256).max;
    enum LoanState { Offered, Filled, Refunded, Cancelled }

    struct Loan {
        address[] tokenCollateralAddresses;
        uint256[] tokenCollateralAmounts;
        uint256[] tokenCollateralIndexes;
        address[] tokenLoanAddresses;
        uint256[] tokenLoanAmounts;
        uint256[] tokenLoanIndexes;
        uint256 durationOfLoanSeconds;
        address advertiser;
        uint256 chainId;
        uint256 loanId;
        LoanState state;
    }

    mapping(bytes32 => Loan) public loans;

    event NewLoanAdvertised(
        bytes32 loanID,
        uint256 chainId,
        address[] tokenCollateralAddresses,
        uint256[] tokenCollateralAmounts,
        uint256[] tokenCollateralIndexes,
        address[] tokenLoanAddresses,
        uint256[] tokenLoanAmounts,
        uint256[] tokenLoanIndexes,
        uint256 durationOfLoanSeconds
    );

    event LoanOfferRevoked(
        uint256 chainId,
        uint256 loanId
    );

    function advertiseNewLoan(
        address[] calldata tokenCollateralAddresses,
        uint256[] calldata tokenCollateralAmounts,
        uint256[] calldata tokenCollateralIndexes,
        address[] calldata tokenLoanAddresses,
        uint256[] calldata tokenLoanAmounts,
        uint256[] calldata tokenLoanIndexes,
        uint256 durationOfLoanSeconds,
        uint256 chainId,
        uint256 loanId
    ) public {
        require(
            tokenCollateralAddresses.length == tokenCollateralAmounts.length && 
            tokenCollateralAddresses.length == tokenCollateralIndexes.length,
            "Collateral array lengths must match"
        );

        require(
            tokenLoanAddresses.length == tokenLoanAmounts.length && 
            tokenLoanAddresses.length == tokenLoanIndexes.length,
            "Loan array lengths must match"
        );

        bytes32 loanHash = keccak256(abi.encodePacked(chainId, "_", loanId));

        loans[loanHash] = Loan({
            tokenCollateralAddresses: tokenCollateralAddresses,
            tokenCollateralAmounts: tokenCollateralAmounts,
            tokenCollateralIndexes: tokenCollateralIndexes,
            tokenLoanAddresses: tokenLoanAddresses,
            tokenLoanAmounts: tokenLoanAmounts,
            tokenLoanIndexes: tokenLoanIndexes,
            durationOfLoanSeconds: durationOfLoanSeconds,
            advertiser: msg.sender,
            chainId: chainId,
            loanId: loanId,
            state: LoanState.Offered
        });

        emit NewLoanAdvertised(
            loanHash,
            chainId,
            tokenCollateralAddresses,
            tokenCollateralAmounts,
            tokenCollateralIndexes,
            tokenLoanAddresses,
            tokenLoanAmounts,
            tokenLoanIndexes,
            durationOfLoanSeconds);
    }

    function revokeLoanOffer(
        uint256 chainId,
        uint256 loanId
    ) public {
        bytes32 loanHash = keccak256(abi.encodePacked(chainId, "_", loanId));
        Loan storage loan = loans[loanHash];

        require(loan.advertiser == msg.sender, "Only the advertiser can revoke the loan offer");
        require(loan.state == LoanState.Offered, "Loan offer cannot be revoked");

        loan.state = LoanState.Cancelled;

        emit LoanOfferRevoked(chainId, loanId);
    }
}
