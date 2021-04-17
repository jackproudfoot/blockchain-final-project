//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Jack Proudfoot
 * @dev Wallet smart contract that tracks unclaimed balances.  Uses access control to allow multiple smart contracts to transfer wallets funds.
 *
 */
contract Wallet is AccessControl{

    bytes32 public constant SPENDER_ROLE = "SPENDER";
    bytes32 public constant STABLECOIN_ALLOCATOR_ROLE = "STABLECOIN_ALLOCATOR";

    address private _stablecoinAddress;

    mapping (address => uint256) private _unclaimedStablecoinBalance;

    /**
    * @dev Creates role bindings for SPENDER_ROLE
    */
    constructor (address stablecoinAddress_) {
        _stablecoinAddress = stablecoinAddress_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SPENDER_ROLE, msg.sender);
    }


    /**
    * @dev Allocates `amount` stablecoins to `to`
    */
    function allocateStablecoins(address _to, uint256 _amount) public {
        require(hasRole(STABLECOIN_ALLOCATOR_ROLE, msg.sender), "Wallet: sender does not posses STABLECOIN_ALLOCATOR role");

        _unclaimedStablecoinBalance[_to] += _amount;
    }

    /**
    * @dev Claim any stablecoin balance earned by Decent Loan Tokens
    */
    function claimStablecoinBalance(address _lender) public {
        require(_unclaimedStablecoinBalance[_lender] > 0, "Wallet: Stablecoin balance for that account is zero");

        IERC20 stablecoin = IERC20(_stablecoinAddress);
        stablecoin.transfer(_lender, _unclaimedStablecoinBalance[_lender]);

        _unclaimedStablecoinBalance[_lender] = 0;
    }

    /**
    * @dev Used by smart contracts to transfer `_value` of token with contract `_tokenContract` to address `_to`
    */
    function transfer(address _to, uint256 _amount, address _tokenContract) public {
        require(hasRole(SPENDER_ROLE, msg.sender), "Wallet: sender does not posses SPENDER role");

        IERC20 token = IERC20(_tokenContract);

        token.transfer(_to, _amount);
    }

    /**
    * @dev Withdraws all ether in the smart contract to `wallet`
    */
    function withdrawEther(address payable wallet) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Wallet: sender does not posses DEFAULT_ADMIN_ROLE required to transfer ether");

        wallet.transfer(address(this).balance);
    }
}