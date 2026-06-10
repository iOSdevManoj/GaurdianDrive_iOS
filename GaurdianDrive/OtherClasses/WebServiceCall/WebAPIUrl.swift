//
//  WebAPIUrl.swift
//  LTT
//

import Foundation

//MARK: - Web Services Constant
class WebURL {

    //    static let googleAutoPlaceApi:String = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
    //    static let googlePlaceApi:String = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    //    static let googleGetAddressApi:String = "https://maps.googleapis.com/maps/api/geocode/json"
    static let appNameAlertTitle: String = "Gaurdian Drive App"

    //Dev Base url
    static let baseURL: String = "https://www.api.guardian-drive.dharechainfotech.com/"
    static let socketUrl: String =
        "wss://www.api.guardian-drive.dharechainfotech.com/web-socket/location"

    //Prod Base url
    //    static let baseURL:String = "https://apimicro1.phobaxxapp.com/api/"

    //Parent
    static let sendRegisterEmailCode: String = baseURL + "account/parent/register/email/send-code"
    static let sendValidateEmailCode: String =
        baseURL + "account/parent/register/email/validate-code"
    static let submitBasicData: String = baseURL + "account/parent/register/email"
    static let sendRegisterPhoneCode: String =
        baseURL + "account/parent/register/mobile-no/send-code"
    static let sendValidatePhoneCode: String =
        baseURL + "account/parent/register/mobile-no/validate-code"
    static let submitPhoneBasicData: String = baseURL + "account/parent/register/mobile-no"
    static let loginWithEmail: String = baseURL + "account/login/email/send-code"
    static let loginEmailOtpVerify: String = baseURL + "account/login/email"
    static let loginWithPhone: String = baseURL + "account/login/mobile-no/send-code"
    static let loginPhoneOtpVerify: String = baseURL + "account/login/mobile-no"
    static let addChild: String = baseURL + "child/add"
    static let getAddedChild: String = baseURL + "child/all"
    static let uploadDPImage: String = baseURL + "account/dp"
    static let socialRegister: String = baseURL + "account/parent/register/social"
    static let socialLogin: String = baseURL + "account/login/social"
    static let sendQRCodeData: String = baseURL + "account/login/qr/send-code"
    static let verifyQRCodeOTP: String = baseURL + "account/login/qr-code"

    //Child
    static let sendChildRegisterEmailCode: String =
        baseURL + "account/child/register/email/send-code"
    static let sendChildValidateEmailCode: String =
        baseURL + "account/child/register/email/validate-code"
    static let submitChildBasicData: String = baseURL + "account/child/register/email"
    static let sendChildRegisterPhoneCode: String =
        baseURL + "account/child/register/mobile-no/send-code"
    static let sendChildValidatePhoneCode: String =
        baseURL + "account/child/register/mobile-no/validate-code"
    static let submitChildPhoneBasicData: String = baseURL + "account/child/register/mobile-no"

    //Profile
    static let getProfile: String = baseURL + "profile"  // Use same for update profile -> PUT Method
    static let sendProfileEmailOTP: String = baseURL + "profile/email/send-code"
    static let sendProfileMobileOTP: String = baseURL + "profile/mobile-no/send-code"
    static let verifyEmailOTP: String = baseURL + "profile/email/validate-code"
    static let verifyPhoneNoOTP: String = baseURL + "profile/mobile-no/validate-code"
    static let logout: String = baseURL + "profile/logout"
    static let deleteAccount: String = baseURL + "profile"
    static let uploadProfileImage: String = baseURL + "profile/dp"
    static let getMySubscription: String = baseURL + "profile/subscription"
    static let getPinVerify: String = baseURL + "profile/verify-pin"
    static let registerDeviceToken: String = baseURL + "profile/register-device"
    static let freePendingDays: String = baseURL + "profile/pending-trial-days"
    static let allNotification: String = baseURL + "profile/notifications"
    static let readNotification: String = baseURL + "profile/notification/" // 565/read

    //Add Child Flow
    static let parentAddChild: String = baseURL + "child/add"
    static let getAddedChilds: String = baseURL + "child/all"
    static let childAccountApi: String = baseURL + "child/"
    static let getChildPolicy: String = baseURL + "child/my/drive-mode-policy"
    static let setHelpTicket: String = baseURL + "support-ticket/new"

    //Subscription..
    static let subscriptionVerify: String = baseURL + "parent/apple/transaction/verify"

    //Parent Control
    static func childAppsSync(childId: String) -> String {
        return baseURL + "child/\(childId)/apps/sync"
    }

    static func getChildApps(childId: String) -> String {
        return baseURL + "child/\(childId)/apps"
    }

    static func getAllChildApps(childId: String) -> String {
        return baseURL + "child/\(childId)/apps/all"
    }

    static func requestNoDriveMode(childId: String) -> String {
        return baseURL + "child/\(childId)/none-drive-mode/request"
    }

    static func approveRequest(childId: String, requestId: String) -> String {
        return baseURL + "child/\(childId)/app/\(requestId)/approve"
    }

    static func rejectRequest(childId: String, requestId: String) -> String {
        return baseURL + "child/\(childId)/app/\(requestId)/reject"
    }

    static func cancelRequest(childId: String, requestId: String) -> String {
        return baseURL + "child/\(childId)/app/\(requestId)/cancel"
    }

    static func approveNoDriveRequest(childId: String, requestId: String) -> String {
        return baseURL + "child/\(childId)/none-drive-mode/\(requestId)/approve"
    }

    static func rejectNoDriveRequest(childId: String, requestId: String) -> String {
        return baseURL + "child/\(childId)/none-drive-mode/\(requestId)/reject"
    }

    static func cancelNoDriveRequest(childId: String, requestId: String) -> String {
        return baseURL + "child/\(childId)/none-drive-mode/\(requestId)/cancel"
    }

    static let getRequestedNoDriveModeSchedule: String =
        baseURL + "child/my/request/schedule/requested/none-drive-mode"

    static func updateCurrentLocation(childId: String) -> String {
        return baseURL + "child/\(childId)/current-location"
    }

    static func getLastLocation(childId: String) -> String {
        return baseURL + "child/\(childId)/last-location"
    }

    static func childCustomData(childId: String) -> String {
        return baseURL + "child/\(childId)/app/custom-data"
    }
}
