;; TradePulse Portfolio Tracker Contract

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data structures
(define-map portfolios 
    {owner: principal, id: uint}
    {
        name: (string-ascii 64),
        created-at: uint,
        last-updated: uint,
        total-value: uint,
        profit-loss: int
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
        profit-loss: int
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
                profit-loss: 0
            }
        )
        (var-set next-portfolio-id (+ portfolio-id u1))
        (ok portfolio-id)
    )
)

(define-public (add-holding (portfolio-id uint) (asset (string-ascii 10)) (amount uint) (price uint))
    (let
        (
            (portfolio (get-portfolio portfolio-id))
        )
        (asserts! (is-some portfolio) err-not-found)
        (asserts! (is-eq tx-sender (get owner (unwrap-panic portfolio))) err-unauthorized)
        
        (map-set holdings
            {portfolio-id: portfolio-id, asset: asset}
            {
                amount: amount,
                avg-price: price,
                last-updated: block-height,
                current-price: price,
                value: (* amount price),
                profit-loss: 0
            }
        )
        (update-portfolio-value portfolio-id)
        (ok true)
    )
)

(define-public (update-asset-price (portfolio-id uint) (asset (string-ascii 10)) (new-price uint))
    (let
        (
            (portfolio (get-portfolio portfolio-id))
            (holding (get-holding portfolio-id asset))
        )
        (asserts! (is-some portfolio) err-not-found)
        (asserts! (is-some holding) err-not-found)
        (asserts! (is-eq tx-sender (get owner (unwrap-panic portfolio))) err-unauthorized)
        
        (let
            (
                (unwrapped-holding (unwrap-panic holding))
                (new-value (* (get amount unwrapped-holding) new-price))
                (pl (- new-value (* (get amount unwrapped-holding) (get avg-price unwrapped-holding))))
            )
            (map-set holdings
                {portfolio-id: portfolio-id, asset: asset}
                {
                    amount: (get amount unwrapped-holding),
                    avg-price: (get avg-price unwrapped-holding),
                    last-updated: block-height,
                    current-price: new-price,
                    value: new-value,
                    profit-loss: pl
                }
            )
            (update-portfolio-value portfolio-id)
            (ok true)
        )
    )
)

(define-public (record-transaction 
    (portfolio-id uint)
    (asset (string-ascii 10))
    (type (string-ascii 4))
    (amount uint)
    (price uint))
    (let
        (
            (portfolio (get-portfolio portfolio-id))
            (tx-id (var-get next-transaction-id))
        )
        (asserts! (is-some portfolio) err-not-found)
        (asserts! (is-eq tx-sender (get owner (unwrap-panic portfolio))) err-unauthorized)
        
        (map-set transactions
            {portfolio-id: portfolio-id, tx-id: tx-id}
            {
                asset: asset,
                type: type,
                amount: amount,
                price: price,
                timestamp: block-height,
                value: (* amount price)
            }
        )
        (var-set next-transaction-id (+ tx-id u1))
        (ok tx-id)
    )
)

;; Portfolio analytics
(define-private (update-portfolio-value (portfolio-id uint))
    (let
        (
            (portfolio (get-portfolio portfolio-id))
            (holdings-list (get-portfolio-holdings portfolio-id))
        )
        (match portfolio
            portfolio-data
            (let
                (
                    (total-value (fold + (map get-holding-value holdings-list) u0))
                    (total-pl (fold + (map get-holding-pl holdings-list) 0))
                )
                (map-set portfolios
                    {owner: tx-sender, id: portfolio-id}
                    {
                        name: (get name portfolio-data),
                        created-at: (get created-at portfolio-data),
                        last-updated: block-height,
                        total-value: total-value,
                        profit-loss: total-pl
                    }
                )
                (ok true)
            )
            err-not-found
        )
    )
)

(define-private (get-holding-value (holding {portfolio-id: uint, asset: (string-ascii 10)}))
    (match (map-get? holdings holding)
        holding-data (get value holding-data)
        u0
    )
)

(define-private (get-holding-pl (holding {portfolio-id: uint, asset: (string-ascii 10)}))
    (match (map-get? holdings holding)
        holding-data (get profit-loss holding-data)
        0
    )
)

;; Read functions
(define-read-only (get-portfolio (portfolio-id uint))
    (map-get? portfolios {owner: tx-sender, id: portfolio-id})
)

(define-read-only (get-holding (portfolio-id uint) (asset (string-ascii 10)))
    (map-get? holdings {portfolio-id: portfolio-id, asset: asset})
)

(define-read-only (get-transaction (portfolio-id uint) (tx-id uint))
    (map-get? transactions {portfolio-id: portfolio-id, tx-id: tx-id})
)

(define-read-only (get-portfolio-holdings (portfolio-id uint))
    (map unwrap-panic
        (filter is-some
            (map 
                (lambda (asset)
                    (map-get? holdings {portfolio-id: portfolio-id, asset: asset})
                )
                (list "BTC" "ETH" "STX")
            )
        )
    )
)
