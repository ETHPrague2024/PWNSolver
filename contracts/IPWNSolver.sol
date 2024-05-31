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
        uint256 tokenLoanRepaymentAmount;
        uint256 durationOfLoanSeconds;
        address advertiser;
        address filler;
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
        uint256 tokenLoanRepaymentAmount,
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

    function getLoan(uint256 chainId, uint256 loanId) public pure returns(Loan) {
        bytes32 loanHash = getLoanKey(chainId, loanId);
        return loans[loanHash];
    }

    function advertiseNewLoan(
        address tokenCollateralAddress,
        uint256 tokenCollateralAmount,
        uint256 tokenCollateralIndex,
        address tokenLoanAddress,
        uint256 tokenLoanAmount,
        uint256 tokenLoanIndex,
        uint256 tokenLoanRepaymentAmount,
        uint256 durationOfLoanSeconds,
        uint256 chainId,
        uint256 loanId
    ) public {

        bytes32 loanHash = getLoanKey(chainId, loanId);

        // Check if the loanHash already exists
        require(loans[loanHash].advertiser == address(0), "Loan already exists");

        loans[loanHash] = Loan({
            tokenCollateralAddress: tokenCollateralAddress,
            tokenCollateralAmount: tokenCollateralAmount,
            tokenCollateralIndex: tokenCollateralIndex,
            tokenLoanAddress: tokenLoanAddress,
            tokenLoanAmount: tokenLoanAmount,
            tokenLoanIndex: tokenLoanIndex,
            tokenLoanRepaymentAmount : tokenLoanRepaymentAmount,
            durationOfLoanSeconds: durationOfLoanSeconds,
            advertiser: msg.sender,
            filler: address(0),
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
            tokenLoanRepaymentAmount,
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
    ) public payable {
        // This is not the right chain to fill this loan on
        // TODO - make this x-chain, for now reject fills for other chains
        require(block.chainid == chainId, "Invalid chain ID");

        bytes32 loanHash = getLoanKey(chainId, loanId);
        Loan storage loan = loans[loanHash];

        require(loan.state == LoanState.Offered, "Loan is not available for fulfillment");

        // Transfer collateral tokens to the contract
        // TODO execute a transfer to the PWN contract to fill the loan
        if(loan.tokenLoanIndex == 0x0000000000000000000000000000000000000000) {
            // Native token
            require(msg.value == loan.tokenLoanAmount, "Incorrect tx value");
        }
        else if (loan.tokenLoanIndex == NON_NFT) {
            // ERC20 token
            IERC20 token = IERC20(loan.tokenLoanAddress);
            require(token.transferFrom(msg.sender, address(this), loan.tokenLoanAmount), "ERC20 transfer failed");
        } else {
            // ERC 721 token
            IERC721 token = IERC721(loan.tokenLoanAddress);
            token.safeTransferFrom(msg.sender, address(this), loan.tokenLoanIndex);
        }

        loan.state = LoanState.Filled;
        loan.filler = msg.sender;
        emit LoanFilled(loanId);
    }

    function claimOverdueLoanCollateral(
        uint256 chainId,
        uint256 loanId
    ) public {
        
        bytes32 loanHash = getLoanKey(chainId, loanId);
        require(loan.state == LoanState.Filled, "Loan not filled");
        require(loan.filler == msg.sender, "Only loan sender can reclaim");

        // TODO store time at which the loan was filled?
        //      and then check whether enough time has passed
        //      to initiate a claim on loan inventory?
        require(false, "unimplemented");
    }

}
