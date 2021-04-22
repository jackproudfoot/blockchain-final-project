import React from 'react';

import AccountPanel from './AccountPanel'
import WalletPanel from './WalletPanel'
import LoanProviderPanel from './LoanProviderPanel'

class Contract extends React.Component {
    state = { };

    componentDidMount = () => {
        const { drizzleState } = this.props;

        this.setState({  drizzleState })
    }

    render() {
        const { drizzle, drizzleState } = this.props;
       
        return (
            <div className="contract-container">
                <AccountPanel drizzle={drizzle} drizzleState={drizzleState} />
                <WalletPanel drizzle={drizzle} drizzleState={drizzleState} />
                <LoanProviderPanel drizzle={drizzle} drizzleState={drizzleState} />
            </div>
        );
    }
}


export default Contract;