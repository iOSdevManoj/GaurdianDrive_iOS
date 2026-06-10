//
//  ParentHomeViewModel.swift
//  GaurdianDrive
//

import Foundation
import UIKit

class ParentHomeViewModel {
    
    static let shared = ParentHomeViewModel()
    
    let apiCallViewModel = ApiCallViewModel()
    
    // MARK: - Properties
    
    /// Saves a UIImage as a PNG file in the app's Documents/AppIcons directory.
    private func saveIcon(_ image: UIImage, for appId: Int) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("AppIcons", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        let fileURL = dir.appendingPathComponent("\(appId).png")
        guard let pngData = image.pngData() else { return }
        try? pngData.write(to: fileURL, options: .atomic)
    }
    var arrAppRequests: [ChildRequestedApp] = []
    var arrNoDriveRequests: [ChildRequestedApp] = []
    var arrApprovedApps: [ChildRequestedApp] = []

    // Populated from /apps/all — no separate API calls needed
    var speedAlert: Bool = false
    var speedAlertThreshold: Double = 0
    var policyTitle: String = ""
    var policyDescription: String = ""
    var lastLocationLat: Double = 0
    var lastLocationLng: Double = 0
    var lastLocationSpeed: Double = 0
    var lastDriveMode: String = ""  // driveMode sent by the child device
    var localTime: String = ""

    // MARK: - API Calls
    func fetchChildData(childId: String, completion: @escaping (Bool) -> Void) {
        let strUrl = WebURL.getAllChildApps(childId: childId)
        let appsUrl = WebURL.childAccountApi + "\(childId)/apps"
        
        // Fetch both endpoints in parallel: /apps/all (requests/policy) + /apps (blocked-apps with correct names)
        var allAppsResponse: [String: Any] = [:]
        var blockedAppNameByToken: [String: String] = [:]
        let group = DispatchGroup()
        
        group.enter()
        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: strUrl, aParams: [:]) { (isSuccess, responseDict) in
            if isSuccess { allAppsResponse = responseDict }
            group.leave()
        }
        
        group.enter()
        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: appsUrl, aParams: [:]) { (isSuccess, responseDict) in
            if isSuccess, let appsArray = responseDict["apps"] as? [[String: Any]] {
                for app in appsArray {
                    let tok = app["token"] as? String ?? app["_id"] as? String ?? ""
                    let n = app["name"] as? String ?? ""
                    if !tok.isEmpty && AppNameResolution.isResolved(n) {
                        blockedAppNameByToken[tok] = n
                    }
                }
                print("📋 [Parent] Blocked-apps name map: \(blockedAppNameByToken.count) resolved names")
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            guard !allAppsResponse.isEmpty else {
                completion(false)
                return
            }
            self.parseChildData(from: allAppsResponse, blockedAppNameByToken: blockedAppNameByToken)
            completion(true)
        }
    }
    
    private func parseChildData(from responseDict: [String: Any], blockedAppNameByToken: [String: String]) {
        let decoder = JSONDecoder()
        
        if let requestedAppsData = try? JSONSerialization.data(withJSONObject: responseDict["driveModeRequestedApps"] as? [[String: Any]] ?? []),
           var reqApps = try? decoder.decode([ChildRequestedApp].self, from: requestedAppsData) {
            
            // Patch unresolved names using the blocked-apps name map (correct user-provided names)
            for i in reqApps.indices {
                let tok = reqApps[i].token ?? reqApps[i]._id ?? ""
                if AppNameResolution.isUnresolved(reqApps[i].name),
                   let betterName = blockedAppNameByToken[tok] {
                    print("📋 [Parent] Patching '\(reqApps[i].name ?? "nil")' → '\(betterName)'")
                    reqApps[i].name = betterName
                }
            }
            
            self.arrAppRequests = reqApps.sorted { ($0.sortDate ?? .distantPast) > ($1.sortDate ?? .distantPast) }
            for app in self.arrAppRequests {
                if let id = app.id, let image = app.decodeIcon() {
                    self.saveIcon(image, for: id)
                }
            }
        } else {
            self.arrAppRequests = []
        }
        
        // Merge REQUESTED + APPROVED + REJECTED no-drive entries
        var combinedNoDriveRequests: [ChildRequestedApp] = []
        if let requestedData = try? JSONSerialization.data(withJSONObject: responseDict["noneDriveModeRequested"] as? [[String: Any]] ?? []),
           let requested = try? decoder.decode([ChildRequestedApp].self, from: requestedData) {
            combinedNoDriveRequests.append(contentsOf: requested)
        }
        if let approvedData = try? JSONSerialization.data(withJSONObject: responseDict["noneDriveModeRequestApproved"] as? [[String: Any]] ?? []),
           let approved = try? decoder.decode([ChildRequestedApp].self, from: approvedData) {
            combinedNoDriveRequests.append(contentsOf: approved)
        }
        if let rejectedData = try? JSONSerialization.data(withJSONObject: responseDict["noneDriveModeRequestRejected"] as? [[String: Any]] ?? []),
           let rejected = try? decoder.decode([ChildRequestedApp].self, from: rejectedData) {
            combinedNoDriveRequests.append(contentsOf: rejected)
        }
        self.arrNoDriveRequests = combinedNoDriveRequests
            .sorted { ($0.sortDate ?? .distantPast) > ($1.sortDate ?? .distantPast) }
        
        if let approvedAppsData = try? JSONSerialization.data(withJSONObject: responseDict["driveModeApprovedApps"] as? [[String: Any]] ?? []),
           var approvedApps = try? decoder.decode([ChildRequestedApp].self, from: approvedAppsData) {
            
            // Patch unresolved names using the blocked-apps name map (correct user-provided names)
            for i in approvedApps.indices {
                let tok = approvedApps[i].token ?? approvedApps[i]._id ?? ""
                if AppNameResolution.isUnresolved(approvedApps[i].name),
                   let betterName = blockedAppNameByToken[tok] {
                    print("📋 [Parent] Patching approved '\(approvedApps[i].name ?? "nil")' → '\(betterName)'")
                    approvedApps[i].name = betterName
                }
            }
            
            self.arrApprovedApps = approvedApps.sorted { ($0.sortDate ?? .distantPast) > ($1.sortDate ?? .distantPast) }
        } else {
            self.arrApprovedApps = []
        }

        // Speed settings
        self.speedAlert = responseDict["speedAlert"] as? Bool ?? false
        self.speedAlertThreshold = (responseDict["speedAlertThreshold"] as? Double)
            ?? Double(responseDict["speedAlertThreshold"] as? String ?? "") ?? 0

        // Drive-mode policy
        if let policy = responseDict["driveModePolicy"] as? [String: Any] {
            self.policyTitle = policy["title"] as? String ?? ""
            self.policyDescription = policy["description"] as? String ?? ""
        } else {
            self.policyTitle = ""
            self.policyDescription = ""
        }

        // Last known location
        if let loc = responseDict["lastLocation"] as? [String: Any] {
            self.lastLocationLat   = Double("\(loc["latitude"] ?? 0.0)") ?? 0.0
            self.lastLocationLng   = Double("\(loc["longitude"] ?? 0.0)") ?? 0.0
            self.lastLocationSpeed = Double("\(loc["speed"] ?? 0.0)") ?? 0.0
            self.lastDriveMode     = loc["driveMode"] as? String ?? ""
            self.localTime         = loc["localTime"] as? String ?? ""
        } else {
            self.lastLocationLat   = 0
            self.lastLocationLng   = 0
            self.lastLocationSpeed = 0
            self.lastDriveMode     = ""
            self.localTime         = ""
        }
    }

    
    func performAppRequestAction(childId: String, requestId: String, action: String, permissionType: String, completion: @escaping (Bool, String?) -> Void) {
        let strUrl: String
        if action == "approve" {
            strUrl = WebURL.approveRequest(childId: childId, requestId: requestId)
        } else {
            strUrl = WebURL.rejectRequest(childId: childId, requestId: requestId)
        }
        
        let param = ["token": "", "permissionType": permissionType] as [String : Any]
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: strUrl, param: param) { (isSuccess, responseDict, statusCode) in
            if isSuccess {
                completion(true, nil)
            } else {
                let strMessage = responseDict["defaultMessage"] as? String ?? responseDict["message"] as? String ?? "Failed to \(action) request"
                completion(false, strMessage)
            }
        }
    }

    // MARK: - Cancel approved app
    func cancelApprovedApp(childId: String, requestId: String, completion: @escaping (Bool, String?) -> Void) {
        let strUrl = WebURL.cancelRequest(childId: childId, requestId: requestId)
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: strUrl, param: [:]) { (isSuccess, responseDict, statusCode) in
            if isSuccess {
                completion(true, nil)
            } else {
                let strMessage = responseDict["defaultMessage"] as? String
                    ?? responseDict["message"] as? String
                    ?? "Failed to cancel approved app"
                completion(false, strMessage)
            }
        }
    }
    
    func performNoDriveModeAction(childId: String, request: ChildRequestedApp, action: String, completion: @escaping (Bool, String?) -> Void) {
        guard let requestId = request.id != nil ? String(request.id!) : request._id else {
            completion(false, "Invalid Request ID")
            return
        }
        
        let strUrl: String
        if action == "approve" {
            strUrl = WebURL.approveNoDriveRequest(childId: childId, requestId: requestId)
        } else {
            strUrl = WebURL.rejectNoDriveRequest(childId: childId, requestId: requestId)
        }
        
        let param = [
            "startTime": request.startTime ?? "",
            "endTime": request.endTime ?? "",
            "reason": request.reason ?? ""
        ] as [String : Any]
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: strUrl, param: param) { (isSuccess, responseDict, statusCode) in
            if isSuccess {
                completion(true, nil)
            } else {
                let strMessage = responseDict["defaultMessage"] as? String ?? responseDict["message"] as? String ?? "Failed to \(action) request"
                completion(false, strMessage)
            }
        }
    }

    /// Called when a parent revokes an APPROVED no-drive mode request.
    /// Hits: POST /child/{childId}/none-drive-mode/{requestId}/cancel
    func cancelNoDriveModeAction(childId: String, request: ChildRequestedApp, completion: @escaping (Bool, String?) -> Void) {
        guard let requestId = request.id != nil ? String(request.id!) : request._id else {
            completion(false, "Invalid Request ID")
            return
        }

        let strUrl = WebURL.cancelNoDriveRequest(childId: childId, requestId: requestId)

        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: strUrl, param: [:]) { (isSuccess, responseDict, statusCode) in
            if isSuccess {
                completion(true, nil)
            } else {
                let strMessage = responseDict["defaultMessage"] as? String
                    ?? responseDict["message"] as? String
                    ?? "Failed to cancel no-drive request"
                completion(false, strMessage)
            }
        }
    }

    // MARK: - Clear all cached data on logout
    func clearData() {
        arrAppRequests.removeAll()
        arrNoDriveRequests.removeAll()
        arrApprovedApps.removeAll()
        speedAlert = false
        speedAlertThreshold = 0
        policyTitle = ""
        policyDescription = ""
        lastLocationLat = 0
        lastLocationLng = 0
        lastLocationSpeed = 0
        lastDriveMode = ""
        localTime = ""
    }
}
