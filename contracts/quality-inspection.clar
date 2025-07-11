;; Quality Inspection Contract
;; Ensures completed work meets professional standards

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u300))
(define-constant ERR-NOT-FOUND (err u301))
(define-constant ERR-INVALID-STATUS (err u302))
(define-constant ERR-INVALID-RATING (err u303))
(define-constant ERR-ALREADY-INSPECTED (err u304))

;; Data Variables
(define-data-var next-inspection-id uint u1)
(define-data-var next-dispute-id uint u1)

;; Data Maps
(define-map inspections
  { inspection-id: uint }
  {
    project-id: uint,
    contractor: principal,
    inspector: principal,
    client: principal,
    quality-score: uint,
    completion-status: (string-ascii 20),
    inspection-date: uint,
    notes: (string-ascii 200),
    photos-hash: (optional (buff 32)),
    approved: bool
  }
)

(define-map quality-metrics
  { project-id: uint }
  {
    workmanship: uint,
    timeliness: uint,
    cleanliness: uint,
    communication: uint,
    overall-rating: uint,
    meets-standards: bool
  }
)

(define-map inspector-certifications
  { inspector: principal }
  {
    certified: bool,
    certification-date: uint,
    specializations: (list 5 (string-ascii 30)),
    total-inspections: uint,
    accuracy-rating: uint
  }
)

(define-map quality-disputes
  { dispute-id: uint }
  {
    inspection-id: uint,
    disputer: principal,
    reason: (string-ascii 200),
    status: (string-ascii 20),
    created-at: uint,
    resolved-at: (optional uint),
    resolution: (optional (string-ascii 200))
  }
)

(define-map contractor-quality-history
  { contractor: principal }
  {
    total-projects: uint,
    avg-quality-score: uint,
    total-disputes: uint,
    resolved-disputes: uint,
    certification-level: (string-ascii 20)
  }
)

;; Public Functions

;; Register as certified inspector
(define-public (register-inspector (specializations (list 5 (string-ascii 30))))
  (let
    (
      (existing-cert (map-get? inspector-certifications { inspector: tx-sender }))
    )
    (asserts! (is-none existing-cert) ERR-UNAUTHORIZED)
    (map-set inspector-certifications
      { inspector: tx-sender }
      {
        certified: true,
        certification-date: block-height,
        specializations: specializations,
        total-inspections: u0,
        accuracy-rating: u0
      }
    )
    (ok true)
  )
)

;; Submit quality inspection
(define-public (submit-inspection
  (project-id uint)
  (contractor principal)
  (client principal)
  (quality-score uint)
  (completion-status (string-ascii 20))
  (notes (string-ascii 200))
  (photos-hash (optional (buff 32)))
)
  (let
    (
      (inspection-id (var-get next-inspection-id))
      (inspector-cert (unwrap! (map-get? inspector-certifications { inspector: tx-sender }) ERR-UNAUTHORIZED))
    )
    (asserts! (get certified inspector-cert) ERR-UNAUTHORIZED)
    (asserts! (<= quality-score u100) ERR-INVALID-RATING)

    ;; Create inspection record
    (map-set inspections
      { inspection-id: inspection-id }
      {
        project-id: project-id,
        contractor: contractor,
        inspector: tx-sender,
        client: client,
        quality-score: quality-score,
        completion-status: completion-status,
        inspection-date: block-height,
        notes: notes,
        photos-hash: photos-hash,
        approved: (>= quality-score u70)
      }
    )

    ;; Update inspector stats
    (map-set inspector-certifications
      { inspector: tx-sender }
      (merge inspector-cert {
        total-inspections: (+ (get total-inspections inspector-cert) u1)
      })
    )

    (var-set next-inspection-id (+ inspection-id u1))
    (ok inspection-id)
  )
)

;; Submit detailed quality metrics
(define-public (submit-quality-metrics
  (project-id uint)
  (workmanship uint)
  (timeliness uint)
  (cleanliness uint)
  (communication uint)
)
  (let
    (
      (inspector-cert (unwrap! (map-get? inspector-certifications { inspector: tx-sender }) ERR-UNAUTHORIZED))
      (overall-rating (/ (+ workmanship timeliness cleanliness communication) u4))
    )
    (asserts! (get certified inspector-cert) ERR-UNAUTHORIZED)
    (asserts! (<= workmanship u10) ERR-INVALID-RATING)
    (asserts! (<= timeliness u10) ERR-INVALID-RATING)
    (asserts! (<= cleanliness u10) ERR-INVALID-RATING)
    (asserts! (<= communication u10) ERR-INVALID-RATING)

    (map-set quality-metrics
      { project-id: project-id }
      {
        workmanship: workmanship,
        timeliness: timeliness,
        cleanliness: cleanliness,
        communication: communication,
        overall-rating: overall-rating,
        meets-standards: (>= overall-rating u7)
      }
    )
    (ok true)
  )
)

;; File quality dispute
(define-public (file-dispute (inspection-id uint) (reason (string-ascii 200)))
  (let
    (
      (inspection-data (unwrap! (map-get? inspections { inspection-id: inspection-id }) ERR-NOT-FOUND))
      (dispute-id (var-get next-dispute-id))
    )
    ;; Only contractor or client can file dispute
    (asserts! (or
      (is-eq tx-sender (get contractor inspection-data))
      (is-eq tx-sender (get client inspection-data))
    ) ERR-UNAUTHORIZED)

    (map-set quality-disputes
      { dispute-id: dispute-id }
      {
        inspection-id: inspection-id,
        disputer: tx-sender,
        reason: reason,
        status: "open",
        created-at: block-height,
        resolved-at: none,
        resolution: none
      }
    )

    (var-set next-dispute-id (+ dispute-id u1))
    (ok dispute-id)
  )
)

;; Resolve quality dispute
(define-public (resolve-dispute (dispute-id uint) (resolution (string-ascii 200)))
  (let
    (
      (dispute-data (unwrap! (map-get? quality-disputes { dispute-id: dispute-id }) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status dispute-data) "open") ERR-INVALID-STATUS)

    (map-set quality-disputes
      { dispute-id: dispute-id }
      (merge dispute-data {
        status: "resolved",
        resolved-at: (some block-height),
        resolution: (some resolution)
      })
    )
    (ok true)
  )
)

;; Update contractor quality history
(define-public (update-contractor-history (contractor principal) (quality-score uint))
  (let
    (
      (history (default-to
        {
          total-projects: u0,
          avg-quality-score: u0,
          total-disputes: u0,
          resolved-disputes: u0,
          certification-level: "basic"
        }
        (map-get? contractor-quality-history { contractor: contractor })
      ))
      (new-total (+ (get total-projects history) u1))
      (new-avg (/ (+ (* (get avg-quality-score history) (get total-projects history)) quality-score) new-total))
    )
    (map-set contractor-quality-history
      { contractor: contractor }
      (merge history {
        total-projects: new-total,
        avg-quality-score: new-avg
      })
    )
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-inspection (inspection-id uint))
  (map-get? inspections { inspection-id: inspection-id })
)

(define-read-only (get-quality-metrics (project-id uint))
  (map-get? quality-metrics { project-id: project-id })
)

(define-read-only (get-inspector-certification (inspector principal))
  (map-get? inspector-certifications { inspector: inspector })
)

(define-read-only (get-dispute (dispute-id uint))
  (map-get? quality-disputes { dispute-id: dispute-id })
)

(define-read-only (get-contractor-quality-history (contractor principal))
  (map-get? contractor-quality-history { contractor: contractor })
)

(define-read-only (is-inspector-certified (inspector principal))
  (match (map-get? inspector-certifications { inspector: inspector })
    cert-data (get certified cert-data)
    false
  )
)

(define-read-only (get-project-approval-status (project-id uint))
  (match (map-get? quality-metrics { project-id: project-id })
    metrics (get meets-standards metrics)
    false
  )
)
