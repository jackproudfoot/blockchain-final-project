import React from 'react';
import './LoanProviderPanel.css';

import LoanApplication from './LoanApplication';

class AccountPanel extends React.Component {
    state = { totalApplicationsDataKey: null};

    componentDidMount = () => {
        const { drizzle, drizzleState } = this.props;
        const loanProviderContract = drizzle.contracts.LoanProvider;

        const totalApplicationsDataKey = loanProviderContract.methods["totalApplications"].cacheCall();
        
        this.setState({ totalApplicationsDataKey })
    }


    _updateInput = (e) => {
        this.setState({ [e.target.name]: e.target.value })
    }

    _submitApplication = () => {
        if (this.state.amountValue && this.state.rateValue) {
            
            const { drizzle, drizzleState } = this.props;
            const contract = drizzle.contracts.LoanProvider;

            const value = (this.state.amountValue) * (10 ** 18)
            const rate = Math.pow(this.state.rateValue, 1 / (6 * 60 * 24 * 365));

            const stackId = contract.methods["createLoan"].cacheSend( value.toString(), Math.trunc(rate), {
                from: drizzleState.accounts[0]
            });

            this.setState({ amountValue: undefined, rateValue: undefined })
        }
    }

    render() {
        const { drizzle, drizzleState } = this.props;
        const { LoanProvider } = this.props.drizzleState.contracts;
        const storedTotalApplications = LoanProvider.totalApplications[this.state.totalApplicationsDataKey];

        const interestPerBlock = <span className="block-interest">Interest per block: {this.state.rateValue / (6 * 60 * 24 * 365)}%</span>;

        const loanApplications = []

        if (storedTotalApplications) {
            for (let i = 0; i < storedTotalApplications.value; i++) {
                loanApplications.push(<li><LoanApplication id={i} drizzle={drizzle} drizzleState={drizzleState} /></li>)
            }
        }
        

        return (
            <div className="panel">
                <div className="lp-panel-content">
                    <p><b>Loan Provider Contract</b></p>
                    <p>Total Loan Applications: {storedTotalApplications && (storedTotalApplications.value)}</p>
                    <p className="create-loan-application">
                        Create Loan Application:
                        <input placeholder="Amount" name="amountValue" onChange={this._updateInput} value={this.state.amountValue}/>
                        <input placeholder="Rate %" name="rateValue" onChange={this._updateInput} value={this.state.rateValue}/>
                        <button onClick={this._submitApplication}>Create</button>
                        
                        {this.state.rateValue ? interestPerBlock : ''}
                    </p>
                    
                    Loan Applications: 
                    <ul>
                        {loanApplications}
                    </ul>
                    
                    
                </div>
            </div>
        );
    }
}


export default AccountPanel;