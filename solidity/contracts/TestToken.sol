// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
@title Testnet Stablecoin
@author Jack Proudfoot
@notice You can use this contract for testing basic ERC20 token functionality.
Largely inspired by OpenZeppelin ERC-20 template: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
*/
contract TestToken {
    mapping(address => uint256) private _balances;

    string public name = "TestToken";
    string public symbol = "TEST";

    uint256 private _numTokens = 1000000;

    uint8 public decimals = 18;
    uint256 public totalSupply = _numTokens * (10 ** decimals);

    constructor() {
        _balances[msg.sender] = totalSupply;
    }

    /**
    * @dev Get the token balance of `_owner` 
    * @param _owner Address to check balance of
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }


    /**
    * @dev Transfers `_value` tokens to address `_to`
    * @param _to Address to receive tokens
    * @param _value Amount of tokens to transfer
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "ERC20: transfer from the zero address");
        
        uint256 senderBalance = _balances[msg.sender];

        require(senderBalance >= _value, "ERC20: transfer amount exceeds balance");

        _balances[msg.sender] = senderBalance - _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}