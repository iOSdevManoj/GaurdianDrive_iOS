import Foundation
import UIKit
import ManagedSettings
struct ChildRequestedApp: Codable {
    var id: Int? = nil
    var appName: String? = nil
    var name: String? = nil
    var status: String? = nil
    var date: String? = nil
    var createdAt: String? = nil
    var token: String? = nil
    var _id: String? = nil
    var deviceType: String? = nil
    var icon: String? = nil
    var iconBase64: String? = nil
    var userName: String? = nil
    var username: String? = nil
    /// Blocked flag — server may send as Int (1/0) or String ("1"/"0").
    /// Always stored as String so existing callers don't need to change.
    var a: String? = nil
    var b: String? = nil
    var c: String? = nil
    var permissionType: String? = nil
    var currentStatus: String? = nil
    var currentStatusTime: String? = nil  // e.g. "2026-03-05T21:00:40.918717Z"

    // No-Drive Mode specific fields
    var type: String? = nil
    var requestedTime: String? = nil
    var startTime: String? = nil
    var endTime: String? = nil
    var reason: String? = nil

    // MARK: - Convenience init (used when constructing from local AppBlockStatus)
    init(appName: String? = nil, token: String? = nil) {
        self.appName = appName
        self.token = token
    }

    // MARK: - Custom decoding to handle "a" as Int or String
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id              = try container.decodeIfPresent(Int.self,    forKey: .id)
        appName         = try container.decodeIfPresent(String.self, forKey: .appName)
        name            = try container.decodeIfPresent(String.self, forKey: .name)
        status          = try container.decodeIfPresent(String.self, forKey: .status)
        date            = try container.decodeIfPresent(String.self, forKey: .date)
        createdAt       = try container.decodeIfPresent(String.self, forKey: .createdAt)
        token           = try container.decodeIfPresent(String.self, forKey: .token)
        _id             = try container.decodeIfPresent(String.self, forKey: ._id)
        deviceType      = try container.decodeIfPresent(String.self, forKey: .deviceType)
        icon            = try container.decodeIfPresent(String.self, forKey: .icon)
        b               = try container.decodeIfPresent(String.self, forKey: .b)
        c               = try container.decodeIfPresent(String.self, forKey: .c)
        permissionType  = try container.decodeIfPresent(String.self, forKey: .permissionType)
        currentStatus   = try container.decodeIfPresent(String.self, forKey: .currentStatus)
        currentStatusTime = try container.decodeIfPresent(String.self, forKey: .currentStatusTime)
        type            = try container.decodeIfPresent(String.self, forKey: .type)
        requestedTime   = try container.decodeIfPresent(String.self, forKey: .requestedTime)
        startTime       = try container.decodeIfPresent(String.self, forKey: .startTime)
        endTime         = try container.decodeIfPresent(String.self, forKey: .endTime)
        reason          = try container.decodeIfPresent(String.self, forKey: .reason)
        userName        = try container.decodeIfPresent(String.self, forKey: .userName)
        username        = try container.decodeIfPresent(String.self, forKey: .username)

        // "a" can arrive as Int (1/0) or String ("1"/"0") depending on the endpoint.
        let aAsInt = try? container.decode(Int.self, forKey: .a)
        if let v = aAsInt {
            a = String(v)
        } else {
            a = try? container.decode(String.self, forKey: .a)
        }
    }

    // Computed properties for safe defaults
    var displayAppName: String {
        let rawName = name ?? ""
        let rawAppName = appName ?? ""
        let rawUserName = userName ?? username ?? ""
        
        let nameResolved = AppNameResolution.isResolved(rawName)
        let appNameResolved = AppNameResolution.isResolved(rawAppName)
        let userNameResolved = AppNameResolution.isResolved(rawUserName)
        
        // Determine the best resolved name to use.
        // Priority: userName (user-provided) > name > appName > cache
        // This ensures child-submitted custom names always win over system-resolved names.
        var chosenName = ""
        if userNameResolved {
            // User explicitly provided this name — always prefer it
            chosenName = rawUserName
        } else if nameResolved {
            chosenName = rawName
        } else if appNameResolved {
            chosenName = rawAppName
        } else if let cached = AppNameResolutionCache.cachedName(forTokenStr: displayToken) {
            chosenName = cached
        } else {
            return "Unknown App"
        }
        
        // If the chosen name is a bundle ID (contains '.'), try to fallback to a clean name,
        // or clean the bundle ID.
        if chosenName.contains(".") {
            if userNameResolved && !rawUserName.contains(".") {
                return rawUserName
            }
            if appNameResolved && !rawAppName.contains(".") {
                return rawAppName
            }
            if nameResolved && !rawName.contains(".") {
                return rawName
            }
            return AppNameResolution.cleanBundleId(chosenName)
        }
        
        return chosenName
    }
    
    var displayToken: String {
        return token ?? _id ?? (id != nil ? String(id!) : "")
    }
    
    var displayStatus: String {
        return currentStatus ?? status ?? "SYNCED"
    }
    
    /// Date + Time for App Request cells — e.g. "Mar 5, 2026  9:00 PM"
    var displayDate: String {
        let rawString = currentStatusTime ?? createdAt ?? date ?? requestedTime
        if let raw = rawString, let formatted = parseAndFormat(raw) {
            return formatted
        }
        return rawString ?? "--"
    }
    
    /// Date + Time for No-Drive Request cells — e.g. "Mar 5, 2026  11:00 PM"
    var formattedTime: String {
        let rawString = startTime ?? requestedTime ?? currentStatusTime
        if let raw = rawString, let formatted = parseAndFormat(raw) {
            return formatted
        }
        return rawString ?? displayDate
    }
    
    var durationString: String {
        guard let startStr = startTime, let endStr = endTime else { return "Request" }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var startDate = isoFormatter.date(from: startStr)
        var endDate = isoFormatter.date(from: endStr)
        
        if startDate == nil {
            let backupFormatter = ISO8601DateFormatter()
            startDate = backupFormatter.date(from: startStr)
            endDate = backupFormatter.date(from: endStr)
        }
        
        guard let sDate = startDate, let eDate = endDate else { return "Request" }
        
        let diff = Int(eDate.timeIntervalSince(sDate) / 60)
        if diff >= 60 {
            let hours = diff / 60
            let mins = diff % 60
            if mins > 0 { return "\(hours) hr \(mins) Min" }
            return "\(hours) hr"
        }
        return "\(diff) Min"
    }

    func getApplicationToken() -> ApplicationToken? {
        guard let tokenStr = token, let tokenData = Data(base64Encoded: tokenStr) else { return nil }
        return try? JSONDecoder().decode(ApplicationToken.self, from: tokenData)
    }

    func getCategoryToken() -> ActivityCategoryToken? {
        guard let tokenStr = token, let tokenData = Data(base64Encoded: tokenStr) else { return nil }
        return try? JSONDecoder().decode(ActivityCategoryToken.self, from: tokenData)
    }
    
    // MARK: - Private helpers
    
    /// Decodes the Base64 icon string into a UIImage, if present.
    func decodeIcon() -> UIImage? {
        guard let base64 = iconBase64, let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
    
    /// Parses an ISO 8601 string and returns "MMM d, yyyy  h:mm a" (date + time).
    private func parseAndFormat(_ isoString: String) -> String? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var parsedDate = isoFormatter.date(from: isoString)
        
        if parsedDate == nil {
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            parsedDate = fallback.date(from: isoString)
        }
        
        guard let finalDate = parsedDate else { return nil }
        
        let out = DateFormatter()
        out.dateFormat = "MMM d, yyyy  h:mm a"
        return out.string(from: finalDate)
    }
    
    var sortDate: Date? {
        let rawString = currentStatusTime ?? createdAt ?? startTime ?? requestedTime ?? date
        guard let raw = rawString else { return nil }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: raw) {
            return date
        }
        
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: raw)
    }
}

