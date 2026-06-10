//
//  DictionaryExtension.swift


import UIKit

//NSDictionary Contains Value
extension NSDictionary {
    
    //MARK: - Get String From Dictionary
    func getString(key:String) -> String {
        
        if let value = self[key] {
            
            let string = NSString.init(format: "%@", value as! CVarArg) as String
            if (string.lowercased() == "null" || string.lowercased() == "nil" || string.lowercased() == "<null>") {
                return ""
            }
            return string.removeWhiteSpace()
        }
        return ""
    }
    //MARK: - Get Bool From Dictionary
    func getBool(key:String) -> Bool {
        
        if let value = self[key] {
            
            let string = NSString.init(format: "%@", value as! CVarArg) as String
            if (string.lowercased() == "null" || string.lowercased() == "nil" || string.lowercased() == "<null>") {
                return false
            }
            if (string.isNumber) {
                
                return Bool(truncating: NSNumber(integerLiteral: Int(string)!))
            } else if (string.lowercased() == "false" || string == "0") {
                return false
                
            } else if (string.lowercased() == "true" || string == "1") {
                return true
                
            } else {
                return false
            }
        }
        return false
    }
    //MARK: - Get Int From Dictionary
    func getInt(key:String) -> Int {
        
        if let value = self[key] {
            
            let string = NSString.init(format: "%@", value as! CVarArg) as String
            if (string.lowercased() == "null" || string.lowercased() == "nil" || string.lowercased() == "<null>") {
                return 0
            }
            
            if (string.isNumber) {
                
                return Int(string)!
            } else {
                return 0
            }
            
        }
        return 0
    }
    //MARK: - Get Double From Dictionary
    func getDouble(key:String) -> Double {
        
        if let value = self[key] {
            
            let string = NSString.init(format: "%@", value as! CVarArg) as String
            if (string.lowercased() == "null" || string.lowercased() == "nil" || string.lowercased() == "<null>") {
                return Double(0.0)
            }
            if (string.isFloat) {
                
                return Double(string)!
            } else {
                return Double(0.0)
            }
        }
        return Double(0.0)
    }
    //MARK: - Get Float From Dictionary
    func getFloat(key:String) -> Float {
        
        if let value = self[key] {
            
            let string = NSString.init(format: "%@", value as! CVarArg) as String
            if (string.lowercased() == "null" || string.lowercased() == "nil" || string.lowercased() == "<null>") {
                return Float(0.0)
            }
            if (string.isFloat) {
                
                return Float(string)!
            } else {
                return Float(0.0)
            }
        }
        return Float(0.0)
    }
    //MARK: - Get Dictionary From Dictionary
    func getDictionary(key:String) -> NSDictionary {
        
        if let value = self[key] as? NSDictionary {
            
            let string = NSString.init(format: "%@", value as CVarArg) as String
            if (string.lowercased() == "null" || string.lowercased() == "nil" || string.lowercased() == "<null>") {
                return NSDictionary()
            }
            return value
        }
        return NSDictionary()
    }
    //MARK: - Get Array From Dictionary
    func getArray(key:String) -> NSArray {
        
        if let value = self[key] as? NSArray {
            
            let string = NSString.init(format: "%@", value as CVarArg) as String
            if (string.lowercased() == "null" || string == "nil" || string.lowercased() == "<null>") {
                return NSArray()
            }
            return value
        }
        return NSArray()
    }
}
