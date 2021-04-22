//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Wallet.sol";
import "./LoanToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @author Jack Proudfoot
 * @dev Primary contract for providing Decent Loans. Handles loan applications, Decent Loan Token creation, loan payments, and distribution payments.
 *
 * Escrow functionality inspired by: https://github.com/axic/ethereum-tokenescrow/blob/master/tokenescrow.sol
 */
contract LoanProvider is Ownable {
    string private _baseuri;

    address private _loanTokenContract;
    address private _stablecoinContract;
    address private _walletAddress;

    uint256 private _totalApplications = 0;

    mapping (uint256 => Escrow) public escrows;

    mapping (uint256 => address) public _loanTokens;
    mapping (address => bool) _validToken;

    struct Escrow {
        uint256 tokenAmount;
        uint256 tokenReceived;
        address recipient;
    }

    event LoanApplicationCreated(uint256 id);
    event LoanApplicationSupported(uint256 id, uint256 amount);
    event LoanTokenCreated(address loanTokenAddress);


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
    * @dev Create a new loan application with principle balance of `tokenAmount` and rate of `rate`
    */
    function createLoan(uint256 tokenAmount, uint256 rate) public returns (uint256) {
        uint256 _loanID = _totalApplications;
        
        escrows[_loanID] = Escrow(tokenAmount, 0, msg.sender);

        _totalApplications += 1;

        LoanApplicationCreated(_loanID);

        address _newLoanToken = Clones.clone(_loanTokenContract);
        LoanToken(_newLoanToken).init(_loanID, address(this), _walletAddress, tokenAmount, rate);
        
        LoanTokenCreated(_newLoanToken);

        _loanTokens[_loanID] = _newLoanToken;
        _validToken[_newLoanToken] = true;

        return _loanID;
    }

    /** 
    * @dev Provide `amount` tokens to the escrow for loan `loanID` in exchange for Decent Loan Tokens
    */
    function supportLoan(uint256 loanID, uint256 amount) public {
        require(loanID < _totalApplications, "LoanProvider: Invalid Loan ID");
        require(escrows[loanID].tokenAmount > 0);
        require(escrows[loanID].tokenAmount > escrows[loanID].tokenReceived, "LoanProvider: Loan fully supported");

        uint256 balanceToSend = amount;
        if (escrows[loanID].tokenAmount - escrows[loanID].tokenReceived < amount) {
            balanceToSend = escrows[loanID].tokenAmount - escrows[loanID].tokenReceived;
        }

        IERC20 token = IERC20(_stablecoinContract);

        // transfer stablecoin tokens to this smart contract
        token.transferFrom(msg.sender, _walletAddress, balanceToSend);

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

        // activate DLT
        LoanToken loanToken = LoanToken(_loanTokens[loanID]);
        loanToken.activateToken(block.number);

        Wallet wallet = Wallet(_walletAddress);
        wallet.transfer(msg.sender, escrows[loanID].tokenAmount, _stablecoinContract);
    }


    /**
    * @dev Makes a payment of `amount` for loan with ID `loanID`
    */
    function makePayment(uint256 _amount, uint256 _loanID) public {
        require(_loanID < _totalApplications);
        require(escrows[_loanID].tokenAmount == escrows[_loanID].tokenReceived);

        LoanToken loanToken = LoanToken(_loanTokens[_loanID]);
        uint256 currentBalance = loanToken.balanceAtBlock(block.number);
        require(currentBalance > 0, "LoanProvider: Loan must have balance greater than 0 to make payment");

        uint256 payment = _amount < currentBalance ? _amount : currentBalance;

        IERC20 stablecoin = IERC20(_stablecoinContract);
        stablecoin.transferFrom(msg.sender, _walletAddress, payment);


        loanToken.processPayment(payment, block.number);

    }

    /**
    * @dev Acts as a proxy for updating unclaimed stablecoin balances from DLTs
    */
    function allocateStablecoinProxy(address _to, uint256 _amount) public {
        require(_validToken[msg.sender], "LoanProvider: Proxy can only be called from valid Decent Loan Token");

        Wallet wallet = Wallet(_walletAddress);
        wallet.allocateStablecoins(_to, _amount);
    }


    // /* Get the URI for the loan application data */
    // function getURI(uint256 applicationID) public view returns (string memory) {
    //     return string(abi.encodePacked(_baseuri, applicationID.toString()));
    // }

    /**
    * @dev Returns the total number of applications that have been created 
    */
    function totalApplications() public view returns (uint256) {
        return _totalApplications;
    }

    /* Sets the base uri for the loan application data */
    function setURI(string memory _newUri) public onlyOwner {
        _baseuri = _newUri;
    }

}