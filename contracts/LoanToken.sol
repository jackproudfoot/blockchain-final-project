//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./LoanApplication.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @author Jack Proudfoot
 * @dev Implementation of the {IERC20} interface for Loan Tokens with dividend paying feature.
 *
 * Dividend functionality inspired by: https://medium.com/crowdbotics/how-to-build-a-dividend-token-with-solidity-81ae3bf3fe72
 */
contract LoanToken is ERC20{

    uint256 private _loanID;
    address private _loanApplicationContract;

    uint256 private _balance;

    uint256 private _unclaimedDistributions;
    uint256 private _totalDistributions;

    uint256 private _leftoverPayment;

    uint256 private _interestPoints;
    uint256 private _lastPaymentBlock;


    mapping (address => uint256) private _lastDistributionClaimed;

    /**
     * @dev Sets the values for {loanID} and calls ERC20 constructor
     * The value of {loanID} is immutable.
     */
    constructor (uint256 loanID_, address loanApplicationContract_, address walletContract_, uint256 amount_) ERC20("Decent Loan Token", "DLT") {
       _loanID = loanID_;
       _loanApplicationContract = loanApplicationContract_;
       _balance = amount_;
       _totalDistributions = 0;

       _mint(walletContract_, amount_);
    }

    /**
    * @dev Modifier applied to any function that moves tokens to update distributions earned from this token for `lender`
    */
    modifier updatesDistributions (address _lender) {
        updateDistributions(_lender);
        _;
    }

    /**
    * @dev Claims the distributions for this token for `_lender` 
    */
    function updateDistributions (address _lender) {
        uint256 payment = distributionsOwed(lender);
        if(payment > 0) {
            LoanApplication loanProvider = LoanApplication(_loanApplicationContract);
            loanProvider.allocateStablecoinProxy(lender, payment);

            _unclaimedDistributions = _unclaimedDistributions - payment;
            _lastDistributionClaimed[lender] = _totalDistributions;
        }
    }

    /**
    * @dev Computes the amount of distributions owed to `_lender`
    */
    function distributionsOwed (address _lender) public returns (uint256) {
        uint256 outstandingDistributions = _totalDistributions - _lastDistributionClaimed[_lender];

        return outstandingDistributions * balanceOf(_lender);
    }

    /** 
    @dev Get the balance of the loan at block `blockNumber`
    */
    function currentBalance(uint256 _blockNumber) {
        // COMPUTE COMPOUND INTEREST
    }

    /**
    * @dev Processes payment of `amount` towards loan balance during `_blockNumber`
    */
    function processPayment(uint256 _amount, uint256 _blockNumber) public {
        require(msg.sender == _loanApplicationContract, "LoanToken: This function can only be called from the LoanProvider contract");
        require(_blockNumber > _lastPaymentBlock);
        
        uint256 updatedBalance = currentBalance(_blockNumber) - _amount;
        
        uint256 additionalDistributions = (_amount + _leftoverPayment) / totalSupply();

        _unclaimedDistributions += additionalDistributions * totalSupply();
        _totalDistributions += additionalDistributions;
        _leftoverPayment = (_amount + _leftoverPayment) % totalSupply();
        
        _balance = updatedBalance;
    }

    /**
    * @dev Gets the `loanID`
    */
    function getLoanID() public returns (uint256) {
        return _loanID;
    }
}