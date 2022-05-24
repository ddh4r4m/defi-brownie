import React from 'react';
import { Mainnet, DAppProvider, ChainId, useEtherBalance, useEthers, Config } from '@usedapp/core'
import { Header } from "./components/Header"
import { Container } from '@mui/system';

function App() {
  return (
    <DAppProvider config={
      {
        supportedChains: [ChainId.Kovan, ChainId.Rinkeby]
      }
    }>
      <Header />
      <Container maxWidth="md">
        <div>Hi</div>
      </Container>
    </DAppProvider>
  );
}

export default App;
