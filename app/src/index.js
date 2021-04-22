import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';

import { Drizzle, generateStore } from '@drizzle/store';
import { DrizzleContext } from '@drizzle/react-plugin';

import Stablecoin from './contracts/Stablecoin.json';
import Wallet from './contracts/Wallet.json';
import LoanProvider from './contracts/LoanProvider.json';
import LoanToken from './contracts/LoanToken.json';

const options = { contracts: [Stablecoin, Wallet, LoanProvider, LoanToken] };
const drizzleStore = generateStore(options);
const drizzle = new Drizzle(options, drizzleStore);
 
ReactDOM.render(
  <React.StrictMode>
    <DrizzleContext.Provider drizzle={drizzle}>
      <App />
    </DrizzleContext.Provider>
  </React.StrictMode>,
  document.getElementById('root')
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
