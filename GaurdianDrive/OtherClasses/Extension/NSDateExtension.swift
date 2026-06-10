//
//  NSDateExtension.swift


import UIKit

//MARK: - NSDate Extention for UTC date
extension NSDate {
    
    //Get UTC formate to date
    func getUTCFormateDate() -> String {
        let dateFormatter = DateFormatter()
        let timeZone = NSTimeZone(name: "UTC")
        dateFormatter.timeZone = timeZone as TimeZone?
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self as Date)
    }
    
    //Get system date to date
    func getSystemFormateDate() -> String {
        let dateFormatter = DateFormatter()
        let timeZone = NSTimeZone.system
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "dd/MM/yy hh:mma"
        return dateFormatter.string(from: self as Date)
    }
    //Get Time stemp
    func getTimeStemp() -> String {
        
        return "\(self.timeIntervalSince1970 * 1000)"
    }
    
}
extension UIDatePicker {
    func set18YearValidation() {
        let currentDate: Date = Date()
        var calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var components: DateComponents = DateComponents()
        components.calendar = calendar
        components.year = -18
        let maxDate: Date = calendar.date(byAdding: components, to: currentDate)!
        components.year = -150
        let minDate: Date = calendar.date(byAdding: components, to: currentDate)!
        self.minimumDate = minDate
        self.maximumDate = maxDate
    } }
