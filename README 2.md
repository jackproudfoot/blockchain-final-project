# Smart Contracts for Project

Uses [Truffle](https://www.trufflesuite.com/) and [Ganache](https://www.trufflesuite.com/ganache) for development.

#### Running the Example

The [TestToken smart contract](./contracts/TestToken.sol) is an example of a partial implementation of an ERC20 token. Take a look at the [Truffle Getting Started Docs](https://www.trufflesuite.com/docs/truffle/getting-started/compiling-contracts) for a thorough explanation of the various components. Below are the commands to deploy and test the smart contract.

```bash
# Compile smart contracts using solc compiler
$ truffle compile

# Deploy smart contracts to network (or local ganache environment)
$ truffle migrate

# Run the full test suite
$ truffle test
```