;; Collectible Card Game Smart Contract

;; Constants
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TRANSFER (err u103))
(define-constant ERR-INVALID-INPUT (err u104))
(define-constant MAX-UINT u340282366920938463463374607431768211455)

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var next-card-id uint u1)
(define-data-var is-paused bool false)

;; Data Maps
(define-map card-details
  { card-id: uint }
  {
    name: (string-ascii 24),
    attack-power: uint,
    defense-power: uint,
    rarity-level: uint,
    card-owner: principal
  }
)

(define-map player-card-collection
  { player: principal }
  { owned-card-ids: (list 100 uint) }
)

(define-map player-balances principal uint)

;; Read-only functions
(define-read-only (get-card-info (card-id uint))
  (map-get? card-details { card-id: card-id })
)

(define-read-only (get-balance (player principal))
  (default-to u0 (map-get? player-balances player))
)

(define-read-only (get-player-cards (player principal))
  (default-to { owned-card-ids: (list) }
    (map-get? player-card-collection { player: player }))
)

;; Private functions
(define-private (transfer-ownership (card-id uint) (from principal) (to principal))
  (let ((card (get-card-info card-id)))
    (if (and
          (is-some card)
          (is-eq (get card-owner (unwrap-panic card)) from))
      (begin
        (map-set card-details 
          { card-id: card-id }
          (merge (unwrap-panic card) { card-owner: to }))
        (ok true))
      ERR-INVALID-TRANSFER)))

;; Public functions
(define-public (mint-card (name (string-ascii 24)) (attack uint) (defense uint) (rarity uint) (recipient principal))
  (let ((id (var-get next-card-id)))
    (if (is-eq tx-sender (var-get contract-owner))
      (if (and 
            (<= (len name) u24)
            (<= attack u1000)
            (<= defense u1000)
            (<= rarity u10)
            (not (is-eq recipient tx-sender))
            (not (is-eq recipient (var-get contract-owner)))
            (not (is-eq recipient 'ST000000000000000000002AMW42H)))
        (begin
          (map-set card-details { card-id: id }
            { 
              name: name,
              attack-power: attack,
              defense-power: defense,
              rarity-level: rarity,
              card-owner: recipient
            })
          (var-set next-card-id (+ id u1))
          (ok id))
        ERR-INVALID-INPUT)
      ERR-OWNER-ONLY)))

(define-public (transfer-card (card-id uint) (recipient principal))
  (let ((sender tx-sender))
    (if (and 
          (not (var-get is-paused))
          (not (is-eq recipient sender))
          (not (is-eq recipient (var-get contract-owner)))
          (not (is-eq recipient 'ST000000000000000000002AMW42H))
          (is-some (get-card-info card-id)))
      (transfer-ownership card-id sender recipient)
      ERR-INVALID-TRANSFER)))

(define-public (battle (attacker-id uint) (defender-id uint))
  (let (
    (attacker (get-card-info attacker-id))
    (defender (get-card-info defender-id))
  )
    (if (and
          (is-some attacker)
          (is-some defender)
          (is-eq (get card-owner (unwrap-panic attacker)) tx-sender)
          (not (is-eq (get card-owner (unwrap-panic defender)) tx-sender))
          (not (var-get is-paused)))
        (if (> (get attack-power (unwrap-panic attacker)) 
               (get defense-power (unwrap-panic defender)))
            (transfer-ownership defender-id 
              (get card-owner (unwrap-panic defender)) 
              tx-sender)
            (ok false))
        ERR-INVALID-TRANSFER)))

(define-public (purchase-card (card-id uint) (price uint))
  (let (
    (card (get-card-info card-id))
    (buyer tx-sender)
  )
    (if (and 
          (is-some card)
          (not (is-eq buyer (get card-owner (unwrap-panic card))))
          (not (var-get is-paused))
          (< price MAX-UINT))
        (match (stx-transfer? price buyer (get card-owner (unwrap-panic card)))
          success (transfer-ownership card-id (get card-owner (unwrap-panic card)) buyer)
          error ERR-INSUFFICIENT-BALANCE)
        ERR-INVALID-TRANSFER)))

;; Admin functions
(define-public (pause)
  (if (is-eq tx-sender (var-get contract-owner))
      (ok (var-set is-paused true))
      ERR-OWNER-ONLY))

(define-public (unpause)
  (if (is-eq tx-sender (var-get contract-owner))
      (ok (var-set is-paused false))
      ERR-OWNER-ONLY))

(define-public (set-contract-owner (new-owner principal))
  (if (and 
        (is-eq tx-sender (var-get contract-owner))
        (not (is-eq new-owner tx-sender))
        (not (is-eq new-owner 'ST000000000000000000002AMW42H)))
      (ok (var-set contract-owner new-owner))
      ERR-OWNER-ONLY))