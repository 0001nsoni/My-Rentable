;; RentableNFT Marketplace Contract
;; Platform for renting gaming NFTs, metaverse items, and utility tokens with automated return mechanisms

;; Define the NFT trait for rentable items
(define-trait rentable-nft-trait
  (
    ;; Transfer function for the NFT
    (transfer (uint principal principal) (response bool uint))
    ;; Get owner function
    (get-owner (uint) (response principal uint))
  ))

;; Use the rentable-nft-trait for external NFT contracts
(use-trait rentable-nft-trait .rentable-nft-trait)

;; Constants
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-item-not-available (err u102))
(define-constant err-rental-expired (err u103))
(define-constant err-rental-not-expired (err u104))
(define-constant err-insufficient-payment (err u105))
(define-constant err-item-not-found (err u106))
(define-constant err-already-rented (err u107))

;; Data structures
(define-map rental-listings 
  uint 
  {
    owner: principal,
    nft-contract: principal,
    token-id: uint,
    rental-price: uint,
    rental-duration: uint,
    is-active: bool
  })

(define-map active-rentals
  uint
  {
    listing-id: uint,
    renter: principal,
    start-block: uint,
    end-block: uint,
    total-paid: uint
  })

;; Counters
(define-data-var next-listing-id uint u0)
(define-data-var next-rental-id uint u0)

;; Function 1: Create Rental Listing
(define-public (create-rental-listing (nft-contract principal) (token-id uint) (rental-price uint) (rental-duration uint))
  (let 
    (
      (listing-id (var-get next-listing-id))
    )
    (begin
      ;; Get NFT owner and verify the caller owns the NFT
      (let ((nft-owner (unwrap! (contract-call? nft-contract rentable-nft-trait.get-owner token-id) err-item-not-found)))
        (asserts! (is-eq tx-sender nft-owner) err-not-authorized))
      ;; Transfer NFT to contract for escrow
      (as-contract (try! (contract-call? nft-contract rentable-nft-trait.transfer token-id tx-sender tx-sender)))
      ;; Create the rental listing
      (map-set rental-listings listing-id
        {
          owner: tx-sender,
          nft-contract: nft-contract,
          token-id: token-id,
          rental-price: rental-price,
          rental-duration: rental-duration,
          is-active: true
        })
      ;; Increment listing counter
      (var-set next-listing-id (+ listing-id u1))
      (ok listing-id))))

;; Function 2: Rent NFT Item
(define-public (rent-nft-item (listing-id uint))
  (let 
    (
      (listing-data (unwrap! (map-get? rental-listings listing-id) err-item-not-found))
      (rental-id (var-get next-rental-id))
      (rental-duration (get rental-duration listing-data))
      (rental-price (get rental-price listing-data))
      (nft-contract (get nft-contract listing-data))
      (token-id (get token-id listing-data))
      (owner (get owner listing-data))
      (end-block (+ block-height rental-duration))
    )
    (begin
      ;; Check if listing is active
      (asserts! (get is-active listing-data) err-item-not-available)
      ;; Process payment
      (try! (stx-transfer? rental-price tx-sender owner))
      ;; Create rental record
      (map-set active-rentals rental-id
        {
          listing-id: listing-id,
          renter: tx-sender,
          start-block: block-height,
          end-block: end-block,
          total-paid: rental-price
        })
      ;; Deactivate listing
      (map-set rental-listings listing-id 
        (merge listing-data { is-active: false }))
      ;; Increment rental counter
      (var-set next-rental-id (+ rental-id u1))
      ;; Transfer NFT to renter from contract
      (as-contract (try! (contract-call? nft-contract rentable-nft-trait.transfer token-id tx-sender tx-sender)))
      (ok rental-id))))

;; Function 3: Return rented item
(define-public (return-rented-item (rental-id uint))
  (let 
    (
      (rental-data (unwrap! (map-get? active-rentals rental-id) err-item-not-found))
      (listing-id (get listing-id rental-data))
      (listing-data (unwrap! (map-get? rental-listings listing-id) err-item-not-found))
      (nft-contract (get nft-contract listing-data))
      (token-id (get token-id listing-data))
      (owner (get owner listing-data))
      (end-block (get end-block rental-data))
      (renter (get renter rental-data))
    )
    (begin
      ;; Check if rental has expired
      (asserts! (>= block-height end-block) err-rental-not-expired)
      ;; Check if caller is the renter
 (asserts! (is-eq tx-sender renter) err-not-authorized)
      ;; Transfer NFT back to owner from contract
      (as-contract (try! (contract-call? nft-contract rentable-nft-trait.transfer token-id tx-sender owner)))
      ;; Remove rental record
      (map-delete active-rentals rental-id)
      ;; Reactivate listing
      (map-set rental-listings listing-id 
        (merge listing-data { is-active: true }))
      (ok true))))

;; Read-only functions for querying data
(define-read-only (get-rental-listing (listing-id uint))
  (map-get? rental-listings listing-id))

(define-read-only (get-active-rental (rental-id uint))
  (map-get? active-rentals rental-id))

(define-read-only (get-next-listing-id)
  (var-get next-listing-id))

(define-read-only (get-next-rental-id)
  (var-get next-rental-id))