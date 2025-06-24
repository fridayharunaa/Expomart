;; title: Expomart
;; version: 1.0.0
;; summary: Export Bidding Market - Global buyers bid on export orders
;; description: A decentralized marketplace where exporters can list their products and global buyers can place competitive bids

;; traits

;; token definitions

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ORDER_NOT_FOUND (err u101))
(define-constant ERR_ORDER_EXPIRED (err u102))
(define-constant ERR_ORDER_CLOSED (err u103))
(define-constant ERR_BID_TOO_LOW (err u104))
(define-constant ERR_INSUFFICIENT_FUNDS (err u105))
(define-constant ERR_INVALID_AMOUNT (err u106))
(define-constant ERR_SELF_BID (err u107))
(define-constant ERR_ORDER_ACTIVE (err u108))
(define-constant PLATFORM_FEE_PERCENT u2)

;; data vars
(define-data-var next-order-id uint u1)
(define-data-var next-bid-id uint u1)
(define-data-var platform-treasury principal CONTRACT_OWNER)

;; data maps
(define-map export-orders
  { order-id: uint }
  {
    exporter: principal,
    product-name: (string-ascii 100),
    description: (string-ascii 500),
    quantity: uint,
    min-price: uint,
    deadline: uint,
    status: (string-ascii 20),
    winning-bid: (optional uint),
    created-at: uint
  }
)

(define-map bids
  { bid-id: uint }
  {
    order-id: uint,
    bidder: principal,
    amount: uint,
    message: (string-ascii 200),
    created-at: uint,
    status: (string-ascii 20)
  }
)

(define-map order-bids
  { order-id: uint, bidder: principal }
  { bid-id: uint, amount: uint }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-map order-highest-bid
  { order-id: uint }
  { bid-id: uint, amount: uint, bidder: principal }
)

;; public functions

(define-public (create-export-order (product-name (string-ascii 100)) (description (string-ascii 500)) (quantity uint) (min-price uint) (duration uint))
  (let
    (
      (order-id (var-get next-order-id))
      (deadline (+ stacks-block-height duration))
    )
    (asserts! (> quantity u0) ERR_INVALID_AMOUNT)
    (asserts! (> min-price u0) ERR_INVALID_AMOUNT)
    (asserts! (> duration u0) ERR_INVALID_AMOUNT)
    
    (map-set export-orders
      { order-id: order-id }
      {
        exporter: tx-sender,
        product-name: product-name,
        description: description,
        quantity: quantity,
        min-price: min-price,
        deadline: deadline,
        status: "active",
        winning-bid: none,
        created-at: stacks-block-height
      }
    )
    
    (var-set next-order-id (+ order-id u1))
    (ok order-id)
  )
)

(define-public (place-bid (order-id uint) (amount uint) (message (string-ascii 200)))
  (let
    (
      (order (unwrap! (map-get? export-orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
      (bid-id (var-get next-bid-id))
      (user-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender }))))
      (current-highest (map-get? order-highest-bid { order-id: order-id }))
    )
    (asserts! (is-eq (get status order) "active") ERR_ORDER_CLOSED)
    (asserts! (< stacks-block-height (get deadline order)) ERR_ORDER_EXPIRED)
    (asserts! (not (is-eq tx-sender (get exporter order))) ERR_SELF_BID)
    (asserts! (>= amount (get min-price order)) ERR_BID_TOO_LOW)
    (asserts! (>= user-balance amount) ERR_INSUFFICIENT_FUNDS)
    
    (match current-highest
      highest-bid (asserts! (> amount (get amount highest-bid)) ERR_BID_TOO_LOW)
      true
    )
    
    (map-set bids
      { bid-id: bid-id }
      {
        order-id: order-id,
        bidder: tx-sender,
        amount: amount,
        message: message,
        created-at: stacks-block-height,
        status: "active"
      }
    )
    
    (map-set order-bids
      { order-id: order-id, bidder: tx-sender }
      { bid-id: bid-id, amount: amount }
    )
    
    (map-set order-highest-bid
      { order-id: order-id }
      { bid-id: bid-id, amount: amount, bidder: tx-sender }
    )
    
    (var-set next-bid-id (+ bid-id u1))
    (ok bid-id)
  )
)

(define-public (accept-bid (order-id uint) (bid-id uint))
  (let
    (
      (order (unwrap! (map-get? export-orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
      (bid (unwrap! (map-get? bids { bid-id: bid-id }) ERR_ORDER_NOT_FOUND))
      (platform-fee (/ (* (get amount bid) PLATFORM_FEE_PERCENT) u100))
      (exporter-amount (- (get amount bid) platform-fee))
    )
    (asserts! (is-eq tx-sender (get exporter order)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status order) "active") ERR_ORDER_CLOSED)
    (asserts! (is-eq (get order-id bid) order-id) ERR_ORDER_NOT_FOUND)
    
    (try! (stx-transfer? (get amount bid) (get bidder bid) (get exporter order)))
    (try! (stx-transfer? platform-fee (get bidder bid) (var-get platform-treasury)))
    
    (map-set export-orders
      { order-id: order-id }
      (merge order { status: "completed", winning-bid: (some bid-id) })
    )
    
    (map-set bids
      { bid-id: bid-id }
      (merge bid { status: "accepted" })
    )
    
    (ok true)
  )
)

(define-public (cancel-order (order-id uint))
  (let
    (
      (order (unwrap! (map-get? export-orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get exporter order)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status order) "active") ERR_ORDER_CLOSED)
    
    (map-set export-orders
      { order-id: order-id }
      (merge order { status: "cancelled" })
    )
    
    (ok true)
  )
)

(define-public (deposit-funds (amount uint))
  (let
    (
      (current-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender }))))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set user-balances
      { user: tx-sender }
      { balance: (+ current-balance amount) }
    )
    
    (ok true)
  )
)

(define-public (withdraw-funds (amount uint))
  (let
    (
      (current-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender }))))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= current-balance amount) ERR_INSUFFICIENT_FUNDS)
    
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    
    (map-set user-balances
      { user: tx-sender }
      { balance: (- current-balance amount) }
    )
    
    (ok true)
  )
)

;; read only functions

(define-read-only (get-export-order (order-id uint))
  (map-get? export-orders { order-id: order-id })
)

(define-read-only (get-bid (bid-id uint))
  (map-get? bids { bid-id: bid-id })
)

(define-read-only (get-user-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-read-only (get-highest-bid (order-id uint))
  (map-get? order-highest-bid { order-id: order-id })
)

(define-read-only (get-user-bid-for-order (order-id uint) (bidder principal))
  (map-get? order-bids { order-id: order-id, bidder: bidder })
)

(define-read-only (is-order-expired (order-id uint))
  (match (map-get? export-orders { order-id: order-id })
    order (>= stacks-block-height (get deadline order))
    false
  )
)

(define-read-only (get-next-order-id)
  (var-get next-order-id)
)

(define-read-only (get-next-bid-id)
  (var-get next-bid-id)
)

(define-read-only (get-platform-fee-for-amount (amount uint))
  (/ (* amount PLATFORM_FEE_PERCENT) u100)
)

;; private functions

(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)