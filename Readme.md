# RentableNFT Marketplace Contract

This Clarity smart contract enables a decentralized marketplace for renting NFTs (gaming items, metaverse assets, utility tokens) with automated return mechanisms. It supports listing NFTs for rent, renting them for a specified duration, and returning them after the rental period.

## Features

- **NFT Escrow:** NFTs are held in escrow by the contract during the rental period.
- **Rental Listings:** Owners can list their NFTs for rent, specifying price and duration.
- **Automated Return:** NFTs are automatically returned to the owner after the rental period.
- **Payment Handling:** Rental payments are transferred to the NFT owner.
- **Query Functions:** Read-only functions to fetch listings and rentals.

## Contract Functions

### Public Functions

- `create-rental-listing(nft-contract, token-id, rental-price, rental-duration)`
  - List an NFT for rent. Transfers the NFT to contract escrow.
- `rent-nft-item(listing-id)`
  - Rent an NFT. Transfers payment to owner and NFT to renter.
- `return-rented-item(rental-id)`
  - Return the rented NFT after the rental period. Transfers NFT back to owner.

### Read-Only Functions

- `get-rental-listing(listing-id)`
  - Returns details of a rental listing.
- `get-active-rental(rental-id)`
  - Returns details of an active rental.
- `get-next-listing-id()`
  - Returns the next available listing ID.
- `get-next-rental-id()`
  - Returns the next available rental ID.

## Data Structures

- **rental-listings:** Stores active and inactive rental listings.
- **active-rentals:** Stores currently rented NFTs and their details.

## Error Codes

- `err-owner-only` (u100): Only the owner can perform this action.
- `err-not-authorized` (u101): Unauthorized action.
- `err-item-not-available` (u102): Item is not available for rent.
- `err-rental-expired` (u103): Rental period has expired.
- `err-rental-not-expired` (u104): Rental period has not expired.
- `err-insufficient-payment` (u105): Payment is insufficient.
- `err-item-not-found` (u106): Item not found.
- `err-already-rented` (u107): Item is already rented.

## Usage

1. **Deploy the contract** on the Stacks blockchain.
2. **List an NFT for rent** using `create-rental-listing`.
3. **Rent an NFT** using `rent-nft-item`.
4. **Return the NFT** after the rental period using `return-rented-item`.

## Requirements

- The NFT contract must implement the `rentable-nft-trait` (transfer and get-owner functions).
- The contract principal must be able to hold