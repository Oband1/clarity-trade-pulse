;; TradePulse Portfolio Tracker Contract

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-price-out-of-bounds (err u104))
(define-constant err-update-too-frequent (err u105))

;; Events
(define-data-var last-price-update uint u0)
(define-constant min-update-interval u10) ;; Minimum blocks between updates

;; Data structures
(define-map portfolios 
    {owner: principal, id: uint}
    {
        name: (string-ascii 64),
        created-at: uint,
        last-updated: uint,
        total-value: uint,
        profit-loss: int,
        roi: int,
        diversity-score: uint,
        risk-score: uint
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
        total-invested: uint,
        weight: uint
    }
)

;; [Previous data structures remain unchanged]

;; Enhanced analytics functions
(define-private (calculate-portfolio-diversity (portfolio-id uint))
    (let
        (
            (holdings-list (get-portfolio-holdings portfolio-id))
            (total-value (get-portfolio-value portfolio-id))
        )
        (if (is-eq total-value u0)
            u0
            (fold calculate-holding-weight holdings-list u0)
        )
    )
)

(define-private (calculate-holding-weight (holding {asset: (string-ascii 10), value: uint}) (acc uint))
    (let
        (
            (weight (/ (* holding.value u100) (get-portfolio-value portfolio-id)))
        )
        (+ acc (if (> weight u20) u1 u0))
    )
)

;; Enhanced batch operations
(define-public (batch-update-prices 
    (portfolio-id uint) 
    (assets (list 20 (string-ascii 10))) 
    (prices (list 20 uint)))
    (let
        (
            (portfolio (get-portfolio portfolio-id))
            (current-block block-height)
        )
        (asserts! (is-some portfolio) err-not-found)
        (asserts! (is-eq tx-sender (get owner (unwrap-panic portfolio))) err-unauthorized)
        (asserts! (is-eq (len assets) (len prices)) err-invalid-input)
        (asserts! (> current-block (+ (var-get last-price-update) min-update-interval)) err-update-too-frequent)
        
        ;; Validate price bounds
        (asserts! (fold check-price-bounds prices true) err-price-out-of-bounds)
        
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
        
        ;; Update portfolio metrics
        (update-portfolio-metrics portfolio-id)
        (var-set last-price-update current-block)
        (ok true)
    )
)

;; Enhanced portfolio metrics
(define-read-only (get-portfolio-metrics (portfolio-id uint))
    (let
        (
            (portfolio (get-portfolio portfolio-id))
            (holdings-list (get-portfolio-holdings portfolio-id))
            (diversity-score (calculate-portfolio-diversity portfolio-id))
        )
        (match portfolio
            portfolio-data
            (ok {
                total-value: (get total-value portfolio-data),
                profit-loss: (get profit-loss portfolio-data),
                roi: (get roi portfolio-data),
                asset-count: (len holdings-list),
                last-updated: (get last-updated portfolio-data),
                diversity-score: diversity-score,
                risk-score: (calculate-risk-score portfolio-id)
            })
            err-not-found
        )
    )
)

;; [Rest of the original contract functions remain unchanged]
