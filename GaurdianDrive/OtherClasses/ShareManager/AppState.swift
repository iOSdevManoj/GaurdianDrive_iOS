//
//  AppState.swift


import UIKit

class AppState: NSObject {
    
    private var _user:UserModel?
    var user: UserModel? {
        set { _user = newValue! }
        get { return (_user) }
    }
    
    private var _strMyToken:String = "wwww"
    var strMyToken: String? {
        set { _strMyToken = newValue! }
        get { return (_strMyToken) }
    }
    
    override init() {
        super.init()
    }
    
    class var sharedInstance: AppState {
        struct Singleton {
            static let instance = AppState()
        }
        return Singleton.instance
    }
}

    
