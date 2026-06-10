import Foundation
import FamilyControls

struct AppCommand: Codable {
    enum Action: String, Codable {
        case block = "Block"
        case unblock = "Unblock"
    }

    let token: String // Base64 encoded ApplicationToken or ActivityCategoryToken
    let action: Action
    let appName: String?
    let type: String? // "app" or "category", defaults to "app"
}
