//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Escrow functionality inspired by: https://github.com/axic/ethereum-tokenescrow/blob/master/tokenescrow.sol

contract LoanApplication is Ownable{
    string private _baseuri = "www.decent.com/applications/";

    address private _tokenaddr;

    uint256 private _totalApplications = 0;

    mapping (uint256 => Escrow) public escrows;
    
    mapping (uint256 => mapping (address => uint256)) _balances;
    mapping (uint256 => address[]) _lenders;

    struct Escrow {
        uint256 tokenAmount;
        uint256 tokenReceived;
        address recipient;
    }

    event LoanApplicationCreated(uint256 id);
    event LoanApplicationSupported(uint256 id, uint256 amount);

    constructor (string memory baseuri, address tokenaddr) {
        _baseuri = baseuri;
        _tokenaddr = tokenaddr;
    }

    /* Create a new loan application */
    function createLoan(uint256 tokenAmount) public {
        uint256 _loanID = _totalApplications;
        
        escrows[_loanID] = Escrow(tokenAmount, 0, msg.sender);

        _totalApplications += 1;

        LoanApplicationCreated(_loanID);
    }

    /* Provide tokens in support of loan */
    function supportLoan(uint256 loanID, uint256 amount) public {
        require(loanID < _totalApplications);
        require(escrows[loanID].tokenAmount > 0);
        require(escrows[loanID].tokenAmount > escrows[loanID].tokenReceived);

        uint256 balanceToSend = amount;
        if (escrows[loanID].tokenAmount - escrows[loanID].tokenReceived < amount) {
            balanceToSend = escrows[loanID].tokenAmount - escrows[loanID].tokenReceived;
        }

        IERC20 token = IERC20(_tokenaddr);

        // transfer tokens to contract
        token.transferFrom(msg.sender, address(this), amount);

        // add address to list of lenders
        if (_balances[loanID][msg.sender] == 0) {
            _lenders[loanID].push(msg.sender);
        }

        _balances[loanID][msg.sender] += balanceToSend;
        escrows[loanID].tokenReceived += balanceToSend;

        LoanApplicationSupported(loanID, balanceToSend);
    }

    /* Claim the principle amount of the loan */
    function claimPrinciple(uint256 loanID) public {
        require(loanID < _totalApplications);
        require(escrows[loanID].recipient == msg.sender);   // only allow recipient to claim principle
        require(escrows[loanID].tokenAmount == escrows[loanID].tokenReceived);  // only allow principle to be claimed when fully supported

        // Create distribution tokens here


        IERC20 token = IERC20(_tokenaddr);
        token.transfer(msg.sender, escrows[loanID].tokenAmount);
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