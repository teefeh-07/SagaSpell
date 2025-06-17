
;; SagaSpell - A magical spell casting smart contract
;; Users can create, own, and cast spells with different powers and rarities

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-MANA (err u102))
(define-constant ERR-SPELL-ON-COOLDOWN (err u103))
(define-constant ERR-INVALID-SPELL (err u104))
(define-constant ERR-UNAUTHORIZED (err u105))

;; data maps and vars
(define-data-var next-spell-id uint u1)
(define-data-var total-spells uint u0)

;; Map to store spell data
(define-map spells
  { spell-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    power: uint,
    mana-cost: uint,
    rarity: (string-ascii 20),
    creator: principal,
    owner: principal,
    cast-count: uint,
    cooldown-blocks: uint,
    created-at: uint
  }
)

;; Map to store user data
(define-map users
  { user: principal }
  {
    mana: uint,
    total-spells-owned: uint,
    total-spells-cast: uint,
    last-mana-regen: uint
  }
)

;; Map to track spell ownership
(define-map spell-owners
  { spell-id: uint }
  { owner: principal }
)

;; Map to track spell cooldowns
(define-map spell-cooldowns
  { spell-id: uint, caster: principal }
  { last-cast-block: uint }
)

;; private functions

;; Calculate mana regeneration for a user
(define-private (calculate-mana-regen (user principal))
  (let (
    (user-data (default-to
      { mana: u100, total-spells-owned: u0, total-spells-cast: u0, last-mana-regen: u0 }
      (map-get? users { user: user })
    ))
    (blocks-passed (- block-height (get last-mana-regen user-data)))
    (mana-to-add (/ blocks-passed u10)) ;; 1 mana per 10 blocks
    (current-mana (get mana user-data))
    (max-mana u1000)
  )
    (if (< current-mana max-mana)
      (min max-mana (+ current-mana mana-to-add))
      current-mana
    )
  )
)

;; Update user mana
(define-private (update-user-mana (user principal))
  (let (
    (current-data (default-to
      { mana: u100, total-spells-owned: u0, total-spells-cast: u0, last-mana-regen: u0 }
      (map-get? users { user: user })
    ))
    (new-mana (calculate-mana-regen user))
  )
    (map-set users
      { user: user }
      (merge current-data {
        mana: new-mana,
        last-mana-regen: block-height
      })
    )
    (ok new-mana)
  )
)

;; Check if spell is on cooldown
(define-private (is-spell-on-cooldown (spell-id uint) (caster principal))
  (match (map-get? spell-cooldowns { spell-id: spell-id, caster: caster })
    cooldown-data
      (let (
        (spell-data (unwrap! (map-get? spells { spell-id: spell-id }) false))
        (blocks-since-cast (- block-height (get last-cast-block cooldown-data)))
      )
        (< blocks-since-cast (get cooldown-blocks spell-data))
      )
    false
  )
)

;; public functions

;; Initialize user account
(define-public (initialize-user)
  (let (
    (user tx-sender)
  )
    (match (map-get? users { user: user })
      existing-user (ok "User already initialized")
      (begin
        (map-set users
          { user: user }
          {
            mana: u100,
            total-spells-owned: u0,
            total-spells-cast: u0,
            last-mana-regen: block-height
          }
        )
        (ok "User initialized successfully")
      )
    )
  )
)

;; Create a new spell
(define-public (create-spell
  (name (string-ascii 50))
  (description (string-ascii 200))
  (power uint)
  (mana-cost uint)
  (rarity (string-ascii 20))
  (cooldown-blocks uint)
)
  (let (
    (spell-id (var-get next-spell-id))
    (creator tx-sender)
  )
    ;; Validate inputs
    (asserts! (> (len name) u0) ERR-INVALID-SPELL)
    (asserts! (> power u0) ERR-INVALID-SPELL)
    (asserts! (> mana-cost u0) ERR-INVALID-SPELL)

    ;; Create the spell
    (map-set spells
      { spell-id: spell-id }
      {
        name: name,
        description: description,
        power: power,
        mana-cost: mana-cost,
        rarity: rarity,
        creator: creator,
        owner: creator,
        cast-count: u0,
        cooldown-blocks: cooldown-blocks,
        created-at: block-height
      }
    )

    ;; Set spell ownership
    (map-set spell-owners
      { spell-id: spell-id }
      { owner: creator }
    )

    ;; Update user data
    (let (
      (user-data (default-to
        { mana: u100, total-spells-owned: u0, total-spells-cast: u0, last-mana-regen: block-height }
        (map-get? users { user: creator })
      ))
    )
      (map-set users
        { user: creator }
        (merge user-data { total-spells-owned: (+ (get total-spells-owned user-data) u1) })
      )
    )

    ;; Update contract state
    (var-set next-spell-id (+ spell-id u1))
    (var-set total-spells (+ (var-get total-spells) u1))

    (ok spell-id)
  )
)

;; Cast a spell
(define-public (cast-spell (spell-id uint))
  (let (
    (caster tx-sender)
    (spell-data (unwrap! (map-get? spells { spell-id: spell-id }) ERR-NOT-FOUND))
  )
    ;; Update user mana first
    (unwrap! (update-user-mana caster) ERR-INSUFFICIENT-MANA)

    (let (
      (user-data (unwrap! (map-get? users { user: caster }) ERR-NOT-FOUND))
      (mana-cost (get mana-cost spell-data))
      (current-mana (get mana user-data))
    )
      ;; Check if user has enough mana
      (asserts! (>= current-mana mana-cost) ERR-INSUFFICIENT-MANA)

      ;; Check if spell is not on cooldown
      (asserts! (not (is-spell-on-cooldown spell-id caster)) ERR-SPELL-ON-COOLDOWN)

      ;; Deduct mana
      (map-set users
        { user: caster }
        (merge user-data {
          mana: (- current-mana mana-cost),
          total-spells-cast: (+ (get total-spells-cast user-data) u1)
        })
      )

      ;; Update spell cast count
      (map-set spells
        { spell-id: spell-id }
        (merge spell-data { cast-count: (+ (get cast-count spell-data) u1) })
      )

      ;; Set cooldown
      (map-set spell-cooldowns
        { spell-id: spell-id, caster: caster }
        { last-cast-block: block-height }
      )

      (ok {
        spell-name: (get name spell-data),
        power: (get power spell-data),
        caster: caster,
        block-height: block-height
      })
    )
  )
)

;; Transfer spell ownership
(define-public (transfer-spell (spell-id uint) (new-owner principal))
  (let (
    (current-owner tx-sender)
    (spell-data (unwrap! (map-get? spells { spell-id: spell-id }) ERR-NOT-FOUND))
  )
    ;; Check if sender is the current owner
    (asserts! (is-eq current-owner (get owner spell-data)) ERR-UNAUTHORIZED)

    ;; Update spell ownership
    (map-set spells
      { spell-id: spell-id }
      (merge spell-data { owner: new-owner })
    )

    (map-set spell-owners
      { spell-id: spell-id }
      { owner: new-owner }
    )

    ;; Update user spell counts
    (let (
      (old-owner-data (default-to
        { mana: u100, total-spells-owned: u0, total-spells-cast: u0, last-mana-regen: block-height }
        (map-get? users { user: current-owner })
      ))
      (new-owner-data (default-to
        { mana: u100, total-spells-owned: u0, total-spells-cast: u0, last-mana-regen: block-height }
        (map-get? users { user: new-owner })
      ))
    )
      (map-set users
        { user: current-owner }
        (merge old-owner-data { total-spells-owned: (- (get total-spells-owned old-owner-data) u1) })
      )

      (map-set users
        { user: new-owner }
        (merge new-owner-data { total-spells-owned: (+ (get total-spells-owned new-owner-data) u1) })
      )
    )

    (ok true)
  )
)

;; Read-only functions

;; Get spell details
(define-read-only (get-spell (spell-id uint))
  (map-get? spells { spell-id: spell-id })
)

;; Get user data
(define-read-only (get-user (user principal))
  (map-get? users { user: user })
)

;; Get user's current mana (with regeneration calculated)
(define-read-only (get-user-mana (user principal))
  (calculate-mana-regen user)
)

;; Get spell owner
(define-read-only (get-spell-owner (spell-id uint))
  (map-get? spell-owners { spell-id: spell-id })
)

;; Check if spell is on cooldown for a user
(define-read-only (check-spell-cooldown (spell-id uint) (user principal))
  (is-spell-on-cooldown spell-id user)
)

;; Get total number of spells
(define-read-only (get-total-spells)
  (var-get total-spells)
)

;; Get next spell ID
(define-read-only (get-next-spell-id)
  (var-get next-spell-id)
)
