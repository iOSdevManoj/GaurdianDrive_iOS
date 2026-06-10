//
//  ChildAddressModel.swift
//  GaurdianDrive
//
//  Created by KETAN on 12/03/26.
//

import UIKit

class ChildAddressModel: NSObject {
    
      var addressLine1 : String = ""
       var addressLine2 : String = ""
       var childId : String = ""
       var childName : String = ""
       var city : String = ""
       var country : String = ""
       var id : String = ""
       var landmark : String = ""
       var latitude : String = ""
       var longitude : String = ""
       var state : String = ""
       var status : String = ""
       var title : String = ""
       var version : String = ""
       var zipcode : String = ""

       struct KeyPlacesData {
           static let addressLine1 = "addressLine1"
           static let addressLine2 = "addressLine2"
           static let childId = "childId"
           static let childName = "childName"
           static let city = "city"
           static let country = "country"
           static let id = "id"
           static let landmark = "landmark"
           static let latitude = "latitude"
           static let longitude = "longitude"
           static let state = "state"
           static let status = "status"
           static let title = "title"
           static let version = "version"
           static let zipcode = "zipcode"
       }
       
       override init() {
       }
       
       init(dict : NSDictionary) {
           self.addressLine1 = dict.getString(key: KeyPlacesData.addressLine1)
           self.addressLine2 = dict.getString(key: KeyPlacesData.addressLine2)
           self.childId = dict.getString(key: KeyPlacesData.childId)
           self.childName = dict.getString(key: KeyPlacesData.childName)
           self.city = dict.getString(key: KeyPlacesData.city)
           self.country = dict.getString(key: KeyPlacesData.country)
           self.id = dict.getString(key: KeyPlacesData.id)
           self.landmark = dict.getString(key: KeyPlacesData.landmark)
           self.latitude = dict.getString(key: KeyPlacesData.latitude)
           self.longitude = dict.getString(key: KeyPlacesData.longitude)
           self.state = dict.getString(key: KeyPlacesData.state)
           self.status = dict.getString(key: KeyPlacesData.status)
           self.title = dict.getString(key: KeyPlacesData.title)
           self.version = dict.getString(key: KeyPlacesData.version)
           self.zipcode = dict.getString(key: KeyPlacesData.zipcode)
       }
}
