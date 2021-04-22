import React from 'react';
import './AccountPanel.css';

class AccountPanel extends React.Component {
    state = { requestAmount: 1000, allowance: 0, balanceOfDataKey: null, storedAllowanceDataKay: null, stablecoinState: null};

    componentDidMount = () => {
        const { drizzle, drizzleState } = this.props;
        const stablecoinContract = drizzle.contracts.Stablecoin;
        const loanProviderContract = drizzle.contracts.LoanProvider;

        const balanceOfDataKey = stablecoinContract.methods["balanceOf"].cacheCall(drizzleState.accounts[0]);
        const storedAllowanceDataKay = stablecoinContract.methods["allowance"].cacheCall(drizzleState.accounts[0], loanProviderContract.address);
        
        this.setState({ balanceOfDataKey, storedAllowanceDataKay, stablecoinState: drizzleState.contracts.Stablecoin })
    }

    _updateRequestAmount = (e) => {
        this.setState({ requestAmount: e.target.value });
    }

    _claimStablecoin = (e) => {
        const { drizzle, drizzleState } = this.props;
        const contract = drizzle.contracts.Stablecoin;


        const stackId = contract.methods["mint"].cacheSend( drizzleState.accounts[0], e.target.value, {
            from: drizzleState.accounts[0]
        });
    }
    
    _updateInput = (e) => {
        this.setState({ [e.target.name]: e.target.value })
    }

    _setAllowance = () => {
        const { drizzle, drizzleState } = this.props;
        const contract = drizzle.contracts.Stablecoin;
        const loanProviderContract = drizzle.contracts.LoanProvider;

        const allowance = this.state.allowance * (10 ** 18)

        const stackId = contract.methods["approve"].cacheSend( loanProviderContract.address, allowance.toString(), {
            from: drizzleState.accounts[0]
        });
    }

    render() {
        const { drizzleState } = this.props;
        const { Stablecoin } = this.props.drizzleState.contracts;
        const storedBalanceOf = Stablecoin.balanceOf[this.state.balanceOfDataKey];

        const storedAllowance = Stablecoin.allowance[this.state.storedAllowanceDataKay];

        // console.log("Account panel re-rendered")
        // console.log(Stablecoin)

        return (
            <div className="panel">
                <div className="panel-content">
                    <p><b>Account</b></p>
                    <p>Public address: { drizzleState.accounts[0] } </p>
                    <p>
                        Stablecoin balance: {storedBalanceOf && (storedBalanceOf.value / 10**18)} STBC
                        <span className="allowance-form">
                            <button value="10" onClick={this._claimStablecoin }>+10</button>
                            <button value="100" onClick={this._claimStablecoin }>+100</button>
                            <input value={ this.state.requestAmount } onChange={this._updateRequestAmount} />
                            <button value={ this.state.requestAmount } onClick={this._claimStablecoin }>+{ this.state.requestAmount }</button>
                        </span>
                    </p>
                    <p>
                        Stablecoin allowance: {storedAllowance && (storedAllowance.value / 10**18)} STBC
                        <span className="allowance-form">
                            <input name="allowance" value={this.state.allowance} onChange={this._updateInput} /> STBC <button onClick={this._setAllowance} className="allowance-form-button">Set Allowance</button>
                        </span>
                    </p>
                </div>
            </div>
        );
    }
}


export default AccountPanel;