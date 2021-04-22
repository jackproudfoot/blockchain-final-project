import React from 'react';

import LoanToken from './contracts/LoanToken.json';

import './LoanApplication.css';


class AccountPanel extends React.Component {
    state = { escrowDataKey: null, loanTokenDataKey: null, fundedDataKey: null, commitFunds: 0, tokenContractConfig: null, tokenContractBalanceDataKey: null};

    componentDidMount = () => {
        const { drizzle, drizzleState } = this.props;
        const loanProviderContract = drizzle.contracts.LoanProvider;

        const escrowDataKey = loanProviderContract.methods["escrows"].cacheCall(this.props.id);
        const loanTokenDataKey = loanProviderContract.methods["_loanTokens"].cacheCall(this.props.id);


        this.setState({ escrowDataKey, loanTokenDataKey })
    }


    _updateInput = (e) => {
        this.setState({ [e.target.name]: e.target.value })
    }

    _contributeTokens = () => {
        const { drizzle, drizzleState } = this.props;
        const contract = drizzle.contracts.LoanProvider;

        const funds = this.state.commitFunds * (10 ** 18)

        const stackId = contract.methods["supportLoan"].cacheSend( this.props.id, funds.toString(), {
            from: drizzleState.accounts[0]
        });

        this.setState({ commitFunds: 0 })
    }

    componentDidUpdate = () => {
        const { drizzle, drizzleState } = this.props;

        const { LoanProvider } = this.props.drizzleState.contracts;
        const storedLoanToken = LoanProvider._loanTokens[this.state.loanTokenDataKey];

        if (storedLoanToken && !drizzleState.contracts[storedLoanToken.value.toString()]) {
            

            const loanTokenAddress = storedLoanToken && storedLoanToken.value.toString();

            const tokenContractConfig = {
                contractName: loanTokenAddress,
                web3Contract: new drizzle.web3.eth.Contract(LoanToken.abi, loanTokenAddress)
            }

            drizzle.addContract(tokenContractConfig)

            const loanTokenContract = drizzle.contracts[loanTokenAddress];
            const tokenContractBalanceDataKey = loanTokenContract.methods["balanceOf"].cacheCall(drizzleState.accounts[0], {from: drizzleState.accounts[0]});
            const tokenContractCurrentBalanceDataKey = loanTokenContract.methods["currentBalance"].cacheCall({from: drizzleState.accounts[0]});
            const tokenActivatedDataKey = loanTokenContract.methods["getActivated"].cacheCall({from: drizzleState.accounts[0]});
            const earnedPaymentsDataKey = loanTokenContract.methods["distributionsOwed"].cacheCall(drizzleState.accounts[0], {from: drizzleState.accounts[0]});
            const getRateDataKey = loanTokenContract.methods["getRate"].cacheCall({from: drizzleState.accounts[0]});

            const getPaymentValuesDataKey = loanTokenContract.methods["getPaymentValues"].cacheCall((10**18).toString());

            this.setState({ tokenContractConfig, tokenContractBalanceDataKey, tokenContractCurrentBalanceDataKey, tokenActivatedDataKey, earnedPaymentsDataKey, getPaymentValuesDataKey, getRateDataKey })
        }
    }


    _claimPrinciple = () => {
        const { drizzle, drizzleState } = this.props;

        const { LoanProvider } = drizzle.contracts;

        const stackId = LoanProvider.methods["claimPrinciple"].cacheSend( this.props.id, {
            from: drizzleState.accounts[0]
        });
    }

    _makePayment = () => {
        const { drizzle, drizzleState } = this.props;

        const { LoanProvider } = drizzle.contracts;

        const stackId = LoanProvider.methods["makePayment"].cacheSend( (this.state.paymentAmount * 10**18).toString(), this.props.id, {
            from: drizzleState.accounts[0]
        });

        this.setState({ paymentAmount: 0})
    }

    _claimPayments = () => {
        const { drizzle, drizzleState } = this.props;

        if (this.state.tokenContractConfig) {
            const loanTokenContract = drizzle.contracts[this.state.tokenContractConfig.contractName];

            const stackId = loanTokenContract.methods["updateDistributions"].cacheSend( drizzleState.accounts[0], {
                from: drizzleState.accounts[0]
            });
        }

        
    }

    render() {

        const { drizzle, drizzleState } = this.props;

        const { LoanProvider } = this.props.drizzleState.contracts;
        const storedEscrow = LoanProvider.escrows[this.state.escrowDataKey];
        const storedLoanToken = LoanProvider._loanTokens[this.state.loanTokenDataKey];


        let claimButton;
        let yourBalance = 0;
        let tokenBalance = 0;
        let earnedPayments = 0;
        let activated = false
        let rate = 0;
        if (this.state.tokenContractConfig != null) {
            const LoanTokenContract = drizzleState.contracts[this.state.tokenContractConfig.contractName];
            
            const storedLoanTokenBalance = LoanTokenContract.balanceOf[this.state.tokenContractBalanceDataKey];

            yourBalance = storedLoanTokenBalance ? storedLoanTokenBalance.value : 0;


            const currentLoanBalance = LoanTokenContract.currentBalance[this.state.tokenContractCurrentBalanceDataKey];
            tokenBalance = currentLoanBalance ? currentLoanBalance.value : 0;


            const storedTokenActivated = LoanTokenContract.getActivated[this.state.tokenActivatedDataKey];
            if (storedTokenActivated) {
                activated = storedTokenActivated.value
            }
            
            if (storedEscrow && storedEscrow.value.recipient == drizzleState.accounts[0]) {
                claimButton = <button disabled={(storedEscrow && storedEscrow.value.tokenAmount != storedEscrow.value.tokenReceived) || (storedTokenActivated && storedTokenActivated.value)} onClick={this._claimPrinciple}>Claim</button>
            }

            const storedEarnedDistributions = LoanTokenContract.distributionsOwed[this.state.earnedPaymentsDataKey];
            earnedPayments = storedEarnedDistributions ? storedEarnedDistributions.value : 0;

            const getRate = LoanTokenContract.getRate[this.state.getRateDataKey];
            rate = getRate && getRate.value;
            console.log(rate)

            // console.log(LoanTokenContract)
            // console.log(LoanProvider)

            const getPaymentsStored = LoanTokenContract.getPaymentValues[this.state.getPaymentValuesDataKey];
            //console.log(getPaymentsStored && getPaymentsStored.value)
        }


        
        const status = <p>Status: <span>{activated ? 'Active' : 'Pending'}</span></p>;

        return (
            <div className="application-panel">
                <div className="la-panel-content">
                    <p><b>Loan Application #{this.props.id}</b></p>
                    <p>Recipient: {storedEscrow && storedEscrow.value.recipient}</p>
                    <p>
                        Requested Loan Amount: {storedEscrow && storedEscrow.value.tokenAmount / 10**18} STBC
                        <span className="contribute-form">{claimButton}</span>
                    </p>
                    <p>Rate: {((rate * 10**-18)).toFixed(18)}% per block </p>
                    <p>Total Committed Funds: {storedEscrow && storedEscrow.value.tokenReceived / 10**18} STBC</p>
                    <p>
                        Your Committed Funds: {yourBalance / 10**18} STBC
                        <span className="contribute-form">
                            <input name="commitFunds" value={this.state.commitFunds} onChange={this._updateInput} /> STBC <button onClick={this._contributeTokens}>Contribute</button>
                        </span>
                    </p>
                    <p>
                        Loan Balance: { (tokenBalance / 10**18).toFixed(9) } STBC
                        <span className="contribute-form">
                            <input name="paymentAmount" value={this.state.paymentAmount} onChange={this._updateInput} /> STBC <button onClick={this._makePayment}>Make Payment</button>
                        </span>
                    </p>
                    <p>Loan Token: {storedLoanToken && storedLoanToken.value}</p>
                    <p>Your Loan Token Balance: { yourBalance / 10**18 } DLT </p>
                    <p>
                        Your Earned Payments: { earnedPayments / 10**18 } STBC
                        <span className="contribute-form">
                            <button onClick={this._claimPayments}>Claim</button>
                        </span>
                    </p>
                    
                </div>
            </div>
        );
    }
}


export default AccountPanel;