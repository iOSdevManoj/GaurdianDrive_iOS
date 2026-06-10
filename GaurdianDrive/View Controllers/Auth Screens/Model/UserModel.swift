//
//  UserModel.swift
//  GaurdianDrive
//
//  Created by KETAN on 08/01/26.
//

import UIKit

class UserModel: NSObject,NSCoding {
    
    var name : String = ""
    var timeZoneOffset: String = ""
    var userId : String = ""
    var email: String = ""
    var mobileNo: String = ""
    var countryCode: String = ""
    var type: String = ""
    var dpUrl: String = ""
    var status: String = ""
    var localAaddedTime: String = ""
    var pin: String = ""

    struct KeyPlacesData    {
        static let name = "name"
        static let timeZoneOffset = "timeZoneOffset"
        static let userId = "userId"
        static let email = "email"
        static let mobileNo = "mobileNo"
        static let countryCode = "countryCode"
        static let type = "type"
        static let dpUrl = "dpUrl"
        static let id = "id"
        static let status = "status"
        static let localAaddedTime = "localAaddedTime"
        static let pin = "pin"

    }
    override init(){
    }
    
    init(dict : NSDictionary){
        self.name = dict.getString(key: KeyPlacesData.name)
        self.timeZoneOffset = dict.getString(key: KeyPlacesData.timeZoneOffset)
        self.userId = dict.getString(key: KeyPlacesData.userId)
        self.email = dict.getString(key: KeyPlacesData.email)
        self.mobileNo = dict.getString(key: KeyPlacesData.mobileNo)
        self.countryCode = dict.getString(key: KeyPlacesData.countryCode)
        self.type = dict.getString(key: KeyPlacesData.type)
        self.dpUrl = dict.getString(key: KeyPlacesData.dpUrl)
        self.status = dict.getString(key: KeyPlacesData.status)
        self.localAaddedTime = dict.getString(key: KeyPlacesData.localAaddedTime)
        self.pin = dict.getString(key: KeyPlacesData.pin)

        if self.userId == ""
        {
            self.userId = dict.getString(key: KeyPlacesData.id)
        }
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(name, forKey: KeyPlacesData.name)
        aCoder.encode(timeZoneOffset, forKey: KeyPlacesData.timeZoneOffset)
        aCoder.encode(userId, forKey: KeyPlacesData.userId)
        aCoder.encode(email, forKey: KeyPlacesData.email)
        aCoder.encode(mobileNo, forKey: KeyPlacesData.mobileNo)
        aCoder.encode(countryCode, forKey: KeyPlacesData.countryCode)
        aCoder.encode(type, forKey: KeyPlacesData.type)
        aCoder.encode(dpUrl, forKey: KeyPlacesData.dpUrl)

    }
    
    required convenience init?(coder aDecoder:
                               NSCoder) {
        
        self.init()
        self.name = createString(value: aDecoder.decodeObject(forKey: KeyPlacesData.name) as AnyObject)
        self.timeZoneOffset = createString(value: aDecoder.decodeObject(forKey: KeyPlacesData.timeZoneOffset) as AnyObject)
        self.userId = createString(value:aDecoder.decodeObject(forKey: KeyPlacesData.userId) as AnyObject)
        self.email = createString(value:aDecoder.decodeObject(forKey: KeyPlacesData.email) as AnyObject)
        self.mobileNo = createString(value:aDecoder.decodeObject(forKey: KeyPlacesData.mobileNo) as AnyObject)
        self.countryCode = createString(value:aDecoder.decodeObject(forKey: KeyPlacesData.countryCode) as AnyObject)
        self.type = createString(value:aDecoder.decodeObject(forKey: KeyPlacesData.type) as AnyObject)
        self.dpUrl = createString(value:aDecoder.decodeObject(forKey: KeyPlacesData.dpUrl) as AnyObject)
    }
    
    static func setArchiveData(_ userProfile: UserModel) {
        do {
            let userProfile1 = try NSKeyedArchiver.archivedData(withRootObject: userProfile, requiringSecureCoding: false)
            UserDefaults.Main.set(userProfile1, forKey: .profile)
        } catch {
            print("error to save in archive")
        }
    }
    
    static func unarchiveUserProfileData() -> UserModel
    {
        let userData =  UserDefaults.Main.object(forKey: .profile)
        do {
            let userModelData = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(userData as! Data)) as? UserModel
            return userModelData!
        }
    }

}
