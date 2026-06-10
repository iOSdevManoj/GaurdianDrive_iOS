//
//  UserSubscriptionResponseModel.swift
//  GaurdianDrive
//
//  Created by KETAN on 19/03/26.
//

import UIKit

class UserSubscriptionResponseModel: NSObject {
    
     var id: Int = 0
     var originalPurchaseDate: Double = 0
     var parentId: Int = 0
     var currency: String = ""
     var parentName: String = ""
     var inAppOwnershipType: String = ""
     var type: String = ""
     var environment: String = ""
     var transactionReason: String = ""
     var transactionId: String = ""
     var productId: String = ""
     var purchaseDate: Double = 0
     var expiresDateLocal: String = ""
     var price: Int = 0
     var maxChild: Int = 0
     var originalTransactionId: String = ""
     var status: String = ""
     var subscriptionGroupIdentifier: String = ""
     var storefrontId: String = ""
     var purchaseDateLocal: String = ""
     var version: Int = 0
     var signedDateLocal: String = ""
     var quantity: Int = 0
     var xnType: String = ""
     var bundleId: String = ""
     var signedDate: Double = 0
     var expiresDate: Double = 0
     var webOrderLineItemId: String = ""
     var originalPurchaseDateLocal: String = ""
     var storefront: String = ""
     var appTransactionId: String = ""
    var Origionalstatus: String = ""

     override init() {}

     struct Keys {
         static let id = "id"
         static let originalPurchaseDate = "originalPurchaseDate"
         static let parentId = "parentId"
         static let currency = "currency"
         static let parentName = "parentName"
         static let inAppOwnershipType = "inAppOwnershipType"
         static let type = "type"
         static let environment = "environment"
         static let transactionReason = "transactionReason"
         static let transactionId = "transactionId"
         static let productId = "productId"
         static let purchaseDate = "purchaseDate"
         static let expiresDateLocal = "expiresDateLocal"
         static let price = "price"
         static let maxChild = "maxChild"
         static let originalTransactionId = "originalTransactionId"
         static let status = "status"
         static let subscriptionGroupIdentifier = "subscriptionGroupIdentifier"
         static let storefrontId = "storefrontId"
         static let purchaseDateLocal = "purchaseDateLocal"
         static let version = "version"
         static let signedDateLocal = "signedDateDateLocal"
         static let quantity = "quantity"
         static let xnType = "xnType"
         static let bundleId = "bundleId"
         static let signedDate = "signedDate"
         static let expiresDate = "expiresDate"
         static let webOrderLineItemId = "webOrderLineItemId"
         static let originalPurchaseDateLocal = "originalPurchaseDateLocal"
         static let storefront = "storefront"
         static let appTransactionId = "appTransactionId"
     }

     init(dict: NSDictionary) {

         self.id = dict.getInt(key: Keys.id)
         self.originalPurchaseDate = dict.getDouble(key: Keys.originalPurchaseDate)
         self.parentId = dict.getInt(key: Keys.parentId)
         self.currency = dict.getString(key: Keys.currency)
         self.parentName = dict.getString(key: Keys.parentName)
         self.inAppOwnershipType = dict.getString(key: Keys.inAppOwnershipType)
         self.type = dict.getString(key: Keys.type)
         self.environment = dict.getString(key: Keys.environment)
         self.transactionReason = dict.getString(key: Keys.transactionReason)
         self.transactionId = dict.getString(key: Keys.transactionId)
         self.productId = dict.getString(key: Keys.productId)
         self.purchaseDate = dict.getDouble(key: Keys.purchaseDate)
         self.expiresDateLocal = dict.getString(key: Keys.expiresDateLocal)
         self.price = dict.getInt(key: Keys.price)
         self.maxChild = dict.getInt(key: Keys.maxChild)
         self.originalTransactionId = dict.getString(key: Keys.originalTransactionId)
         self.status = dict.getString(key: Keys.status)
         self.subscriptionGroupIdentifier = dict.getString(key: Keys.subscriptionGroupIdentifier)
         self.storefrontId = dict.getString(key: Keys.storefrontId)
         self.purchaseDateLocal = dict.getString(key: Keys.purchaseDateLocal)
         self.version = dict.getInt(key: Keys.version)
         self.signedDateLocal = dict.getString(key: Keys.signedDateLocal)
         self.quantity = dict.getInt(key: Keys.quantity)
         self.xnType = dict.getString(key: Keys.xnType)
         self.bundleId = dict.getString(key: Keys.bundleId)
         self.signedDate = dict.getDouble(key: Keys.signedDate)
         self.expiresDate = dict.getDouble(key: Keys.expiresDate)
         self.webOrderLineItemId = dict.getString(key: Keys.webOrderLineItemId)
         self.originalPurchaseDateLocal = dict.getString(key: Keys.originalPurchaseDateLocal)
         self.storefront = dict.getString(key: Keys.storefront)
         self.appTransactionId = dict.getString(key: Keys.appTransactionId)
     }
}
