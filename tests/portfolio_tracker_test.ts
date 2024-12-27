import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new portfolio",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'create-portfolio', [
                types.ascii("My Crypto Portfolio")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Can add holdings to portfolio",
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
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
        
        let getHolding = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'get-holding', [
                types.uint(1),
                types.ascii("BTC")
            ], wallet1.address)
        ]);
        
        const holding = getHolding.receipts[0].result.expectSome().expectTuple();
        assertEquals(holding['amount'], types.uint(100000000));
        assertEquals(holding['avg-price'], types.uint(50000000000));
    }
});

Clarinet.test({
    name: "Can record transactions",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'create-portfolio', [
                types.ascii("My Crypto Portfolio")
            ], wallet1.address),
            Tx.contractCall('portfolio-tracker', 'record-transaction', [
                types.uint(1),
                types.ascii("BTC"),
                types.ascii("BUY"),
                types.uint(100000000),
                types.uint(50000000000)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
        
        let getTx = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'get-transaction', [
                types.uint(1),
                types.uint(1)
            ], wallet1.address)
        ]);
        
        const tx = getTx.receipts[0].result.expectSome().expectTuple();
        assertEquals(tx['asset'], types.ascii("BTC"));
        assertEquals(tx['type'], types.ascii("BUY"));
        assertEquals(tx['amount'], types.uint(100000000));
    }
});