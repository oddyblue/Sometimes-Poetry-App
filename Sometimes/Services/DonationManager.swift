// DonationManager.swift
// StoreKit 2 integration for tip jar donations

import Foundation
import StoreKit
import OSLog

private let logger = Logger(subsystem: "com.sometimes.app", category: "Donations")

enum DonationError: Error {
    case failedVerification
}

@MainActor
final class DonationManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published var purchaseError: String?

    // Product IDs for tip jar donations
    // These must match the product IDs in App Store Connect
    private let productIDs = [
        "com.sometimes.app.support.small",   // $2.99
        "com.sometimes.app.support.medium",  // $4.99
        "com.sometimes.app.support.large"    // $9.99
    ]

    init() {
        Task {
            await loadProducts()
        }
    }

    // MARK: - Product Loading

    func loadProducts() async {
        isLoading = true
        purchaseError = nil

        logger.info("Attempting to load products with IDs: \(self.productIDs)")

        do {
            let loadedProducts = try await Product.products(for: productIDs)

            // Sort by price (low to high)
            products = loadedProducts.sorted { $0.price < $1.price }

            if products.isEmpty {
                logger.warning("No products returned from StoreKit - check Configuration.storekit is linked in scheme")
            } else {
                logger.info("Loaded \(self.products.count) donation products: \(self.products.map { $0.id })")
            }
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription), error: \(String(describing: error))")
            purchaseError = "Could not load donation options. Please try again later."
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Consumable purchase - finish immediately
                await transaction.finish()

                logger.info("Donation successful: \(product.id)")
                return true

            case .userCancelled:
                logger.info("User cancelled donation")
                return false

            case .pending:
                logger.info("Donation pending approval")
                purchaseError = "Your donation is pending approval."
                return false

            @unknown default:
                logger.warning("Unknown purchase result")
                return false
            }
        } catch DonationError.failedVerification {
            logger.error("Transaction verification failed")
            purchaseError = "Transaction verification failed. Please contact support."
            return false
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription)")
            purchaseError = "Purchase failed. Please try again."
            return false
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw DonationError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Product Helpers

extension Product {
    var donationDisplayName: String {
        displayName
    }

    var donationDescription: String {
        description
    }

    var donationIcon: String {
        "heart.fill"
    }
}
