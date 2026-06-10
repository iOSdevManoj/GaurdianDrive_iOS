import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import SwiftData
import SwiftUI
import os

@MainActor
class AppBlockerManager: ObservableObject {
    static let shared = AppBlockerManager()
    
    // Logger for system console visibility
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "org.app.GaurdianDrive",
        category: "AppBlockerManager")
    
    var modelContainer: ModelContainer?
    
    @Published var isAuthorized = false
    @Published var showDenialAlert = false
    @Published var errorMessage: String?
    
    // Direct store access for immediate blocking
    private let store = ManagedSettingsStore()
    
    // Speed Logic — all values in MPH
    @Published var currentSpeedMph: Double = 0.0
    @Published var speedLimitMph: Double = 15.0  // Default speed limit for child (set by server)
    @Published var parentsSpeedLimitMph: Double = 15.0  // Default for parent's device (set by server)
    @Published var isSpeedExceeded: Bool = false
    
    /// ⭐ Single source of truth — speed limit fetched from server.
    // let appBlockingThresholdMph: Double = 15.0 // Removed in favor of speedLimitMph
    
    private var speedObserver: NSObjectProtocol?
    
    private let activityNamePrefix = "MyApp.BlockingActivity"
    private let eventName = "MyApp.BlockingEvent"
    
    /// UserDefaults key to persist the parent's manual block state across app kills.
    private let parentManualBlockKey = "ParentManualBlockActive"
    
    /// Tracks last applied shield state to avoid redundant ManagedSettings calls on every GPS ping.
    /// nil = unknown (first run), true = shields ON, false = shields OFF.
    private var lastShieldState: Bool? = nil
    private var lastAppliedCount: Int? = nil
    
    /// Cache for blocked tokens to avoid redundant SwiftData fetches on every GPS update.
    private var cachedBlockedTokens: Set<ApplicationToken>? = nil
    
    /// Clears all shields on the default store and all dynamic chunk stores.
    private func clearAllShieldsAndSettings() {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else { return }
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        // Clear all dynamic overflow stores used for large selections
        for i in 0..<5 {
            let chunkStore = ManagedSettingsStore(
                named: ManagedSettingsStore.Name("Store_Chunk_\(i)"))
            chunkStore.shield.applications = nil
            chunkStore.shield.applicationCategories = nil
            chunkStore.shield.webDomains = nil
        }
        
        enforceAppRemovalPolicy()
    }
    
    private init() {
        // Check initial status
        updateAuthorizationStatus()
        // Subscribe to real GPS speed broadcasts from LocationPermissionManager
        subscribeToSpeedUpdates()
    }
    
    deinit {
        if let obs = speedObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    // MARK: - Speed Subscription
    private func subscribeToSpeedUpdates() {
        speedObserver = NotificationCenter.default.addObserver(
            forName: .speedDidUpdate,
            object: nil,
            queue: nil  // deliver on posting thread; we dispatch to MainActor below
        ) { [weak self] notification in
            guard let self = self else { return }
            if let mph = notification.userInfo?["speedMPH"] as? Double {
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.currentSpeedMph = mph
                    let threshold = self.speedLimitMph
                    let newExceeded = mph > threshold
                    
                    // Only re-evaluate if speed state actually changed (crossed the threshold)
                    if self.isSpeedExceeded != newExceeded {
                        self.isSpeedExceeded = newExceeded
                        self.logger.info(
                            "[Speed] State changed: exceeded=\(newExceeded) at \(mph) mph")
                        self.reEvaluateSpeed()
                    }
                }
            }
        }
    }
    
    func requestAuthorization() {
        logger.info("Requesting authorization...")
        Task {
            do {
                let center = AuthorizationCenter.shared
                try await center.requestAuthorization(for: .individual)
                
                // Request notification permission via manager
                try await PushNotificationManager.shared.requestAuthorization()
                
                logger.info("Authorization request returned successfully.")
                updateAuthorizationStatus()
            } catch {
                logger.error("Failed to authorize: \(error.localizedDescription)")
                updateAuthorizationStatus()
                errorMessage = error.localizedDescription
                showDenialAlert = true
            }
        }
    }
    
    private func updateAuthorizationStatus() {
        let status = AuthorizationCenter.shared.authorizationStatus
        logger.info("Current authorization status: \(String(describing: status))")
        switch status {
        case .approved:
            isAuthorized = true
        case .denied:
            isAuthorized = false
            showDenialAlert = true
        case .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
        
        enforceAppRemovalPolicy()
    }
    
    /// Enforces whether the child is allowed to delete apps from the device, driven by FeatureFlag
    func enforceAppRemovalPolicy() {
        let status = AuthorizationCenter.shared.authorizationStatus
        if status == .approved {
            // Only enforce "Deny App Removal" if a child is actually logged in.
            // If logged out or parent login, we allow app removal.
            let isLoggedIn =
            AppState.sharedInstance.user?.userId != nil
            && !(AppState.sharedInstance.user?.userId.isEmpty ?? true)
            let isParent = UserDefaults.Main.bool(forKey: .isParent)
            let isChild = isLoggedIn && !isParent
            
            var appSettings = store.application
            if isChild && !FeatureFlag.isChildUserCanRemoveApp {
                appSettings.denyAppRemoval = true
                appSettings.denyAppInstallation = false
                store.application = appSettings
                logger.info("Enforced app removal deny policy for child.")
            } else {
                appSettings.denyAppRemoval = false
                store.application = appSettings
                logger.info("App removal allowed for this user (Parent or Logged Out).")
            }
        } else {
            logger.info(
                "Cannot enforce app removal policy: Family Controls not approved (\(String(describing: status)))."
            )
        }
    }
    
    // MARK: - Scheduling
    /// Called when a new app selection arrives (push notification or server sync).
    /// Saves the blocked tokens to SwiftData (single source of truth) then re-evaluates shields.
    func startMonitoring(selection: FamilyActivitySelection) {
        lastShieldState = nil
        lastAppliedCount = nil
        cachedBlockedTokens = nil  // Invalidate cache
        
        // Detect "select all" — FamilyActivityPicker leaves applicationTokens EMPTY
        // when the user picks all apps. Persist this flag so reEvaluateSpeed can use it.
        let isSelectAll = selection.applicationTokens.isEmpty
        UserDefaults.standard.set(isSelectAll, forKey: "BlockAll_SelectAll")
        
        // Persist the incoming selection to SwiftData so it survives app kills.
        ensureModelContainer()
        if let context = modelContainer.map({ ModelContext($0) }) {
            let existing = (try? context.fetch(FetchDescriptor<BlockingSelection>()))?.first
            let tokens = selection.applicationTokens
            let statuses: [AppBlockStatus] = tokens.map { token in
                // Preserve existing isBlocked flag if present; default to true for new tokens.
                let current = existing?.appStatuses.first(where: { $0.token == token })
                return AppBlockStatus(
                    token: token, isBlocked: current?.isBlocked ?? true,
                    appName: current?.appName ?? "Unknown")
            }
            if let existing = existing {
                existing.appStatuses = statuses
                existing.selection = selection // Persist the full selection including categories
                existing.categoryStatuses = []
            } else {
                context.insert(
                    BlockingSelection(
                        selection: selection, // Use the incoming selection directly
                        appStatuses: statuses,
                        categoryStatuses: []))
            }
            try? context.save()
            logger.info("[startMonitoring] Saved \(statuses.count) app tokens to SwiftData. isSelectAll=\(isSelectAll)")
        }
        
        let isParent = UserDefaults.Main.bool(forKey: .isParent)
        if isParent {
            evaluateAndApplyShieldsForParent()
        } else {
            reEvaluateSpeed(force: true)
        }
    }
    
    /// Called by the parent's "Block Selected" button.
    func applyParentManualBlock(selection: FamilyActivitySelection) {
        // Detect "select all" — applicationTokens is empty when user picks all apps in picker
        let isSelectAll = selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty
        
        guard !selection.applicationTokens.isEmpty
                || !selection.webDomainTokens.isEmpty
                || !selection.categoryTokens.isEmpty
                || isSelectAll else {
            logger.info("[Parent] applyParentManualBlock: No apps selected, nothing to block.")
            return
        }
        
        UserDefaults.standard.set(true, forKey: parentManualBlockKey)
        UserDefaults.standard.set(isSelectAll, forKey: "BlockAll_SelectAll")
        
        // 2. Persist the actual selection in SwiftData so it survives app kills
        ensureModelContainer()
        if let container = modelContainer {
            let context = ModelContext(container)
            let blockingSelection = try? context.fetch(FetchDescriptor<BlockingSelection>()).first
            
            let appStatuses = selection.applicationTokens.map {
                AppBlockStatus(token: $0, isBlocked: true, appName: "Manual Block")
            }
            
            if let existing = blockingSelection {
                existing.appStatuses = appStatuses
                existing.selection = selection
            } else {
                context.insert(
                    BlockingSelection(
                        selection: selection,
                        appStatuses: appStatuses,
                        categoryStatuses: []
                    ))
            }
            try? context.save()
        }
        
        lastShieldState = nil
        logger.info(
            "[Parent] Applying manual block for \(isSelectAll ? "ALL" : "\(selection.applicationTokens.count)") apps. Selection saved to SwiftData."
        )
        applyShieldsWithChunks(
            tokens: selection.applicationTokens,
            webDomains: selection.webDomainTokens,
            blockAll: isSelectAll
        )
    }
    
    /// Called by the parent's "Unblock All" button.
    func clearParentBlock() {
        logger.info("[Parent] Clearing all local shields (Unblock All). Removing persisted state.")
        UserDefaults.standard.set(false, forKey: parentManualBlockKey)
        UserDefaults.standard.set(false, forKey: "BlockAll_SelectAll")
        lastShieldState = nil
        lastAppliedCount = nil
        cachedBlockedTokens = nil
        clearAllShieldsAndSettings()
        DeviceActivityCenter().stopMonitoring()
    }
    
    /// Restores a previously-active parent manual block on app relaunch.
    func restoreParentBlockIfNeeded() {
        guard UserDefaults.standard.bool(forKey: parentManualBlockKey) else { return }
        
        logger.info("[Parent] App relaunched — detected active manual block. Restoring shields...")
        ensureModelContainer()
        guard let container = modelContainer else {
            logger.error("[Parent] restoreParentBlockIfNeeded: no ModelContainer available.")
            return
        }
        
        let context = ModelContext(container)
        guard let saved = try? context.fetch(FetchDescriptor<BlockingSelection>()).first else {
            logger.info("[Parent] restoreParentBlockIfNeeded: no saved selection found.")
            return
        }
        
        let blockedTokens = saved.appStatuses.filter { $0.isBlocked }.map { $0.token }
        guard !blockedTokens.isEmpty else {
            logger.info("[Parent] restoreParentBlockIfNeeded: no checked apps to restore.")
            return
        }
        
        var selection = FamilyActivitySelection(includeEntireCategory: true)
        selection.applicationTokens = Set(blockedTokens)
        selection.categoryTokens = []
        
        logger.info(
            "[Parent] Restoring manual block for \(blockedTokens.count) apps after relaunch.")
        applyShieldsWithChunks(tokens: Set(blockedTokens))
    }
    
    func reEvaluateSpeed(force: Bool = false) {
        let isParent = UserDefaults.Main.bool(forKey: .isParent)
        if isParent {
            evaluateAndApplyShieldsForParent()
            return
        }
        
        // 1. Check if we have an active No-Drive schedule (approved window).
        // This takes precedence over speed.
        if checkNoDriveSchedule() {
            if lastShieldState != false || force {
                logger.info("[Shield] Active No-Drive schedule — clearing all shields.")
                clearAllShieldsAndSettings()
                lastShieldState = false
                lastAppliedCount = nil
            }
            return
        }
        
        // 2. Check if we are below speed limit
        guard self.currentSpeedMph > self.speedLimitMph else {
            if lastShieldState != false || force {
                logger.info(
                    "[Shield] Speed below limit (\(self.currentSpeedMph) <= \(self.speedLimitMph)). Clearing shields."
                )
                clearAllShieldsAndSettings()
                lastShieldState = false
                lastAppliedCount = nil
            }
            return
        }
        
        // 3. We are above speed and no schedule exemption. Determine apps to block.
        let isSelectAll = UserDefaults.standard.bool(forKey: "BlockAll_SelectAll")
        
        if let cached = cachedBlockedTokens, !force {
            applyShieldsWithChunks(tokens: cached, blockAll: isSelectAll)
            return
        }
        
        ensureModelContainer()
        guard let container = modelContainer else { return }
        let context = ModelContext(container)
        guard let saved = try? context.fetch(FetchDescriptor<BlockingSelection>()).first else {
            logger.info("[Shield] No selection found in SwiftData.")
            return
        }
        
        // Logical rule for Child drive-mode:
        // Block apps that are "isBlocked" (a=1) UNLESS they are "APPROVED".
        let tokensToBlock = Set(
            saved.appStatuses.filter {
                $0.isBlocked && $0.status != "APPROVED"
            }.map { $0.token })
        
        cachedBlockedTokens = tokensToBlock
        logger.info(
            "[Shield] Speed exceeded. Blocking \(isSelectAll ? "ALL apps" : "\(tokensToBlock.count) apps") (excluding approved ones)."
        )
        
        if lastShieldState != true || lastAppliedCount != tokensToBlock.count || force {
            applyShieldsWithChunks(
                tokens: tokensToBlock,
                webDomains: saved.selection.webDomainTokens,
                categories: saved.selection.categoryTokens,
                blockAll: isSelectAll
            )
            lastShieldState = true
            lastAppliedCount = tokensToBlock.count
        }
    }
    
    private func checkNoDriveSchedule() -> Bool {
        let now = Date()
        let isoParser = ISO8601DateFormatter()
        isoParser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoParserNoFrac = ISO8601DateFormatter()
        
        let inMemoryActive = ChildHomeViewModel.shared.noDriveModeApprovedList.contains { entry in
            let status = (entry.currentStatus ?? entry.status ?? "").uppercased()
            guard status == "APPROVED" else { return false }
            let start =
            isoParser.date(from: entry.startTime ?? "")
            ?? isoParserNoFrac.date(from: entry.startTime ?? "")
            let end =
            isoParser.date(from: entry.endTime ?? "")
            ?? isoParserNoFrac.date(from: entry.endTime ?? "")
            guard let s = start, let e = end else { return false }
            return now >= s && now <= e
        }
        let useUserDefaultsFallback = !ChildHomeViewModel.shared.didFetchApprovedSchedules
        return inMemoryActive
        || (useUserDefaultsFallback
            ? ChildHomeViewModel.hasActiveApprovedNoDriveSchedule() : false)
    }
    
    private func evaluateAndApplyShieldsForParent() {
        let isManualBlockActive = UserDefaults.standard.bool(forKey: parentManualBlockKey)
        let threshold = UserDefaults.Main.bool(forKey: .isParent) ? parentsSpeedLimitMph : speedLimitMph
        
        if self.currentSpeedMph > threshold {
            ensureModelContainer()
            if let container = modelContainer {
                let context = ModelContext(container)
                if let saved = try? context.fetch(FetchDescriptor<BlockingSelection>()).first {
                    let tokensToBlock = Set(
                        saved.appStatuses.filter { $0.isBlocked }.map { $0.token })
                    
                    if lastShieldState != true || lastAppliedCount != tokensToBlock.count {
                        logger.info(
                            "[Parent] Speed > 15 mph. Blocking \(tokensToBlock.count) selected apps."
                        )
                        applyShieldsWithChunks(
                            tokens: tokensToBlock,
                            webDomains: saved.selection.webDomainTokens,
                            categories: saved.selection.categoryTokens
                        )
                        lastShieldState = true
                        lastAppliedCount = tokensToBlock.count
                    }
                }
            }
        } else if isManualBlockActive {
            if lastShieldState != true {
                restoreParentBlockIfNeeded()
                lastShieldState = true
            }
        } else {
            if lastShieldState != false {
                clearAllShieldsAndSettings()
                lastShieldState = false
                lastAppliedCount = nil
            }
        }
    }
    
    /// Unified shield application that handles the 50-app limit via multiple stores (chunks).
    /// When `blockAll` is explicitly true, uses .all(except: ownApp) policy.
    /// An empty `tokens` set with `blockAll = false` means "nothing to block" — shields are cleared.
    private func applyShieldsWithChunks(
        tokens: Set<ApplicationToken>,
        webDomains: Set<WebDomainToken>? = nil,
        categories: Set<ActivityCategoryToken>? = nil,
        blockAll: Bool = false
    ) {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            logger.warning("[Shield] Skipping shield application — Family Controls not approved.")
            return
        }
        
        // ── "Select All" path ────────────────────────────────────────────────
        // Only enter block-all mode when explicitly requested.
        // An empty tokens set means the parent selected nothing — clear shields instead.
        if blockAll {
            let ownTokens = ParentControlViewModel.shared.ownAppTokens
            var allowedTokens = ownTokens
            
            // Exclude child's approved apps from block-all shield
            let approvedTokens = Set(ChildHomeViewModel.shared.approvedApps.compactMap { $0.getApplicationToken() })
            allowedTokens.formUnion(approvedTokens)
            
            logger.info("[Shield] Applying block-all shield (except \(allowedTokens.count) allowed tokens).")
            store.shield.applicationCategories = .all(except: allowedTokens)
            store.shield.applications = nil
            store.shield.webDomains = (webDomains?.isEmpty ?? true) ? nil : webDomains
            // Clear all overflow chunk stores — not needed for block-all
            for i in 0..<5 {
                let chunkStore = ManagedSettingsStore(named: ManagedSettingsStore.Name("Store_Chunk_\(i)"))
                chunkStore.shield.applications = nil
                chunkStore.shield.applicationCategories = nil
            }
            return
        }
        
        // ── Empty tokens — nothing to block ─────────────────────────────────
        if tokens.isEmpty {
            logger.info("[Shield] No tokens to block — clearing all shields.")
            clearAllShieldsAndSettings()
            return
        }
        
        // ── Specific tokens path ─────────────────────────────────────────────
        let tokenArray = Array(tokens)
        let chunkSize = 45  // Slightly below 50 for safety
        logger.info(
            "[Shield] Applying shields for \(tokenArray.count) apps across multiple stores.")
        
        // Primary store: first chunk + web domains
        let firstChunk = Array(tokenArray.prefix(chunkSize))
        store.shield.applications = Set(firstChunk)
        store.shield.applicationCategories = (categories?.isEmpty ?? true) ? nil : ShieldSettings.ActivityCategoryPolicy.specific(categories!)
        store.shield.webDomains = (webDomains?.isEmpty ?? true) ? nil : webDomains
        
        // Overflow chunks
        let remaining =
        tokenArray.count > chunkSize ? Array(tokenArray.suffix(from: chunkSize)) : []
        let chunks = stride(from: 0, to: remaining.count, by: chunkSize).map {
            Array(remaining[$0..<min($0 + chunkSize, remaining.count)])
        }
        
        for (index, chunk) in chunks.enumerated() {
            guard index < 5 else {
                logger.warning(
                    "[Shield] Limit reached: Only the first \(chunkSize * 6) apps can be blocked.")
                break
            }
            let chunkStore = ManagedSettingsStore(
                named: ManagedSettingsStore.Name("Store_Chunk_\(index)"))
            chunkStore.shield.applications = Set(chunk)
            chunkStore.shield.applicationCategories = nil
            chunkStore.shield.webDomains = nil
        }
        
        // Clear unused higher stores
        for i in chunks.count..<5 {
            let chunkStore = ManagedSettingsStore(
                named: ManagedSettingsStore.Name("Store_Chunk_\(i)"))
            chunkStore.shield.applications = nil
        }
    }
    
    func stopMonitoring() {
        lastShieldState = false
        lastAppliedCount = nil
        clearAllShieldsAndSettings()
        DeviceActivityCenter().stopMonitoring()
    }
    
    func handlePushNotification(userInfo: [AnyHashable: Any]) {
        var payload: [String: Any] = [:]
        if let dataString = userInfo["data"] as? String,
           let dataBytes = dataString.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: dataBytes) as? [String: Any]
        {
            payload = parsed
        } else if let dataDirect = userInfo["data"] as? [String: Any] {
            payload = dataDirect
        }
        
        let tokenString =
        (payload["blockingToken"] as? String) ?? (userInfo["blockingToken"] as? String)
        let commandsJSON =
        (payload["blockingCommands"] as? String) ?? (userInfo["blockingCommands"] as? String)
        
        if let tokenString = tokenString {
            if tokenString == "UNBLOCK" {
                logger.info("Received UNBLOCK command. Stopping all monitoring.")
                stopMonitoring()
                return
            }
            if let data = Data(base64Encoded: tokenString) {
                if let selection = try? JSONDecoder().decode(
                    FamilyActivitySelection.self, from: data)
                {
                    startMonitoring(selection: selection)
                } else if let singleToken = try? JSONDecoder().decode(
                    ApplicationToken.self, from: data)
                {
                    var sel = FamilyActivitySelection(includeEntireCategory: true)
                    sel.applicationTokens = [singleToken]
                    startMonitoring(selection: sel)
                }
            }
        } else if let commandsJSON = commandsJSON, let data = commandsJSON.data(using: .utf8) {
            if let commands = try? JSONDecoder().decode([AppCommand].self, from: data) {
                // Read current blocked tokens from SwiftData (single source of truth)
                ensureModelContainer()
                var currentStatuses =
                (try? modelContainer.flatMap {
                    try ModelContext($0).fetch(FetchDescriptor<BlockingSelection>()).first
                })?.appStatuses ?? []
                
                for command in commands {
                    guard let tokenData = Data(base64Encoded: command.token),
                          let token = try? JSONDecoder().decode(
                            ApplicationToken.self, from: tokenData)
                    else { continue }
                    if command.action == .block {
                        if !currentStatuses.contains(where: { $0.token == token }) {
                            currentStatuses.append(
                                AppBlockStatus(
                                    token: token, isBlocked: true,
                                    appName: command.appName ?? "Unknown"))
                        }
                        logger.info("Blocking: \(command.appName ?? "Unknown")")
                    } else {
                        currentStatuses.removeAll { $0.token == token }
                        logger.info("Unblocking: \(command.appName ?? "Unknown")")
                    }
                }
                
                // Build a selection from updated statuses and go through the standard path
                var updatedSel = FamilyActivitySelection(includeEntireCategory: true)
                updatedSel.applicationTokens = Set(
                    currentStatuses.filter { $0.isBlocked }.map { $0.token })
                startMonitoring(selection: updatedSel)
            }
        }
    }
    
    func ensureModelContainer() {
        if modelContainer == nil {
            modelContainer = try? ModelContainer(for: BlockingSelection.self)
            // Only link context on first initialization, not on every call
            if let container = modelContainer {
                Task { @MainActor in
                    ParentControlViewModel.shared.setModelContext(container.mainContext)
                }
            }
        }
    }
    
    func fetchAndSyncServerApps(childId: String? = nil, completion: (() -> Void)? = nil) {
        let resolvedId =
        childId
        ?? (UserDefaults.Main.bool(forKey: .isParent)
            ? nil : AppState.sharedInstance.user?.userId)
        guard let finalId = resolvedId, !finalId.isEmpty else {
            completion?()
            return
        }
        
        let url = WebURL.getChildApps(childId: finalId)
        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: url, aParams: [:]) {
            (success, dict) in
            if success, let apps = dict["apps"] as? [[String: Any]] {
                self.handleLaunchServerResponse(apps)
            }
            completion?()
        }
    }
    
    // MARK: - Fetch Speed Limit from Server
    func fetchSpeedLimit(completion: ((Double) -> Void)? = nil) {
        guard let userId = AppState.sharedInstance.user?.userId, !userId.isEmpty else {
            logger.error("fetchSpeedLimit: no userId, skipping")
            completion?(speedLimitMph)
            return
        }
        
        let url = WebURL.childAccountApi + "\(userId)/speed-alert-threshold"
        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: url, aParams: [:]) {
            [weak self] (isSuccess, responseDict) in
            guard let self = self else { return }
            
            if isSuccess,
               let raw = responseDict["speedAlertThreshold"],
               let value = Double("\(raw)"),
               value > 0
            {
                self.speedLimitMph = value
                UserDefaults.standard.set(value, forKey: "SpeedBlock_SpeedLimitMph")
            } else {
                let persisted = UserDefaults.standard.double(forKey: "SpeedBlock_SpeedLimitMph")
                if persisted > 0 { self.speedLimitMph = persisted }
            }
            let resolved = self.speedLimitMph
            DispatchQueue.main.async { completion?(resolved) }
        }
    }
    
    private func handleLaunchServerResponse(_ data: [[String: Any]]) {
        ensureModelContainer()
        guard let context = modelContainer.map({ ModelContext($0) }) else { return }
        
        let results = try? context.fetch(FetchDescriptor<BlockingSelection>())
        let blockingSelection = results?.first
        var appStatuses = blockingSelection?.appStatuses ?? []
        var updated = false
        
        // ── Empty response = parent removed ALL apps ──────────────────────────
        if data.isEmpty {
            if !appStatuses.isEmpty {
                if let selection = blockingSelection {
                    selection.appStatuses = []
                    selection.categoryStatuses = []
                    try? context.save()
                }
            }
            if !ChildHomeViewModel.shared.requestedApps.isEmpty {
                ChildHomeViewModel.shared.requestedApps.removeAll()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .childHomeDataDidUpdate, object: nil)
                }
            }
            if !UserDefaults.Main.bool(forKey: .isParent) {
                cachedBlockedTokens = nil
                lastShieldState = nil
                lastAppliedCount = nil
                reEvaluateSpeed(force: true)
            }
            return
        }
        
        // Build sets of blocked/unblocked tokens from the server response upfront.
        // Used both for SwiftData updates AND for ChildHomeViewModel sync below.
        var serverUnblockedTokens = Set<ApplicationToken>()
        var serverBlockedTokens   = Set<ApplicationToken>()
        
        for itemData in data {
            // Try 'token' first, fallback to '_id' as used in some server responses
            guard let tokenStr = itemData["token"] as? String ?? itemData["_id"] as? String,
                  !tokenStr.isEmpty,
                  let tokenData = Data(base64Encoded: tokenStr),
                  let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData)
            else { continue }
            
            // Handle 'a' as either String ("1"/"0") or Integer (1/0)
            let statusRaw = itemData["a"]
            let isBlocked: Bool
            if let strStatus = statusRaw as? String {
                isBlocked = (strStatus == "1")
            } else if let intStatus = statusRaw as? Int {
                isBlocked = (intStatus == 1)
            } else {
                continue  // Unknown status format
            }
            
            if isBlocked { serverBlockedTokens.insert(token) }
            else         { serverUnblockedTokens.insert(token) }
            
            let name = itemData["name"] as? String ?? "Unknown App"
            var resolvedName = name
            if !AppNameResolution.isResolved(resolvedName),
               let cached = AppNameResolutionCache.cachedName(forTokenStr: tokenStr) {
                resolvedName = cached
            }
            if resolvedName.contains(".") {
                resolvedName = AppNameResolution.cleanBundleId(resolvedName)
            }
            
            if resolvedName.lowercased().contains("(category)") || resolvedName.lowercased() == "category" {
                continue
            }
            
            if let index = appStatuses.firstIndex(where: { $0.token == token }) {
                if !isBlocked {
                    // Server says unblocked -> remove from local list
                    print("[AppBlocker] Removing server-unblocked app: \(appStatuses[index].appName ?? resolvedName)")
                    appStatuses.remove(at: index)
                    updated = true
                } else if appStatuses[index].isBlocked != isBlocked
                            || appStatuses[index].status
                            != (itemData["status"] as? String ?? itemData["currentStatus"] as? String)
                {
                    appStatuses[index].isBlocked = isBlocked
                    appStatuses[index].status =
                    itemData["status"] as? String ?? itemData["currentStatus"] as? String
                    if !AppNameResolution.isResolved(appStatuses[index].appName ?? "") && AppNameResolution.isResolved(resolvedName) {
                        appStatuses[index].appName = resolvedName
                    }
                    updated = true
                }
            } else if isBlocked {
                appStatuses.append(
                    AppBlockStatus(
                        token: token, isBlocked: isBlocked, appName: resolvedName,
                        status: itemData["status"] as? String ?? itemData["currentStatus"]
                        as? String))
                updated = true
            }
        }
        
        // ── Remove orphaned SwiftData entries absent from the server response entirely ──
        // If the parent fully deletes an app, the server may stop returning it at all
        // (rather than returning it with a=0). Without this step, the child's SwiftData
        // retains the entry and the app keeps appearing in the "Request App Access" popup.
        let allServerTokens = serverBlockedTokens.union(serverUnblockedTokens)
        if !allServerTokens.isEmpty {
            let orphans = appStatuses.filter { !allServerTokens.contains($0.token) }
            if !orphans.isEmpty {
                appStatuses.removeAll { !allServerTokens.contains($0.token) }
                updated = true
                // Mirror removal in the child's in-memory request list
                ChildHomeViewModel.shared.requestedApps.removeAll { app in
                    guard let t = app.getApplicationToken() else { return false }
                    return !allServerTokens.contains(t)
                }
                logger.info("[AppBlocker] Removed \(orphans.count) orphaned app(s) absent from server response")
            }
        }

        // ── Always sync ChildHomeViewModel regardless of SwiftData changes ──
        // This handles the case where parent removes ALL apps: the server returns
        // all tokens with a=0, but SwiftData may already be empty (no match →
        // updated=false), so we must still clear the child's in-memory list.
        let vmChanged = !serverUnblockedTokens.isEmpty
        if vmChanged {
            // Remove unblocked apps from the in-memory list
            ChildHomeViewModel.shared.requestedApps.removeAll { app in
                guard let t = app.getApplicationToken() else { return false }
                return serverUnblockedTokens.contains(t)
            }
            // Also mark any remaining entries with a=0 if server says so
            for i in ChildHomeViewModel.shared.requestedApps.indices {
                if let t = ChildHomeViewModel.shared.requestedApps[i].getApplicationToken(),
                   serverUnblockedTokens.contains(t) {
                    ChildHomeViewModel.shared.requestedApps[i].a = "0"
                }
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .childHomeDataDidUpdate, object: nil)
            }
        }
        
        if updated {
            cachedBlockedTokens = nil  // Invalidate cache
            if let selection = blockingSelection {
                selection.appStatuses = appStatuses
                selection.categoryStatuses = []
            } else {
                context.insert(
                    BlockingSelection(
                        selection: FamilyActivitySelection(includeEntireCategory: true),
                        appStatuses: appStatuses,
                        categoryStatuses: []))
            }
            try? context.save()
            
            // Re-evaluate shields from the freshly saved SwiftData — no in-memory selection needed.
            if !UserDefaults.Main.bool(forKey: .isParent) {
                lastShieldState = nil
                lastAppliedCount = nil
                cachedBlockedTokens = nil  // Invalidate cache
                reEvaluateSpeed()
            }
        } else if !serverUnblockedTokens.isEmpty {
            // SwiftData was already empty but shields may still be active — clear them.
            if !UserDefaults.Main.bool(forKey: .isParent) {
                cachedBlockedTokens = nil
                reEvaluateSpeed(force: true)
                ;            }
        }
    }
}
