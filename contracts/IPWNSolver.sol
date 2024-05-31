// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PWNLoan {

    uint256 constant NON_NFT = type(uint256).max;
    uint256 public loanCount = 0;

    struct Loan {
        address[] tokenAddresses;
        uint256[] tokenAmounts;
        uint256[] tokenIndexes;
        uint256 durationOfLoanSeconds;
        address advertiser;
    }

    mapping(uint256 => Loan) public loans;

    event NewLoanAdvertised(
        uint256 loanID,
        address[] tokenAddresses,
        uint256[] tokenAmounts,
        uint256[] tokenIndexes,
        uint256 durationOfLoanSeconds
    );

    function advertiseNewLoan(
        address[] memory tokenAddresses,
        uint256[] memory tokenAmounts,
        uint256[] memory tokenIndexes,
        uint256 durationOfLoanSeconds
    ) public {
        require(
            tokenAddresses.length == tokenAmounts.length && 
            tokenAddresses.length == tokenIndexes.length,
            "Array lengths must match"
        );

        loans[loanCount] = Loan({
            tokenAddresses: tokenAddresses,
            tokenAmounts: tokenAmounts,
            tokenIndexes: tokenIndexes,
            durationOfLoanSeconds: durationOfLoanSeconds,
            advertiser: msg.sender
        });

        emit NewLoanAdvertised(loanCount, tokenAddresses, tokenAmounts, tokenIndexes, durationOfLoanSeconds);
        loanCount++;
    }
}
