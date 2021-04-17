//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Wallet.sol"
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @author Jack Proudfoot
 * @dev Primary contract for providing Decent Loans. Handles loan applications, Decent Loan Token creation, loan payments, and distribution payments.
 *
 * Escrow functionality inspired by: https://github.com/axic/ethereum-tokenescrow/blob/master/tokenescrow.sol
 */
contract LoanApplication is Ownable, CloneFactory18{
    string private _baseuri = "www.decent.com/applications/";

    address private _loanTokenContract;
    address private _stablecoinContract;
    address private _walletAddress;

    uint256 private _totalApplications = 0;

    mapping (uint256 => Escrow) public escrows;

    mapping (uint256 => address) _loanTokens;
    mapping (address => bool) _validToken;

    struct Escrow {
        uint256 tokenAmount;
        uint256 tokenReceived;
        address recipient;
    }

    event LoanApplicationCreated(uint256 id);
    event LoanApplicationSupported(uint256 id, uint256 amount);


    /**
    * @dev Sets the values for {baseuri} and {loanTokenContract}
    */
    constructor (string memory baseuri_, address loanTokenContract_, address stablecoinContract_, address walletAddress_) {
        _baseuri = baseuri_;
        _loanTokenContract = loanTokenContract_;
        _stablecoinContract = stablecoinContract_;
        _walletAddress = walletAddress_;
    }

    /** 
    * @dev Create a new loan application with principle balance of `tokenAmount` 
    */
    function createLoan(uint256 tokenAmount) public return uint256 {
        uint256 _loanID = _totalApplications;
        
        escrows[_loanID] = Escrow(tokenAmount, 0, msg.sender);

        _totalApplications += 1;

        LoanApplicationCreated(_loanID);

        address _newLoanToken = createClone(_loanTokenContract);
        LoanToken(_newLoanToken).init(_loanID, _walletAddress, tokenAmount);
        
        _loanTokens[_loanID] = _newLoanToken;
        _validToken[_newLoanToken] = true;

        return _loanID;
    }

    /** 
    * @dev Provide `amount` tokens to the escrow for loan `loanID` in exchange for Decent Loan Tokens
    */
    function supportLoan(uint256 loanID, uint256 amount) public {
        require(loanID < _totalApplications);
        require(escrows[loanID].tokenAmount > 0);
        require(escrows[loanID].tokenAmount > escrows[loanID].tokenReceived);

        uint256 balanceToSend = amount;
        if (escrows[loanID].tokenAmount - escrows[loanID].tokenReceived < amount) {
            balanceToSend = escrows[loanID].tokenAmount - escrows[loanID].tokenReceived;
        }

        IERC20 token = IERC20(_stablecoinContract);

        // transfer stablecoin tokens to this smart contract
        token.transferFrom(msg.sender, _walletAddress, amount);

        escrows[loanID].tokenReceived += balanceToSend;

        // transfer DLT to the lender
        Wallet wallet = Wallet(_walletAddress);
        wallet.transfer(msg.sender, amount, _loanTokens[loanID]);

        LoanApplicationSupported(loanID, balanceToSend);
    }

    /**
    * @dev Used by the loan recipient to claim the principle of loan with ID `loanID`
    */
    function claimPrinciple(uint256 loanID) public {
        require(loanID < _totalApplications);
        require(escrows[loanID].recipient == msg.sender);   // only allow recipient to claim principle
        require(escrows[loanID].tokenAmount == escrows[loanID].tokenReceived);  // only allow principle to be claimed when fully supported

        // unlock DLT

        Wallet wallet = Wallet(_walletAddress);
        wallet.transfer(msg.sender, amount, _stablecoinContract);
    }

    
    /**
    * @dev Makes a payment of `amount` for loan with ID `loanID`
    */
    function makePayment(uint256 _amount, uint256 _loanID) {
        require(_loanID < _totalApplications);
        require(escrows[_loanID].tokenAmount == escrows[_loanID].tokenReceived);

        LoanToken loanToken = LoanToken(_loanTokens[_loanID])
        uint265 currentBalance = loanToken.currentBalance(block.number);
        require(loanToken.currentBalance > 0);

        uint256 payment = _amount < currentBalance ? _amount : currentBalance;

        IERC20 stablecoin = IERC20(_stablecoinContract);
        stablecoin.transferFrom(msg.sender, _walletAddress, payment);

        loanToken.processPayment(payment, block.number);
    }

    /**
    * @dev Acts as a proxy for updating unclaimed stablecoin balances from DLTs
    */
    function allocateStablecoinProxy(address _to, uint256 _amount) public {
        require(_validToken[msg.sender], "LoanApplication: Proxy can only be called from valid Decent Loan Token");

        Wallet wallet = Wallet(_walletAddress);
        wallet.allocateStablecoins(_to, _amount);
    }


    // /* Get the URI for the loan application data */
    // function getURI(uint256 applicationID) public view returns (string memory) {
    //     return string(abi.encodePacked(_baseuri, applicationID.toString()));
    // }

    /* Sets the base uri for the loan application data */
    function setURI(string memory _newUri) public onlyOwner {
        _baseuri = _newUri;
    }

}