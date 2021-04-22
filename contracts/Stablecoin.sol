//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @author Jack Proudfoot
 * @dev Implementation of the {IERC20} interface for a mock stablecoin. 
 * @notice Should be used only for testing and development.
 *
 */
contract Stablecoin is ERC20{

    /**
     * @dev Creates ERC20 token to act as a mock stablecoin and mints tokens to `_to`
     */
    constructor () ERC20("Stablecoin", "STBL") {
       // do nothing
    }

    event TokenTransfer(address from, address to, uint256 amount);

    /**
    *  @dev mint `_amount` whole tokens to `_account`
    */
    function mint(address _to, uint256 _amount) public {
        uint256 tokensToMint = _amount * (10 ** decimals());
        _mint(_to, tokensToMint);
    }

    /**
    *  @dev mint `_amount` whole tokens to sender
    */
    function mint(uint256 _amount) public {
        uint256 tokensToMint = _amount * (10 ** decimals());
        _mint(msg.sender, tokensToMint);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        TokenTransfer(from, to, amount);
    }
}