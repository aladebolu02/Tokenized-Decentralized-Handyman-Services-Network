;; Project Estimation Contract
;; Provides accurate cost and timeline assessments

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u200))
(define-constant ERR-NOT-FOUND (err u201))
(define-constant ERR-INVALID-STATUS (err u202))
(define-constant ERR-INVALID-BID (err u203))
(define-constant ERR-PROJECT-CLOSED (err u204))

;; Data Variables
(define-data-var next-project-id uint u1)
(define-data-var next-bid-id uint u1)

;; Data Maps
(define-map projects
  { project-id: uint }
  {
    owner: principal,
    title: (string-ascii 50),
    description: (string-ascii 200),
    category: (string-ascii 30),
    location: (string-ascii 50),
    budget-min: uint,
    budget-max: uint,
    timeline-days: uint,
    status: (string-ascii 20),
    created-at: uint,
    selected-bid: (optional uint)
  }
)

(define-map project-bids
  { bid-id: uint }
  {
    project-id: uint,
    contractor: principal,
    estimated-cost: uint,
    timeline-days: uint,
    materials-cost: uint,
    labor-cost: uint,
    description: (string-ascii 200),
    status: (string-ascii 20),
    submitted-at: uint
  }
)

(define-map project-contractors
  { project-id: uint, contractor: principal }
  { bid-id: uint }
)

(define-map contractor-stats
  { contractor: principal }
  {
    total-bids: uint,
    accepted-bids: uint,
    avg-accuracy: uint,
    total-projects: uint
  }
)

;; Public Functions

;; Create a new project
(define-public (create-project
  (title (string-ascii 50))
  (description (string-ascii 200))
  (category (string-ascii 30))
  (location (string-ascii 50))
  (budget-min uint)
  (budget-max uint)
  (timeline-days uint)
)
  (let
    (
      (project-id (var-get next-project-id))
    )
    (asserts! (< budget-min budget-max) ERR-INVALID-BID)
    (map-set projects
      { project-id: project-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        category: category,
        location: location,
        budget-min: budget-min,
        budget-max: budget-max,
        timeline-days: timeline-days,
        status: "open",
        created-at: block-height,
        selected-bid: none
      }
    )
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

;; Submit a bid for a project
(define-public (submit-bid
  (project-id uint)
  (estimated-cost uint)
  (timeline-days uint)
  (materials-cost uint)
  (labor-cost uint)
  (description (string-ascii 200))
)
  (let
    (
      (project-data (unwrap! (map-get? projects { project-id: project-id }) ERR-NOT-FOUND))
      (bid-id (var-get next-bid-id))
      (existing-bid (map-get? project-contractors { project-id: project-id, contractor: tx-sender }))
    )
    (asserts! (is-eq (get status project-data) "open") ERR-PROJECT-CLOSED)
    (asserts! (is-none existing-bid) ERR-INVALID-BID)
    (asserts! (>= estimated-cost (get budget-min project-data)) ERR-INVALID-BID)
    (asserts! (<= estimated-cost (get budget-max project-data)) ERR-INVALID-BID)
    (asserts! (is-eq estimated-cost (+ materials-cost labor-cost)) ERR-INVALID-BID)

    ;; Create bid record
    (map-set project-bids
      { bid-id: bid-id }
      {
        project-id: project-id,
        contractor: tx-sender,
        estimated-cost: estimated-cost,
        timeline-days: timeline-days,
        materials-cost: materials-cost,
        labor-cost: labor-cost,
        description: description,
        status: "pending",
        submitted-at: block-height
      }
    )

    ;; Link contractor to project
    (map-set project-contractors
      { project-id: project-id, contractor: tx-sender }
      { bid-id: bid-id }
    )

    ;; Update contractor stats
    (match (map-get? contractor-stats { contractor: tx-sender })
      stats
      (map-set contractor-stats
        { contractor: tx-sender }
        (merge stats { total-bids: (+ (get total-bids stats) u1) })
      )
      (map-set contractor-stats
        { contractor: tx-sender }
        {
          total-bids: u1,
          accepted-bids: u0,
          avg-accuracy: u0,
          total-projects: u0
        }
      )
    )

    (var-set next-bid-id (+ bid-id u1))
    (ok bid-id)
  )
)

;; Accept a bid
(define-public (accept-bid (project-id uint) (bid-id uint))
  (let
    (
      (project-data (unwrap! (map-get? projects { project-id: project-id }) ERR-NOT-FOUND))
      (bid-data (unwrap! (map-get? project-bids { bid-id: bid-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get owner project-data)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get project-id bid-data) project-id) ERR-INVALID-BID)
    (asserts! (is-eq (get status project-data) "open") ERR-PROJECT-CLOSED)

    ;; Update project status
    (map-set projects
      { project-id: project-id }
      (merge project-data {
        status: "in-progress",
        selected-bid: (some bid-id)
      })
    )

    ;; Update bid status
    (map-set project-bids
      { bid-id: bid-id }
      (merge bid-data { status: "accepted" })
    )

    ;; Update contractor stats
    (match (map-get? contractor-stats { contractor: (get contractor bid-data) })
      stats
      (map-set contractor-stats
        { contractor: (get contractor bid-data) }
        (merge stats {
          accepted-bids: (+ (get accepted-bids stats) u1),
          total-projects: (+ (get total-projects stats) u1)
        })
      )
      false
    )

    (ok true)
  )
)

;; Close project
(define-public (close-project (project-id uint))
  (let
    (
      (project-data (unwrap! (map-get? projects { project-id: project-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get owner project-data)) ERR-UNAUTHORIZED)
    (map-set projects
      { project-id: project-id }
      (merge project-data { status: "closed" })
    )
    (ok true)
  )
)

;; Update estimation accuracy
(define-public (update-accuracy (contractor principal) (accuracy-score uint))
  (let
    (
      (stats (unwrap! (map-get? contractor-stats { contractor: contractor }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (<= accuracy-score u100) ERR-INVALID-BID)
    (map-set contractor-stats
      { contractor: contractor }
      (merge stats { avg-accuracy: accuracy-score })
    )
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

(define-read-only (get-bid (bid-id uint))
  (map-get? project-bids { bid-id: bid-id })
)

(define-read-only (get-contractor-bid (project-id uint) (contractor principal))
  (match (map-get? project-contractors { project-id: project-id, contractor: contractor })
    bid-ref (map-get? project-bids { bid-id: (get bid-id bid-ref) })
    none
  )
)

(define-read-only (get-contractor-stats (contractor principal))
  (map-get? contractor-stats { contractor: contractor })
)

(define-read-only (is-project-open (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project-data (is-eq (get status project-data) "open")
    false
  )
)
