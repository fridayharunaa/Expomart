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
(define-constant ERR_RATING_OUT_OF_RANGE (err u109))
(define-constant ERR_ALREADY_RATED (err u110))
(define-constant ERR_CANNOT_RATE_SELF (err u111))
(define-constant ERR_NOT_TRANSACTION_PARTICIPANT (err u112))
(define-constant ERR_TRANSACTION_NOT_COMPLETED (err u113))
(define-constant PLATFORM_FEE_PERCENT u2)
(define-constant MIN_RATING u1)
(define-constant MAX_RATING u5)
(define-constant REPUTATION_THRESHOLD_TRUSTED u4)
(define-constant REPUTATION_BONUS_TRUSTED u10)
(define-constant ERR_CATEGORY_NOT_FOUND (err u114))
(define-constant ERR_INVALID_CATEGORY (err u115))
(define-constant ERR_CATEGORY_EXISTS (err u116))
(define-constant ERR_INVALID_SEARCH_PARAMS (err u117))
(define-constant MAX_CATEGORIES u50)
(define-constant MAX_SEARCH_RESULTS u100)

;; data vars
(define-data-var next-order-id uint u1)
(define-data-var next-bid-id uint u1)
(define-data-var next-rating-id uint u1)
(define-data-var platform-treasury principal CONTRACT_OWNER)
(define-data-var next-category-id uint u1)
(define-data-var total-categories uint u0)

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
    created-at: uint,
    category-id: uint,
    origin-country: (string-ascii 50),
    tags: (string-ascii 200)
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

(define-map user-reputation
  { user: principal }
  {
    total-ratings: uint,
    total-score: uint,
    average-rating: uint,
    completed-orders: uint,
    successful-bids: uint,
    trusted-status: bool,
    last-updated: uint
  }
)

(define-map transaction-ratings
  { rating-id: uint }
  {
    order-id: uint,
    rater: principal,
    rated-user: principal,
    rating: uint,
    review: (string-ascii 300),
    transaction-type: (string-ascii 20),
    created-at: uint
  }
)

(define-map user-transaction-ratings
  { order-id: uint, rater: principal, rated-user: principal }
  { rating-id: uint, already-rated: bool }
)

(define-map reputation-badges
  { user: principal, badge-type: (string-ascii 30) }
  { earned-at: uint, active: bool }
)

(define-map product-categories
  { category-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    parent-category: (optional uint),
    is-active: bool,
    created-at: uint,
    order-count: uint
  }
)

(define-map category-stats
  { category-id: uint }
  {
    total-orders: uint,
    active-orders: uint,
    completed-orders: uint,
    total-volume: uint,
    avg-price: uint,
    last-updated: uint
  }
)

(define-map category-by-name
  { name: (string-ascii 50) }
  { category-id: uint }
)

(define-map order-search-index
  { order-id: uint }
  {
    category-id: uint,
    price-range: uint,
    country-code: (string-ascii 10),
    is-active: bool,
    exporter-reputation: uint
  }
)

(define-map trending-categories
  { period: (string-ascii 20), rank: uint }
  { category-id: uint, score: uint }
)

;; public functions

(define-public (create-export-order (product-name (string-ascii 100)) (description (string-ascii 500)) (quantity uint) (min-price uint) (duration uint) (category-id uint) (origin-country (string-ascii 50)) (tags (string-ascii 200)))
  (let
    (
      (order-id (var-get next-order-id))
      (deadline (+ stacks-block-height duration))
      (category (unwrap! (map-get? product-categories { category-id: category-id }) ERR_CATEGORY_NOT_FOUND))
      (price-range (get-price-range min-price))
      (exporter-rep (get average-rating (get-user-reputation tx-sender)))
    )
    (asserts! (> quantity u0) ERR_INVALID_AMOUNT)
    (asserts! (> min-price u0) ERR_INVALID_AMOUNT)
    (asserts! (> duration u0) ERR_INVALID_AMOUNT)
    (asserts! (get is-active category) ERR_INVALID_CATEGORY)
    
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
        created-at: stacks-block-height,
        category-id: category-id,
        origin-country: origin-country,
        tags: tags
      }
    )
    
    (map-set order-search-index
      { order-id: order-id }
      {
        category-id: category-id,
        price-range: price-range,
        country-code: (slice-string origin-country u0 u10),
        is-active: true,
        exporter-reputation: exporter-rep
      }
    )
    
    (try! (update-category-stats category-id "new-order" min-price))
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
    
    (unwrap-panic (update-user-stats (get exporter order) "completed-orders"))
    (unwrap-panic (update-user-stats (get bidder bid) "successful-bids"))
    (unwrap-panic (update-category-stats (get category-id order) "complete-order" (get amount bid)))
    
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

(define-public (rate-user (order-id uint) (rated-user principal) (rating uint) (review (string-ascii 300)) (transaction-type (string-ascii 20)))
  (let
    (
      (order (unwrap! (map-get? export-orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
      (rating-id (var-get next-rating-id))
      (existing-rating (map-get? user-transaction-ratings { order-id: order-id, rater: tx-sender, rated-user: rated-user }))
    )
    (asserts! (>= rating MIN_RATING) ERR_RATING_OUT_OF_RANGE)
    (asserts! (<= rating MAX_RATING) ERR_RATING_OUT_OF_RANGE)
    (asserts! (not (is-eq tx-sender rated-user)) ERR_CANNOT_RATE_SELF)
    (asserts! (is-eq (get status order) "completed") ERR_TRANSACTION_NOT_COMPLETED)
    (asserts! (is-none existing-rating) ERR_ALREADY_RATED)
    
    (asserts! (or 
      (and (is-eq tx-sender (get exporter order)) (is-eq rated-user (get bidder (unwrap! (map-get? bids { bid-id: (unwrap! (get winning-bid order) ERR_ORDER_NOT_FOUND) }) ERR_ORDER_NOT_FOUND))))
      (and (is-eq tx-sender (get bidder (unwrap! (map-get? bids { bid-id: (unwrap! (get winning-bid order) ERR_ORDER_NOT_FOUND) }) ERR_ORDER_NOT_FOUND))) (is-eq rated-user (get exporter order)))
    ) ERR_NOT_TRANSACTION_PARTICIPANT)
    
    (map-set transaction-ratings
      { rating-id: rating-id }
      {
        order-id: order-id,
        rater: tx-sender,
        rated-user: rated-user,
        rating: rating,
        review: review,
        transaction-type: transaction-type,
        created-at: stacks-block-height
      }
    )
    
    (map-set user-transaction-ratings
      { order-id: order-id, rater: tx-sender, rated-user: rated-user }
      { rating-id: rating-id, already-rated: true }
    )
    
    (unwrap-panic (update-user-reputation rated-user rating))
    (var-set next-rating-id (+ rating-id u1))
    
    (ok rating-id)
  )
)

(define-public (award-badge (user principal) (badge-type (string-ascii 30)))
  (let
    (
      (user-rep (default-to 
        { total-ratings: u0, total-score: u0, average-rating: u0, completed-orders: u0, successful-bids: u0, trusted-status: false, last-updated: u0 }
        (map-get? user-reputation { user: user })
      ))
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    
    (map-set reputation-badges
      { user: user, badge-type: badge-type }
      { earned-at: stacks-block-height, active: true }
    )
    
    (ok true)
  )
)

(define-public (revoke-badge (user principal) (badge-type (string-ascii 30)))
  (let
    (
      (badge (unwrap! (map-get? reputation-badges { user: user, badge-type: badge-type }) ERR_ORDER_NOT_FOUND))
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    
    (map-set reputation-badges
      { user: user, badge-type: badge-type }
      (merge badge { active: false })
    )
    
    (ok true)
  )
)

(define-public (create-category (name (string-ascii 50)) (description (string-ascii 200)) (parent-category (optional uint)))
  (let
    (
      (category-id (var-get next-category-id))
      (current-categories (var-get total-categories))
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (< current-categories MAX_CATEGORIES) ERR_INVALID_CATEGORY)
    (asserts! (is-none (map-get? category-by-name { name: name })) ERR_CATEGORY_EXISTS)
    
    (match parent-category
      parent-id (asserts! (is-some (map-get? product-categories { category-id: parent-id })) ERR_CATEGORY_NOT_FOUND)
      true
    )
    
    (map-set product-categories
      { category-id: category-id }
      {
        name: name,
        description: description,
        parent-category: parent-category,
        is-active: true,
        created-at: stacks-block-height,
        order-count: u0
      }
    )
    
    (map-set category-by-name
      { name: name }
      { category-id: category-id }
    )
    
    (map-set category-stats
      { category-id: category-id }
      {
        total-orders: u0,
        active-orders: u0,
        completed-orders: u0,
        total-volume: u0,
        avg-price: u0,
        last-updated: stacks-block-height
      }
    )
    
    (var-set next-category-id (+ category-id u1))
    (var-set total-categories (+ current-categories u1))
    (ok category-id)
  )
)

(define-public (update-category (category-id uint) (name (string-ascii 50)) (description (string-ascii 200)) (is-active bool))
  (let
    (
      (category (unwrap! (map-get? product-categories { category-id: category-id }) ERR_CATEGORY_NOT_FOUND))
      (old-name (get name category))
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    
    (if (not (is-eq name old-name))
      (begin
        (map-delete category-by-name { name: old-name })
        (map-set category-by-name { name: name } { category-id: category-id })
      )
      true
    )
    
    (map-set product-categories
      { category-id: category-id }
      (merge category { 
        name: name,
        description: description,
        is-active: is-active
      })
    )
    
    (ok true)
  )
)

(define-public (search-orders-by-category (category-id uint) (min-price uint) (max-price uint) (limit uint))
  (let
    (
      (category (unwrap! (map-get? product-categories { category-id: category-id }) ERR_CATEGORY_NOT_FOUND))
      (search-limit (if (> limit MAX_SEARCH_RESULTS) MAX_SEARCH_RESULTS limit))
    )
    (asserts! (get is-active category) ERR_INVALID_CATEGORY)
    (asserts! (> search-limit u0) ERR_INVALID_SEARCH_PARAMS)
    (asserts! (<= min-price max-price) ERR_INVALID_SEARCH_PARAMS)
    
    (ok { 
      category-id: category-id,
      search-params: { min-price: min-price, max-price: max-price, limit: search-limit },
      results-available: true
    })
  )
)

(define-public (search-orders-by-country (country-code (string-ascii 10)) (limit uint))
  (let
    (
      (search-limit (if (> limit MAX_SEARCH_RESULTS) MAX_SEARCH_RESULTS limit))
    )
    (asserts! (> search-limit u0) ERR_INVALID_SEARCH_PARAMS)
    (asserts! (> (len country-code) u0) ERR_INVALID_SEARCH_PARAMS)
    
    (ok { 
      country-code: country-code,
      limit: search-limit,
      results-available: true
    })
  )
)

(define-public (update-trending-categories (period (string-ascii 20)))
  (let
    (
      (current-block stacks-block-height)
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (or (is-eq period "daily") (is-eq period "weekly") (is-eq period "monthly")) ERR_INVALID_SEARCH_PARAMS)
    
    (map-set trending-categories
      { period: period, rank: u1 }
      { category-id: u1, score: u100 }
    )
    
    (map-set trending-categories
      { period: period, rank: u2 }
      { category-id: u2, score: u85 }
    )
    
    (map-set trending-categories
      { period: period, rank: u3 }
      { category-id: u3, score: u70 }
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

(define-read-only (get-user-reputation (user principal))
  (default-to 
    { total-ratings: u0, total-score: u0, average-rating: u0, completed-orders: u0, successful-bids: u0, trusted-status: false, last-updated: u0 }
    (map-get? user-reputation { user: user })
  )
)

(define-read-only (get-transaction-rating (rating-id uint))
  (map-get? transaction-ratings { rating-id: rating-id })
)

(define-read-only (get-user-ratings-for-order (order-id uint) (rater principal) (rated-user principal))
  (map-get? user-transaction-ratings { order-id: order-id, rater: rater, rated-user: rated-user })
)

(define-read-only (get-user-badge (user principal) (badge-type (string-ascii 30)))
  (map-get? reputation-badges { user: user, badge-type: badge-type })
)

(define-read-only (is-user-trusted (user principal))
  (let
    (
      (user-rep (get-user-reputation user))
    )
    (get trusted-status user-rep)
  )
)

(define-read-only (get-reputation-score (user principal))
  (let
    (
      (user-rep (get-user-reputation user))
    )
    (get average-rating user-rep)
  )
)

(define-read-only (calculate-reputation-bonus (user principal))
  (let
    (
      (user-rep (get-user-reputation user))
      (avg-rating (get average-rating user-rep))
    )
    (if (>= avg-rating REPUTATION_THRESHOLD_TRUSTED)
      REPUTATION_BONUS_TRUSTED
      u0
    )
  )
)

(define-read-only (get-category (category-id uint))
  (map-get? product-categories { category-id: category-id })
)

(define-read-only (get-category-by-name (name (string-ascii 50)))
  (match (map-get? category-by-name { name: name })
    name-entry (map-get? product-categories { category-id: (get category-id name-entry) })
    none
  )
)

(define-read-only (get-category-stats (category-id uint))
  (map-get? category-stats { category-id: category-id })
)

(define-read-only (get-trending-categories (period (string-ascii 20)) (rank uint))
  (map-get? trending-categories { period: period, rank: rank })
)

(define-read-only (get-order-search-info (order-id uint))
  (map-get? order-search-index { order-id: order-id })
)

(define-read-only (get-total-categories)
  (var-get total-categories)
)

(define-read-only (get-next-category-id)
  (var-get next-category-id)
)

(define-read-only (search-orders-by-price-range (min-price uint) (max-price uint))
  (let
    (
      (price-range-min (get-price-range min-price))
      (price-range-max (get-price-range max-price))
    )
    { min-range: price-range-min, max-range: price-range-max, valid: (<= min-price max-price) }
  )
)

(define-read-only (get-category-hierarchy (category-id uint))
  (match (map-get? product-categories { category-id: category-id })
    cat-data (match (get parent-category cat-data)
      parent-id (some { 
        category-id: category-id,
        name: (get name cat-data),
        parent-id: parent-id,
        has-parent: true 
      })
      (some { 
        category-id: category-id,
        name: (get name cat-data),
        parent-id: u0,
        has-parent: false 
      })
    )
    none
  )
)

;; private functions

(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

(define-private (update-user-reputation (user principal) (new-rating uint))
  (let
    (
      (current-rep (default-to 
        { total-ratings: u0, total-score: u0, average-rating: u0, completed-orders: u0, successful-bids: u0, trusted-status: false, last-updated: u0 }
        (map-get? user-reputation { user: user })
      ))
      (new-total-ratings (+ (get total-ratings current-rep) u1))
      (new-total-score (+ (get total-score current-rep) new-rating))
      (new-average (/ new-total-score new-total-ratings))
      (new-trusted-status (>= new-average REPUTATION_THRESHOLD_TRUSTED))
    )
    
    (map-set user-reputation
      { user: user }
      {
        total-ratings: new-total-ratings,
        total-score: new-total-score,
        average-rating: new-average,
        completed-orders: (get completed-orders current-rep),
        successful-bids: (get successful-bids current-rep),
        trusted-status: new-trusted-status,
        last-updated: stacks-block-height
      }
    )
    
    (ok true)
  )
)

(define-private (update-user-stats (user principal) (stat-type (string-ascii 20)))
  (let
    (
      (current-rep (default-to 
        { total-ratings: u0, total-score: u0, average-rating: u0, completed-orders: u0, successful-bids: u0, trusted-status: false, last-updated: u0 }
        (map-get? user-reputation { user: user })
      ))
    )
    
    (begin
      (if (is-eq stat-type "completed-orders")
        (map-set user-reputation
          { user: user }
          (merge current-rep { 
            completed-orders: (+ (get completed-orders current-rep) u1),
            last-updated: stacks-block-height
          })
        )
        (if (is-eq stat-type "successful-bids")
          (map-set user-reputation
            { user: user }
            (merge current-rep { 
              successful-bids: (+ (get successful-bids current-rep) u1),
              last-updated: stacks-block-height
            })
          )
          false
        )
      )
      (ok true)
    )
  )
)

(define-private (get-price-range (price uint))
  (if (< price u1000)
    u1
    (if (< price u10000)
      u2
      (if (< price u100000)
        u3
        (if (< price u1000000)
          u4
          u5
        )
      )
    )
  )
)

(define-private (slice-string (input (string-ascii 50)) (start uint) (end uint))
  (if (>= start (len input))
    ""
    (let
      (
        (actual-end (if (> end (len input)) (len input) end))
        (slice-length (- actual-end start))
      )
      (if (<= slice-length u0)
        ""
        (if (<= slice-length u10)
          (unwrap-panic (as-max-len? input u10))
          (unwrap-panic (as-max-len? input u10))
        )
      )
    )
  )
)

(define-private (update-category-stats (category-id uint) (action (string-ascii 20)) (amount uint))
  (let
    (
      (current-stats (default-to 
        { total-orders: u0, active-orders: u0, completed-orders: u0, total-volume: u0, avg-price: u0, last-updated: u0 }
        (map-get? category-stats { category-id: category-id })
      ))
      (current-category (unwrap! (map-get? product-categories { category-id: category-id }) ERR_CATEGORY_NOT_FOUND))
    )
    
    (if (is-eq action "new-order")
      (begin
        (map-set category-stats
          { category-id: category-id }
          (merge current-stats {
            total-orders: (+ (get total-orders current-stats) u1),
            active-orders: (+ (get active-orders current-stats) u1),
            total-volume: (+ (get total-volume current-stats) amount),
            avg-price: (if (> (+ (get total-orders current-stats) u1) u0)
              (/ (+ (get total-volume current-stats) amount) (+ (get total-orders current-stats) u1))
              u0
            ),
            last-updated: stacks-block-height
          })
        )
        (map-set product-categories
          { category-id: category-id }
          (merge current-category {
            order-count: (+ (get order-count current-category) u1)
          })
        )
      )
      (if (is-eq action "complete-order")
        (map-set category-stats
          { category-id: category-id }
          (merge current-stats {
            active-orders: (- (get active-orders current-stats) u1),
            completed-orders: (+ (get completed-orders current-stats) u1),
            last-updated: stacks-block-height
          })
        )
        false
      )
    )
    
    (ok true)
  )
)