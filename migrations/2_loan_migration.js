const Wallet = artifacts.require("Wallet");

const Stablecoin = artifacts.require("Stablecoin");
const LoanProvider = artifacts.require("LoanProvider");
const LoanToken = artifacts.require("LoanToken");

module.exports = async function (deployer) {
    await deployer.deploy(Stablecoin);

    await deployer.deploy(Wallet, Stablecoin.address);

    stablecoin = await Stablecoin.deployed();
    await stablecoin.mint(Wallet.address, 1000);
    await stablecoin.mint(1000);

    await deployer.deploy(LoanToken);   // LoanToken for clone factory reference

    await deployer.deploy(LoanProvider, "www.decent.com/applications", LoanToken.address, Stablecoin.address, Wallet.address);

    wallet = await Wallet.deployed();
    
    spenderRole = await wallet.SPENDER_ROLE.call();
    allocatorRole = await wallet.STABLECOIN_ALLOCATOR_ROLE.call();

    await wallet.grantRole(spenderRole, LoanToken.address);
    await wallet.grantRole(spenderRole, LoanProvider.address);
    await wallet.grantRole(allocatorRole, LoanProvider.address);

}
