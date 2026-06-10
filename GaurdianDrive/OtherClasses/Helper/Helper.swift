//
//  Helper.swift


import Foundation
import UIKit
import AVFoundation
import SystemConfiguration

let CMainScreen = UIScreen.main
let CBounds = CMainScreen.bounds
let CScreenSize = CBounds.size
let CScreenWidth = CScreenSize.width
let CScreenHeight = CScreenSize.height
let CScreenOrigin = CBounds.origin
let CScreenX = CScreenOrigin.x
let CScreenY = CScreenOrigin.y

let kInternetDown       = "Your internet connection appears to be off"
let kHostDown           = "Looks like your host has stopped."
let kTimeOut            = "Request has timed out"
let kTokenExpire        = "Session expired - please log in again."
let appName            = "Gauedian Drive App"
let App_Itune_Link            = "itms-apps://itunes.apple.com/app/id"
let GoogleKey = "AIzaSyAhS37p1GSAbZ4uonc-aCEJsRoB40lmdBg"//"AIzaSyBWqjfQjQmieqwtyjDym1AAvQoTBNnu3Do"

//InApp Purchase Bundle ID:
let oneChild_1Month = "com.app.gaurdianDrive.oneChild.1month"
let twoChild_1Month  = "com.app.gaurdianDrive.twoChild.1month"
let threeChild_1Month  = "com.app.gaurdianDrive.threeChild.1month"
let fourChild_1Month  = "com.app.gaurdianDrive.fourChild.1month"
let oneChild_Yearly = "com.app.gaurdianDrive.oneChild.yearly"
let twoChild_Yearly  = "com.app.gaurdianDrive.twoChild.yearly"
let threeChild_Yearly  = "com.app.gaurdianDrive.threeChild.yearly"
let fourChild_Yearly  = "com.app.gaurdianDrive.fourChild.yearly"

//MARK: - Device Type
enum UIUserInterfaceIdiom : Int {
    case Unspecified
    case Phone
    case Pad
}

//MARK: - Main Tabs
enum mainTabs : Int {
    case Attandance = 0
    case Sales = 1
    case Inventory = 2
}
//MARK: - Open OTP Verification
enum OpenOTPVerify : String {
    case Login = "1"
    case SignUp = "2"
    case ForgotPassword = "3"
}
//MARK: - Gallery Selection Type
enum GalleryType : String {
    case Video = "1"
    case Image = "2"
    case Draft = "3"
}
//MARK: - Open OTP Verification
enum OpenProfileFrom : String {
    case RequestMedia = "1"
    case Follow = "2"
    case RequestList = "3"
    case Discovery = "4"
    case Activity = "5"
    case MediaDetails = "6"
    case HomeFeed = "7"
    case RequestSentList = "8"
    case coinsList = "9"
    case follow = "10"
    case notification = "11"
    case block = "12"

}
//MARK: - Media Type
enum MediaType : String {
    case Video = "Video"
    case Image = "Image"
}
//MARK: - Media Profile Type
enum MediaProfileType : String {
    case Private = "Private"
    case Public = "Public"
}

//MARK: - Api Success status
enum ApiResponseStatus : Int {
    case Success = 200
    case NoScanData = 202
    case ExpireAuth = 401
    case Success1 = 201
    case AlreadyExist = 403
    case Error = 400
    case UserBlock = 405
    case Blocked = 203
}

//MARK: - NotificationType
enum NotificationType : String {
    case Follow = "FOLLOW"
    case RequestReceived = "REQUEST_RECEIVED"
    case RequestDecline = "REQUEST_DECLINED"
    case CoinRedeemed = "COIN_REDEEMED"
    case CreateContent = "CONTENT"
    case CoinRefund = "COIN_REFUNDED"
    case ContentView = "CONTENT_VIEWED"
    case Like = "LIKE"
    case Comment = "COMMENT"
    case ReplyComment = "REPLY_COMMENT"
    case PromoNotification = "PROMO_NOTIFICATION"
    case AdminSupport = "ADMIN_SUPPORT"
    case SpecialGift = "SPECIAL_GIFT"

}
//MARK: - SubscriptionType
enum SubscripionType : String {
    case NotFound = "NOT_FOUND"
    case Expired = "EXPIRED"
    case Valid = "VALID"
}

//MARK: - Notificaiton obserwer names
struct NotificationName {
    static let AppRequest = "APP_REQUEST"
    static let AppApprove = "APP_APPROVE"
    static let AppReject = "APP_REJECT"
    static let AppReqCancel = "APP_CANCEL"
}

struct DeviceType {
    static let IS_IPHONE_4_OR_LESS  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
    static let IS_IPHONE_5          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
    static let IS_IPHONE_6          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6PLUS      = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
    static let IS_IPAD              = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1024.0
    static let IS_IPAD_PRO          = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1366.0
    static let IS_IPHONE_X          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 812.0
    static let IS_IPHONE_XSMax_XR   = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 896.0
}

//MARK: - Screen Size
struct ScreenSize {
    
    static let width         = UIScreen.main.bounds.size.width
    static let height        = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(ScreenSize.width, ScreenSize.height)
    static let SCREEN_MIN_LENGTH    = min(ScreenSize.width, ScreenSize.height)
}

//MARK: - Font Layout
struct FontName {
    static let PlusJakartaSansRegular = "PlusJakartaSans-Regular"
    static let PlusJakartaSansLight = "PlusJakartaSans-Light"
    static let PlusJakartaSansMedium = "PlusJakartaSans-Medium"
    static let PlusJakartaSansSemiBold = "PlusJakartaSans-SemiBold"
    static let PlusJakartaSansBold = "PlusJakartaSans-Bold"
}

//MARK: - StoryBoards Constant
struct storyBoards {
    static let Main = UIStoryboard(name: "Main", bundle: Bundle.main)
    static let Home = UIStoryboard(name: "Home", bundle: Bundle.main)
    static let Reports = UIStoryboard(name: "Reports", bundle: Bundle.main)
    static let Settings = UIStoryboard(name: "Settings", bundle: Bundle.main)
    static let Tabbar = UIStoryboard(name: "Tabbar", bundle: Bundle.main)
    static let Child = UIStoryboard(name: "Child", bundle: Bundle.main)
}

//MARK: - Error messages..
enum ErrorMessage : String {
    case email = "Email field is required"
    case emailValid = "Please enter valid email id"
    case passwordRequired = "Password field is required"
}
//MARK: - Permission Messages
enum PermissionMessage : String {
    case Camera = "Phobaxx uses access to your camera to do things such as help you take photos and record videos.\n\nYou can change this access anytime in your device settings."
    case Gallery = "Phobaxx needs access to your library so you can upload photos and videos to share on the app.\n\nYou can manage or limit this access anytime in your device settings."
    case MicroPhone = "Phobaxx needs microphone access to record audio while capturing videos. Your audio is only used for content creation and is never shared without your consent."
}
//MARK: - Permission Title Messages
enum PermissionMessageTitle : String {
    case Camera = "“Phobaxx” Would Like to Access the Camera"
    case Gallery = "“Phobaxx” Would Like to Access Your Photo and Video Library"
    case MicroPhone = "“Phobaxx” Would Like to Access the Microphone"
}

//MARK: - Scaling
struct DeviceScale {
    static let x = ScreenSize.width / 375.0
    static let y = ScreenSize.height / 667.0
    static let xy = (DeviceScale.x + DeviceScale.y) / 2.0
    static let x_iPhone:Float = (DeviceType.IS_IPAD || DeviceType.IS_IPAD_PRO ? Float(1.0) : Float(ScreenSize.width / 375.0))
    static let y_iPhone:Float = (DeviceType.IS_IPAD || DeviceType.IS_IPAD_PRO ? Float(1.0) : Float(ScreenSize.height / 667.0))
}

//MARK: - Helper Class
class Helper {
    //MARK: - Shared Instance
    static let sharedInstance : Helper = {
        let instance = Helper()
        return instance
    }()
    
    static let isDevelopmentBuild:Bool = true
    
}

//MARK: - Set Globally Alert View..
extension UIViewController {
       
    func popupAlert(title: String?, message: String?, actionTitles:[String?], actions:[((UIAlertAction) -> Void)?]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for (index, title) in actionTitles.enumerated() {
            let action = UIAlertAction(title: title, style: .default, handler: actions[index])
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }
    func popupAlertActionSheet(title: String?, message: String?, actionTitles:[String?], actions:[((UIAlertAction) -> Void)?]) {
        
        let attributedString = NSAttributedString(string: title!, attributes: [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)
        ])
        
        let alert = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
        alert.setValue(attributedString, forKey: "attributedTitle")
        
        for (index, title) in actionTitles.enumerated() {
            let action = UIAlertAction(title: title, style:(title == "Cancel") ? .cancel : .default, handler: actions[index])
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }
    func reloadViewFromNib() {
        let parent = view.superview
        view.removeFromSuperview()
        view = nil
        parent?.addSubview(view)
        self.view.layoutIfNeeded()
    }
    //MARK: - View controller extention for Remove child class..
        func removeChild() {
            self.children.forEach {
                $0.willMove(toParent: nil)
                $0.view.removeFromSuperview()
                $0.removeFromParent()
            }
        }
}

//MARK: - Hide/Show view
func setView(view: UIView, hidden: Bool) {
    UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: {
        view.isHidden = hidden
    })
}

func isValidPassword(aStrText:String) -> Bool {
//    let passwordRegex = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[#?!@$%^&<>*~:`-]).{4,11}$"
//    return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: aStrText)
    //"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&<>*~:`-]).{8,}$"
    if aStrText.count < 4
    {
        return false
    }
    else if aStrText.count > 11
    {
        return false
    }
    return true
}

extension AVURLAsset {
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)
        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
}

var hasTopNotch: Bool {
    if #available(iOS 11.0, tvOS 11.0, *) {
        return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
    }
    return false
}
func isValidPassword(aString:String) -> Bool {
    let passwordRegex = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^_&<>*~:`-]).{8,}$"
    return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: aString)
}
//func convertDateFormater(_ date: String,aFromFormate:String,aToFormate:String) -> String
//{
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateFormat = aFromFormate
//    let date = dateFormatter.date(from: date)
//    dateFormatter.dateFormat = aToFormate
//    return  dateFormatter.string(from: date!)
//}

//func convertDateFormaterLocal(_ date: String,aFromFormate:String,aToFormate:String) -> String
//{
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateFormat = aFromFormate
//    dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
//    dateFormatter.locale = Locale.current
//    let date = dateFormatter.date(from: date)
//    dateFormatter.dateFormat = aToFormate
//    return  dateFormatter.string(from: date!)
//}

//MARK: - Hide/ Show password UI and functionality
func setupHideShowPassword(isShow:Bool,imgView:UIImageView,txtField:UITextField)
{
    let strImgName = (isShow) ? "ic_show_pwd" : "ic_hide_pwd"
    imgView.image = UIImage(named:strImgName)
    txtField.isSecureTextEntry = !isShow
}

func getCompressImageData(aImage:UIImage) -> Data
{
    var compressProfileImage = UIImage()
    compressProfileImage = aImage.resizedTo1MB()!
    return compressProfileImage.pngData()!
}
func setUserProfileImageFromUrl(aImageview:UIImageView,aPlaceholderName:String)
{
    if let profileDetails = AppState.sharedInstance.user
    {
        if let imgUrl = URL(string: profileDetails.dpUrl)
        {
            aImageview.sd_setImage(with:imgUrl, placeholderImage:UIImage(named: aPlaceholderName))
        }
        else{
            aImageview.image = UIImage.init(named: aPlaceholderName)
        }
    }
}

func UTCToLocal(date:String,aDateFormate:String) -> (aDate : String, aTime : String){
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

    let dt = dateFormatter.date(from: date)
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.dateFormat = aDateFormate
    
    var strDate = ""
    var strTime = ""
    if dt != nil
    {
        strDate = dateFormatter.string(from: dt!)
        dateFormatter.dateFormat = "hh:mm a"
        strTime = dateFormatter.string(from: dt!)
    }
    
    return (strDate,strTime)
}

func getOrigionalUrlString(strUrl:String) -> String
{
    return strUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
}

func isHideTabbarGlobally(isHide:Bool,viewContoller:UIViewController)
{
    viewContoller.tabBarController?.tabBar.isHidden = isHide
    if rootTab.cons_bottomBar_height != nil{
        rootTab.cons_bottomBar_height.constant = (isHide) ? 0 : 60
        rootTab.viewBottomTabMain.isHidden = isHide
    }
}
func getTimeZoneOffsetMinutes() -> Int {
    return TimeZone.current.secondsFromGMT() / 60
}

func formatServerDate(_ dateString: String) -> (dateTime: String, day: String)? {
    
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    guard let date = isoFormatter.date(from: dateString) else { return nil }

    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone.current
    
    // First line
    dateFormatter.dateFormat = "d MMM yyyy 'on' h:mm a"
    let dateTime = dateFormatter.string(from: date)
    
    // Day name
    dateFormatter.dateFormat = "EEEE"
    let day = dateFormatter.string(from: date)

    return (dateTime, day)
}


enum SubscriptionStatus {
    case active(String)
    case expired
}

func getSubscriptionStatus(_ dateStr: String) -> SubscriptionStatus {

    guard !dateStr.isEmpty else {
        return .expired
    }

    var expiryDate: Date?

    let isoWithMs = ISO8601DateFormatter()
    isoWithMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    expiryDate = isoWithMs.date(from: dateStr)

    if expiryDate == nil {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        expiryDate = iso.date(from: dateStr)
    }

    guard let finalDate = expiryDate else {
        return .expired
    }

    let now = Date()

    // ❌ Expired
    if now >= finalDate {
        return .expired
    }

    let diff = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: finalDate)

    let days = diff.day ?? 0
    let hours = diff.hour ?? 0
    let minutes = diff.minute ?? 0

    if days == 0 && hours == 0 {
        return .active("Expires in \(minutes) minute\(minutes == 1 ? "" : "s")")
    }

    if days == 0 {
        return .active("Expires in \(hours) hour\(hours == 1 ? "" : "s")")
    }

    if days <= 7 {
        return .active("Expires in \(days) day\(days == 1 ? "" : "s")")
    }

    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "dd MMM yyyy 'at' hh:mm a"

    let formattedDate = formatter.string(from: finalDate)

    return .active("Expire subscription on : \(formattedDate)")
}
func getTimeAgo(from timestamp: String) -> String {
    
    guard let timeInterval = Double(timestamp) else {
        return ""
    }
    
    let date = Date(timeIntervalSince1970: timeInterval)
    let now = Date()
    
    let seconds = Int(now.timeIntervalSince(date))
    
    if seconds < 60 {
        return "Just now"
    }
    
    let minutes = seconds / 60
    if minutes < 60 {
        return "\(minutes) min ago"
    }
    
    let hours = minutes / 60
    if hours < 24 {
        return "\(hours) hour\(hours > 1 ? "s" : "") ago"
    }
    
    let days = hours / 24
    if days == 1 {
        return "Yesterday"
    }
    
    if days < 7 {
        return "\(days) days ago"
    }
    
    // Show Date (dd MMM yyyy)
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "dd MMM yyyy"
    
    return formatter.string(from: date)
}
func checkVIPAccess(from vc: UIViewController, onSuccess: @escaping () -> Void) {
    
    if appDelegate.isPurchaseVIP {
        onSuccess()
    } else {
        vc.popupAlert(
            title: "Subscription Expired",
            message: "Your subscription has expired. Please renew from setting to continue using the app.",
            actionTitles: ["OK"],
            actions: [{ _ in }, nil]
        )
    }
}
func formatToDisplay(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "E dd MMM h:mm a"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current // 🔥 auto (India / USA / etc.)
    return formatter.string(from: date)
}

func formatToDisplay(dateString: String) -> String {
    
    let cleanString = dateString.replacingOccurrences(of: "Z", with: "")
       
       let inputFormatter = DateFormatter()
       inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
       inputFormatter.locale = Locale(identifier: "en_US_POSIX")
       inputFormatter.timeZone = TimeZone.current
       
       guard let date = inputFormatter.date(from: cleanString) else {
           return ""
       }
       
       let outputFormatter = DateFormatter()
       outputFormatter.dateFormat = "E dd MMM h:mm a"
       outputFormatter.locale = Locale(identifier: "en_US_POSIX")
       
       return outputFormatter.string(from: date)
}
