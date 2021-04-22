import React from 'react';

import './WalletPanel.css';

class StablecoinPanel extends React.Component {
    state = { unclaimedBalanceOfDataKey: null, balanceOfDataKey: null};

    componentDidMount = () => {
        const { drizzle, drizzleState } = this.props;
        const stablecoinContract = drizzle.contracts.Stablecoin;
        const walletContract = drizzle.contracts.Wallet;

        const balanceOfDataKey = stablecoinContract.methods["balanceOf"].cacheCall(walletContract.address);

        const unclaimedBalanceOfDataKey = walletContract.methods["unclaimedBalanceOf"].cacheCall(drizzleState.accounts[0]);
        
        this.setState({ balanceOfDataKey, unclaimedBalanceOfDataKey })
    }

    
    _claimStablecoins = () => {
        const { drizzle, drizzleState } = this.props;
        const contract = drizzle.contracts.Wallet;

        const stackId = contract.methods["claimStablecoinBalance"].cacheSend( drizzleState.accounts[0], {
            from: drizzleState.accounts[0]
        });
    }
    

    render() {
        const { drizzleState } = this.props;
        const { Stablecoin, Wallet } = this.props.drizzleState.contracts;
        const storedBalanceOf = Stablecoin.balanceOf[this.state.balanceOfDataKey];
        const storedUnclaimedBalanceOf = Wallet.unclaimedBalanceOf[this.state.unclaimedBalanceOfDataKey];

        return (
            <div className="panel">
                <div className="panel-content">
                    <p><b>Wallet Contract</b></p>
                    <p>Stablecoin balance: {storedBalanceOf && (storedBalanceOf.value / 10**18)} STBC</p>
                    <p>
                        Unclaimed Stablecoins: {storedUnclaimedBalanceOf && (storedUnclaimedBalanceOf.value / 10**18)} STBC
                        <button className="wallet-button" onClick={ this._claimStablecoins }>Claim</button>
                    </p>
                </div>
            </div>
        );
    }
}


export default StablecoinPanel;