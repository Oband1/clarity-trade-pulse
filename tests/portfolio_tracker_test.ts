// [Previous test content remains, adding new tests below]

Clarinet.test({
    name: "Can perform batch price updates and calculate ROI",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create portfolio and add holdings
        let block = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'create-portfolio', [
                types.ascii("Test Portfolio")
            ], wallet1.address),
            Tx.contractCall('portfolio-tracker', 'add-holding', [
                types.uint(1),
                types.ascii("BTC"),
                types.uint(100000000),
                types.uint(50000000000)
            ], wallet1.address)
        ]);
        
        // Batch update prices
        let batchUpdate = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'batch-update-prices', [
                types.uint(1),
                types.list([types.ascii("BTC")]),
                types.list([types.uint(55000000000)])
            ], wallet1.address)
        ]);
        
        batchUpdate.receipts[0].result.expectOk();
        
        // Check portfolio metrics
        let metrics = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'get-portfolio-metrics', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        const portfolioMetrics = metrics.receipts[0].result.expectOk().expectTuple();
        assertEquals(portfolioMetrics['total-value'], types.uint(5500000000000000));
        assertEquals(portfolioMetrics['roi'], types.int(10));
    }
});
