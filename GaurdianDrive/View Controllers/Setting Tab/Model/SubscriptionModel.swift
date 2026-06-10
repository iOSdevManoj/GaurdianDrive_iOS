//
//  SubscriptionModel.swift
//  GaurdianDrive
//
//  Created by KETAN on 24/02/26.
//

import UIKit

class SubscriptionModel: NSObject {
    
    var name : String = ""
    var productIdentifry : String = ""
    var price : String = ""
    var sortPrice : Int = 0
    var childCount : String = ""
    var yearly : String = ""
    
    override init() {
        
    }
    struct KeyPlacesData    {
        static let name = "name"
        static let productIdentifry = "productIdentifry"
        static let price = "price"
        static let childCount = "childCount"
        static let yearly = "yearly"

    }
    init(dictData:NSDictionary)
    {
        self.name = dictData.getString(key: KeyPlacesData.name)
        self.price = dictData.getString(key: KeyPlacesData.price)
        self.productIdentifry = dictData.getString(key: KeyPlacesData.productIdentifry)
        self.childCount = dictData.getString(key: KeyPlacesData.childCount)
        self.yearly = dictData.getString(key: KeyPlacesData.yearly)
    }
}
