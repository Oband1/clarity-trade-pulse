;; TradePulse Portfolio Tracker Contract

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))

;; Data structures
(define-map portfolios 
    {owner: principal, id: uint}
    {
        name: (string-ascii 64),
        created-at: uint,
        last-updated: uint,
        total-value: uint,
        profit-loss: int,
        roi: int
    }
)

(define-map holdings
    {portfolio-id: uint, asset: (string-ascii 10)}
    {
        amount: uint,
        avg-price: uint,
        last-updated: uint,
        current-price: uint,
        value: uint,
        profit-loss: int,
        total-invested: uint
    }
)

(define-map transactions
    {portfolio-id: uint, tx-id: uint}
    {
        asset: (string-ascii 10),
        type: (string-ascii 4),
        amount: uint,
        price: uint,
        timestamp: uint,
        value: uint
    }
)

;; Data variables
(define-data-var next-portfolio-id uint u1)
(define-data-var next-transaction-id uint u1)
(define-data-var supported-assets (list 20 (string-ascii 10)) (list "BTC" "ETH" "STX"))

;; Helper functions
(define-private (calculate-roi (current-value uint) (total-invested uint))
    (if (is-eq total-invested u0)
        0
        (* (/ (- current-value total-invested) total-invested) u100)
    )
)

;; Portfolio management
(define-public (create-portfolio (name (string-ascii 64)))
    (let
        (
            (portfolio-id (var-get next-portfolio-id))
        )
        (map-set portfolios 
            {owner: tx-sender, id: portfolio-id}
            {
                name: name,
                created-at: block-height,
                last-updated: block-height,
                total-value: u0,
                profit-loss: 0,
                roi: 0
            }
        )
        (var-set next-portfolio-id (+ portfolio-id u1))
        (ok portfolio-id)
    )
)

;; Batch operations
(define-public (batch-update-prices 
    (portfolio-id uint) 
    (assets (list 20 (string-ascii 10))) 
    (prices (list 20 uint)))
    (let
        (
            (portfolio (get-portfolio portfolio-id))
        )
        (asserts! (is-some portfolio) err-not-found)
        (asserts! (is-eq tx-sender (get owner (unwrap-panic portfolio))) err-unauthorized)
        (asserts! (is-eq (len assets) (len prices)) err-invalid-input)
        
        (map update-asset-price-internal 
            (map unwrap-panic
                (map 
                    (lambda (asset price) 
                        (tuple (portfolio-id portfolio-id) (asset asset) (price price))
                    )
                    assets
                    prices
                )
            )
        )
        (ok true)
    )
)

;; Enhanced analytics
(define-read-only (get-portfolio-metrics (portfolio-id uint))
    (let
        (
            (portfolio (get-portfolio portfolio-id))
            (holdings-list (get-portfolio-holdings portfolio-id))
        )
        (match portfolio
            portfolio-data
            (ok {
                total-value: (get total-value portfolio-data),
                profit-loss: (get profit-loss portfolio-data),
                roi: (get roi portfolio-data),
                asset-count: (len holdings-list),
                last-updated: (get last-updated portfolio-data)
            })
            err-not-found
        )
    )
)

;; [Rest of the original contract functions remain unchanged]
