import UIKit

//MARK: - String Extension
public extension String {
    
    var isEmptyStr:Bool{
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces).isEmpty
    }
}
extension String {
    
    var length: Int { return count    }  // Swift 2.0

    func trim() -> String {

        return self.trimmingCharacters(in: .whitespacesAndNewlines)

    }
    //Remove white space in string
    func removeWhiteSpace() -> String {
        return self.trimmingCharacters(in: .whitespaces)
    }
    
    //Check string is number or not
    var isNumber : Bool {
        get{
            return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        }
    }
    //Check email is valid or not
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: self)
    }
    var isPhoneNumber: Bool {
        let phoneNumberRegEx = "^[0-9+]{9,12}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneNumberRegEx).evaluate(with: self)
//        do {
//            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
//            let matches = detector.matches(in: self, options: [], range: NSMakeRange(0, self.count))
//            if let res = matches.first {
//                return res.resultType == .phoneNumber && res.range.location == 0 && res.range.length == self.count
//            } else {
//                return false
//            }
//        } catch {
//            return false
//        }
    }
    //Check string is Float or not
    var isFloat : Bool {
        get{
            if Float(self) != nil {
                return true
            }else {
                return false
            }
        }
    }
    //Format Number If Needed
    func formatNumberIfNeeded() -> String {
        let charset = CharacterSet(charactersIn: "0123456789.,")
        if self.rangeOfCharacter(from: charset) != nil {
            let currentTextWithoutCommas:NSString = (self.replacingOccurrences(of: ",", with: "")) as NSString
            if currentTextWithoutCommas.length < 1 {
                return ""
            }
            let numberFormatter: NumberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            numberFormatter.minimumFractionDigits = 2
            numberFormatter.maximumFractionDigits = 2
            
            let numberFromString: NSNumber = numberFormatter.number(from: currentTextWithoutCommas as String)!
            let formattedNumberString: NSString = numberFormatter.string(from: numberFromString)! as NSString
            let convertedString:String = String(formattedNumberString)
            return convertedString
            
        } else {
            
            return self
        }
    }
    //MARK: - Check Contains Capital Letter
    func isContainsCapital() -> Bool {

        let capitalLetterRegEx  = ".*[A-Z]+.*"
        let textTest = NSPredicate(format:"SELF MATCHES %@", capitalLetterRegEx)
        let capitalResult = textTest.evaluate(with: self)
        return capitalResult
    }
    //MARK: - Check Contains Number Letter
    func isContainsNumber() -> Bool {
        
        let numberRegEx  = ".*[0-9]+.*"
        let textTest = NSPredicate(format:"SELF MATCHES %@", numberRegEx)
        let numberResult = textTest.evaluate(with: self)
        return numberResult
    }
    //MARK: - Check Contains Special Character
    func isContainsSpecialCharacter() -> Bool {
        
        let specialCharacterRegEx  = ".*[!&^%$#@()/]+.*"
        let textTest = NSPredicate(format:"SELF MATCHES %@", specialCharacterRegEx)
        let specialResult = textTest.evaluate(with: self)
        return specialResult
    }
    
    func isStringWithoutSpace() -> Bool{
        return !self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
    }
    
    //Number Suffix
    func numberSuffix(from number: Int) -> String {
        switch number {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
    func fromBase64() -> String {
        guard let data = Data(base64Encoded: self, options: Data.Base64DecodingOptions.init(rawValue: 0)) else {
            return self
        }
        return String(data: data, encoding: .utf8) ?? self
    }
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    var htmlToAttributedString: NSAttributedString? {
            guard let data = data(using: .utf8) else { return nil }
            do {
                return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
            } catch {
                return nil
            }
        }
        var htmlToString: String {
            return htmlToAttributedString?.string ?? ""
        }
}


//MARK: - check string nil
func createString(value: AnyObject) -> String
{
    var returnString: String = ""
    if let str: String = value as? String {
        
        returnString = str
        
    } else if let str: Int = value as? Int {
        
        returnString = String.init(format: "%d", str)
        
    } else if let _: NSNull = value as? NSNull {
        
        returnString = String.init(format: "")
    }else if let str: Double = value as? Double {
        returnString = String.init(format: "%.4f", str) //2.99
    }else if let str: NSNumber = value as? NSNumber {
        returnString = String.init(format: "%.4f", str) //2.99
    }else if let str: NSDecimalNumber = value as? NSDecimalNumber {
        let usLocale = Locale(identifier: "en_US")
      
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 4
        nf.locale = usLocale
        returnString = nf.string(from: str)! //2.99
    }
    return returnString
}
//MARK: - check string nil
func createFloatToString(value: AnyObject) -> String {
    
    var returnString: String = ""
    if let str: String = value as? String {
        
        returnString = str
        
    } else if let str: Float = value as? Float {
        
        returnString = String.init(format: "%.2f", str)
        
    } else if let _: NSNull = value as? NSNull {
        
        returnString = String.init(format: "")
    }
    return returnString
}
func convertStringToInt(value: String) -> Int {
    var returnInt = 0
    if let intValue: Int = Int(value) {
        returnInt = intValue
    }
    return returnInt
}


func createDoubleToString(value: AnyObject) -> String {
    
    var returnString: String = ""
    if let str: String = value as? String {
        
        returnString = str
        
    } else if let str: Double = value as? Double {
        
        returnString = String.init(format: "%.2f", str)
        
    } else if let _: NSNull = value as? NSNull {
        
        returnString = String.init(format: "")
    }
    return returnString
}
//MARK: - Get String From Dictionary
func getStringFromDictionary(dictionary:[String:Any], key:String) -> String {
    
    if let value = dictionary[key] {
        
        let string = NSString.init(format: "%@", value as! CVarArg) as String
        if (string == "null" || string == "NULL" || string == "nil" || string == "<null>") {
            return ""
        }
        return string.removeWhiteSpace()
    }
    return ""
}
//MARK: - Get Bool From Dictionary
func getBoolFromDictionary(dictionary:NSDictionary, key:String) -> Bool {
    
    if let value = dictionary[key] {
        
        let string = NSString.init(format: "%@", value as! CVarArg) as String
        if (string == "null" || string == "NULL" || string == "nil") {
            return false
        }
        if (string.isNumber) {
            
            return Bool(truncating: NSNumber(integerLiteral: Int(string)!))
        } else if (string == "false" || string == "FALSE" || string == "False") {
            return false
            
        } else if (string == "true" || string == "TRUE" || string == "True") {
            return true
            
        } else {
            return false
        }
        
    }
    return false
}
//MARK: - Get Int From Dictionary
func getIntFromDictionary(dictionary:[String:Any], key:String) -> Int {
    
    if let value = dictionary[key] {
        
        let string = NSString.init(format: "%@", value as! CVarArg) as String
        if (string == "null" || string == "NULL" || string == "nil") {
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
func getDoubleFromDictionary(dictionary:NSDictionary, key:String) -> Double {
    
    if let value = dictionary[key] {
        
        let string = NSString.init(format: "%@", value as! CVarArg) as String
        if (string == "null" || string == "NULL" || string == "nil") {
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
func getFloatFromDictionary(dictionary:NSDictionary, key:String) -> Float {
    
    if let value = dictionary[key] {
        
        let string = NSString.init(format: "%@", value as! CVarArg) as String
        if (string == "null" || string == "NULL" || string == "nil") {
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
func getDictionaryFromDictionary(dictionary:[String:Any], key:String) -> [String:Any] {
    
    if let value = dictionary[key] as? [String:Any] {
        
        let string = NSString.init(format: "%@", value as CVarArg) as String
        if (string == "null" || string == "NULL" || string == "nil") {
            return [:]
        }
        return value
    }
    return [:]
}
//MARK: - Get Array From Dictionary
func getArrayFromDictionary(dictionary:[String:Any], key:String) -> [Any] {
    
    if let value = dictionary[key] as? [Any] {
        
        let string = NSString.init(format: "%@", value as CVarArg) as String
        if (string == "null" || string == "NULL" || string == "nil") {
            return []
        }
        return value
    }
    return []
}
//MARK: - Get perfect number float or integer
func getPerfectNumberFloatOrInt(number:Float) -> String {
    
    let reviews_av = number
    let isInteger = floor(reviews_av) == reviews_av
    var strReviews_av = ""
    if (isInteger) {
        
        strReviews_av = String(Int(reviews_av))
    } else {
        
        strReviews_av = String(format: "%.1f", reviews_av)
    }
    return strReviews_av
}
//MARK: - String Extension
extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex])
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
}
extension String {
    //Get only digit and symbol
    var onlyDigits: String {
        return onlyCharacters(charSets: [.decimalDigits,.symbols])
    }
    //Get only letters
    var onlyLetters: String {
        return onlyCharacters(charSets: [.letters])
    }
    ///Remove character from string
    private func removeCharacters(unicodeScalarsFilter: (UnicodeScalar) -> Bool) -> String {
        let filtredUnicodeScalars = unicodeScalars.filter{unicodeScalarsFilter($0)}
        return String(String.UnicodeScalarView(filtredUnicodeScalars))
    }
    
    private func removeCharacters(from charSets: [CharacterSet], unicodeScalarsFilter: (CharacterSet, UnicodeScalar) -> Bool) -> String {
        return removeCharacters{ unicodeScalar in
            for charSet in charSets {
                let result = unicodeScalarsFilter(charSet, unicodeScalar)
                if result {
                    return true
                }
            }
            return false
        }
    }
    
    func removeCharacters(charSets: [CharacterSet]) -> String {
        return removeCharacters(from: charSets) { charSet, unicodeScalar in
            !charSet.contains(unicodeScalar)
        }
    }
    
    func removeCharacters(charSet: CharacterSet) -> String {
        return removeCharacters(charSets: [charSet])
    }
    
    func onlyCharacters(charSets: [CharacterSet]) -> String {
        return removeCharacters(from: charSets) { charSet, unicodeScalar in
            charSet.contains(unicodeScalar)
        }
    }
    
    func onlyCharacters(charSet: CharacterSet) -> String {
        return onlyCharacters(charSets: [charSet])
    }
//    func UTCToLocal(date:String) -> String {
//        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//        
//        let dt = dateFormatter.date(from: date)
//        dateFormatter.timeZone = TimeZone.current
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//        var str = ""
//        if dt != nil
//        {
//            str = dateFormatter.string(from: dt!)
//        }
//        return str
//    }
}



