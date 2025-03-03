// Enhanced test suite with new analytics tests

Clarinet.test({
    name: "Can calculate portfolio diversity and risk metrics",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create portfolio with multiple assets
        let block = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'create-portfolio', [
                types.ascii("Test Portfolio")
            ], wallet1.address),
            Tx.contractCall('portfolio-tracker', 'add-holding', [
                types.uint(1),
                types.ascii("BTC"),
                types.uint(100000000),
                types.uint(50000000000)
            ], wallet1.address),
            Tx.contractCall('portfolio-tracker', 'add-holding', [
                types.uint(1),
                types.ascii("ETH"),
                types.uint(500000000),
                types.uint(3000000000)
            ], wallet1.address)
        ]);
        
        // Check enhanced metrics
        let metrics = chain.mineBlock([
            Tx.contractCall('portfolio-tracker', 'get-portfolio-metrics', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        const portfolioMetrics = metrics.receipts[0].result.expectOk().expectTuple();
        assertEquals(portfolioMetrics['diversity-score'], types.uint(2));
        assertEquals(portfolioMetrics['risk-score'], types.uint(1));
    }
});

// [Previous tests remain unchanged]
