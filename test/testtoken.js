/*
Test examples from: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
*/

const TestToken = artifacts.require("TestToken");

const _numTokens = 1000000;
const _decimals = 18;
const _totalSupply = _numTokens * (10 ** _decimals)

contract("TestToken", accounts => {
    it(`should put ${_totalSupply} TestTokens in the first account`, () =>
        TestToken.deployed()
        .then(instance => instance.balanceOf.call(accounts[0]))
        .then(balance => {
            assert.equal(
                balance.valueOf(),
                _totalSupply,
                `there were not ${_totalSupply} tokens in the first account`
            );
        })
    );

    const _tokens_to_send = 10000;
    it(`should transfer ${_tokens_to_send} tokens from the first account to the second`, () => {
        let contract_instance;
        
        const account_one = accounts[0];
        const account_two = accounts[1];

        let account_one_starting_balance;
        let account_two_starting_balance;
        let account_one_ending_balance;
        let account_two_ending_balance;

        return TestToken.deployed()
        .then(instance => {
            contract_instance = instance;
            return contract_instance.balanceOf.call(account_one);
        })
        .then(balance => {
            account_one_starting_balance = parseFloat(balance);
            return contract_instance.balanceOf.call(account_two);
        })
        .then(balance => {
            account_two_starting_balance = parseFloat(balance);
            return contract_instance.transfer(account_two, _tokens_to_send, { from: account_one });
        })
        .then(() => contract_instance.balanceOf.call(account_one))
        .then(balance => {
            account_one_ending_balance = parseFloat(balance);
            return contract_instance.balanceOf.call(account_two);
        })
        .then(balance => {
            account_two_ending_balance = parseFloat(balance);

            assert.equal(
                account_one_starting_balance - _tokens_to_send,
                account_one_ending_balance,
                `${_tokens_to_send} were not removed from sender`
            );

            assert.equal(
                account_two_starting_balance + _tokens_to_send,
                account_two_ending_balance,
                `${_tokens_to_send} were not added to receiver`
            );
        })
        
    });


})