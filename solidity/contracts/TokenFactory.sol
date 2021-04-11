// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./TestToken.sol";
import "@optionality.io/clone-factory/contracts/CloneFactory18.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Example from https://github.com/optionality/clone-factory
contract TokenFactory is Ownable, CloneFactory18 {
    address public libraryAddress;

    event TokenCreated(address newAddress);

    function TokenFactory(address _libraryAddress) public {
        libraryAddress = _libraryAddress;
    }

    function setLibraryAddress(address _libraryAddress) public onlyOwner {
        libraryAddress = _libraryAddress;
    }

    function createToken(string _name, uint256 _value) public onlyOwner {
        address clone = createClone(libraryAddress);
        //TestToken(clone).init(_name, _value);
        TokenCreated(clone);
    }
}