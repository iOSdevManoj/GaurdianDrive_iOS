//
//  DateExtension.swift


import UIKit

extension Date {
    
    //Get Current Year From Current Date
    func getCurrentYear(yearFormate:String) -> String {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate(yearFormate)
        return df.string(from: self)
    }
    //Get Current Month From Current Date
    func getCurrentMonth(monthFormate:String) -> String {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate(monthFormate)
        return df.string(from: self)
    }
    //Get Current Day From Current Date
    func getCurrentDay(dayFormate:String) -> String {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate(dayFormate)
        return df.string(from: self)
    }
}

