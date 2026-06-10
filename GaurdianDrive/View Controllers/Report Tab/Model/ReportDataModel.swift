//
//  ReportDataModel.swift
//  GaurdianDrive
//
//  Created by KETAN on 05/03/26.
//
import UIKit

class ReportDataModel: NSObject {
    
    var averageSpeed : String = ""
    var version: String = ""
    var durationOfActiveDriveMode : String = ""
    var noOfActiveDriveMode: String = ""
    var percentageOfNightDrive: String = ""
    var highestSpeed: String = ""
    var childId: String = ""
    var topSpeeds = [TopSpeedModel]()
    var dailyHistories = [DailyHistories]()

    struct KeyPlacesData    {
        static let averageSpeed = "averageSpeed"
        static let version = "version"
        static let durationOfActiveDriveMode = "durationOfActiveDriveMode"
        static let noOfActiveDriveMode = "noOfActiveDriveMode"
        static let percentageOfNightDrive = "percentageOfNightDrive"
        static let highestSpeed = "highestSpeed"
        static let childId = "childId"
        static let dailyHistories = "dailyHistories"
        static let topSpeeds = "topSpeeds"
    }
    
    override init(){
    }
    
    init(dict : NSDictionary){
        
        self.averageSpeed = dict.getString(key: KeyPlacesData.averageSpeed)
        self.version = dict.getString(key: KeyPlacesData.version)
        self.durationOfActiveDriveMode = dict.getString(key: KeyPlacesData.durationOfActiveDriveMode)
        self.noOfActiveDriveMode = dict.getString(key: KeyPlacesData.noOfActiveDriveMode)
        self.percentageOfNightDrive = dict.getString(key: KeyPlacesData.percentageOfNightDrive)
        self.highestSpeed = dict.getString(key: KeyPlacesData.highestSpeed)
        self.childId = dict.getString(key: KeyPlacesData.childId)
        
        let arrTopSpeedsList = dict.getArray(key: KeyPlacesData.topSpeeds)
        for speedData in arrTopSpeedsList
        {
            let speedModel = TopSpeedModel.init(dict: speedData as! NSDictionary)
            self.topSpeeds.append(speedModel)
        }
        
        let arrdailyHistoriesList = dict.getArray(key: KeyPlacesData.dailyHistories)
        for historyData in arrdailyHistoriesList
        {
            let historyDataModel = DailyHistories.init(dict: historyData as! NSDictionary)
            self.dailyHistories.append(historyDataModel)
        }
    }
}

class TopSpeedModel: NSObject {
    
    var childId : String = ""
    var childName: String = ""
    var id : String = ""
    var latitude: String = ""
    var longitude: String = ""
    var localTime: String = ""
    var speed: String = ""

    struct KeyPlacesData    {
        static let childId = "childId"
        static let childName = "childName"
        static let id = "id"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let localTime = "localTime"
        static let speed = "speed"
    }
    
    override init(){
    }
    
    init(dict : NSDictionary){
        self.childId = dict.getString(key: KeyPlacesData.childId)
        self.childName = dict.getString(key: KeyPlacesData.childName)
        self.id = dict.getString(key: KeyPlacesData.id)
        self.latitude = dict.getString(key: KeyPlacesData.latitude)
        self.longitude = dict.getString(key: KeyPlacesData.longitude)
        self.localTime = dict.getString(key: KeyPlacesData.localTime)
        self.speed = dict.getString(key: KeyPlacesData.speed)
    }
}
class DailyHistories: NSObject {
    
    var childId : String = ""
    var childName: String = ""
    var id : String = ""
    var averageSpeed: String = ""
    var day: String = ""
    var date: String = ""
    var durationOfActiveDriveMode: String = ""
    var noOfActiveDriveMode: String = ""

    struct KeyPlacesData    {
        static let childId = "childId"
        static let childName = "childName"
        static let id = "id"
        static let averageSpeed = "averageSpeed"
        static let day = "day"
        static let date = "date"
        static let durationOfActiveDriveMode = "durationOfActiveDriveMode"
        static let noOfActiveDriveMode = "noOfActiveDriveMode"

    }
    
    override init(){
    }
    
    init(dict : NSDictionary){
        self.childId = dict.getString(key: KeyPlacesData.childId)
        self.childName = dict.getString(key: KeyPlacesData.childName)
        self.id = dict.getString(key: KeyPlacesData.id)
        self.averageSpeed = dict.getString(key: KeyPlacesData.averageSpeed)
        self.day = dict.getString(key: KeyPlacesData.day)
        self.date = dict.getString(key: KeyPlacesData.date)
        self.durationOfActiveDriveMode = dict.getString(key: KeyPlacesData.durationOfActiveDriveMode)
        self.noOfActiveDriveMode = dict.getString(key: KeyPlacesData.noOfActiveDriveMode)
    }
}
