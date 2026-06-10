import Foundation
import UserNotifications
import FirebaseMessaging
import FamilyControls
import os

@MainActor
class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "org.app.GaurdianDrive", category: "PushNotificationManager")
    
    override private init() {
        super.init()
    }
    
    func requestAuthorization() async throws {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
    }
    
    func handleIncomingNotification(userInfo: [AnyHashable: Any]) {
        logger.info("Handling notification payload")
        
        // Delegate the blocking logic to AppBlockerManager
        AppBlockerManager.shared.handlePushNotification(userInfo: userInfo)
    }
}

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10+ devices.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "org.app.GaurdianDrive", category: "PushNotificationManager")
        logger.info("Will Present Notification: \(userInfo)")
        
        // Trigger logic even if in foreground via MainActor
        Task { @MainActor in
            self.handleIncomingNotification(userInfo: userInfo)
        }

        // Change this to your preferred presentation option
        completionHandler([[.banner, .badge, .sound]])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "org.app.GaurdianDrive", category: "PushNotificationManager")
        logger.info("Did Receive Response: \(userInfo)")
        
        Task { @MainActor in
            self.handleIncomingNotification(userInfo: userInfo)
        }

        completionHandler()
    }
}

extension PushNotificationManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "org.app.GaurdianDrive", category: "PushNotificationManager")
        logger.info("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        // NotificationCenter posting is thread-safe, but if observers expect main thread, 
        // it's safer to just post, but let's stick to standard practice. 
        // NotificationCenter.default.post is thread-safe.
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}
