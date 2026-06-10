import UserNotifications
import FamilyControls
import ManagedSettings
import os

// Define AppCommand locally for the Extension to avoid Target Membership issues
struct AppCommand: Codable {
    enum Action: String, Codable {
        case block = "Block"
        case unblock = "Unblock"
    }

    let token: String // Base64 encoded ApplicationToken
    let action: Action
    let appName: String?
    let type: String? // "app" or "category", defaults to "app"
}

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    // Direct store access
    let store = ManagedSettingsStore()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "org.app.GaurdianDrive.NotificationService", category: "NotificationService")

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        let userInfo = request.content.userInfo
        logger.info("Function: didReceive. Payload: \(userInfo)")
        
        if let bestAttemptContent = bestAttemptContent {
            
            // Parse nested "data" payload
            var nestedData: [String: Any]? = nil
            if let dataString = userInfo["data"] as? String,
               let dataBytes = dataString.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: dataBytes) as? [String: Any] {
                nestedData = parsed
            } else if let dataDirect = userInfo["data"] as? [String: Any] {
                nestedData = dataDirect
            }
            
            let commandsJSON = (nestedData?["blockingCommands"] as? String) ?? (userInfo["blockingCommands"] as? String)
            let tokenString = (nestedData?["blockingToken"] as? String) ?? (userInfo["blockingToken"] as? String)

            if let commandsJSON = commandsJSON,
               let cmdData = commandsJSON.data(using: .utf8) {
                do {
                    let commands = try JSONDecoder().decode([AppCommand].self, from: cmdData)
                    logger.info("Decoded \(commands.count) commands.")

                    var currentApps = store.shield.applications ?? []
                    var actionsLog = ""

                    for command in commands {
                        guard let tokenData = Data(base64Encoded: command.token) else {
                            logger.error("Invalid token for \(command.appName ?? "?")")
                            continue
                        }

                        // We now treat everything as an application token per standardization
                        guard let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData) else {
                            logger.error("Invalid app token for \(command.appName ?? "?")")
                            continue
                        }
                        
                        switch command.action {
                        case .block:
                            currentApps.insert(token)
                            logger.info("ACTION: BLOCK \(command.appName ?? "?")")
                        case .unblock:
                            currentApps.remove(token)
                            logger.info("ACTION: UNBLOCK \(command.appName ?? "?")")
                        }

                        if let name = command.appName {
                            if !actionsLog.isEmpty { actionsLog += ", " }
                            actionsLog += "\(command.action.rawValue) \(name)"
                        }
                    }

                    store.shield.applications = currentApps
                    // Categories are cleared/hidden
                    store.shield.applicationCategories = .specific([])
                    logger.info("Updated store. Apps: \(currentApps.count)")

                    bestAttemptContent.title = "Restrictions Updated"
                    bestAttemptContent.body = actionsLog.isEmpty ? "Processed \(commands.count) commands" : actionsLog

                } catch {
                    logger.error("Failed to decode command list: \(error)")
                    bestAttemptContent.title = "Command Error"
                    bestAttemptContent.body = "Invalid command format."
                }
            }
            else if let tokenString = tokenString {
                if tokenString == "UNBLOCK" {
                    logger.info("Received GLOBAL UNBLOCK.")
                    store.clearAllSettings()
                    bestAttemptContent.title = "App Unblocked"
                    bestAttemptContent.body = "All restrictions released."
                } else if let data = Data(base64Encoded: tokenString) {
                    if let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                        store.shield.applications = selection.applicationTokens
                        store.shield.applicationCategories = .specific([])
                        store.shield.webDomains = selection.webDomainTokens
                        bestAttemptContent.title = "Blocking Active"
                        bestAttemptContent.body = "Restricted \(selection.applicationTokens.count) apps."
                    } else if let singleToken = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                        store.shield.applications = [singleToken]
                        bestAttemptContent.title = "Blocking Active"
                        bestAttemptContent.body = "Restricted 1 app."
                    }
                }
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            bestAttemptContent.title = "\(bestAttemptContent.title) [Timeout]"
            contentHandler(bestAttemptContent)
        }
    }
}
