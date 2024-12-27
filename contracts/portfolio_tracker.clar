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
        last-updated: uint
    }
)

(define-map holdings
    {portfolio-id: uint, asset: (string-ascii 10)}
    {
        amount: uint,
        avg-price: uint,
        last-updated: uint
    }
)

(define-map transactions
    {portfolio-id: uint, tx-id: uint}
    {
        asset: (string-ascii 10),
        type: (string-ascii 4),
        amount: uint,
        price: uint,
        timestamp: uint
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
                last-updated: block-height
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
                last-updated: block-height
            }
        )
        (ok true)
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
                timestamp: block-height
            }
        )
        (var-set next-transaction-id (+ tx-id u1))
        (ok tx-id)
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