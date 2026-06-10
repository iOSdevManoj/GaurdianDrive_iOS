//
//  NotificationModel.swift
//  GaurdianDrive
//
//  Created by KETAN on 22/03/26.
//

import UIKit

class NotificationModel: NSObject {
    
    var body: String = ""
    var data = DataModel()
    var deviceToken: String = ""
    var deviceType: String = ""
    var id: String = ""
    var jsonData: String = ""
    var status: String = ""
    var time: String = ""
    var title: String = ""
    var type: String = ""
    var userId: String = ""
    var version: String = ""
    var isRead: Bool = false

    struct Keys {
        static let body = "body"
        static let data = "data"
        static let deviceToken = "deviceToken"
        static let deviceType = "deviceType"
        static let id = "id"
        static let jsonData = "jsonData"
        static let status = "status"
        static let time = "time"
        static let title = "title"
        static let type = "type"
        static let userId = "userId"
        static let version = "version"
        static let isRead = "isRead"

    }
    
    override init() {
    }
    
    init(dict: NSDictionary) {
        self.body = dict.getString(key: Keys.body)
        self.data = DataModel.init(dict: dict.getDictionary(key: Keys.data))
        self.deviceToken = dict.getString(key: Keys.deviceToken)
        self.deviceType = dict.getString(key: Keys.deviceType)
        self.id = dict.getString(key: Keys.id)
        self.jsonData = dict.getString(key: Keys.jsonData)
        self.status = dict.getString(key: Keys.status)
        self.time = dict.getString(key: Keys.time)
        self.title = dict.getString(key: Keys.title)
        self.type = dict.getString(key: Keys.type)
        self.userId = dict.getString(key: Keys.userId)
        self.version = dict.getString(key: Keys.version)
        self.isRead = dict.getBool(key: Keys.isRead)
    }
}

class DataModel: NSObject {
    
    var appName: String = ""
    var childId: String = ""
    var childName: String = ""
    var mode: String = ""
    var parentId: String = ""
    var parentName: String = ""

    struct Keys {
        static let appName = "appName"
        static let childId = "childId"
        static let childName = "childName"
        static let mode = "mode"
        static let parentId = "parentId"
        static let parentName = "parentName"
    }
    
    override init() {
    }
    
    init(dict: NSDictionary) {
        self.appName = dict.getString(key: Keys.appName)
        self.childId = dict.getString(key: Keys.childId)
        self.childName = dict.getString(key: Keys.childName)
        self.mode = dict.getString(key: Keys.mode)
        self.parentId = dict.getString(key: Keys.parentId)
        self.parentName = dict.getString(key: Keys.parentName)
    }
}
