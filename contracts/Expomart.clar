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
(define-constant ERR_DOCUMENT_NOT_FOUND (err u118))
(define-constant ERR_DOCUMENT_EXPIRED (err u119))
(define-constant ERR_INVALID_DOCUMENT (err u120))
(define-constant ERR_DOCUMENT_EXISTS (err u121))
(define-constant ERR_COMPLIANCE_NOT_MET (err u122))
(define-constant ERR_VERIFICATION_FAILED (err u123))
(define-constant ERR_INVALID_EXPIRY (err u124))
(define-constant MAX_DOCUMENTS_PER_USER u25)
(define-constant DOCUMENT_VALIDITY_PERIOD u52560)
(define-constant COMPLIANCE_GRACE_PERIOD u1440)
(define-constant ERR_MARKET_DATA_NOT_FOUND (err u125))
(define-constant ERR_INVALID_TIMEFRAME (err u126))
(define-constant ERR_INSUFFICIENT_DATA (err u127))
(define-constant ERR_PRICE_ANALYSIS_FAILED (err u128))
(define-constant MAX_PRICE_HISTORY_ENTRIES u100)
(define-constant MIN_DATA_POINTS_FOR_ANALYSIS u5)
(define-constant PRICE_VOLATILITY_THRESHOLD u20)
(define-constant MARKET_ANALYSIS_WINDOW u4320)

;; data vars
(define-data-var next-order-id uint u1)
(define-data-var next-bid-id uint u1)
(define-data-var next-rating-id uint u1)
(define-data-var platform-treasury principal CONTRACT_OWNER)
(define-data-var next-category-id uint u1)
(define-data-var total-categories uint u0)
(define-data-var next-document-id uint u1)
(define-data-var next-compliance-id uint u1)
(define-data-var total-documents uint u0)
(define-data-var next-market-entry-id uint u1)
(define-data-var next-price-alert-id uint u1)
(define-data-var market-analysis-last-updated uint u0)

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

(define-map trade-documents
  { document-id: uint }
  {
    owner: principal,
    document-type: (string-ascii 50),
    document-hash: (string-ascii 64),
    issuer: (string-ascii 100),
    issue-date: uint,
    expiry-date: uint,
    status: (string-ascii 20),
    verification-status: (string-ascii 20),
    created-at: uint,
    last-updated: uint
  }
)

(define-map user-documents
  { user: principal, document-type: (string-ascii 50) }
  { document-id: uint, is-active: bool }
)

(define-map compliance-requirements
  { compliance-id: uint }
  {
    category-id: uint,
    destination-country: (string-ascii 50),
    required-documents: (string-ascii 200),
    mandatory: bool,
    created-by: principal,
    created-at: uint,
    is-active: bool
  }
)

(define-map order-compliance
  { order-id: uint }
  {
    compliance-status: (string-ascii 20),
    required-docs-count: uint,
    verified-docs-count: uint,
    last-check: uint,
    compliance-deadline: uint,
    verification-notes: (string-ascii 300)
  }
)

(define-map document-verifications
  { document-id: uint, verifier: principal }
  {
    verification-date: uint,
    verification-result: bool,
    verification-notes: (string-ascii 200),
    verifier-reputation: uint
  }
)

(define-map expired-documents-tracker
  { owner: principal, month: uint }
  { expired-count: uint, total-documents: uint }
)

(define-map market-price-history
  { category-id: uint, region: (string-ascii 50), period: uint }
  {
    average-price: uint,
    min-price: uint,
    max-price: uint,
    total-orders: uint,
    total-volume: uint,
    period-start: uint,
    period-end: uint,
    last-updated: uint
  }
)

(define-map price-trend-analysis
  { category-id: uint, region: (string-ascii 50) }
  {
    current-avg-price: uint,
    previous-avg-price: uint,
    price-change-percent: uint,
    volatility-score: uint,
    trend-direction: (string-ascii 20),
    confidence-level: uint,
    data-points: uint,
    last-analysis: uint
  }
)

(define-map market-insights
  { insight-id: uint }
  {
    category-id: uint,
    region: (string-ascii 50),
    insight-type: (string-ascii 30),
    title: (string-ascii 100),
    description: (string-ascii 300),
    impact-score: uint,
    generated-at: uint,
    expires-at: uint,
    is-active: bool
  }
)

(define-map price-recommendations
  { category-id: uint, region: (string-ascii 50), price-tier: uint }
  {
    recommended-min-price: uint,
    recommended-max-price: uint,
    success-probability: uint,
    market-position: (string-ascii 20),
    reasoning: (string-ascii 200),
    based-on-orders: uint,
    last-updated: uint
  }
)

(define-map regional-market-stats
  { region: (string-ascii 50), category-id: uint }
  {
    active-exporters: uint,
    active-buyers: uint,
    avg-order-value: uint,
    total-transactions: uint,
    market-activity-score: uint,
    seasonal-factor: uint,
    competition-level: uint,
    last-calculated: uint
  }
)

(define-map price-alerts
  { alert-id: uint }
  {
    user: principal,
    category-id: uint,
    region: (string-ascii 50),
    target-price: uint,
    alert-type: (string-ascii 20),
    trigger-condition: (string-ascii 30),
    is-triggered: bool,
    created-at: uint,
    triggered-at: (optional uint),
    is-active: bool
  }
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

(define-public (upload-trade-document (document-type (string-ascii 50)) (document-hash (string-ascii 64)) (issuer (string-ascii 100)) (expiry-duration uint))
  (let
    (
      (document-id (var-get next-document-id))
      (current-docs (var-get total-documents))
      (user-doc-count (get-user-document-count tx-sender))
      (expiry-date (+ stacks-block-height expiry-duration))
    )
    (asserts! (< user-doc-count MAX_DOCUMENTS_PER_USER) ERR_INVALID_DOCUMENT)
    (asserts! (> expiry-duration u0) ERR_INVALID_EXPIRY)
    (asserts! (< expiry-duration DOCUMENT_VALIDITY_PERIOD) ERR_INVALID_EXPIRY)
    (asserts! (> (len document-type) u0) ERR_INVALID_DOCUMENT)
    (asserts! (> (len document-hash) u0) ERR_INVALID_DOCUMENT)
    
    (asserts! (is-none (map-get? user-documents { user: tx-sender, document-type: document-type })) ERR_DOCUMENT_EXISTS)
    
    (map-set trade-documents
      { document-id: document-id }
      {
        owner: tx-sender,
        document-type: document-type,
        document-hash: document-hash,
        issuer: issuer,
        issue-date: stacks-block-height,
        expiry-date: expiry-date,
        status: "pending",
        verification-status: "unverified",
        created-at: stacks-block-height,
        last-updated: stacks-block-height
      }
    )
    
    (map-set user-documents
      { user: tx-sender, document-type: document-type }
      { document-id: document-id, is-active: true }
    )
    
    (var-set next-document-id (+ document-id u1))
    (var-set total-documents (+ current-docs u1))
    (ok document-id)
  )
)

(define-public (verify-document (document-id uint) (verification-result bool) (verification-notes (string-ascii 200)))
  (let
    (
      (document (unwrap! (map-get? trade-documents { document-id: document-id }) ERR_DOCUMENT_NOT_FOUND))
      (verifier-rep (get average-rating (get-user-reputation tx-sender)))
    )
    (asserts! (not (is-eq tx-sender (get owner document))) ERR_NOT_AUTHORIZED)
    (asserts! (< stacks-block-height (get expiry-date document)) ERR_DOCUMENT_EXPIRED)
    (asserts! (is-eq (get status document) "pending") ERR_INVALID_DOCUMENT)
    (asserts! (>= verifier-rep u3) ERR_NOT_AUTHORIZED)
    
    (map-set document-verifications
      { document-id: document-id, verifier: tx-sender }
      {
        verification-date: stacks-block-height,
        verification-result: verification-result,
        verification-notes: verification-notes,
        verifier-reputation: verifier-rep
      }
    )
    
    (map-set trade-documents
      { document-id: document-id }
      (merge document {
        status: (if verification-result "verified" "rejected"),
        verification-status: (if verification-result "verified" "failed"),
        last-updated: stacks-block-height
      })
    )
    
    (ok true)
  )
)

(define-public (update-document-status (document-id uint) (new-status (string-ascii 20)))
  (let
    (
      (document (unwrap! (map-get? trade-documents { document-id: document-id }) ERR_DOCUMENT_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get owner document)) ERR_NOT_AUTHORIZED)
    (asserts! (or (is-eq new-status "active") (is-eq new-status "inactive") (is-eq new-status "renewed")) ERR_INVALID_DOCUMENT)
    
    (map-set trade-documents
      { document-id: document-id }
      (merge document {
        status: new-status,
        last-updated: stacks-block-height
      })
    )
    
    (ok true)
  )
)

(define-public (create-compliance-requirement (category-id uint) (destination-country (string-ascii 50)) (required-documents (string-ascii 200)) (mandatory bool))
  (let
    (
      (compliance-id (var-get next-compliance-id))
      (category (unwrap! (map-get? product-categories { category-id: category-id }) ERR_CATEGORY_NOT_FOUND))
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active category) ERR_INVALID_CATEGORY)
    (asserts! (> (len destination-country) u0) ERR_INVALID_SEARCH_PARAMS)
    (asserts! (> (len required-documents) u0) ERR_INVALID_SEARCH_PARAMS)
    
    (map-set compliance-requirements
      { compliance-id: compliance-id }
      {
        category-id: category-id,
        destination-country: destination-country,
        required-documents: required-documents,
        mandatory: mandatory,
        created-by: tx-sender,
        created-at: stacks-block-height,
        is-active: true
      }
    )
    
    (var-set next-compliance-id (+ compliance-id u1))
    (ok compliance-id)
  )
)

(define-public (check-order-compliance (order-id uint))
  (let
    (
      (order (unwrap! (map-get? export-orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
      (compliance-deadline (+ (get deadline order) COMPLIANCE_GRACE_PERIOD))
      (doc-count (count-verified-documents-for-order order-id (get category-id order)))
    )
    (asserts! (is-eq tx-sender (get exporter order)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status order) "active") ERR_ORDER_CLOSED)
    
    (map-set order-compliance
      { order-id: order-id }
      {
        compliance-status: (if (>= (get verified doc-count) (get required doc-count)) "compliant" "pending"),
        required-docs-count: (get required doc-count),
        verified-docs-count: (get verified doc-count),
        last-check: stacks-block-height,
        compliance-deadline: compliance-deadline,
        verification-notes: "System check completed"
      }
    )
    
    (ok { required: (get required doc-count), verified: (get verified doc-count) })
  )
)

(define-public (track-expired-documents)
  (let
    (
      (current-month (/ stacks-block-height u4320))
      (user-docs (get-user-document-count tx-sender))
      (expired-docs (count-expired-documents tx-sender))
    )
    
    (map-set expired-documents-tracker
      { owner: tx-sender, month: current-month }
      { expired-count: expired-docs, total-documents: user-docs }
    )
    
    (ok { total: user-docs, expired: expired-docs })
  )
)

(define-public (renew-document (document-id uint) (new-expiry-duration uint))
  (let
    (
      (document (unwrap! (map-get? trade-documents { document-id: document-id }) ERR_DOCUMENT_NOT_FOUND))
      (new-expiry-date (+ stacks-block-height new-expiry-duration))
    )
    (asserts! (is-eq tx-sender (get owner document)) ERR_NOT_AUTHORIZED)
    (asserts! (> new-expiry-duration u0) ERR_INVALID_EXPIRY)
    (asserts! (< new-expiry-duration DOCUMENT_VALIDITY_PERIOD) ERR_INVALID_EXPIRY)
    (asserts! (is-eq (get verification-status document) "verified") ERR_VERIFICATION_FAILED)
    
    (map-set trade-documents
      { document-id: document-id }
      (merge document {
        expiry-date: new-expiry-date,
        status: "renewed",
        last-updated: stacks-block-height
      })
    )
    
    (ok new-expiry-date)
  )
)

(define-public (record-market-price (category-id uint) (region (string-ascii 50)) (price uint) (order-count uint) (volume uint))
  (let
    (
      (current-period (/ stacks-block-height u4320))
      (existing-data (map-get? market-price-history { category-id: category-id, region: region, period: current-period }))
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (> price u0) ERR_INVALID_AMOUNT)
    (asserts! (> order-count u0) ERR_INVALID_AMOUNT)
    
    (match existing-data
      current-data (map-set market-price-history
        { category-id: category-id, region: region, period: current-period }
        {
          average-price: (/ (+ (* (get average-price current-data) (get total-orders current-data)) (* price order-count)) (+ (get total-orders current-data) order-count)),
          min-price: (if (< price (get min-price current-data)) price (get min-price current-data)),
          max-price: (if (> price (get max-price current-data)) price (get max-price current-data)),
          total-orders: (+ (get total-orders current-data) order-count),
          total-volume: (+ (get total-volume current-data) volume),
          period-start: (get period-start current-data),
          period-end: stacks-block-height,
          last-updated: stacks-block-height
        }
      )
      (map-set market-price-history
        { category-id: category-id, region: region, period: current-period }
        {
          average-price: price,
          min-price: price,
          max-price: price,
          total-orders: order-count,
          total-volume: volume,
          period-start: stacks-block-height,
          period-end: stacks-block-height,
          last-updated: stacks-block-height
        }
      )
    )
    
    (ok true)
  )
)

(define-public (generate-price-trend-analysis (category-id uint) (region (string-ascii 50)))
  (let
    (
      (current-period (/ stacks-block-height u4320))
      (previous-period (- current-period u1))
      (current-data (map-get? market-price-history { category-id: category-id, region: region, period: current-period }))
      (previous-data (map-get? market-price-history { category-id: category-id, region: region, period: previous-period }))
    )
    (asserts! (is-some current-data) ERR_INSUFFICIENT_DATA)
    (asserts! (is-some previous-data) ERR_INSUFFICIENT_DATA)
    
    (let
      (
        (current-price (get average-price (unwrap-panic current-data)))
        (previous-price (get average-price (unwrap-panic previous-data)))
        (price-change (if (> current-price previous-price) 
          (/ (* (- current-price previous-price) u100) previous-price)
          (/ (* (- previous-price current-price) u100) previous-price)
        ))
        (volatility (calculate-price-volatility category-id region))
        (trend-dir (if (> current-price previous-price) "rising" "falling"))
        (data-points (+ (get total-orders (unwrap-panic current-data)) (get total-orders (unwrap-panic previous-data))))
        (confidence (if (>= data-points MIN_DATA_POINTS_FOR_ANALYSIS) u85 u45))
      )
      
      (map-set price-trend-analysis
        { category-id: category-id, region: region }
        {
          current-avg-price: current-price,
          previous-avg-price: previous-price,
          price-change-percent: price-change,
          volatility-score: volatility,
          trend-direction: trend-dir,
          confidence-level: confidence,
          data-points: data-points,
          last-analysis: stacks-block-height
        }
      )
      
      (var-set market-analysis-last-updated stacks-block-height)
      (ok { price-change: price-change, trend: trend-dir, confidence: confidence })
    )
  )
)

(define-public (generate-price-recommendation (category-id uint) (region (string-ascii 50)) (desired-tier uint))
  (let
    (
      (trend-data (map-get? price-trend-analysis { category-id: category-id, region: region }))
      (market-stats (map-get? regional-market-stats { region: region, category-id: category-id }))
    )
    (asserts! (is-some trend-data) ERR_MARKET_DATA_NOT_FOUND)
    (asserts! (<= desired-tier u3) ERR_INVALID_AMOUNT)
    
    (let
      (
        (base-price (get current-avg-price (unwrap-panic trend-data)))
        (volatility (get volatility-score (unwrap-panic trend-data)))
        (competition-level (match market-stats
          stats (get competition-level stats)
          u50
        ))
        (tier-multiplier (if (is-eq desired-tier u1) 
          u85
          (if (is-eq desired-tier u2) u100 u115)
        ))
        (recommended-min (/ (* base-price tier-multiplier) u100))
        (recommended-max (/ (* base-price (+ tier-multiplier u15)) u100))
        (success-prob (calculate-success-probability volatility competition-level desired-tier))
        (position (if (is-eq desired-tier u1) "budget" (if (is-eq desired-tier u2) "standard" "premium")))
        (reasoning "Based on market trends and competition analysis")
      )
      
      (map-set price-recommendations
        { category-id: category-id, region: region, price-tier: desired-tier }
        {
          recommended-min-price: recommended-min,
          recommended-max-price: recommended-max,
          success-probability: success-prob,
          market-position: position,
          reasoning: reasoning,
          based-on-orders: (get data-points (unwrap-panic trend-data)),
          last-updated: stacks-block-height
        }
      )
      
      (ok { min-price: recommended-min, max-price: recommended-max, success-rate: success-prob })
    )
  )
)

(define-public (create-price-alert (category-id uint) (region (string-ascii 50)) (target-price uint) (alert-type (string-ascii 20)) (condition (string-ascii 30)))
  (let
    (
      (alert-id (var-get next-price-alert-id))
    )
    (asserts! (> target-price u0) ERR_INVALID_AMOUNT)
    
    (map-set price-alerts
      { alert-id: alert-id }
      {
        user: tx-sender,
        category-id: category-id,
        region: region,
        target-price: target-price,
        alert-type: alert-type,
        trigger-condition: condition,
        is-triggered: false,
        created-at: stacks-block-height,
        triggered-at: none,
        is-active: true
      }
    )
    
    (var-set next-price-alert-id (+ alert-id u1))
    (ok alert-id)
  )
)

(define-public (update-regional-market-stats (region (string-ascii 50)) (category-id uint) (exporters uint) (buyers uint) (avg-value uint) (transactions uint))
  (let
    (
      (activity-score (calculate-market-activity-score exporters buyers transactions))
      (seasonal-factor (calculate-seasonal-factor stacks-block-height))
      (competition-score (calculate-competition-level exporters transactions))
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    
    (map-set regional-market-stats
      { region: region, category-id: category-id }
      {
        active-exporters: exporters,
        active-buyers: buyers,
        avg-order-value: avg-value,
        total-transactions: transactions,
        market-activity-score: activity-score,
        seasonal-factor: seasonal-factor,
        competition-level: competition-score,
        last-calculated: stacks-block-height
      }
    )
    
    (ok true)
  )
)

(define-public (generate-market-insight (category-id uint) (region (string-ascii 50)) (insight-type (string-ascii 30)) (title (string-ascii 100)) (description (string-ascii 300)) (impact uint))
  (let
    (
      (insight-id (var-get next-market-entry-id))
      (expires-at (+ stacks-block-height u17280))
    )
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (<= impact u100) ERR_INVALID_AMOUNT)
    
    (map-set market-insights
      { insight-id: insight-id }
      {
        category-id: category-id,
        region: region,
        insight-type: insight-type,
        title: title,
        description: description,
        impact-score: impact,
        generated-at: stacks-block-height,
        expires-at: expires-at,
        is-active: true
      }
    )
    
    (var-set next-market-entry-id (+ insight-id u1))
    (ok insight-id)
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

(define-read-only (get-trade-document (document-id uint))
  (map-get? trade-documents { document-id: document-id })
)

(define-read-only (get-user-document (user principal) (document-type (string-ascii 50)))
  (map-get? user-documents { user: user, document-type: document-type })
)

(define-read-only (get-compliance-requirement (compliance-id uint))
  (map-get? compliance-requirements { compliance-id: compliance-id })
)

(define-read-only (get-order-compliance-status (order-id uint))
  (map-get? order-compliance { order-id: order-id })
)

(define-read-only (get-document-verification (document-id uint) (verifier principal))
  (map-get? document-verifications { document-id: document-id, verifier: verifier })
)

(define-read-only (get-expired-documents-summary (owner principal) (month uint))
  (map-get? expired-documents-tracker { owner: owner, month: month })
)

(define-read-only (get-total-documents)
  (var-get total-documents)
)

(define-read-only (get-next-document-id)
  (var-get next-document-id)
)

(define-read-only (get-next-compliance-id)
  (var-get next-compliance-id)
)

(define-read-only (is-document-expired (document-id uint))
  (match (map-get? trade-documents { document-id: document-id })
    document (>= stacks-block-height (get expiry-date document))
    false
  )
)

(define-read-only (is-document-verified (document-id uint))
  (match (map-get? trade-documents { document-id: document-id })
    document (is-eq (get verification-status document) "verified")
    false
  )
)

(define-read-only (get-document-days-until-expiry (document-id uint))
  (match (map-get? trade-documents { document-id: document-id })
    document (if (> (get expiry-date document) stacks-block-height)
      (- (get expiry-date document) stacks-block-height)
      u0
    )
    u0
  )
)

(define-read-only (get-market-price-history (category-id uint) (region (string-ascii 50)) (period uint))
  (map-get? market-price-history { category-id: category-id, region: region, period: period })
)

(define-read-only (get-price-trend-analysis (category-id uint) (region (string-ascii 50)))
  (map-get? price-trend-analysis { category-id: category-id, region: region })
)

(define-read-only (get-price-recommendation (category-id uint) (region (string-ascii 50)) (price-tier uint))
  (map-get? price-recommendations { category-id: category-id, region: region, price-tier: price-tier })
)

(define-read-only (get-regional-market-stats (region (string-ascii 50)) (category-id uint))
  (map-get? regional-market-stats { region: region, category-id: category-id })
)

(define-read-only (get-market-insight (insight-id uint))
  (map-get? market-insights { insight-id: insight-id })
)

(define-read-only (get-price-alert (alert-id uint))
  (map-get? price-alerts { alert-id: alert-id })
)

(define-read-only (get-current-market-period)
  (/ stacks-block-height u4320)
)

(define-read-only (get-market-analysis-status)
  {
    last-updated: (var-get market-analysis-last-updated),
    current-period: (get-current-market-period),
    next-market-entry-id: (var-get next-market-entry-id),
    next-alert-id: (var-get next-price-alert-id)
  }
)

(define-read-only (calculate-market-score (category-id uint) (region (string-ascii 50)))
  (let
    (
      (trend-data (map-get? price-trend-analysis { category-id: category-id, region: region }))
      (market-stats (map-get? regional-market-stats { region: region, category-id: category-id }))
    )
    (match trend-data
      trend (match market-stats
        stats {
          market-activity: (get market-activity-score stats),
          price-stability: (- u100 (get volatility-score trend)),
          competition-intensity: (get competition-level stats),
          trend-strength: (get confidence-level trend),
          overall-score: (/ (+ (get market-activity-score stats) (- u100 (get volatility-score trend)) (get confidence-level trend)) u3)
        }
        { market-activity: u0, price-stability: u50, competition-intensity: u50, trend-strength: u0, overall-score: u25 }
      )
      { market-activity: u0, price-stability: u50, competition-intensity: u50, trend-strength: u0, overall-score: u25 }
    )
  )
)

(define-read-only (is-price-alert-triggered (alert-id uint))
  (match (map-get? price-alerts { alert-id: alert-id })
    alert (and 
      (get is-active alert)
      (not (get is-triggered alert))
    )
    false
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

(define-private (get-user-document-count (user principal))
  (let
    (
      (doc-types (list "export-license" "origin-certificate" "quality-certificate" "customs-declaration" "phytosanitary-certificate"))
    )
    (fold count-user-docs-by-type doc-types u0)
  )
)

(define-private (count-user-docs-by-type (doc-type (string-ascii 50)) (acc uint))
  (match (map-get? user-documents { user: tx-sender, document-type: doc-type })
    user-doc (if (get is-active user-doc) (+ acc u1) acc)
    acc
  )
)

(define-private (count-expired-documents (user principal))
  (let
    (
      (doc-types (list "export-license" "origin-certificate" "quality-certificate" "customs-declaration" "phytosanitary-certificate"))
    )
    (fold count-expired-docs-by-type doc-types u0)
  )
)

(define-private (count-expired-docs-by-type (doc-type (string-ascii 50)) (acc uint))
  (match (map-get? user-documents { user: tx-sender, document-type: doc-type })
    user-doc (match (map-get? trade-documents { document-id: (get document-id user-doc) })
      document (if (>= stacks-block-height (get expiry-date document)) (+ acc u1) acc)
      acc
    )
    acc
  )
)

(define-private (count-verified-documents-for-order (order-id uint) (category-id uint))
  (let
    (
      (required-docs u2)
      (verified-docs u1)
    )
    { required: required-docs, verified: verified-docs }
  )
)

(define-private (validate-document-type (doc-type (string-ascii 50)))
  (or 
    (is-eq doc-type "export-license")
    (or 
      (is-eq doc-type "origin-certificate")
      (or 
        (is-eq doc-type "quality-certificate")
        (or 
          (is-eq doc-type "customs-declaration")
          (is-eq doc-type "phytosanitary-certificate")
        )
      )
    )
  )
)

(define-private (is-compliance-met (order-id uint))
  (match (map-get? order-compliance { order-id: order-id })
    compliance (is-eq (get compliance-status compliance) "compliant")
    false
  )
)

(define-private (calculate-compliance-score (verified-count uint) (required-count uint))
  (if (> required-count u0)
    (/ (* verified-count u100) required-count)
    u100
  )
)

(define-private (calculate-price-volatility (category-id uint) (region (string-ascii 50)))
  (let
    (
      (current-period (/ stacks-block-height u4320))
      (periods-to-check (list u0 u1 u2 u3 u4))
      (volatility-sum (fold sum-price-volatility periods-to-check { category: category-id, region: region, sum: u0, count: u0 }))
    )
    (if (> (get count volatility-sum) u0)
      (/ (get sum volatility-sum) (get count volatility-sum))
      u50
    )
  )
)

(define-private (sum-price-volatility (period-offset uint) (acc { category: uint, region: (string-ascii 50), sum: uint, count: uint }))
  (let
    (
      (current-period (/ stacks-block-height u4320))
      (check-period (- current-period period-offset))
      (price-data (map-get? market-price-history { category-id: (get category acc), region: (get region acc), period: check-period }))
    )
    (match price-data
      data (let
        (
          (price-range (if (> (get max-price data) u0) (/ (* (- (get max-price data) (get min-price data)) u100) (get max-price data)) u0))
        )
        {
          category: (get category acc),
          region: (get region acc),
          sum: (+ (get sum acc) price-range),
          count: (+ (get count acc) u1)
        }
      )
      acc
    )
  )
)

(define-private (calculate-success-probability (volatility uint) (competition uint) (tier uint))
  (let
    (
      (volatility-factor (if (> volatility PRICE_VOLATILITY_THRESHOLD) u70 u85))
      (competition-factor (if (> competition u70) u75 u90))
      (tier-factor (if (is-eq tier u1) u95 (if (is-eq tier u2) u85 u70)))
    )
    (/ (+ volatility-factor competition-factor tier-factor) u3)
  )
)

(define-private (calculate-market-activity-score (exporters uint) (buyers uint) (transactions uint))
  (let
    (
      (user-activity (+ exporters buyers))
      (transaction-factor (if (> transactions u0) (if (< (/ transactions u2) u50) (/ transactions u2) u50) u0))
      (user-factor (if (> user-activity u0) (if (< (/ user-activity u2) u50) (/ user-activity u2) u50) u0))
    )
    (+ transaction-factor user-factor)
  )
)

(define-private (calculate-seasonal-factor (current-block uint))
  (let
    (
      (month-equivalent (mod (/ current-block u4320) u12))
    )
    (if (or (is-eq month-equivalent u11) (is-eq month-equivalent u0) (is-eq month-equivalent u1))
      u110
      (if (or (is-eq month-equivalent u5) (is-eq month-equivalent u6) (is-eq month-equivalent u7))
        u95
        u100
      )
    )
  )
)

(define-private (calculate-competition-level (exporters uint) (transactions uint))
  (let
    (
      (competition-ratio (if (> transactions u0) (/ exporters transactions) u0))
    )
    (if (> competition-ratio u2)
      u80
      (if (> competition-ratio u1)
        u60
        u40
      )
    )
  )
)


