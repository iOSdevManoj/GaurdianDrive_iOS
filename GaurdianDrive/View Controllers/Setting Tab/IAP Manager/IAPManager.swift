//
//  IAPManager.swift
//  GaurdianDrive
//
//  Created by KETAN on 17/03/26.
//

//import Foundation
//import StoreKit
//
//
//final class IAPManager: NSObject {
//
//    static let shared = IAPManager()
//
//    private override init() {
//        super.init()
//        SKPaymentQueue.default().add(self)
//    }
//
//    // MARK: - Properties
//    private var products: [SKProduct] = []
//    private var productRequest: SKProductsRequest?
//    private var handledTransactions = Set<String>()
//
//    // MARK: - Callbacks
//    var onProductsFetched: (([SKProduct]) -> Void)?
//    var onPurchaseSuccess: ((String, String) -> Void)? // productId, transactionId
//    var onPurchaseFailed: ((String) -> Void)?
//
//    // MARK: - Fetch Products
//    func fetchProducts(ids: [String]) {
//        productRequest?.cancel()
//
//        let request = SKProductsRequest(productIdentifiers: Set(ids))
//        request.delegate = self
//        request.start()
//
//        self.productRequest = request
//    }
//
//    // MARK: - Purchase
//    func purchase(productId: String) {
//        guard let product = products.first(where: { $0.productIdentifier == productId }) else {
//            onPurchaseFailed?("Product not found")
//            return
//        }
//
//        guard SKPaymentQueue.canMakePayments() else {
//            onPurchaseFailed?("Purchases disabled")
//            return
//        }
//
//        let payment = SKPayment(product: product)
//        SKPaymentQueue.default().add(payment)
//    }
//
//    // MARK: - Restore
//    func restorePurchases() {
//        SKPaymentQueue.default().restoreCompletedTransactions()
//    }
//}
//
//// MARK: - SKProductsRequestDelegate
//extension IAPManager: SKProductsRequestDelegate {
//
//    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
//        self.products = response.products
//        onProductsFetched?(response.products)
//    }
//}
//
//// MARK: - SKPaymentTransactionObserver
//extension IAPManager: SKPaymentTransactionObserver {
//
//    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
//
//        for trans in transactions {
//
//            let id = trans.transactionIdentifier ??
//                     trans.original?.transactionIdentifier ?? ""
//
//            if handledTransactions.contains(id) {
//                SKPaymentQueue.default().finishTransaction(trans)
//                continue
//            }
//
//            switch trans.transactionState {
//
//            case .purchased:
//
////                // ❌ Ignore auto-renew (important)
////                if trans.original != nil {
////                    SKPaymentQueue.default().finishTransaction(trans)
////                    continue
////                }
////
////                handledTransactions.insert(id)
////
////                let productId = trans.payment.productIdentifier
////                onPurchaseSuccess?(productId, id)
////
////                SKPaymentQueue.default().finishTransaction(trans)
//                
//                
//                handledTransactions.insert(id)
//
//                let productId = trans.payment.productIdentifier
//                let originalId = trans.original?.transactionIdentifier ?? id
//
//                onPurchaseSuccess?(productId, originalId)
//
//                SKPaymentQueue.default().finishTransaction(trans)
//
//            case .restored:
//
//                handledTransactions.insert(id)
//
//                let productId = trans.original?.payment.productIdentifier ?? trans.payment.productIdentifier
//                onPurchaseSuccess?(productId, id)
//
//                SKPaymentQueue.default().finishTransaction(trans)
//
//            case .failed:
//
//                if let error = trans.error as? SKError,
//                   error.code != .paymentCancelled {
//                    onPurchaseFailed?(error.localizedDescription)
//                }
//
//                SKPaymentQueue.default().finishTransaction(trans)
//
//            case .purchasing:
//                break
//
//            case .deferred:
//                break
//
//            @unknown default:
//                break
//            }
//        }
//    }
//}
//
import Foundation
import StoreKit

@MainActor
final class IAPManager: ObservableObject {

    static let shared = IAPManager()

    private init() {
        listenForTransactions()
    }

    // MARK: - Properties

    @Published var products: [Product] = []
    private var updateTask: Task<Void, Never>?
    private var handledTransactionIDs = Set<String>()
    private var isManualPurchaseFlow = false
    // MARK: - Callbacks

    // ✅ UPDATED (added transactionId)
    var onPurchaseSuccess: ((String, String, String, Date?) -> Void)?
    // productId, transactionId, originalTransactionId, expiry

    var onPurchaseFailed: ((String) -> Void)?
    var onRestoreSuccess: ((String, String, String, Date?) -> Void)?
    private var isRestoreFlow = false
    // MARK: - Fetch Products

    func fetchProducts(ids: [String]) async {
        do {
            self.products = try await Product.products(for: ids)
        } catch {
            print("❌ Failed to fetch products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(productId: String) async {

        isManualPurchaseFlow = true   // ✅ mark manual purchase

        guard let product = products.first(where: { $0.id == productId }) else {
            onPurchaseFailed?("Product not found")
            return
        }

        do {
            let result = try await product.purchase()

            switch result {

            case .success(let verification):

                let transaction = try checkVerified(verification)

                await handleTransaction(transaction)

                await transaction.finish()

            case .userCancelled:
                isManualPurchaseFlow = false
                onPurchaseFailed?("User cancelled")

            case .pending:
                isManualPurchaseFlow = false
                print("⏳ Pending")

            @unknown default:
                isManualPurchaseFlow = false
            }

        } catch {
            isManualPurchaseFlow = false
            onPurchaseFailed?(error.localizedDescription)
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        isRestoreFlow = true   // ✅ mark restore
        do {
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)
                await handleTransaction(transaction)
            }
        } catch {
            print("❌ Restore failed: \(error)")
            appDelegate.hideHud()
        }
    }

    //MARK: - Listen for Auto-Renew Updates
    private func listenForTransactions() {
        updateTask = Task.detached { [weak self] in
            guard let self = self else { return }

            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.handleTransaction(transaction)
                    await transaction.finish()
                } catch {
                    print("❌ Transaction update failed")
                }
            }
        }
    }

    // MARK: - Handle Transaction

    private func handleTransaction(_ transaction: Transaction) async {

        let transactionId = String(transaction.id)

        // 🚨 Prevent duplicate calls
        if handledTransactionIDs.contains(transactionId) {
            print("⚠️ Duplicate transaction ignored:", transactionId)
            return
        }

        handledTransactionIDs.insert(transactionId)

        let productId = transaction.productID
        let originalTransactionId = String(transaction.originalID)
        let expiryDate = transaction.expirationDate

        print("✅ Transaction received:")
        print("Product:", productId)
        print("Transaction ID:", transactionId)
        print("Original Transaction ID:", originalTransactionId)
        print("Expiry:", String(describing: expiryDate))

//        onPurchaseSuccess?(productId,
//                           transactionId,
//                           originalTransactionId,
//                           expiryDate)
        
        if isManualPurchaseFlow {

               print("🟢 Manual Purchase → API CALL")

               isManualPurchaseFlow = false  //✅ reset immediately

               onPurchaseSuccess?(
                   productId,
                   transactionId,
                   originalTransactionId,
                   expiryDate
               )

        }  else if isRestoreFlow {
            
            self.isRestoreFlow = false
            
            onRestoreSuccess?(
                      productId,
                      transactionId,
                      originalTransactionId,
                      expiryDate
                  )
        }
        else {
            
               print("🟡 Ignored (renew / restore / listener)")
           }
    }
    
    //MARK: - Verify Transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "IAP",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Transaction not verified"])
        case .verified(let safe):
            return safe
        }
    }

    //MARK: - Get Active Subscription (Local Check)
    func getActiveSubscription() async -> (productId: String,
                                          transactionId: String,
                                          originalTransactionId: String,
                                          expiry: Date?)? {

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {

                return (
                    transaction.productID,
                    String(transaction.id),
                    String(transaction.originalID),
                    transaction.expirationDate
                )
            }
        }
        return nil
    }
}
