//
//  BundleExtension.swift


import UIKit

//MARK: - Bundle Information
extension Bundle {
    
    //Get Release Version Number
    var releaseVersionNumber: String? {
        
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    //Get Build Version Number
    var buildVersionNumber: String? {
        
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
