const LoanERC20Token = artifacts.require("LoanERC20Token");

module.exports = function (deployer) {
  // can test deployment of this contract here (although it would be deployed by the loan
  // contract instead)
  deployer.deploy(
    LoanERC20Token,
    "0xec225ff8b4a65c60f805ada7048d1811b8900a43",
    "Loan",
    "L"
  );
};
