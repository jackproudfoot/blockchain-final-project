// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// using Remix IDE (OpenZeppelin latest version - 4.0.0) - comment the line above/uncomment the line below
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";

contract LoanERC20Token is ERC20 {
    // the address of the loan contract that initializes this contract
    // only this address can handle transferring/minting/burning of tokens
    address public loanContract;

    constructor(
        address _loanContract,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) {
        loanContract = _loanContract;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount); // call the parent hook first
        require(
            msg.sender == loanContract,
            "Only the controlling loan contract can interact with this child token contract: invalid call/transaction"
        );
    }
}
