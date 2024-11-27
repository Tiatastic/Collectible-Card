;; Collectible Card Game Smart Contract

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))

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

;; Variables
(define-data-var next-available-card-id uint u1)
(define-data-var is-game-paused bool false)

;; Read-only functions

(define-read-only (get-card-info (card-id uint))
  (match (map-get? card-details { card-id: card-id })
    card-info card-info
    ERR-NOT-FOUND
  )
)

(define-read-only (get-player-balance (player-address principal))
  (default-to u0 (map-get? player-balances player-address))
)

(define-read-only (get-player-cards (player-address principal))
  (match (map-get? player-card-collection { player: player-address })
    player-cards (get owned-card-ids player-cards)
    (list)
  )
)

;; Private functions

(define-private (transfer-card-ownership (card-id uint) (current-owner principal) (new-owner principal))
  (match (map-get? card-details { card-id: card-id })
    card (if (and (is-eq (get card-owner card) current-owner) (is-some (map-get? player-card-collection { player: new-owner })))
      (begin
        (map-set card-details { card-id: card-id }
          (merge card { card-owner: new-owner }))
        (map-set player-card-collection { player: current-owner }
          { owned-card-ids: (filter (lambda (id) (not (is-eq id card-id))) (get-player-cards current-owner)) })
        (map-set player-card-collection { player: new-owner }
          { owned-card-ids: (unwrap! (as-max-len? (concat (get-player-cards new-owner) card-id) u100) ERR-NOT-FOUND) })
        (ok true))
      ERR-NOT-FOUND)
    ERR-NOT-FOUND
  )
)

;; Public functions

(define-public (mint-new-card (card-name (string-ascii 24)) (attack-value uint) (defense-value uint) (rarity-value uint) (recipient-address principal))
  (let ((new-card-id (var-get next-available-card-id)))
    (if (is-eq tx-sender CONTRACT-OWNER)
      (begin
        (map-set card-details { card-id: new-card-id }
          { name: card-name, attack-power: attack-value, defense-power: defense-value, rarity-level: rarity-value, card-owner: recipient-address })
        (map-set player-card-collection { player: recipient-address }
          { owned-card-ids: (unwrap! (as-max-len? (concat (get-player-cards recipient-address) new-card-id) u100) ERR-NOT-FOUND) })
        (var-set next-available-card-id (+ new-card-id u1))
        (ok new-card-id))
      ERR-OWNER-ONLY)
  )
)

(define-public (transfer-card (card-id uint) (recipient-address principal))
  (let ((sender-address tx-sender))
    (if (not (var-get is-game-paused))
      (transfer-card-ownership card-id sender-address recipient-address)
      ERR-OWNER-ONLY)
  )
)

(define-public (initiate-card-battle (attacker-card-id uint) (defender-card-id uint))
  (let (
    (attacker-card (unwrap! (map-get? card-details { card-id: attacker-card-id }) ERR-NOT-FOUND))
    (defender-card (unwrap! (map-get? card-details { card-id: defender-card-id }) ERR-NOT-FOUND))
  )
    (if (and
      (is-eq (get card-owner attacker-card) tx-sender)
      (not (is-eq (get card-owner defender-card) tx-sender))
      (not (var-get is-game-paused)))
      (if (> (get attack-power attacker-card) (get defense-power defender-card))
        (begin
          (transfer-card-ownership defender-card-id (get card-owner defender-card) tx-sender)
          (ok true))
        (ok false))
      ERR-OWNER-ONLY)
  )
)

(define-public (purchase-card (card-id uint) (offer-price uint))
  (let (
    (buyer-address tx-sender)
    (card (unwrap! (map-get? card-details { card-id: card-id }) ERR-NOT-FOUND))
    (seller-address (get card-owner card))
  )
    (if (and (not (is-eq buyer-address seller-address)) (not (var-get is-game-paused)))
      (match (stx-transfer? offer-price buyer-address seller-address)
        success (transfer-card-ownership card-id seller-address buyer-address)
        error ERR-INSUFFICIENT-BALANCE)
      ERR-OWNER-ONLY)
  )
)

;; Admin functions

(define-public (pause-game-operations)
  (if (is-eq tx-sender CONTRACT-OWNER)
    (begin
      (var-set is-game-paused true)
      (ok true))
    ERR-OWNER-ONLY)
)

(define-public (resume-game-operations)
  (if (is-eq tx-sender CONTRACT-OWNER)
    (begin
      (var-set is-game-paused false)
      (ok true))
    ERR-OWNER-ONLY)
)

(define-public (transfer-contract-ownership (new-owner-address principal))
  (if (is-eq tx-sender CONTRACT-OWNER)
    (begin
      (var-set CONTRACT-OWNER new-owner-address)
      (ok true))
    ERR-OWNER-ONLY)
)