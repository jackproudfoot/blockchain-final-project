import React from 'react';
import { DrizzleContext } from '@drizzle/react-plugin';
import Contract from './Contract';

const DrizzleConsumer = () => (
    <DrizzleContext.Consumer>
        {drizzleContext => {
            const { drizzle, drizzleState, initialized } = drizzleContext;

            if (!initialized) {
                return "Loading...";
            }

            return (
                <Contract drizzle={drizzle} drizzleState={drizzleState} />
            );
        }}
    </DrizzleContext.Consumer>
)

export default DrizzleConsumer;