//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./LoanProvider.sol";
import "./DeciMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @author Jack Proudfoot
 * @dev Implementation of the {IERC20} interface for Loan Tokens with dividend paying feature.
 *
 * Dividend functionality inspired by: https://medium.com/crowdbotics/how-to-build-a-dividend-token-with-solidity-81ae3bf3fe72
 */
contract LoanToken is ERC20, DeciMath{

    uint256 private _loanID;
    address private _loanProviderContract;

    uint256 private _balance;
    uint256 private _rate;

    uint256 private _unclaimedDistributions;
    uint256 private _totalDistributions;

    uint256 private _leftoverPayment;

    uint256 private _interestPoints;
    uint256 private _lastPaymentBlock;

    bool private _activated;


    mapping (address => uint256) private _lastDistributionClaimed;

    bool private _initialized;

    /**
     * @dev Shim constructor meant to be used to deploy or clone contract without initializing state.
     */
    constructor () ERC20("Decent Loan Token", "DLT") {
       _initialized = false;
    }

    /**
    * @dev One time initialization function used by the clone factory to initialize state of cloned contract
    */
    function init (uint256 loanID_, address loanProviderContract_, address walletContract_, uint256 amount_, uint256 rate_) public {
        require(!_initialized, "LoanToken: Contract already initialized");
        
        _loanID = loanID_;
        _loanProviderContract = loanProviderContract_;
        _balance = amount_;
        _rate = rate_;
        _totalDistributions = 0;

        _activated = false;

        _mint(walletContract_, amount_);

        _initialized = true;
    }

    /**
    * @dev Modifier applied to all functions that ensures that the contract has been initialized
    */
    modifier ensuresInitialized () {
        require(_initialized, "LoanToken: Contract must be initialized by the init() function.");
        _;
    }

    /**
    * @dev Modifier applied to functions that ensures that the contract has been activated
    */
    modifier ensuresActivated () {
        //require(_activated, "LoanToken: Contract must be activated before this function can be used.");
        _;
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
    function updateDistributions (address _lender) public ensuresInitialized ensuresActivated {
        uint256 payment = distributionsOwed(_lender);
        if(payment > 0) {
            LoanProvider loanProvider = LoanProvider(_loanProviderContract);
            loanProvider.allocateStablecoinProxy(_lender, payment);

            _unclaimedDistributions = _unclaimedDistributions - payment;
            _lastDistributionClaimed[_lender] = _totalDistributions;
        }
    }

    /**
    * @dev Computes the amount of distributions owed to `_lender`
    */
    function distributionsOwed (address _lender) public view ensuresInitialized ensuresActivated returns (uint256) {
        uint256 outstandingDistributions = _totalDistributions - _lastDistributionClaimed[_lender];

        return decMul18(outstandingDistributions, balanceOf(_lender));
    }

    /** 
    @dev Get the balance of the loan at block `blockNumber`
    */
    function balanceAtBlock(uint256 _blockNumber) public view ensuresInitialized ensuresActivated returns (uint256) {
        uint256 blocksElapsed = _blockNumber - _lastPaymentBlock;

        if (blocksElapsed == 0) {
            return _balance;
        }

        uint256 balance = decMul18(_balance, powBySquare18(TEN18 + _rate, blocksElapsed));

        return balance;
    }

    /**
    * Gets the balance of the loan at the current block
    */
    function currentBalance() public view ensuresInitialized ensuresActivated returns (uint256) {
        return balanceAtBlock(block.number);
    }

    /**
    * @dev Processes payment of `amount` towards loan balance during `_blockNumber`
    */
    function processPayment(uint256 _amount, uint256 _blockNumber) public ensuresInitialized ensuresActivated {
        require(msg.sender == _loanProviderContract, "LoanToken: This function can only be called from the LoanProvider contract");
        require(_blockNumber > _lastPaymentBlock, "LoanToken: Cannot make multiple payments in the same block");
        
        uint256 updatedBalance = balanceAtBlock(_blockNumber) - _amount;
        
        // uint256 additionalDistributions = decDiv18(_amount + _leftoverPayment, totalSupply());

        // _unclaimedDistributions += decMul18(additionalDistributions, totalSupply());
        // _totalDistributions += additionalDistributions;
        // _leftoverPayment = (_amount + _leftoverPayment) - _unclaimedDistributions;

        uint256 additionalDistributions = decDiv18(_amount, totalSupply());

        _unclaimedDistributions += decMul18(additionalDistributions, totalSupply());
        _totalDistributions += additionalDistributions;

        _lastPaymentBlock = _blockNumber;
        
        _balance = updatedBalance;
    }

    function getPaymentValues(uint256 _amount) public view returns (uint256) {
        return decDiv18(_amount, totalSupply());
    }

    /**
    * @dev activate the token when the loan principle is claimed
    */
    function activateToken(uint256 _blockNumber) public ensuresInitialized {
        require(msg.sender == _loanProviderContract, "LoanToken: This function can only be called from the LoanProvider contract");

        _activated = true;
        _lastPaymentBlock = _blockNumber;
    }

    /**
    * @dev Gets the `loanID`
    */
    function getLoanID() public view ensuresInitialized returns (uint256) {
        return _loanID;
    }

    /**
    * @dev Adds updatesDistributions modifier to ERC20 transfer function 
    */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override ensuresInitialized updatesDistributions(sender) {
        ERC20._transfer(sender, recipient, amount);
    }

    /**
    * @dev Gets whether the loan has been activated
    */
    function getActivated() public view returns (bool) {
        return _activated;
    }

    /**
    * @dev Returnst the interest rate of the loan (per block)
    */
    function getRate() public view returns (uint256) {
        return _rate;
    }
}