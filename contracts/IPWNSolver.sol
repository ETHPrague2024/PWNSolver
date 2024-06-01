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
    bytes constant EMPTY_BYTES = "";
    enum LoanState { Offered, Filled, Cancelled, Claimed, OutcomeOtherChain }

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
        uint256 chainIdLoan;
        uint256 loanId;
        LoanState state;
    }

    mapping(bytes32 => Loan) public loans;
    IPWNSimpleLoan public pwnSimpleLoan;

    event NewLoanAdvertised(
        address borrowerAddress,
        uint256 loanID,
        uint256 chainIdLoan,
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
        address borrowerAddress,
        address tokenCollateralAddress,
        uint256 tokenCollateralAmount,
        uint256 tokenCollateralIndex,
        address tokenLoanAddress,
        uint256 tokenLoanAmount,
        uint256 tokenLoanIndex,
        uint256 tokenLoanRepaymentAmount,
        uint256 durationOfLoanSeconds,
        uint256 chainIdLoan,
        uint256 loanId
    ) public {

        bytes32 loanHash = getLoanKey(block.chainid, loanId);

        require(loans[loanHash].advertiser == address(0), "Loan already exists");

        LoanState state = LoanState.Offered;
        if (block.chainid != chainIdLoan) {
            state = LoanState.OutcomeOtherChain;
        }

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
            chainIdLoan: chainIdLoan,
            loanId: loanId,
            state: state
        });

        emit NewLoanAdvertised(
            borrowerAddress,
            loanId,
            chainIdLoan,
            tokenCollateralAddress,
            tokenCollateralAmount,
            tokenCollateralIndex,
            tokenLoanAddress,
            tokenLoanAmount,
            tokenLoanIndex,
            tokenLoanRepaymentAmount,
            durationOfLoanSeconds
        );
    }

    function revokeLoanOffer(
        uint256 chainIdCollateral,
        uint256 loanId
    ) public {
        bytes32 loanHash = getLoanKey(chainIdCollateral, loanId);
        Loan storage loan = loans[loanHash];

        // Limitation - no atomicity between source and destination chain so 
        // disallow revoking of offers since we can't tell the state of the loan
        require(block.chainid == loan.chainIdLoan, "Filling is on another chain, unable to revoke");

        require(loan.advertiser == msg.sender, "Only the advertiser can revoke the loan offer");
        require(loan.state == LoanState.Offered, "Loan offer cannot be revoked");

        loan.state = LoanState.Cancelled;
        emit LoanOfferRevoked(loanId);
    }

    function fulfillLoan(
        uint256 chainIdCollateral,
        uint256 chainIdLoan,
        uint256 loanId,
        bytes calldata signature,
        bytes calldata loanTermsData
    ) public payable {
        if (chainIdCollateral == chainIdLoan) {
            // same chain
            require(block.chainid == chainIdCollateral, "Wrong chain");
  
            bytes32 loanHash = getLoanKey(chainIdCollateral, loanId);
            Loan storage loan = loans[loanHash];

            require(block.chainid == loan.chainIdLoan, "Filling is on another chain, unable to fill");
            require(loan.state == LoanState.Offered, "Loan offer not in a state to be filled");

            pwnSimpleLoan.createLOAN(
                LOAN_TERMS_CONTRACT,
                loanTermsData,
                signature,
                EMPTY_BYTES,
                EMPTY_BYTES
            );

            loan.state = LoanState.Filled;
            loan.filler = msg.sender;

        } else {
            // x-chain

            require(block.chainid == chainIdLoan, "Wrong chain");

            // TODO : we can't create the loan on this chain since PWN doesn't currently
            // support x-chain loans, however we would call into the pwn contract here
            // to initialise the loan and supply the inventory
        }

        emit LoanFilled(loanId);
    }

    function claimLoan(
        uint256 chainIdCollateral,
        uint256 chainIdLoan,
        uint256 loanId
    ) public {
        // NOTE: assumption here is that claiming always is initiated on the source chain
        // meaning if a loan has defaulted the collateral is supplied directly OR if a loan
        // has been repaid, this triggers a PWN process which credits the funds on the destination chain

        require(block.chainid == chainIdCollateral, "Invalid chain ID");

        bytes32 loanHash = getLoanKey(chainIdCollateral, loanId);
        Loan storage loan = loans[loanHash];

        require(loan.state == LoanState.Filled, "Loan is not available for claiming");

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

        if ((finalCollateralBalance - initialCollateralBalance) == loan.tokenCollateralAmount) {
            transferCollateral(loan.tokenCollateralAddress, loan.tokenCollateralIndex, loan.tokenCollateralAmount, isCollateralNFT, loan.advertiser);
        } else if ((finalLoanBalance - initialLoanBalance) == loan.tokenLoanRepaymentAmount) {
            transferLoan(loan.tokenLoanAddress, loan.tokenLoanIndex, loan.tokenLoanRepaymentAmount, isLoanNFT, loan.advertiser);
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

    function transferCollateral(
        address tokenCollateralAddress,
        uint256 tokenCollateralIndex,
        uint256 tokenCollateralAmount,
        bool isCollateralNFT,
        address to
    ) internal {
        if (isCollateralNFT) {
            IERC721(tokenCollateralAddress).safeTransferFrom(address(this), to, tokenCollateralIndex);
        } else {
            IERC20(tokenCollateralAddress).transfer(to, tokenCollateralAmount);
        }
    }

    function transferLoan(
        address tokenLoanAddress,
        uint256 tokenLoanIndex,
        uint256 tokenLoanRepaymentAmount,
        bool isLoanNFT,
        address to
    ) internal {
        if (isLoanNFT) {
            IERC721(tokenLoanAddress).safeTransferFrom(address(this), to, tokenLoanIndex);
        } else {
            IERC20(tokenLoanAddress).transfer(to, tokenLoanRepaymentAmount);
        }
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
