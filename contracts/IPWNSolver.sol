// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IPWNSimpleLoan {
    function createLOAN(
        address loanTermsFactoryContract,
        bytes calldata loanTermsFactoryData,
        bytes calldata signature,
        bytes calldata loanAssetPermit,
        bytes calldata collateralPermit
    ) external returns (uint256 loanId);

    function claimLOAN(uint256 loanId) external;
}

contract PWNLoan is IERC721Receiver {

    address constant LOAN_TERMS_CONTRACT = address(0x9Cb87eC6448299aBc326F32d60E191Ef32Ab225D);
    uint256 constant NON_NFT = type(uint256).max;
    enum LoanState { Offered, Filled, Refunded, Cancelled, Claimed }

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
    IPWNSimpleLoan public pwnSimpleLoan;

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

    event LoanClaimed(
        uint256 loanId
    );

    constructor() {
        pwnSimpleLoan = IPWNSimpleLoan(0x4188C513fd94B0458715287570c832d9560bc08a);
    }

    function getLoanKey(uint256 chainId, uint256 loanId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(chainId, "_", loanId));
    }

    function getLoan(uint256 chainId, uint256 loanId) public view returns (Loan memory) {
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
            tokenLoanRepaymentAmount: tokenLoanRepaymentAmount,
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
        uint256 loanId,
        bytes signature,
        bytes loanTermsData
    ) public payable {
        // This is not the right chain to fill this loan on
        require(block.chainid == chainId, "Invalid chain ID");

        bytes32 loanHash = getLoanKey(chainId, loanId);
        Loan storage loan = loans[loanHash];

        require(loan.state == LoanState.Offered, "Loan is not available for fulfillment");

        pwnSimpleLoan.createLOAN(
            LOAN_TERMS_CONTRACT,
            loanTermsData,
            signature,
            bytes(0x00),
            bytes(0x00)
        );

        loan.state = LoanState.Filled;
        loan.filler = msg.sender;
        emit LoanFilled(loanId);
    }

    function claimLoan(
        uint256 chainId,
        uint256 loanId
    ) public {
        bytes32 loanHash = getLoanKey(chainId, loanId);
        Loan storage loan = loans[loanHash];

        require(loan.state == LoanState.Filled, "Loan is not available for claiming");
        require(loan.advertiser == msg.sender, "Only the advertiser can claim the loan");

        bool isCollateralNFT = loan.tokenCollateralIndex != NON_NFT;
        bool isLoanNFT = loan.tokenLoanIndex != NON_NFT;

        (uint256 initialCollateralBalance, uint256 initialLoanBalance) = checkBalances(
            loan.tokenCollateralAddress,
            loan.tokenCollateralIndex,
            loan.tokenLoanAddress,
            loan.tokenLoanIndex,
            isCollateralNFT,
            isLoanNFT
        );

        pwnSimpleLoan.claimLOAN(loanId);

        (uint256 finalCollateralBalance, uint256 finalLoanBalance) = checkBalances(
            loan.tokenCollateralAddress,
            loan.tokenCollateralIndex,
            loan.tokenLoanAddress,
            loan.tokenLoanIndex,
            isCollateralNFT,
            isLoanNFT
        );

        // Transfer tokens to the advertiser based on balance change
        if ((finalCollateralBalance - initialCollateralBalance) == loan.tokenCollateralAmount) {
            if (isCollateralNFT) {
                IERC721(loan.tokenCollateralAddress).safeTransferFrom(address(this), loan.advertiser, loan.tokenCollateralIndex);
            } else {
                IERC20(loan.tokenCollateralAddress).transfer(loan.advertiser, loan.tokenCollateralAmount);
            }
        } else if ((finalLoanBalance - initialLoanBalance) == loan.tokenLoanRepaymentAmount) {
            if (isLoanNFT) {
                IERC721(loan.tokenLoanAddress).safeTransferFrom(address(this), loan.advertiser, loan.tokenLoanIndex);
            } else {
                IERC20(loan.tokenLoanAddress).transfer(loan.advertiser, loan.tokenLoanRepaymentAmount);
            }
        } else {
            revert("Invalid token balance change");
        }

        loan.state = LoanState.Claimed;
        emit LoanClaimed(loanId);
    }

    function checkBalances(
        address tokenCollateralAddress,
        uint256 tokenCollateralIndex,
        address tokenLoanAddress,
        uint256 tokenLoanIndex,
        bool isCollateralNFT,
        bool isLoanNFT
    ) internal view returns (uint256, uint256) {
        uint256 collateralBalance;
        uint256 loanBalance;
        if (isCollateralNFT) {
            collateralBalance = IERC721(tokenCollateralAddress).ownerOf(tokenCollateralIndex) == address(this) ? 1 : 0;
        } else {
            collateralBalance = IERC20(tokenCollateralAddress).balanceOf(address(this));
        }

        if (isLoanNFT) {
            loanBalance = IERC721(tokenLoanAddress).ownerOf(tokenLoanIndex) == address(this) ? 1 : 0;
        } else {
            loanBalance = IERC20(tokenLoanAddress).balanceOf(address(this));
        }

        return (collateralBalance, loanBalance);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
