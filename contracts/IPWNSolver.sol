// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PWNLoan {

    uint256 constant NON_NFT = type(uint256).max;
    enum LoanState { Offered, Filled, Refunded, Cancelled }

    struct Loan {
        address tokenCollateralAddress;
        uint256 tokenCollateralAmount;
        uint256 tokenCollateralIndex;
        address tokenLoanAddress;
        uint256 tokenLoanAmount;
        uint256 tokenLoanIndex;
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
        address tokenCollateralAddress,
        uint256 tokenCollateralAmount,
        uint256 tokenCollateralIndex,
        address tokenLoanAddress,
        uint256 tokenLoanAmount,
        uint256 tokenLoanIndex,
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
        address tokenCollateralAddress,
        uint256 tokenCollateralAmount,
        uint256 tokenCollateralIndex,
        address tokenLoanAddress,
        uint256 tokenLoanAmount,
        uint256 tokenLoanIndex,
        uint256 durationOfLoanSeconds,
        uint256 chainId,
        uint256 loanId
    ) public {
        bytes32 loanHash = getLoanKey(chainId, loanId);

        loans[loanHash] = Loan({
            tokenCollateralAddress: tokenCollateralAddress,
            tokenCollateralAmount: tokenCollateralAmount,
            tokenCollateralIndex: tokenCollateralIndex,
            tokenLoanAddress: tokenLoanAddress,
            tokenLoanAmount: tokenLoanAmount,
            tokenLoanIndex: tokenLoanIndex,
            durationOfLoanSeconds: durationOfLoanSeconds,
            advertiser: msg.sender,
            chainId: chainId,
            loanId: loanId,
            state: LoanState.Offered
        });

        emit NewLoanAdvertised(
            loanId,
            chainId,
            tokenCollateralAddress,
            tokenCollateralAmount,
            tokenCollateralIndex,
            tokenLoanAddress,
            tokenLoanAmount,
            tokenLoanIndex,
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
        if (loan.tokenLoanIndex == NON_NFT) {
            IERC20 token = IERC20(loan.tokenLoanAddress);
            require(token.transferFrom(msg.sender, address(this), loan.tokenLoanAmount), "ERC20 transfer failed");
        } else {
            IERC721 token = IERC721(loan.tokenLoanAddress);
            token.safeTransferFrom(msg.sender, address(this), loan.tokenLoanIndex);
        }

        loan.state = LoanState.Filled;
        emit LoanFilled(loanId);
    }
}
