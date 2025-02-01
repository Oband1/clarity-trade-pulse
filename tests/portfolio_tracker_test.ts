import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new portfolio with analytics",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'create-portfolio', [
                types.ascii("My Crypto Portfolio")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let getPortfolio = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'get-portfolio', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        const portfolio = getPortfolio.receipts[0].result.expectSome().expectTuple();
        assertEquals(portfolio['total-value'], types.uint(0));
        assertEquals(portfolio['profit-loss'], types.int(0));
    }
});

Clarinet.test({
    name: "Can track portfolio value and profit/loss",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'create-portfolio', [
                types.ascii("My Crypto Portfolio")
            ], wallet1.address),
            Tx.contractCall('portfolio-tracker', 'add-holding', [
                types.uint(1),
                types.ascii("BTC"),
                types.uint(100000000), // 1 BTC
                types.uint(50000000000) // $50,000
            ], wallet1.address)
        ]);
        
        block.receipts.map(receipt => receipt.result.expectOk());
        
        let getHolding = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'get-holding', [
                types.uint(1),
                types.ascii("BTC")
            ], wallet1.address)
        ]);
        
        const holding = getHolding.receipts[0].result.expectSome().expectTuple();
        assertEquals(holding['value'], types.uint(5000000000000000));
        assertEquals(holding['profit-loss'], types.int(0));
        
        // Update price and check profit/loss
        let updatePrice = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'update-asset-price', [
                types.uint(1),
                types.ascii("BTC"),
                types.uint(55000000000) // $55,000
            ], wallet1.address)
        ]);
        
        updatePrice.receipts[0].result.expectOk();
        
        let updatedHolding = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'get-holding', [
                types.uint(1),
                types.ascii("BTC")
            ], wallet1.address)
        ]);
        
        const newHolding = updatedHolding.receipts[0].result.expectSome().expectTuple();
        assertEquals(newHolding['value'], types.uint(5500000000000000));
        assertEquals(newHolding['profit-loss'], types.int(500000000000000));
    }
});
