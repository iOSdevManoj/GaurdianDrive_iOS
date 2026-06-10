import FamilyControls
import Foundation
import ManagedSettings
import SwiftUI
import UIKit

class ChildHomeViewModel: NSObject {

    static let shared = ChildHomeViewModel()

    var requestedApps: [ChildRequestedApp] = []
    var isAppsDataLoaded: Bool = false
    var noDriveModeScheduleList: [ChildRequestedApp] = []
    var noDriveModeApprovedList: [ChildRequestedApp] = []
    var noDriveModeRejectedList: [ChildRequestedApp] = []
    /// True once `fetchApprovedNoDriveModeRequests` has succeeded at least once this launch.
    /// Prevents stale UserDefaults from blocking the speed-shield logic.
    var didFetchApprovedSchedules: Bool = false

    var normalRequestedApps: [ChildRequestedApp] {
        return requestedApps.filter {
            let status = ($0.currentStatus ?? $0.status ?? "").uppercased()
            let isStillBlocked = ($0.a ?? "0") == "1"
            let name = $0.displayAppName
            let isUnknown = (name == "Unknown App" || name == "Unknown" || name == "Removed App")
            
            return $0.permissionType != "NONE_DRIVE_MODE"
                && isStillBlocked
                && (status == "REQUESTED" || status == "REJECTED")
        }.sorted { ($0.sortDate ?? .distantPast) > ($1.sortDate ?? .distantPast) }
    }

    var noDriveRequestedApps: [ChildRequestedApp] {
        let apps = requestedApps.filter {
            let status = ($0.currentStatus ?? $0.status ?? "").uppercased()
            return $0.permissionType == "NONE_DRIVE_MODE"
            && (status == "REQUESTED" || status == "APPROVED" || status == "REJECTED")
        }

        let requestedList = noDriveModeScheduleList
            + noDriveModeApprovedList
            + noDriveModeRejectedList
            + apps

        return requestedList.sorted {
            ($0.sortDate ?? .distantPast) > ($1.sortDate ?? .distantPast)
        }
    }

    var approvedApps: [ChildRequestedApp] {
        return requestedApps.filter {
            let status = ($0.currentStatus ?? $0.status ?? "").uppercased()
            let isStillBlocked = ($0.a ?? "0") == "1"
            let name = $0.displayAppName
            let isUnknown = (name == "Unknown App" || name == "Unknown" || name == "Removed App")
            
            // Only show if parent still has this app blocked AND it is approved
            return $0.permissionType != "NONE_DRIVE_MODE"
                && isStillBlocked
                && status == "APPROVED"
        }.sorted { ($0.sortDate ?? .distantPast) > ($1.sortDate ?? .distantPast) }
    }

    /// Returns `true` when an approved no-drive schedule covers the current moment.
    /// Checks the in-memory list first (populated after each API fetch); falls back
    /// to UserDefaults only when the API hasn't been called yet this session.
    var hasActiveNoDriveApproval: Bool {
        let now = Date()
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoShort = ISO8601DateFormatter()

        let inMemoryActive = noDriveModeApprovedList.contains { entry in
            let status = (entry.currentStatus ?? entry.status ?? "").uppercased()
            guard status == "APPROVED" else { return false }
            let start = isoFull.date(from: entry.startTime ?? "") ?? isoShort.date(from: entry.startTime ?? "")
            let end   = isoFull.date(from: entry.endTime   ?? "") ?? isoShort.date(from: entry.endTime   ?? "")
            guard let s = start, let e = end else { return false }
            return now >= s && now <= e
        }
        if inMemoryActive { return true }

        // Fallback to UserDefaults only before the first successful API fetch.
        if !didFetchApprovedSchedules {
            return ChildHomeViewModel.hasActiveApprovedNoDriveSchedule()
        }
        return false
    }

    func fetchRequestedApps(completion: @escaping (Bool) -> Void) {
        guard let user = AppState.sharedInstance.user else {
            completion(false)
            return
        }

        let userId = user.userId
        let strUrl = WebURL.childAccountApi + "\(userId)/apps"
        print("🔄 [FetchApps] Fetching apps from: \(strUrl)")
        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: strUrl, aParams: [:]) {
            [weak self] (isSuccess, responseDict) in
            guard let self = self else { return }
            if isSuccess {
                print("✅ [FetchApps] Successfully fetched apps")
                if let appsDataArray = responseDict["apps"] as? [[String: Any]] {
                    print("✅ [FetchApps] Found \(appsDataArray.count) apps")
                    // Log each app's name for debugging
                    for (index, app) in appsDataArray.enumerated() {
                        let name = app["name"] as? String ?? "nil"
                        let token = app["token"] as? String ?? "nil"
                        let status = app["currentStatus"] as? String ?? app["status"] as? String ?? "nil"
                        print("✅ [FetchApps] App \(index): name='\(name)', status='\(status)', token='\(token.prefix(12))...'")
                    }
                    do {
                        let jsonData = try JSONSerialization.data(
                            withJSONObject: appsDataArray, options: [])
                        let decoder = JSONDecoder()
                        let fetched = try decoder.decode([ChildRequestedApp].self, from: jsonData)

                        // FIX: Only preserve local REQUESTED items that are not yet on the server
                        // AND whose parent-side block flag is still a=1. Apps the parent has removed
                        // (a=0 on parent's endpoint, or absent from server) must not be re-injected
                        // back into the list, otherwise "Remove All" appears to have no effect on
                        // the child's UI.
                        let serverIds = Set(fetched.compactMap { $0.id })
                        let localPending = self.requestedApps.filter { app in
                            let status = (app.currentStatus ?? app.status ?? "").uppercased()
                            // Only keep locally-pending items that are still blocked (a=1)
                            let isStillBlocked = (app.a ?? "0") == "1"
                            return status == "REQUESTED" && isStillBlocked && !serverIds.contains(app.id ?? -1)
                        }
                        self.requestedApps = fetched + localPending
                        self.isAppsDataLoaded = true   // ← mark cache as valid

                        // Cache any real names the server returned so the child's
                        // "Select App" dropdown shows them instantly without Label(token) resolution.
                        for app in fetched {
                            guard let tokenStr = app.token, !tokenStr.isEmpty else { continue }
                            let serverName = app.name ?? app.appName ?? ""
                            guard AppNameResolution.isResolved(serverName) else { continue }
                            // Store under both the raw server key and the canonical re-encoded key
                            AppNameResolutionCache.store(name: serverName, forTokenStr: tokenStr)
                            if let tokenData = Data(base64Encoded: tokenStr),
                               let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData),
                               let canonicalData = try? JSONEncoder().encode(token) {
                                AppNameResolutionCache.store(name: serverName, forTokenStr: canonicalData.base64EncodedString())
                            }
                        }

                        completion(true)
                    } catch {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }

    /// Fetches the child's own requested no-drive mode schedule list.
    func fetchRequestedNoDriveModeSchedule(
        completion: @escaping (Bool, [ChildRequestedApp]) -> Void
    ) {
        let strUrl = WebURL.getRequestedNoDriveModeSchedule

        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: strUrl, aParams: [:]) {
            [weak self] (isSuccess, responseDict) in
            guard let self = self else { return }

            if isSuccess,
                let rawArray = responseDict["childRequests"] as? [[String: Any]]
            {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: rawArray)
                    self.noDriveModeScheduleList = try JSONDecoder().decode(
                        [ChildRequestedApp].self, from: jsonData)
                    completion(true, self.noDriveModeScheduleList)
                } catch {
                    completion(false, [])
                }
            } else {
                completion(false, [])
            }
        }
    }

    /// Cancel a regular app permission request.
    /// POST /child/{userId}/app/{requestId}/cancel
    func cancelAppRequest(requestId: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = AppState.sharedInstance.user?.userId else {
            completion(false)
            return
        }
        let strUrl = WebURL.childAccountApi + "\(userId)/app/\(requestId)/cancel"

        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: strUrl, param: [:]) {
            (isSuccess, responseDict, statusCode) in
            completion(isSuccess)
        }
    }

    /// Cancel a no-drive mode schedule request.
    /// POST /child/{userId}/none-drive-mode/{requestId}/cancel
    func cancelNoDriveModeRequest(requestId: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = AppState.sharedInstance.user?.userId else {
            completion(false)
            return
        }
        let strUrl = WebURL.childAccountApi + "\(userId)/none-drive-mode/\(requestId)/cancel"

        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: strUrl, param: [:]) {
            (isSuccess, responseDict, statusCode) in
            completion(isSuccess)
        }
    }

    // MARK: - UserDefaults helpers for approved no-drive schedules

    private static let udKey = "NoDriveApprovedSchedules"  // [[String: String]] stored as Data

    /// Persists only non-expired approved schedules to UserDefaults.
    /// Calling this again always overrides stale data and drops expired windows.
    static func saveApprovedNoDriveSchedules(_ list: [ChildRequestedApp]) {
        let now = Date()
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoShort = ISO8601DateFormatter()

        // Keep only entries that are still in the future (end > now) AND are APPROVED
        let valid: [[String: String]] = list.compactMap { entry in
            let status = (entry.currentStatus ?? entry.status ?? "").uppercased()
            guard status == "APPROVED",
                let startStr = entry.startTime,
                let endStr = entry.endTime
            else { return nil }
            // Parse endTime — skip if already expired
            let endDate = isoFull.date(from: endStr) ?? isoShort.date(from: endStr)
            guard let e = endDate, e > now else { return nil }
            return ["startTime": startStr, "endTime": endStr]
        }

        if let data = try? JSONSerialization.data(withJSONObject: valid) {
            UserDefaults.standard.set(data, forKey: udKey)
        }
    }

    /// Returns true if any persisted approved schedule covers the current moment.
    static func hasActiveApprovedNoDriveSchedule() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: udKey),
            let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
        else {
            return false
        }
        let now = Date()
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoShort = ISO8601DateFormatter()

        let active = raw.filter { entry in
            guard let startStr = entry["startTime"], let endStr = entry["endTime"] else {
                return false
            }
            let start = isoFull.date(from: startStr) ?? isoShort.date(from: startStr)
            let end = isoFull.date(from: endStr) ?? isoShort.date(from: endStr)
            guard let s = start, let e = end else { return false }
            return now >= s && now <= e
        }

        // Prune expired entries while we're here (lazy clean-up)
        let stillValid = raw.filter { entry in
            guard let endStr = entry["endTime"] else { return false }
            let end = isoFull.date(from: endStr) ?? isoShort.date(from: endStr)
            return (end ?? .distantPast) > now
        }
        if stillValid.count != raw.count,
            let pruned = try? JSONSerialization.data(withJSONObject: stillValid)
        {
            UserDefaults.standard.set(pruned, forKey: udKey)
        }

        return !active.isEmpty
    }

    /// Fetches the child's approved no-drive mode schedule list (from Parent-configured apps/all endpoint).
    func fetchApprovedNoDriveModeRequests(
        completion: @escaping (Bool) -> Void
    ) {
        guard let user = AppState.sharedInstance.user else {
            completion(false)
            return
        }

        let userId = user.userId
        let strUrl = WebURL.getAllChildApps(childId: userId)

        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: strUrl, aParams: [:]) {
            [weak self] (isSuccess, responseDict) in
            guard let self = self else { return }

            if isSuccess {
                if let rawArray = responseDict["noneDriveModeRequestApproved"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: rawArray)
                        self.noDriveModeApprovedList = try JSONDecoder().decode(
                            [ChildRequestedApp].self, from: jsonData)
                        // Persist to UserDefaults — overrides stale data, drops expired entries
                        ChildHomeViewModel.saveApprovedNoDriveSchedules(
                            self.noDriveModeApprovedList)
                        self.didFetchApprovedSchedules = true
                        completion(true)
                    } catch {
                        completion(false)
                    }
                } else {
                    self.noDriveModeApprovedList = []
                    // Clear UserDefaults too (no approved schedules from server)
                    ChildHomeViewModel.saveApprovedNoDriveSchedules([])
                    self.didFetchApprovedSchedules = true
                    completion(true)
                }
                
                if let rejectedArray = responseDict["noneDriveModeRequestRejected"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: rejectedArray)
                        self.noDriveModeRejectedList = try JSONDecoder().decode(
                            [ChildRequestedApp].self, from: jsonData
                        )
                    } catch {
                        self.noDriveModeRejectedList = []
                    }
                } else {
                    self.noDriveModeRejectedList = []
                }
                
            } else {
                completion(false)
            }
        }
    }

    func clearData() {
        requestedApps.removeAll()
        noDriveModeScheduleList.removeAll()
        noDriveModeApprovedList.removeAll()
        noDriveModeRejectedList.removeAll()
        didFetchApprovedSchedules = false
    }
    
    func syncSingleApp(
        token: String,
        appName: String,
        requestName: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard let userId = AppState.sharedInstance.user?.userId else {
            completion(false)
            return
        }

        // If the name isn't resolved, skip the sync step entirely rather than aborting.
        // The token itself is the reliable identifier — the parent sees the app icon from it.
        // We skip writing "Unknown App" to the server's blocked-app list.
        let isGarbage = AppNameResolution.isUnresolved(appName)

//        guard !isGarbage else {
//            print("⚠️ [SyncSingleApp] Name unresolved for '\(token.prefix(12))...' — skipping sync, proceeding to request")
//            completion(true)  // proceed without sync rather than blocking the request
//            return
//        }
        
        let getUrl = WebURL.childAccountApi + "\(userId)/apps"
        let syncUrl = WebURL.childAppsSync(childId: userId)
        
        let nameToSync = (requestName?.isEmpty == false) ? requestName! : appName
        
        // Store the user-provided name for persistence
        print("🔄 [SyncSingleApp] Using name: '\(nameToSync)' (requestName: '\(requestName ?? "nil")', appName: '\(appName)')")

        // Define the single new app to sync
        let newApp: [String: Any] = [
            "name": nameToSync,
            "token": token,
            "deviceType": "IOS",
            "icon": "",
            "a": "1"  // Mark as blocked
        ]
        
        // Step 1: Fetch existing apps from server first to prevent overwriting other apps
        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: getUrl, aParams: [:]) { [weak self] (fetchSuccess, responseDict) in
            guard let self = self else {
                completion(false)
                return
            }
            
            var mergedApps: [[String: Any]] = []
            
            if fetchSuccess, let existingApps = responseDict["apps"] as? [[String: Any]] {
                // We have existing apps, let's merge them
                mergedApps = existingApps
                
                // Check if the app we want to sync already exists in the list (by token)
                let alreadyExists = existingApps.contains { dict in
                    let existingToken = dict["token"] as? String ?? dict["_id"] as? String ?? ""
                    return existingToken == token
                }
                
                if !alreadyExists {
                    mergedApps.append(newApp)
                    print("✅ [SyncSingleApp] Added new app with name: '\(nameToSync)'")
                } else {
                    // If it already exists, let's make sure it's marked as blocked 'a' = '1'
                    // IMPORTANT: Always preserve the user-provided name (nameToSync)
                    if let index = mergedApps.firstIndex(where: { ($0["token"] as? String ?? $0["_id"] as? String ?? "") == token }) {
                        var updatedApp = mergedApps[index]
                        let oldName = updatedApp["name"] as? String ?? "Unknown"
                        updatedApp["a"] = "1"
                        updatedApp["name"] = nameToSync  // Always use the user-provided name
                        mergedApps[index] = updatedApp
                        print("✅ [SyncSingleApp] Updated existing app: '\(oldName)' → '\(nameToSync)'")
                    }
                }
            } else {
                // Fetch failed or empty list, fall back to just the single app payload
                mergedApps = [newApp]
            }
            
            let params: [String: Any] = ["apps": mergedApps]
            
            print("🔄 [SyncSingleApp] Syncing \(mergedApps.count) app(s) to server")
            print("🔄 [SyncSingleApp] Target app name: '\(nameToSync)'")
            print("🔄 [SyncSingleApp] URL: \(syncUrl)")
            
            apiCallViewModel.putMethodApiCallWithDisctionaryResponse(aUrl: syncUrl, param: params) { (isSuccess, responseDict) in
                if isSuccess {
                    print("✅ [SyncSingleApp] App(s) synced successfully")
                    print("✅ [SyncSingleApp] Server response: \(responseDict)")
                } else {
                    print("❌ [SyncSingleApp] Failed to sync app(s)")
                    print("❌ [SyncSingleApp] Error response: \(responseDict)")
                }
                completion(isSuccess)
            }
        }
    }

    // MARK: - Name resolution for ViewForReqAppSelection

    /// Resolves names for a list of tokens using an isolated key-window approach.
    /// Calls `onResolved(index, name)` on the main thread as each name is found.
    /// Uses `AppNameResolutionCache` first; falls back to off-screen rendering.
    @MainActor
    func resolveNamesForTokens(
        _ tokens: [ApplicationToken],
        tokenStrings: [String],
        onResolved: @escaping (Int, String) -> Void
    ) async {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else { return }
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first else { return }

        // 1. Cache pass — instant for previously seen apps
        var stillUnresolved: [(index: Int, token: ApplicationToken, tokenStr: String)] = []
        for (i, token) in tokens.enumerated() {
            let tokenStr = i < tokenStrings.count ? tokenStrings[i] : ""
            if let cached = AppNameResolutionCache.cachedName(forTokenStr: tokenStr),
               AppNameResolution.isResolved(cached) {
                onResolved(i, cached)
            } else {
                stillUnresolved.append((i, token, tokenStr))
            }
        }
        guard !stillUnresolved.isEmpty else { return }

        // 2. Off-screen key-window resolution — one token at a time
        let previousKeyWindow = windowScene.windows.first { $0.isKeyWindow }
        let screenWidth = windowScene.screen.bounds.width

        let resolutionWindow = UIWindow(windowScene: windowScene)
        resolutionWindow.frame = CGRect(x: screenWidth + 10, y: 0, width: 300, height: 44)
        resolutionWindow.backgroundColor = .white
        resolutionWindow.windowLevel = .normal
        resolutionWindow.makeKeyAndVisible()

        for item in stillUnresolved {
            let hc = UIHostingController(rootView: AnyView(
                Label(item.token)
                    .labelStyle(.automatic)
                    .frame(width: 300, height: 44)
                    .background(Color.white)
            ))
            hc.view.frame = resolutionWindow.bounds
            hc.view.backgroundColor = .white
            resolutionWindow.rootViewController = hc
            resolutionWindow.layoutIfNeeded()

            try? await Task.sleep(nanoseconds: 500_000_000)

            for _ in 0..<6 {
                guard hc.view.window != nil else { break }
                if let name = findAnyLabelText(in: hc.view), AppNameResolution.isResolved(name) {
                    AppNameResolutionCache.store(name: name, forTokenStr: item.tokenStr)
                    onResolved(item.index, name)
                    break
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            resolutionWindow.rootViewController = nil
        }

        resolutionWindow.isHidden = true
        previousKeyWindow?.makeKeyAndVisible()
    }
}
