// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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
        uint256 loanID,
        uint256 chainId,
        address[] tokenCollateralAddresses,
        uint256[] tokenCollateralAmounts,
        uint256[] tokenCollateralIndexes,
        address[] tokenLoanAddresses,
        uint256[] tokenLoanAmounts,
        uint256[] tokenLoanIndexes,
        uint256 durationOfLoanSeconds
    );

    event LoanFilled(
        uint256 loanId
    );

    event LoanOfferRevoked(
        uint256 loanId
    );

    function getLoanKey(uint256 chainId, uint256 loanId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(chainId, "_", loanId));
    }

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

        bytes32 loanHash = getLoanKey(chainId, loanId);

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
            loanId,
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
        bytes32 loanHash = getLoanKey(chainId, loanId);
        Loan storage loan = loans[loanHash];

        require(loan.advertiser == msg.sender, "Only the advertiser can revoke the loan offer");
        require(loan.state == LoanState.Offered, "Loan offer cannot be revoked");

        loan.state = LoanState.Cancelled;

        emit LoanOfferRevoked(loanId);
    }

    function fulfillLoan(
        uint256 chainId,
        uint256 loanId
    ) public {
        // This is not the right chain to fill this loan on
        // TODO - make this x-chain, for now reject fills for other chains
        require(block.chainid == chainId, "Invalid chain ID");

        bytes32 loanHash = getLoanKey(chainId, loanId);
        Loan storage loan = loans[loanHash];

        require(loan.state == LoanState.Offered, "Loan is not available for fulfillment");

        // Transfer collateral tokens to the contract
        // TODO execute a transfer to the PWN contract to fill the loan
        for (uint256 i = 0; i < loan.tokenLoanAddresses.length; i++) {
            if (loan.tokenLoanIndexes[i] == NON_NFT) {
                IERC20 token = IERC20(loan.tokenLoanAddresses[i]);
                require(token.transferFrom(msg.sender, address(this), loan.tokenLoanAmounts[i]), "ERC20 transfer failed");
            } else {
                IERC721 token = IERC721(loan.tokenLoanAddresses[i]);
                token.safeTransferFrom(msg.sender, address(this), loan.tokenLoanIndexes[i]);
            }
        }

        loan.state = LoanState.Filled;
        emit LoanFilled(loanId);
    }
}
