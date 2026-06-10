//
//  AppDelegate.swift
//  GaurdianDrive
//
//  Created by KETAN on 11/12/25.
//

import Firebase
import FirebaseCore
import FamilyControls
import GoogleMaps
import GooglePlaces
import GoogleSignIn
import IQKeyboardManagerSwift
import SVProgressHUD
import SwiftData
import UIKit

let appDelegate = UIApplication.shared.delegate as! AppDelegate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var isFromParent = false
    var subscriptionExpireDate = ""
    var isPurchaseVIP = true
    var isAddNewChild = false

    /// Stored by application(_:handleEventsForBackgroundURLSession:completionHandler:) and
    /// called from LocationPermissionManager.urlSessionDidFinishEvents to tell the OS we're done.
    static var backgroundSessionCompletionHandler: (() -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.

        UIApplication.shared.applicationIconBadgeNumber = 0

        window?.overrideUserInterfaceStyle = .light

        GMSServices.provideAPIKey(GoogleKey)
        GMSPlacesClient.provideAPIKey(GoogleKey)

        //GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
        FirebaseApp.configure()  //Firebase configure....

        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }

        //Setup keyboard settings.
        self.setIQKeyboardSettings()

        // Set notification delegate — permission is requested by PermissionsManager
        // once the user is logged in, so we don't prompt on every cold launch.
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

        //      self.enableLocation()
        Messaging.messaging().delegate = self

        self.checkLogin()

        // Handle background relaunch triggered by significant location changes.
        // When iOS kills the app and then relaunches it due to location events,
        // launchOptions contains the .location key. We start location updates
        // immediately so the speed pipeline re-evaluates and re-applies shields.
        if launchOptions?[.location] != nil {
            print("[AppDelegate] Relaunched by iOS location event — restoring speed monitoring")
            LocationPermissionManager.shared.startUpdating()
        }

        return true
    }

    //MARK: - Set IQKeyboard Settings...
    func setIQKeyboardSettings() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        IQKeyboardManager.shared.previousNextDisplayMode = .alwaysShow
        IQKeyboardManager.shared.toolbarTintColor = UIColor.white
        IQKeyboardManager.shared.toolbarBarTintColor = UIColor.init(named: "AppDarkBlue")
        IQKeyboardManager.shared.placeholderColor = UIColor.white
        IQKeyboardManager.shared.placeholderFont = UIFont.init(name:FontName.PlusJakartaSansRegular, size: 15)
    }

    //MARK: - ShowHud...
    func showHud(isWhiteBG:Bool = false) {
        SVProgressHUD.setDefaultStyle(.custom)
        if isWhiteBG
        {
            SVProgressHUD.setBackgroundColor(.white)
            SVProgressHUD.setBackgroundLayerColor(UIColor.black.withAlphaComponent(0.2))
        }else {
            SVProgressHUD.setBackgroundColor(.clear)
            SVProgressHUD.setBackgroundLayerColor(UIColor.clear)
        }
        SVProgressHUD.setForegroundColor(UIColor.init(named: "AppDarkBlue")!)
        SVProgressHUD.setRingNoTextRadius(25.0)
        SVProgressHUD.show()
        self.window?.rootViewController!.view.isUserInteractionEnabled = false
    }

    //MARK: - HideHud..
    func hideHud() {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            self.window?.rootViewController!.view.isUserInteractionEnabled = true
        }
    }

    //MARK: - Set root controller..
    func setRootController() {
        if UserDefaults.Main.bool(forKey: .isParent) {
            let rootTab = storyBoards.Tabbar.instantiateInitialViewController()
            window?.rootViewController = rootTab  //UINavigationController(rootViewController: rootTab)
        } else {
            let nextVC =
                storyBoards.Child.instantiateViewController(withIdentifier: "ChildHomeVC")
                as? ChildHomeVC
            window?.rootViewController = UINavigationController(rootViewController: nextVC!)
        }
        window?.rootViewController?.navigationController?.setNavigationBarHidden(
            true, animated: false)
        window?.makeKeyAndVisible()
    }

    //MARK: - check login session..
    func checkLogin() {
        if UserDefaults.Main.bool(forKey: .autoLogin) {
            let userLoginData = UserModel.unarchiveUserProfileData()
            let userToken = UserDefaults.Main.string(forKey: .userToken)
            AppState.sharedInstance.strMyToken = userToken
            AppState.sharedInstance.user = userLoginData
            // Initialise SwiftData early so ParentControlViewModel and
            // AppBlockerManager can restore persisted selections after a kill.
            do {
                let schema = Schema([BlockingSelection.self])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [config])
                AppBlockerManager.shared.modelContainer = container
                ParentControlViewModel.shared.setModelContext(container.mainContext)
            } catch {
                print("[AppDelegate] SwiftData init failed: \(error)")
            }

            // Child: sync blocked-app rules from server on launch.
            // Parent: skipped (parent lock is fully local).
            AppBlockerManager.shared.fetchAndSyncServerApps()
            // Request Family Controls authorization if not yet approved.
            // Must be called after login so the system knows which account to authorize.
            let fcStatus = AuthorizationCenter.shared.authorizationStatus
            if fcStatus == .notDetermined {
                AppBlockerManager.shared.requestAuthorization()
            }
            LocationPermissionManager.shared.startUpdating()
            // Parent: immediately restore any manually-set block that was active
            // before the app was killed, before the first speed update arrives.
            if UserDefaults.Main.bool(forKey: .isParent) {
                AppBlockerManager.shared.restoreParentBlockIfNeeded()
                self.apiCallForMySubscription()
            }
            self.setRootController()
        } else {
            if UserDefaults.Main.bool(forKey: .isInfoDone) {
                let nextVC =
                    storyBoards.Main.instantiateViewController(withIdentifier: "ChooseRoleVC")
                    as? ChooseRoleVC
                window?.rootViewController = UINavigationController(rootViewController: nextVC!)
            } else {
                let nextVC =
                    storyBoards.Main.instantiateViewController(withIdentifier: "IntroVC")
                    as? IntroVC
                window?.rootViewController = UINavigationController(rootViewController: nextVC!)
            }
            window?.rootViewController?.navigationController?.setNavigationBarHidden(
                true, animated: false)
            window?.makeKeyAndVisible()
        }
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    //MARK: - Logout user method.
    func logoutUser() {

        // 1. Stop location tracking — no more location uploads or speed events after logout.
        LocationPermissionManager.shared.stopUpdating()
        UserDefaults.standard.removeObject(forKey: "LocationLastSentTimestamp")
        UserDefaults.standard.removeObject(forKey: "LocationChildUserId")

        // 2. Clear ScreenTime / ManagedSettings shields and stop DeviceActivity monitoring.
        //    Synchronous dispatch to MainActor so this completes before we navigate.
        AppBlockerManager.shared.stopMonitoring()
        UserDefaults.standard.removeObject(forKey: "ParentManualBlockActive")
        UserDefaults.standard.removeObject(forKey: "SpeedBlock_IsBlocking")
        UserDefaults.standard.removeObject(forKey: "SpeedBlock_SpeedLimitMph")
        UserDefaults.standard.removeObject(forKey: "ServerSyncedAppsMap")

        // 3. Clear SwiftData (BlockingSelection records) synchronously so the ParentControl
        //    picker never reloads stale app selections from disk on the next login.
        AppBlockerManager.shared.ensureModelContainer()
        if let container = AppBlockerManager.shared.modelContainer {
            let context = ModelContext(container)
            if let rows = try? context.fetch(FetchDescriptor<BlockingSelection>()) {
                rows.forEach { context.delete($0) }
                try? context.save()
            }
        }

        // 4. Clear no-drive-mode UserDefaults schedule cache.
        UserDefaults.standard.removeObject(forKey: "NoDriveApprovedSchedules")

        // 5. Clear all UserDefaults.Main session keys.
        UserDefaults.Main.set("", forKey: .userToken)
        UserDefaults.Main.set(false, forKey: .autoLogin)
        UserDefaults.Main.set(false, forKey: .isParent)
        UserDefaults.Main.removeObj(forKey: .profile)
        UserDefaults.Main.removeObj(forKey: .autoLogin)
        UserDefaults.Main.removeObj(forKey: .userToken)
        // Keep deviceToken in UserDefaults.Main so it can be re-registered after the next login.

        // 6. Reset ALL in-memory singletons — this is the key fix for selected apps
        //    reappearing after login: ParentControlViewModel is a singleton whose
        //    @Published arrays survive the session unless explicitly cleared here.
        AppState.sharedInstance.user = UserModel()
        ChildHomeViewModel.shared.clearData()
        ParentHomeViewModel.shared.clearData()
        ParentControlViewModel.shared.clearData()

        // 7. Navigate to login.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            appDelegate.checkLogin()
        }
    }

    // MARK: - Background URL Session
    /// iOS calls this when a background URLSession task finishes while the app was not running.
    /// We store the completion handler; it is called in LocationPermissionManager.urlSessionDidFinishEvents
    /// so the OS knows we've finished processing and can update its snapshot.
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        if identifier == LocationPermissionManager.backgroundSessionIdentifier {
            AppDelegate.backgroundSessionCompletionHandler = completionHandler
            // Touch the session so it reconnects and processes pending events.
            _ = LocationPermissionManager.shared.backgroundSession
        } else {
            // Not our session — call immediately to avoid watchdog timeout.
            completionHandler()
        }
    }

}

//MARK: - Extension for Firebase methoeds handle...
extension AppDelegate: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken!)")
        if fcmToken != nil {
            let dataDict: [String: String] = ["token": fcmToken!]
            NotificationCenter.default.post(
                name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
            UserDefaults.Main.set(fcmToken!, forKey: .deviceToken)
        }
    }

    private func application(
        application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData
    ) {
        Messaging.messaging().apnsToken = deviceToken as Data
    }

    //MARK: - Called when APNs failed to register the device for push notifications
    func application(
        _ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Print the error to console (you should alert the user that registration failed)
        print("APNs registration failed: \(error)")
    }
}
//MARK: - Extension for notification handle...
extension AppDelegate: UNUserNotificationCenterDelegate {

    // MARK: - Notification Handling
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Swift.Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("📲 [Notification] Received in device tray — userInfo: \(userInfo)")
        // Intercept silent SpeedAction notifications — handle them without showing any banner
        if handleSpeedActionNotification(userInfo) {
            completionHandler([])  // silent — no banner / sound
        } else {
            // Silently refresh parent data in background when a child-request notification arrives
            handleParentDataNotification(userInfo)
            handleChildDataNotification(userInfo)
            completionHandler([.list, .badge, .sound, .banner])
        }
    }

    //MARK: - Received notification in ios 10 and later Then going where user need.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Swift.Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        var notiID = createString(value: userInfo[AnyHashable("id")] as AnyObject)
        if notiID == ""
        {
            if let id = getNotificationId(from: userInfo) {
                print("ID:", id) // ✅ 57010
                notiID = "\(id)"
            }
        }
        //Api calling for view and read notification....
        self.readNotificationViews(notificationID: notiID)
        
        // Handle SpeedAction (fires when user taps notification after app was killed)
        _ = handleSpeedActionNotification(userInfo)
        print("👆 [Notification] User tapped notification — userInfo: \(userInfo)")
        // Refresh parent data so the UI is up-to-date when the parent opens the app
        handleParentDataNotification(userInfo)
        handleChildDataNotification(userInfo)
        UIApplication.shared.applicationIconBadgeNumber = 0
        completionHandler()
    }

    /// Handles silent speed-action notifications from LocationPermissionManager.
    /// Returns true if the notification was a SpeedAction (caller should suppress banner).
    @discardableResult
    private func handleSpeedActionNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard let action = userInfo["speedAction"] as? String else { return false }
        print("[AppDelegate] Speed action notification received: \(action)")
        Task { @MainActor in
            switch action {
            case "BLOCK":
                // Persist and re-evaluate shields with the current speed
                UserDefaults.standard.set(true, forKey: "SpeedBlock_IsBlocking")
                AppBlockerManager.shared.reEvaluateSpeed()
            case "UNBLOCK":
                UserDefaults.standard.set(false, forKey: "SpeedBlock_IsBlocking")
                AppBlockerManager.shared.stopMonitoring()
            default:
                break
            }
        }
        return true
    }

    /// Silently refreshes ParentHomeViewModel when a child request notification arrives.
    /// Only runs for parent users. Does NOT affect SpeedAction or any other notification type.
    private func handleParentDataNotification(_ userInfo: [AnyHashable: Any]) {
        // Only relevant for parent accounts
        guard UserDefaults.Main.bool(forKey: .isParent) else { return }

        // Extract notification type from root-level key (sent by server alongside the data payload)
        let notifType = userInfo["type"] as? String ?? ""
        let supportedTypes = ["APP_REQUEST", "NO_DRIVE_REQUEST", "NDM_REQUEST", "NDM_CANCEL", "APP_CANCEL",
                              "APP_APPROVED", "NO_DRIVE_APPROVED", "APP_REJECTED", "NO_DRIVE_REJECTED"]
        guard supportedTypes.contains(notifType) else { return }

        // Parse the nested "data" payload — FCM sends it as a JSON string
        var dataDict: [String: Any] = [:]
        if let dataString = userInfo["data"] as? String,
           let dataBytes = dataString.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: dataBytes) as? [String: Any] {
            dataDict = parsed
        } else if let dataDirect = userInfo["data"] as? [String: Any] {
            dataDict = dataDirect
        }

        // Extract childId from the nested "jsonData" string inside data
        var childId: String?
        if let jsonDataStr = dataDict["jsonData"] as? String,
           let jsonBytes = jsonDataStr.data(using: .utf8),
           let jsonDict = try? JSONSerialization.jsonObject(with: jsonBytes) as? [String: Any] {
            if let id = jsonDict["childId"] as? Int {
                childId = String(id)
            } else if let id = jsonDict["childId"] as? String {
                childId = id
            }
        }

        guard let childId = childId else {
            print("⚠️ [Notification] Could not extract childId from \(notifType) payload")
            return
        }

        print("🔄 [Notification] \(notifType) for childId \(childId) — refreshing parent data silently")

        // Silently refresh — no HUD, background fetch
        ParentHomeViewModel.shared.fetchChildData(childId: childId) { success in
            guard success else { return }
            DispatchQueue.main.async {
                // Update app-blocking shields to reflect any approved/rejected changes
                ParentControlViewModel.shared.updateMonitoring()
                // Notify HomeVC (if it's on screen) to reload its tables/collections
                NotificationCenter.default.post(
                    name: .parentHomeDataDidUpdate,
                    object: nil,
                    userInfo: ["childId": childId]
                )
                print("✅ [Notification] Parent home data refreshed for childId \(childId)")
            }
        }
    }

    /// Silently refreshes Child data when a parent response notification arrives.
    /// Only runs for child users.
    private func handleChildDataNotification(_ userInfo: [AnyHashable: Any]) {
        // Only relevant for child accounts
        guard !UserDefaults.Main.bool(forKey: .isParent) else { return }

        // Extract notification type
        let notifType = userInfo["type"] as? String ?? ""
        let supportedTypes = [
            "APP_APPROVE", "APP_APPROVED",
            "NO_DRIVE_APPROVE", "NO_DRIVE_APPROVED",
            "APP_REJECT", "APP_REJECTED",
            "NO_DRIVE_REJECT", "NO_DRIVE_REJECTED",
            "APP_CANCEL_BY_PARENT",
            "NDM_CANCEL_BY_PARENT",
            "NDM_REJECT",
            "NDM_APPROVE"
        ]
        guard supportedTypes.contains(notifType) else { return }

        print("🔄 [Notification] \(notifType) — refreshing child data silently")

        // 1. Refresh regular requests
        ChildHomeViewModel.shared.fetchRequestedApps { _ in
            DispatchQueue.main.async {
                AppBlockerManager.shared.reEvaluateSpeed() // Updates actual system shields
                NotificationCenter.default.post(name: .childHomeDataDidUpdate, object: nil)
            }
        }
        
        // 2. Refresh no-drive mode requests
        ChildHomeViewModel.shared.fetchRequestedNoDriveModeSchedule { _, _ in
            DispatchQueue.main.async {
                AppBlockerManager.shared.reEvaluateSpeed() // Updates actual system shields
                NotificationCenter.default.post(name: .childHomeDataDidUpdate, object: nil)
            }
        }
        
        // 3. Refresh approved no-drive schedules (to update blocking state if needed)
        ChildHomeViewModel.shared.fetchApprovedNoDriveModeRequests { _ in
            DispatchQueue.main.async {
                AppBlockerManager.shared.reEvaluateSpeed() // Updates actual system shields
                NotificationCenter.default.post(name: .childHomeDataDidUpdate, object: nil)
            }
        }
    }
}

extension AppDelegate{
    
    func getPasscodeApprovedApi(
        url: String,
        params: [String: Any],
        completion: @escaping (_ isSuccess: Bool, _ response: [String: Any], _ statusCode: Int) -> Void
    ) {

        self.showHud()

        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: url, param: params) { (isSuccess, responseDict, statusCode) in

            DispatchQueue.main.async {
                self.hideHud()
                completion(isSuccess, responseDict, statusCode)
            }
        }
    }
    
    //MARK: - Get my subscription...
    func apiCallForMySubscription() {

        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: WebURL.getMySubscription, aParams: [String: Any]()) {
            (isSuccess, responseDict) in

            if isSuccess {
                print(responseDict)

                let strStatus = getStringFromDictionary(
                    dictionary: responseDict, key: "status")
                //NOT_FOUND, EXPIRED, VALID
                
                if strStatus == "NOT_FOUND"
                {
                    appDelegate.subscriptionExpireDate = "Free Trial Expired"
                    self.apiCallForFreeAppDays()
                }else {
                    let dictSubscriptionData = getDictionaryFromDictionary(dictionary: responseDict, key: "subscription")
                    let dict = dictSubscriptionData as NSDictionary
                    
                    // ✅ Map to model
                    let userSubscriptionData = UserSubscriptionResponseModel.init(dict: dict)
                    userSubscriptionData.Origionalstatus = strStatus
                    let status = getSubscriptionStatus(userSubscriptionData.expiresDateLocal)

                    switch status {

                    case .expired:
                        
                        appDelegate.subscriptionExpireDate = "Subscription Expired"
                        appDelegate.isPurchaseVIP = false //Change true here..
                        self.window?.rootViewController!.popupAlert(
                            title: "Subscription Expired",
                            message: "Your subscription has expired. Please renew to continue using the app.",
                            actionTitles: ["OK"],
                            actions: [{ _ in
                            }, nil]
                        )
                        NotificationCenter.default.post(name: .getSubscriptionStatus, object: nil)

                    case .active(let message):
                        appDelegate.subscriptionExpireDate = message
                        appDelegate.isPurchaseVIP = true
                        print("✅ Active:", message)
                        NotificationCenter.default.post(name: .getSubscriptionStatus, object: nil)
                    }
                }
            }
            self.saveDeviceTokenForRegisterUser()
        }
    }
    
    func saveDeviceTokenForRegisterUser() {
        
        let fcmToken = UserDefaults.Main.string(forKey: .deviceToken)
        
        let param = ["deviceToken":fcmToken, "deviceType":"IOS"] as [String : Any]
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: WebURL.registerDeviceToken, param: param) { (isSuccess, responseDict, statusCode) in
            if isSuccess {
                print("Device token saved")
            }
        }
    }
    
    //MARK: - Get Free App Days
    func apiCallForFreeAppDays() {

        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: WebURL.freePendingDays, aParams: [String: Any]()) {
            (isSuccess, responseDict) in

            if isSuccess {
                print(responseDict)
                //["days": 0]
                let leftDays = getIntFromDictionary(dictionary: responseDict, key: "days")
                appDelegate.subscriptionExpireDate = "Free trial \(leftDays) days left"
                NotificationCenter.default.post(name: .getSubscriptionStatus, object: nil)

                if leftDays <= 3 {
                    let title: String
                    let message: String

                    if leftDays > 1 {
                        appDelegate.isPurchaseVIP = true
                        title = "Free Trial Ending Soon"
                        message = "Your free trial will expire in \(leftDays) days. Please purchase to continue using all features."
                    } else if leftDays == 1 {
                        appDelegate.isPurchaseVIP = true
                        title = "Last Day of Free Trial"
                        message = "Your free trial expires tomorrow. Purchase now to avoid interruption."
                    } else {
                        appDelegate.isPurchaseVIP = false //Change true here..
                        title = "Free Trial Expired"
                        message = "Your free trial has expired. Please purchase from setting to continue tracking and adding users."
//                        self.window?.rootViewController?.popupAlert(title: "Free Trial Expired", message:"Your free trial has expired. Please purchase to continue tracking and adding users.", actionTitles: ["OK","Upgrade Now"], actions:[{action1 in
//                            
//                        },{action2 in
//                            
//                        },nil])
                    }

                    self.window?.rootViewController?.popupAlert(
                        title: title,
                        message: message,
                        actionTitles: ["OK"],
                        actions: [{ _ in
                            // Navigate to purchase if needed
                        }, nil]
                    )
                }
            }
        }
    }
    
    func readNotificationViews(notificationID:String) {
        
        let mainUrl = WebURL.readNotification + "\(notificationID)/read"
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: mainUrl, param: [String:Any]()) { (isSuccess, responseDict, statusCode) in
            if isSuccess {
                print("read notification...")
            }
        }
    }
}
func getNotificationId(from userInfo: [AnyHashable: Any]) -> Int? {

    // CASE 1: data is already a dictionary
    if let dataDict = userInfo["data"] as? [String: Any],
       let id = dataDict["id"] as? Int {
        return id
    }

    // CASE 2: data is a JSON string
    if let dataString = userInfo["data"] as? String,
       let jsonData = dataString.data(using: .utf8) {

        do {
            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let id = jsonDict["id"] as? Int {
                return id
            }
        } catch {
            print("JSON Error:", error)
        }
    }

    return nil
}
