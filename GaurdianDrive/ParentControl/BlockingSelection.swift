import FamilyControls
import Foundation
import ManagedSettings
import SwiftData

@Model
final class BlockingSelection {
    var selection: FamilyActivitySelection
    var appStatuses: [AppBlockStatus] = []
    var categoryStatuses: [CategoryBlockStatus] = [] // Kept as empty to avoid migration issues if already stored

    init(
        selection: FamilyActivitySelection = FamilyActivitySelection(includeEntireCategory: true),
        appStatuses: [AppBlockStatus] = [],
        categoryStatuses: [CategoryBlockStatus] = []
    ) {
        self.selection = selection
        self.appStatuses = appStatuses
        self.categoryStatuses = categoryStatuses
    }
}

struct AppBlockStatus: Codable, Hashable {
    let token: ApplicationToken
    var isBlocked: Bool
    var appName: String?
    var status: String? // e.g. "APPROVED", "REQUESTED", "REJECTED"
}

struct CategoryBlockStatus: Codable, Hashable {
    let token: ActivityCategoryToken
    var isBlocked: Bool
}
