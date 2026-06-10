//
//  ChildHomeVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 17/12/25.
//

import CoreLocation
import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftData
import SwiftUI
import UIKit

class ChildHomeVC: UIViewController {

    //Outlets....
    @IBOutlet var viewForBG: UIView!
    @IBOutlet var collViewAppList: UICollectionView!
    @IBOutlet var tblViewRequestApps: UITableView!
    @IBOutlet var tblViewNoDriveRequest: UITableView!
    @IBOutlet var viewForMphRound: UIView!
    @IBOutlet var lblMode: UILabel!
    @IBOutlet var lblAccessApps: UILabel!
    @IBOutlet var lblNormalMode: UILabel!
    @IBOutlet var lblMphSpeed: UILabel!
    @IBOutlet var lblMphDetailsDesc: UILabel!
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var lblUserName: UILabel!
    @IBOutlet var switchOnOff: UISwitch!
    @IBOutlet var viewForSpeedText: UIView!
    @IBOutlet var lblRequestNoFound: UILabel!
    @IBOutlet var lblNoDriveReqNoFound: UILabel!
    @IBOutlet var lblNoApprovedApps: UILabel!
    @IBOutlet var lblSpeedLimit: UILabel!
    @IBOutlet var switchDriveMode: UISwitch!

    // Height constraints — connect these in the storyboard to resize tables dynamically
    @IBOutlet var consHeightRequestApps: NSLayoutConstraint!
    @IBOutlet var consHeightNoDriveRequest: NSLayoutConstraint!

    // View All buttons — connect in storyboard
    @IBOutlet weak var btnViewAllRequests: UIButton!
    @IBOutlet weak var btnViewAllNoDrive: UIButton!
    @IBOutlet weak var btnViewAllApproved: UIButton!

    // Arrows for collection view
    private let btnLeft = UIButton()
    private let btnRight = UIButton()

    //Variables...
    private var viewForReqAppSelection: ViewForReqAppSelection?
    private var blockedAppsMap: [String: String] = [:]  // TokenStr -> TokenStr (for API)
    private var blockedAppTokens: [ApplicationToken] = []
    private var blockedAppTokenStrings: [String] = []
    private var blockedAppNames: [String] = []
    
    // Track recently submitted apps to prevent name resolution from overwriting user names
    private var recentlySubmittedApps: [String: Date] = [:]  // TokenStr -> Submission timestamp
    private let recentSubmissionProtectionWindow: TimeInterval = 30.0  // 30 seconds protection

    private var noDriveView: ViewForNoDriveRequest?
    private var speedObserver: NSObjectProtocol?
    private var appActiveObserver: NSObjectProtocol?
    private var lastLocationSentTime: Date?  // For 5-second socket throttle
    var strPolicyTitle = ""
    var strPolicyDescription = "No policy added by parent"
    let apiCallViewModel = ApiCallViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.viewForBG.roundTopCorners(radius: 16)

        //Basic initialisation...
        self.initialisation()

        // Show unified permissions popup for any missing/denied permissions
        PermissionsManager.shared.checkAndShow()
        // Sync permission state to server so parent is notified of any revocations
        ChildPermissionSyncManager.shared.syncIfNeeded()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        //Navigation bar and button hide...
        navigationItem.setHidesBackButton(true, animated: true)
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        //Set profile picture....
        setUserProfileImageFromUrl(
            aImageview: self.imgProfile, aPlaceholderName: "ic_white_placeholder")

        //Api calling for get requested list....
        self.apiCallToGetRequestedList()
        AppBlockerManager.shared.enforceAppRemovalPolicy()

        // ✅ Re-register speed observer if it was removed in viewDidDisappear
        if speedObserver == nil {
            self.getSocketConnectionMessage()
        }

        // Observe app-active events so the permission alert re-appears and speed limit refreshes
        appActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // Refresh approved/requested lists in case parent made changes while backgrounded
            self.apiCallToGetRequestedList()
            AppBlockerManager.shared.fetchSpeedLimit { [weak self] _ in
                guard let self = self else { return }
                let currentMph = LocationPermissionManager.shared.getSpeedMPH()
                let isDriving = currentMph > AppBlockerManager.shared.speedLimitMph
                self.changeViewAndThemAsPerDriveModeChange(
                    isOn: isDriving, currentSpeedMph: currentMph)
            }
            AppBlockerManager.shared.enforceAppRemovalPolicy()
            // Re-check permissions — reshow popup if user returned from Settings
            // without granting everything yet (only missing ones are shown).
            PermissionsManager.shared.checkAndShow()
            ChildPermissionSyncManager.shared.syncIfNeeded()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let obs = speedObserver {
            NotificationCenter.default.removeObserver(obs)
            speedObserver = nil
        }
        if let obs = appActiveObserver {
            NotificationCenter.default.removeObserver(obs)
            appActiveObserver = nil
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        LocationPermissionManager.shared.startUpdating()

    }
}

extension ChildHomeVC {
    //MARK: - Initialisation..
    func initialisation() {
        self.getSocketConnectionMessage()

        self.collViewAppList.register(
            UINib(nibName: "CellForAppsList", bundle: nil),
            forCellWithReuseIdentifier: "CellForAppsList")
        self.setupArrows()
        self.tblViewRequestApps.tableFooterView = UIView()
        self.tblViewNoDriveRequest.tableFooterView = UIView()
        self.tblViewRequestApps.estimatedRowHeight = 80
        self.tblViewNoDriveRequest.estimatedRowHeight = 80
        self.tblViewRequestApps.register(
            UINib(nibName: "CellForRequestApps", bundle: nil),
            forCellReuseIdentifier: "CellForRequestApps")
        self.tblViewNoDriveRequest.register(
            UINib(nibName: "CellForRequestApps", bundle: nil),
            forCellReuseIdentifier: "CellForRequestApps")

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAppsData), for: .valueChanged)
        self.tblViewRequestApps.refreshControl = refreshControl

        //Set user details...
        if let profileDetails = AppState.sharedInstance.user {
            self.lblUserName.text = profileDetails.name
        }

        //Get parent added policy..
        self.apiCallForGetParentAddedPolicy()

        // Listen for silent background refreshes triggered by push notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onChildHomeDataUpdated),
            name: .childHomeDataDidUpdate,
            object: nil
        )

        // Listen for Family Controls authorization approval
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onFamilyControlsAuthApproved),
            name: NSNotification.Name("FamilyControlsAuthDidApprove"),
            object: nil
        )
    }

    /// Called when a push notification causes a silent background data refresh.
    @objc private func onChildHomeDataUpdated() {
        print("🔁 [ChildHomeVC] Reloading UI after push-triggered data refresh")
        self.collViewAppList.reloadData()
        self.tblViewRequestApps.reloadData()
        self.tblViewNoDriveRequest.reloadData()
        self.updateEmptyLabels()
        self.updateTableHeights()

        let currentMph = LocationPermissionManager.shared.getSpeedMPH()
        let isDriving = currentMph > AppBlockerManager.shared.speedLimitMph
        self.changeViewAndThemAsPerDriveModeChange(isOn: isDriving, currentSpeedMph: currentMph)
        self.updateArrowsVisibility()
    }

    @objc private func onFamilyControlsAuthApproved() {
        print("🔓 [ChildHomeVC] Family Controls authorized! Triggering app name resolution.")
        self.resolveUnknownAppNames()
    }

    /// Fetch app requests and no-drive schedule; called on every viewWillAppear and foreground return.
    func apiCallToGetRequestedList() {

        // Sync blocked-app rules from server into SwiftData first, then re-evaluate shields.
        // This ensures removed/added apps from the parent are reflected immediately
        // without requiring the child to relaunch the app.
        //
        // FIX: fetchAndSyncServerApps runs first and may clear requestedApps (e.g. parent used
        // "Remove All"). fetchRequestedApps previously ran in parallel and could overwrite that
        // cleared state. Now fetchRequestedApps is called inside the completion so it runs AFTER
        // the parent-side sync, preventing the race condition that left stale blocked apps in the
        // child's collection view / request table even after the parent removed them.
        AppBlockerManager.shared.fetchAndSyncServerApps {
            // Fetch requested drive-mode apps AFTER parent-side sync completes so that any
            // apps the parent just removed are not re-injected by the child endpoint response.
            ChildHomeViewModel.shared.fetchRequestedApps { [weak self] success in
                DispatchQueue.main.async {
                    self?.collViewAppList.reloadData()
                    self?.tblViewRequestApps.reloadData()
                    self?.tblViewNoDriveRequest.reloadData()
                    self?.updateEmptyLabels()
                    self?.updateTableHeights()
                    if success {
                        self?.reEvaluateShields()
                        self?.updateArrowsVisibility()
                        self?.resolveUnknownAppNames()
                    }
                }
            }
        }

        // Fetch no-drive mode schedule
        self.apiCallForRequestedNoDriveModeSchedule()

        // Fetch approved no-drive mode apps
        ChildHomeViewModel.shared.fetchApprovedNoDriveModeRequests { [weak self] success in
            DispatchQueue.main.async {
                self?.tblViewNoDriveRequest.reloadData()
                self?.updateEmptyLabels()
                self?.updateTableHeights()

                // is refreshed so that an approved No-Drive window lifts app
                // blocking right away — even if the child is already driving.
                if success {
                    self?.reEvaluateShields()
                    let currentMph = LocationPermissionManager.shared.getSpeedMPH()
                    let isDriving = currentMph > AppBlockerManager.shared.speedLimitMph
                    self?.changeViewAndThemAsPerDriveModeChange(
                        isOn: isDriving, currentSpeedMph: currentMph)
                }
            }
        }

        // Fetch speed limit from server and refresh label immediately once it responds
        AppBlockerManager.shared.fetchSpeedLimit { [weak self] _ in
            guard let self = self else { return }
            let currentMph = LocationPermissionManager.shared.getSpeedMPH()
            let isDriving = currentMph > AppBlockerManager.shared.speedLimitMph
            self.changeViewAndThemAsPerDriveModeChange(isOn: isDriving, currentSpeedMph: currentMph)
        }
    }

    /// Refresh both app list and no-drive schedule list, then reload all views.
    @objc func refreshAppsData() {
        let group = DispatchGroup()

        group.enter()
        ChildHomeViewModel.shared.fetchRequestedApps { [weak self] _ in
            // Add a longer delay before resolution to allow user-provided names to fully settle on server
            // This prevents race conditions where resolution overwrites recently submitted user names
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self?.resolveUnknownAppNames()  // Start local name resolution
            }
            group.leave()
        }

        group.enter()
        ChildHomeViewModel.shared.fetchRequestedNoDriveModeSchedule { _, _ in group.leave() }

        group.enter()
        ChildHomeViewModel.shared.fetchApprovedNoDriveModeRequests { _ in group.leave() }

        group.notify(queue: .main) { [weak self] in
            self?.collViewAppList.reloadData()
            self?.tblViewRequestApps.reloadData()
            self?.tblViewNoDriveRequest.reloadData()
            self?.updateEmptyLabels()
            self?.updateTableHeights()
            self?.updateArrowsVisibility()
            self?.tblViewRequestApps.refreshControl?.endRefreshing()
        }
    }

    /// Show/hide the "no data" labels and "View All" buttons based on current array counts.
    func updateEmptyLabels() {
        let vm = ChildHomeViewModel.shared
        let hasRequests = !vm.normalRequestedApps.isEmpty
        let hasNoDrive = !vm.noDriveRequestedApps.isEmpty
        let hasApproved = !vm.approvedApps.isEmpty

        lblRequestNoFound?.isHidden = hasRequests
        lblNoDriveReqNoFound?.isHidden = hasNoDrive
        lblNoApprovedApps?.isHidden = hasApproved

        // Hide View All buttons when there is nothing to show
        btnViewAllRequests?.isHidden = !hasRequests
        btnViewAllNoDrive?.isHidden = !hasNoDrive
    }

    /// Resize the outer container views so height = actual table content + header + padding.
    func updateTableHeights() {
        // Dispatch to the next run-loop cycle so UIKit finishes laying out
        // auto-sizing cells after reloadData() — reading contentSize in the
        // same cycle can return stale/estimated values, causing clipping.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.tblViewRequestApps.layoutIfNeeded()
            self.tblViewNoDriveRequest.layoutIfNeeded()

            let headerHeight: CGFloat = 44  // title label height inside the container
            let paddingVertical: CGFloat = 16  // top + bottom padding inside the container
            let emptyFallback: CGFloat = 160  // height when empty (shows "no records" label)

            let overhead = headerHeight + paddingVertical

            // contentSize.height = sum of all rendered cell heights; 0 only if no rows
            let reqH =
                self.tblViewRequestApps.contentSize.height > 0
                ? self.tblViewRequestApps.contentSize.height : emptyFallback
            let noDriveH =
                self.tblViewNoDriveRequest.contentSize.height > 0
                ? self.tblViewNoDriveRequest.contentSize.height : emptyFallback

            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.consHeightRequestApps?.constant = reqH + overhead
                self?.consHeightNoDriveRequest?.constant = noDriveH + overhead
                self?.view.layoutIfNeeded()
            }
        }
    }

    //Socket connnections.....
    func getSocketConnectionMessage() {
        GuardianSocketManager.shared.onConnect = {
            print("Connected")
            self.sendLocation()
        }

        GuardianSocketManager.shared.connect()

        // Re-send location+speed on every GPS update, but throttled to once every 5 seconds
        speedObserver = NotificationCenter.default.addObserver(
            forName: .speedDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            if let mph = notification.userInfo?["speedMPH"] as? Double {
                self.handleSpeedUpdate(mph: mph)
            }

            // ── Throttle socket sends to once every 5 seconds ───────────────
            let now = Date()
            if let last = self.lastLocationSentTime, now.timeIntervalSince(last) < 5 {
                return  // Less than 5 seconds since last send — skip
            }
            self.lastLocationSentTime = now
            self.sendLocation()
        }
    }

    func sendLocation() {
        let realSpeedMph = LocationPermissionManager.shared.getSpeedMPH()
        let speedLimit = AppBlockerManager.shared.speedLimitMph
        let isDriving = realSpeedMph > speedLimit

        // Determine drive mode label:
        //   - Below speed limit      → no driveMode label needed (empty string)
        //   - Exceeds speed limit + approved No-Drive request → "No-Drive mode active"
        //   - Exceeds speed limit, no exemption              → "Drive mode active"
        let driveMode: String
        if isDriving {
            driveMode =
                ChildHomeViewModel.shared.hasActiveNoDriveApproval
                ? "No-Drive mode active"
                : "Drive mode active"
        } else {
            driveMode = "Normal"
        }

        // ── Primary path: socket (low-latency, real-time) ──────────────────
        if FeatureFlag.isSocketFeatureEnabled && GuardianSocketManager.shared.isConnected {
            let coord = LocationPermissionManager.shared.getCoordinates()
            GuardianSocketManager.shared.sendLocation(
                latitude: coord?.lat ?? 0,
                longitude: coord?.lng ?? 0,
                speed: realSpeedMph,
                driveMode: driveMode
            )
        }
        // ── Fallback REST API polling is centrally managed by LocationManager now
    }
}

//MARK: - Click Events.....
extension ChildHomeVC {
    @IBAction func tapToChildPrivacy(_ sender: UIButton) {
        let childPolicy = ViewForChildPolicy()
        childPolicy.configure(
            title: self.strPolicyTitle,
            description: self.strPolicyDescription
        )
        childPolicy.show(in: self.view)
    }
    @IBAction func tapToProfile(_ sender: UIControl) {

        let objProfileVC =
            storyBoards.Settings.instantiateViewController(withIdentifier: "ProfileVC")
            as! ProfileVC
        self.navigationController?.pushViewController(objProfileVC, animated: true)
    }
    @IBAction func tapToNotification(_ sender: UIControl) {
        let objNotificationListVC =
            storyBoards.Settings.instantiateViewController(withIdentifier: "NotificationListVC")
            as! NotificationListVC
        objNotificationListVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(objNotificationListVC, animated: true)
    }
    @IBAction func tapToRequestAppAccess(_ sender: UIButton) {
        appDelegate.showHud()
        // Fire-and-forget shield/SwiftData sync in background.
        AppBlockerManager.shared.fetchAndSyncServerApps()
        // Fetch fresh server state — completely replaces requestedApps so deleted
        // apps (a=0 on server) NEVER appear, regardless of stale SwiftData.
        ChildHomeViewModel.shared.fetchRequestedApps { [weak self] _ in
            guard let self = self else { appDelegate.hideHud(); return }
            appDelegate.hideHud()

            var items: [ChildBlockedAppItem] = []
            var seenTokens = Set<ApplicationToken>()

            for app in ChildHomeViewModel.shared.requestedApps {
                // Only show apps still blocked by the parent
                guard (app.a ?? "0") == "1" else { continue }
                // Skip already-approved apps
                let status = (app.currentStatus ?? app.status ?? "").uppercased()
                guard status != "APPROVED" else { continue }
                // Need a valid token
                guard let tokenStr = app.token,
                      let tokenData = Data(base64Encoded: tokenStr),
                      let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData)
                else { continue }
                // Dedup
                guard seenTokens.insert(token).inserted else { continue }

                // Best name: cache → server name field → appName field → placeholder
                let serverName = app.name ?? app.appName ?? ""
                let name = AppNameResolutionCache.cachedName(forTokenStr: tokenStr)
                    ?? (AppNameResolution.isResolved(serverName) ? serverName : nil)
                    ?? "Unknown App"
                items.append(ChildBlockedAppItem(token: token, name: name))
            }

            let swiftUIView = ChildBlockedAppsSwiftUIView(apps: items) { [weak self] token, name in
                self?.dismiss(animated: true) {
                    self?.submitRequestAppAccess(token: token, appName: name)
                }
            } onDismiss: { [weak self] in
                self?.dismiss(animated: true)
            }

            let hc = UIHostingController(rootView: swiftUIView)
            if let sheet = hc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
            self.present(hc, animated: true)
        }
    }

    private func submitRequestAppAccess(token: ApplicationToken, appName: String) {
        guard let tokenStr = (try? JSONEncoder().encode(token))?.base64EncodedString() else { return }
        let initialName = AppNameResolution.isResolved(appName) ? appName : "Unknown App"
        
        appDelegate.showHud()
        self.renderLabelName(for: token, tokenStr: tokenStr) { [weak self] resolvedName in
            let finalName = (resolvedName != nil && AppNameResolution.isResolved(resolvedName!)) ? resolvedName! : initialName
            let icon = self?.extractIconBase64(for: token)
            
            self?.apiCallForRequestAppAccess(token: tokenStr, appName: finalName, type: "app", iconBase64: icon) { success in
                appDelegate.hideHud()
                guard success else { return }
                self?.recentlySubmittedApps[tokenStr] = Date()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self?.refreshAppsData()
                }
            }
        }
    }
    @IBAction func tapToReqNoDriveMode(_ sender: UIButton) {
        self.openNoDriveRequestView()
        //        self.openRequestView(isNoDriveMode: true)
    }
    @IBAction func tapToReqAppsViewAll(_ sender: UIButton) {
        let objNoDriveReqListVC =
            storyBoards.Home.instantiateViewController(withIdentifier: "NoDriveReqListVC")
            as! NoDriveReqListVC
        objNoDriveReqListVC.isFromNoDriveReq = false
        objNoDriveReqListVC.isFromChild = true
        self.navigationController?.pushViewController(objNoDriveReqListVC, animated: true)
    }
    @IBAction func tapToNoDriveReqViewAll(_ sender: UIButton) {
        let objNoDriveReqListVC =
            storyBoards.Home.instantiateViewController(withIdentifier: "NoDriveReqListVC")
            as! NoDriveReqListVC
        objNoDriveReqListVC.isFromNoDriveReq = true
        objNoDriveReqListVC.isFromChild = true
        self.navigationController?.pushViewController(objNoDriveReqListVC, animated: true)
    }
    @IBAction func tapToApprovedAppsViewAll(_ sender: UIButton) {
        let objApprovedListVC =
            storyBoards.Home.instantiateViewController(withIdentifier: "NoDriveReqListVC")
            as! NoDriveReqListVC
        objApprovedListVC.isFromApprovedApps = true
        objApprovedListVC.isFromNoDriveReq = false
        objApprovedListVC.isFromChild = true
        self.navigationController?.pushViewController(objApprovedListVC, animated: true)
    }
    @IBAction func switchDriveModeOnOff(_ sender: UISwitch) {
        if sender.isOn {
            print("Switch is ON")
            self.changeViewAndThemAsPerDriveModeChange(isOn: true)
        } else {
            print("Switch is OFF")
            self.changeViewAndThemAsPerDriveModeChange(isOn: false)
        }
    }

    // MARK: - Speed Update Handler
    func handleSpeedUpdate(mph: Double) {
        let speedLimit = AppBlockerManager.shared.speedLimitMph
        let isDriving = mph > speedLimit
        changeViewAndThemAsPerDriveModeChange(isOn: isDriving, currentSpeedMph: mph)
        // Sync switch visually (read-only; user cannot override GPS)
        switchOnOff.setOn(isDriving, animated: true)
    }

    func changeViewAndThemAsPerDriveModeChange(isOn: Bool, currentSpeedMph: Double? = nil) {
        let speedLimit = AppBlockerManager.shared.speedLimitMph
        let actualMph = currentSpeedMph ?? LocationPermissionManager.shared.getSpeedMPH()
        let displayMph = actualMph > 10.0 ? actualMph : 0.0
        let speedInt = Int(actualMph.rounded())

        self.lblSpeedLimit?.text = "\(speedInt)"
        self.switchDriveMode?.setOn(isOn, animated: true)

        let hasNoDriveApproval = isOn && ChildHomeViewModel.shared.hasActiveNoDriveApproval

        if !isOn {
            // Normal mode
            self.viewForMphRound.backgroundColor = UIColor(named: "lightTransparentColor")
            self.lblNormalMode.text = "Normal Mode"
            self.lblNormalMode.textColor = UIColor(named: "AppGreen")
            self.lblMphSpeed.text =
                "Current Speed: \(speedInt)mph, below the speed limit threshold."
            self.lblMphDetailsDesc.text =
                "All applications are currently accessible. Drive mode will automatically activate when your speed exceeds \(Int(speedLimit)) mph."
            self.viewForSpeedText.backgroundColor = UIColor(named: "AppDarkGreen")
            self.lblMode.text = "Normal Mode"
            self.lblAccessApps.text = "All apps accessible"

        } else if hasNoDriveApproval {
            // No-Drive Mode approved
            let amber = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
            let amberBg = UIColor(red: 0.9, green: 0.5, blue: 0.0, alpha: 1.0)
            self.viewForMphRound.backgroundColor = amber
            self.lblNormalMode.text = "No Drive Mode"
            self.lblNormalMode.textColor = amber
            self.lblMphSpeed.text =
                "Current Speed: \(speedInt)mph, below the speed limit threshold."
            self.lblMphDetailsDesc.text =
                "Your No Drive Mode request has been approved. All apps are accessible during this approved period."
            self.viewForSpeedText.backgroundColor = amberBg
            self.lblMode.text = "No Drive Mode"
            self.lblAccessApps.text = "All apps accessible (No Drive Mode approved)"

        } else {
            // Drive mode active — speed exceeded
            self.viewForMphRound.backgroundColor = UIColor(named: "AppRed")
            self.lblNormalMode.text = "Drive mode active"
            self.lblNormalMode.textColor = UIColor(named: "AppRed")
            self.lblMphSpeed.text = "Current speed \(speedInt)mph, speeding alert triggered."
            self.lblMphDetailsDesc.text =
                "For your safety, access to most apps is restricted while driving. Drive mode will automatically turn off when your speed drops below \(Int(speedLimit)) mph."
            self.viewForSpeedText.backgroundColor = UIColor(named: "AppRed")
            self.lblMode.text = "Drive mode active"
            self.lblAccessApps.text = "Access restricted to approved apps only"
        }
    }

    private func setupArrows() {
        [btnLeft, btnRight].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.tintColor = .darkGray
            $0.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            $0.layer.cornerRadius = 15
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.2
            $0.layer.shadowOffset = CGSize(width: 0, height: 1)
            $0.layer.shadowRadius = 2
            (collViewAppList.superview ?? self.view).addSubview($0)
        }

        btnLeft.setImage(UIImage(systemName: "chevron.left.circle.fill"), for: .normal)
        btnRight.setImage(UIImage(systemName: "chevron.right.circle.fill"), for: .normal)

        NSLayoutConstraint.activate([
            btnLeft.leadingAnchor.constraint(equalTo: collViewAppList.leadingAnchor, constant: 5),
            btnLeft.centerYAnchor.constraint(equalTo: collViewAppList.centerYAnchor),
            btnLeft.widthAnchor.constraint(equalToConstant: 30),
            btnLeft.heightAnchor.constraint(equalToConstant: 30),

            btnRight.trailingAnchor.constraint(
                equalTo: collViewAppList.trailingAnchor, constant: -5),
            btnRight.centerYAnchor.constraint(equalTo: collViewAppList.centerYAnchor),
            btnRight.widthAnchor.constraint(equalToConstant: 30),
            btnRight.heightAnchor.constraint(equalToConstant: 30),
        ])

        btnLeft.addTarget(self, action: #selector(scrollLeft), for: .touchUpInside)
        btnRight.addTarget(self, action: #selector(scrollRight), for: .touchUpInside)

        btnLeft.isHidden = true
        btnRight.isHidden = true
    }

    @objc private func scrollLeft() {
        let currentOffset = collViewAppList.contentOffset.x
        let newOffset = max(0, currentOffset - 200)
        collViewAppList.setContentOffset(CGPoint(x: newOffset, y: 0), animated: true)
    }

    @objc private func scrollRight() {
        let currentOffset = collViewAppList.contentOffset.x
        let maxOffset = collViewAppList.contentSize.width - collViewAppList.frame.width
        let newOffset = min(maxOffset, currentOffset + 200)
        collViewAppList.setContentOffset(CGPoint(x: newOffset, y: 0), animated: true)
    }

    private func updateArrowsVisibility() {
        // Dispatch to ensure layout is updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            let contentWidth = self.collViewAppList.contentSize.width
            let frameWidth = self.collViewAppList.frame.width
            let currentOffset = self.collViewAppList.contentOffset.x

            self.btnLeft.isHidden = currentOffset <= 0
            self.btnRight.isHidden = currentOffset >= (contentWidth - frameWidth - 5)

            // If content fits within frame, hide both
            if contentWidth <= frameWidth {
                self.btnLeft.isHidden = true
                self.btnRight.isHidden = true
            }
        }
    }
}

//MARK: - Custom UIView open....
extension ChildHomeVC {

    // MARK: - No Drive Request Model View..
    private func openNoDriveRequestView() {
        if noDriveView != nil { return }

        let viewPopup = ViewForNoDriveRequest.loadXib()
        viewPopup.frame = self.view.bounds
        viewPopup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewPopup.alpha = 0
        viewPopup.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)

        // Configure dropdown (Reason list)
        viewPopup.setReasonList([
            "Emergency",
            "Medical",
            "Office Work",
            "Personal Work",
            "Other",
        ])

        // Callbacks
        viewPopup.onSubmit = {
            [weak self] (date: Date?, startTime: Date?, endTime: Date?, reason: String?) in
            guard let self = self else { return }

            print("Selected Date:", date as Any)
            print("Selected Start Time:", startTime as Any)
            print("Selected End Time:", endTime as Any)
            print("Selected Reason:", reason as Any)

            if let date = date, let start = startTime, let end = endTime, let reason = reason {
                // Combine date and time
                let calendar = Calendar.current
                var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
                let pickedStart = calendar.dateComponents([.hour, .minute], from: start)
                startComponents.hour = pickedStart.hour
                startComponents.minute = pickedStart.minute

                var endComponents = calendar.dateComponents([.year, .month, .day], from: date)
                let pickedEnd = calendar.dateComponents([.hour, .minute], from: end)
                endComponents.hour = pickedEnd.hour
                endComponents.minute = pickedEnd.minute

                if let combinedStart = calendar.date(from: startComponents),
                    let combinedEnd = calendar.date(from: endComponents)
                {
                    self.apiCallForNoDriveModeRequest(
                        startTime: combinedStart, endTime: combinedEnd, reason: reason)
                }
            } else {
                self.view.makeToast("Please fill all details")
            }

            self.closeNoDriveModeView()
        }

        viewPopup.onCloseView = { [weak self] in
            self?.closeNoDriveModeView()
        }

        // UPDATED tap callbacks (as per new UIView class)
        viewPopup.onTapDate = {
            print("Date field tapped")
        }

        viewPopup.onTapStartTime = {
            print("Start Time field tapped")
        }

        viewPopup.onTapEndTime = {
            print("End Time field tapped")
        }

        viewPopup.onTapReason = {
            print("Reason field tapped")
        }

        self.view.addSubview(viewPopup)
        self.noDriveView = viewPopup

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                viewPopup.alpha = 1
                viewPopup.transform = .identity
            })
    }

    // MARK: - Close View (Animated)
    func closeNoDriveModeView() {

        guard let popup = noDriveView else { return }

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                popup.alpha = 0
                popup.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            },
            completion: { _ in
                popup.removeFromSuperview()
            })

        noDriveView = nil
    }

    // MARK: - Open Common View
    // MARK: - Pre-fetch names then open popup

    /// Fetches the blocked app list, resolves ALL names (server cache first, then
    /// Label(token) sequentially for any still unknown), then opens the popup.
    private func prefetchAndOpenRequestView() {
        guard viewForReqAppSelection == nil else { return }

        appDelegate.showHud()

        self.blockedAppTokens.removeAll()
        self.blockedAppTokenStrings.removeAll()
        self.blockedAppNames.removeAll()

        // Step 1: Fetch fresh server data — this also populates AppNameResolutionCache
        // with any real names the parent already resolved and synced.
        ChildHomeViewModel.shared.fetchRequestedApps { [weak self] _ in
            guard let self = self else { appDelegate.hideHud(); return }
            self.fetchBlockedApps {
                guard !self.blockedAppTokens.isEmpty else {
                    appDelegate.hideHud()
                    self.openRequestView(isNoDriveMode: false)
                    return
                }

                // Step 2: Check how many still need Label(token) resolution
                let stillUnknown = self.blockedAppNames.filter {
                    !AppNameResolution.isResolved($0)
                }.count

                if stillUnknown == 0 {
                    // All names came from server cache — open immediately, no HUD delay
                    print("✅ [Prefetch] All \(self.blockedAppTokens.count) names from server cache — opening instantly")
                    appDelegate.hideHud()
                    self.openRequestView(isNoDriveMode: false)
                } else {
                    // Some names still unknown — resolve sequentially via Label(token)
                    print("🔍 [Prefetch] \(stillUnknown)/\(self.blockedAppTokens.count) names need Label resolution")
                    self.resolveAllNamesSequentially(
                        tokens: self.blockedAppTokens,
                        tokenStrings: self.blockedAppTokenStrings,
                        names: self.blockedAppNames
                    ) { [weak self] resolvedNames in
                        guard let self = self else { appDelegate.hideHud(); return }
                        self.blockedAppNames = resolvedNames
                        appDelegate.hideHud()
                        self.openRequestView(isNoDriveMode: false)
                    }
                }
            }
        }
    }

    /// Resolves names one-by-one using a single off-screen window.
    /// FamilyControlsAgent is single-threaded — sequential is the only reliable approach.
    private func resolveAllNamesSequentially(
        tokens: [ApplicationToken],
        tokenStrings: [String],
        names: [String],
        completion: @escaping ([String]) -> Void
    ) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first
        else { completion(names); return }

        var resolvedNames = names

        // Shared off-screen window — reused for every token
        let offscreen = UIWindow(windowScene: windowScene)
        offscreen.frame = CGRect(x: -2000, y: 0, width: 300, height: 44)
        offscreen.isHidden = false
        offscreen.alpha = 0.01
        offscreen.windowLevel = .normal - 1

        // Find indices that still need resolution
        var pending: [Int] = []
        for (i, token) in tokens.enumerated() {
            let tokenStr = tokenStrings[i]
            let canonicalKey = (try? JSONEncoder().encode(token))?.base64EncodedString() ?? tokenStr
            let currentName = i < resolvedNames.count ? resolvedNames[i] : ""

            if AppNameResolution.isResolved(currentName) { continue }

            // Cache hit — instant
            if let cached = AppNameResolutionCache.cachedName(forTokenStr: canonicalKey)
                ?? AppNameResolutionCache.cachedName(forTokenStr: tokenStr) {
                if i < resolvedNames.count { resolvedNames[i] = cached }
                continue
            }
            pending.append(i)
        }

        guard !pending.isEmpty else {
            offscreen.isHidden = true
            completion(resolvedNames)
            return
        }

        print("🔍 [Prefetch] Resolving \(pending.count) names sequentially...")

        func resolveNext(_ pendingIdx: Int) {
            guard pendingIdx < pending.count else {
                // All done
                offscreen.isHidden = true
                offscreen.rootViewController = nil
                completion(resolvedNames)
                return
            }

            let i = pending[pendingIdx]
            let token = tokens[i]
            let tokenStr = tokenStrings[i]
            let canonicalKey = (try? JSONEncoder().encode(token))?.base64EncodedString() ?? tokenStr

            let hc = UIHostingController(rootView: AnyView(
                Label(token)
                    .labelStyle(.automatic)
                    .frame(width: 300, height: 44)
            ))
            hc.view.frame = offscreen.bounds
            hc.view.backgroundColor = .clear
            offscreen.rootViewController = hc
            offscreen.layoutIfNeeded()

            var attempts = 0
            let maxAttempts = 12  // 12 × 0.4s = ~5s per token

            func check() {
                let name = self.findLabelText(in: hc.view)
                if let name = name, AppNameResolution.isResolved(name) {
                    print("✅ [Prefetch] \(pendingIdx+1)/\(pending.count): '\(name)'")
                    if i < resolvedNames.count { resolvedNames[i] = name }
                    // Cache under canonical key
                    AppNameResolutionCache.store(name: name, forTokenStr: canonicalKey)
                    // Update ChildHomeViewModel for future opens
                    if let vmIdx = ChildHomeViewModel.shared.requestedApps.firstIndex(where: {
                        $0.getApplicationToken() == token
                    }) {
                        ChildHomeViewModel.shared.requestedApps[vmIdx].name = name
                    }
                    ParentControlViewModel.shared.updateAppName(name, for: token)
                    offscreen.rootViewController = nil
                    resolveNext(pendingIdx + 1)
                } else if attempts >= maxAttempts {
                    print("⚠️ [Prefetch] \(pendingIdx+1)/\(pending.count): timed out for \(canonicalKey.prefix(8))")
                    offscreen.rootViewController = nil
                    resolveNext(pendingIdx + 1)
                } else {
                    attempts += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { check() }
                }
            }

            // Give FamilyControlsAgent time to populate the view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { check() }
        }

        resolveNext(0)
    }

    private func openRequestView(isNoDriveMode: Bool) {

        //self.isHideTabbar(isHide: true)
        isHideTabbarGlobally(isHide: true, viewContoller: self)
        // prevent duplicate view
        if viewForReqAppSelection != nil { return }

        let reqView = ViewForReqAppSelection.loadXib()
        reqView.frame = view.bounds
        reqView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        reqView.alpha = 0

        view.addSubview(reqView)
        viewForReqAppSelection = reqView

        // ---------- COMMON UI ----------
        reqView.lblDesc.text =
            isNoDriveMode
            ? "Temporarily disable Drive Mode restrictions"
            : "Your parent will be notified of this request"

        reqView.btnSend.setTitle(
            isNoDriveMode ? "Send Request" : "Submit",
            for: .normal
        )

        // ---------- CONFIG ----------
        if isNoDriveMode {
            reqView.lblTitle.text = "Request No-Drive Mode"
            reqView.configure(
                showSecondField: true,
                firstPlaceholder: "Select Date And Time",
                secondPlaceholder: "Select Reason"
            )
            reqView.setDropdownData(
                ["15 minutes", "30 minutes", "45 minutes", "1 hour", "2 hours"],
                listTitle: "Select Duration"
            )
        } else {
            reqView.lblTitle.text = "Request App Access"
            reqView.configure(
                showSecondField: true,
                firstPlaceholder: "Select App",
                secondPlaceholder: "Enter App Name"
            )
            reqView.expandForLargeList()

            // ── If prefetchAndOpenRequestView already built + resolved the list, use it directly ──
            let alreadyPrefetched = !self.blockedAppTokens.isEmpty

            if !alreadyPrefetched {
                // ── FAST PATH: build list synchronously from cache/SwiftData ─────
                self.blockedAppTokens.removeAll()
                self.blockedAppTokenStrings.removeAll()
                self.blockedAppNames.removeAll()

                var seenTokens = Set<ApplicationToken>()

                // 1. ALWAYS load from SwiftData as the baseline
                AppBlockerManager.shared.ensureModelContainer()
                if let container = AppBlockerManager.shared.modelContainer {
                    let context = ModelContext(container)
                    let swiftDataStatuses = (try? context.fetch(FetchDescriptor<BlockingSelection>()).first)?.appStatuses ?? []
                    for entry in swiftDataStatuses where entry.isBlocked {
                        let isApproved = ChildHomeViewModel.shared.requestedApps.contains { app in
                            guard let tokenStr = app.token, let tokenData = Data(base64Encoded: tokenStr),
                                  let serverToken = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData) else { return false }
                            let status = (app.currentStatus ?? app.status ?? "").uppercased()
                            return serverToken == entry.token && status == "APPROVED"
                        }
                        guard !isApproved else { continue }

                        if let tokenData = try? JSONEncoder().encode(entry.token) {
                            let tokenStr = tokenData.base64EncodedString()
                            if !seenTokens.contains(entry.token) {
                                seenTokens.insert(entry.token)
                                self.blockedAppTokens.append(entry.token)
                                self.blockedAppTokenStrings.append(tokenStr)
                                let bestName = AppNameResolutionCache.cachedName(forTokenStr: tokenStr)
                                    ?? (AppNameResolution.isResolved(entry.appName ?? "") ? entry.appName : nil)
                                    ?? "Unknown App"
                                print("app name \(bestName)")
                                self.blockedAppNames.append(bestName)
                            }
                        }
                    }
                }

                // 2. Improve names for SwiftData-confirmed tokens only.
                // seenTokens was built from SwiftData in Step 1 — the authoritative source.
                // Do NOT add tokens absent from seenTokens; parent deletion is already
                // reflected in SwiftData by fetchAndSyncServerApps (run before this code).
                if ChildHomeViewModel.shared.isAppsDataLoaded {
                    for app in ChildHomeViewModel.shared.requestedApps {
                        let blockFlag = app.a ?? "0"
                        let isBlocked = (blockFlag == "1" || blockFlag == "true" || blockFlag == "TRUE")
                        let status = (app.currentStatus ?? app.status ?? "").uppercased()
                        guard isBlocked, status != "APPROVED" else { continue }

                        let tokenStr = app.token ?? ""
                        guard !tokenStr.isEmpty,
                              let tokenData = Data(base64Encoded: tokenStr),
                              let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData)
                        else { continue }

                        // Only update name for tokens already in SwiftData blocked list.
                        guard seenTokens.contains(token) else {
                            print("⚠️ [openRequestView] Skipping deleted app not in SwiftData: \(app.displayAppName)")
                            continue
                        }

                        let appName = app.displayAppName
                        if AppNameResolution.isResolved(appName),
                           let idx = self.blockedAppTokens.firstIndex(of: token),
                           !AppNameResolution.isResolved(self.blockedAppNames[idx]) {
                            self.blockedAppNames[idx] = appName
                            let canonicalKey = (try? JSONEncoder().encode(token))?.base64EncodedString() ?? tokenStr
                            AppNameResolutionCache.store(name: appName, forTokenStr: canonicalKey)
                        }
                    }
                }
            }

            if !self.blockedAppTokens.isEmpty {
                // Show data immediately — names are already resolved (prefetch path) or best-effort
                reqView.setTokenDropdownData(
                    self.blockedAppTokens,
                    tokenStrings: self.blockedAppTokenStrings,
                    listTitle: "Select App",
                    tokenNames: self.blockedAppNames
                )
                if !alreadyPrefetched {
                    // Only run background resolution if we didn't prefetch
                    self.resolveUnknownNamesAndRefresh(reqView: reqView)
                }
            } else {
                // No data at all — show spinner and wait for server
                reqView.setLoadingState(true)
            }

            let existingTokens = self.blockedAppTokens

            // ── BACKGROUND REFRESH: fetch fresh data silently (only when not prefetched) ──
            // When prefetched, the fetch already happened in prefetchAndOpenRequestView.
            if !alreadyPrefetched {
                ChildHomeViewModel.shared.fetchRequestedApps { [weak self, weak reqView] _ in
                    guard let self = self, let reqView = reqView else { return }
                    self.fetchBlockedApps { [weak self, weak reqView] in
                        guard let self = self, let reqView = reqView else { return }
                        reqView.setLoadingState(false)
                        
                        let listChanged = self.blockedAppTokens != existingTokens
                        let wasShowingSpinner = (reqView.viewforTableList.isHidden || existingTokens.isEmpty)

                        if listChanged || wasShowingSpinner {
                            if self.blockedAppTokens.isEmpty {
                                reqView.setEmptyState(
                                    "No blocked apps.\nAsk your parent to block apps first.")
                            } else {
                                reqView.setTokenDropdownData(
                                    self.blockedAppTokens,
                                    tokenStrings: self.blockedAppTokenStrings,
                                    listTitle: "Select App",
                                    tokenNames: self.blockedAppNames
                                )
                                // Resolve any "Unknown App" names in the background
                                self.resolveUnknownNamesAndRefresh(reqView: reqView)
                            }
                        } else {
                            print("⏭ [ChildHomeVC] Background fetch returned identical list — skipping reload to prevent flash.")
                            // Still try to resolve unknown names even if list didn't change
                            self.resolveUnknownNamesAndRefresh(reqView: reqView)
                        }
                    }
                }
            }
        } // end else (isNoDriveMode == false)
        reqView.onSelect = { [weak self] fieldIndex, value in
            guard self != nil else { return }
            print("Selected:", fieldIndex, value)
            //            if fieldIndex == 0 {
            //                //self.selectedFirstValue = value
            //                print("First selection:", value)
            //            } else {
            //               // self.selectedSecondValue = value
            //                print("Second selection:", value)
            //            }
        }

        reqView.onCloseView = { [weak self] in
            self?.closeRequestView()
        }

        reqView.onSubmit = { [weak self, reqView] first, second, appName in
            if !isNoDriveMode {
                if !first.isEmpty {
                    let type = reqView.selectedType
                    var initialName = (appName == nil || appName!.isEmpty) ? "Unknown" : appName!

                    // 1. If appName passed from dropdown is unresolved, check the persistent cache first
                    if !AppNameResolution.isResolved(initialName),
                       let cached = AppNameResolutionCache.cachedName(forTokenStr: first) {
                        initialName = cached
                    }

                    // 2. Fall back to ViewModel's in-memory resolved name
                    if !AppNameResolution.isResolved(initialName),
                       let tokenData = Data(base64Encoded: first),
                       let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData),
                       let resolvedApp = ChildHomeViewModel.shared.requestedApps.first(where: { $0.getApplicationToken() == token }) {
                        let possibleName = resolvedApp.name ?? resolvedApp.appName ?? ""
                        if AppNameResolution.isResolved(possibleName) {
                            initialName = possibleName
                        }
                    }
                    let submit: (String, String?) -> Void = { [weak self, reqView] finalName, iconBase64 in
                        guard let strongSelf = self else { return }
                        strongSelf.apiCallForRequestAppAccess(
                            token: first,
                            appName: finalName,
                            type: type,
                            iconBase64: iconBase64,
                            userName: second
                        ) { success in
//                    let submit: (String) -> Void = { [weak self, reqView] finalName in
//                        guard let strongSelf = self else { return }
//                        // apiCallForRequestAppAccess handles unresolved names gracefully —
//                        // no hard abort here; the token is the reliable identifier.
//
//                        strongSelf.apiCallForRequestAppAccess(
//                            token: first,
//                            appName: finalName,
//                            type: type
//                        ) { success in
                            guard success else { return }
                            
                            // Use user-provided name (second) for display if token name is unresolved
                            let displayName = (second != nil && !second!.isEmpty) ? second! : finalName
                            print("✅ [Submit] success — appending '\(displayName)'")
                            
                            // Track this app as recently submitted to protect from name resolution
                            strongSelf.recentlySubmittedApps[first] = Date()
                            
                            DispatchQueue.main.async {
                                // Clear the text field after successful submission
                                reqView.clearUserNameTextField()
                                reqView.appendSubmittedApp(tokenString: first, appName: displayName)
                                reqView.removeTokenFromDropdown(tokenString: first)
                                // Delay so server persists App A before we re-fetch
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    [weak strongSelf] in
                                    strongSelf?.refreshAppsData()
                                }
                            }
                        }
                    }

//                    if type == "app" {
//                        if AppNameResolution.isResolved(initialName) {
//                            let icon = self?.extractIconBase64(for: token)
//                            submit(initialName, icon)
//                            return
//                        }
////                        if AppNameResolution.isResolved(initialName) {
////                            submit(initialName)
////                            return
////                        }
//                        guard let tokenData = Data(base64Encoded: first),
//                            let token = try? JSONDecoder().decode(
//                                ApplicationToken.self, from: tokenData)
//                        else {
//                            DispatchQueue.main.async {
//                                self?.view.makeToast(
//                                    "Could not identify the app. Please try again in a moment.")
//                            }
//                            return
//                        }
//                        appDelegate.showHud()
//                        // Pass `first` (the base64 tokenStr) so the cache is populated on success
////                        self?.renderLabelName(for: token, tokenStr: first) { resolvedName in
////                            appDelegate.hideHud()
////                            if let resolvedName = resolvedName,
////                               AppNameResolution.isResolved(resolvedName) {
////                                submit(resolvedName)
////                            } else {
////                                // FamilyControlsAgent didn't respond — submit with "Unknown App".
////                                // The token uniquely identifies the app; parent sees the icon.
////                                print("⚠️ [Submit] Name resolution timed out — submitting with placeholder")
////                                submit("Unknown App")
////                            }
////                        }
//                        self?.renderLabelName(for: token, tokenStr: first) { resolvedName in
//                            appDelegate.hideHud()
//                            if let resolvedName = resolvedName,
//                               AppNameResolution.isResolved(resolvedName) {
//                                let icon = self?.extractIconBase64(for: token)
//                                submit(resolvedName, icon)
//                            } else {
//                                print("⚠️ [Submit] Name resolution timed out — submitting with placeholder")
//                                submit("Unknown App", nil)
//                            }
//                        }
//                        return
//                    }
                    if type == "app" {
                        guard let tokenData = Data(base64Encoded: first),
                            let token = try? JSONDecoder().decode(
                                ApplicationToken.self, from: tokenData)
                        else {
                            DispatchQueue.main.async {
                                self?.view.makeToast(
                                    "Could not identify the app. Please try again in a moment.")
                            }
                            return
                        }

                        if AppNameResolution.isResolved(initialName) {
                            let icon = self?.extractIconBase64(for: token)  // ✅ token is decoded above now
                            submit(initialName, icon)
                            return
                        }

                        appDelegate.showHud()
                        self?.renderLabelName(for: token, tokenStr: first) { resolvedName in
                            appDelegate.hideHud()
                            if let resolvedName = resolvedName,
                               AppNameResolution.isResolved(resolvedName) {
                                let icon = self?.extractIconBase64(for: token)
                                submit(resolvedName, icon)
                            } else {
                                print("⚠️ [Submit] Name resolution timed out — submitting with placeholder")
                                submit("Unknown App", nil)
                            }
                        }
                        return
                    }
//                    submit(initialName)
                    submit(initialName, nil)
                } else {
                    appDelegate.window?.rootViewController?.view.makeToast(
                        "Please select an app from the list")
                }
            } else {
                print("No Drive request submitted")
                self?.closeRequestView()
            }
        }
        UIView.animate(withDuration: 0.25) {
            reqView.alpha = 1
        }

    }
    private func closeRequestView() {
        //        self.isHideTabbar(isHide: false)
        guard let reqView = viewForReqAppSelection else { return }

        UIView.animate(
            withDuration: 0.25,
            animations: {
                reqView.alpha = 0
            }
        ) { [weak self] _ in
            reqView.removeFromSuperview()
            self?.viewForReqAppSelection = nil
        }
    }
}

//MARK: - Collectionview delegates and datasource...
extension ChildHomeVC: UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
{
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 80, height: 100)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return ChildHomeViewModel.shared.approvedApps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: "CellForAppsList", for: indexPath) as! CellForAppsList
        // Guard: approvedApps may be mutated between numberOfItemsInSection and cellForItemAt
        let apps = ChildHomeViewModel.shared.approvedApps
        guard indexPath.item < apps.count else { return cell }
        let app = apps[indexPath.item]
        cell.configure(app: app, isApproved: true, isFromChild: true)

        return cell
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == collViewAppList {
            self.updateArrowsVisibility()
        }
    }
}
//MARK: - TableView Delegate and DataSources
extension ChildHomeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tblViewRequestApps {
            let total = ChildHomeViewModel.shared.normalRequestedApps.count
            // Show max 3 app rows + 1 extra "+N more" row when total > 3
            return total > 3 ? 4 : total
        } else {
            return min(ChildHomeViewModel.shared.noDriveRequestedApps.count, 3)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let total = ChildHomeViewModel.shared.normalRequestedApps.count

        // "+N more" card — shown as the 4th row when there are more than 3 apps
        if tableView == self.tblViewRequestApps && total > 3 && indexPath.row == 3 {
            let moreCell = tableView.dequeueReusableCell(withIdentifier: "CellForMoreApps")
                ?? UITableViewCell(style: .default, reuseIdentifier: "CellForMoreApps")
            moreCell.selectionStyle = .none
            moreCell.backgroundColor = .clear
            moreCell.contentView.subviews.forEach { $0.removeFromSuperview() }

            let remaining = total - 3
            let card = UIView()
            card.backgroundColor = UIColor(named: "AppLightBlue")?.withAlphaComponent(0.15)
                ?? UIColor.systemBlue.withAlphaComponent(0.10)
            card.layer.cornerRadius = 12
            card.layer.borderWidth = 1
            card.layer.borderColor = (UIColor(named: "AppDarkBlue") ?? UIColor.systemBlue)
                .withAlphaComponent(0.25).cgColor
            card.translatesAutoresizingMaskIntoConstraints = false
            moreCell.contentView.addSubview(card)

            let lbl = UILabel()
            lbl.text = "+\(remaining) more"
            lbl.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            lbl.textColor = UIColor(named: "AppDarkBlue") ?? .systemBlue
            lbl.textAlignment = .center
            lbl.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(lbl)

            let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrow.tintColor = UIColor(named: "AppDarkBlue") ?? .systemBlue
            arrow.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(arrow)

            NSLayoutConstraint.activate([
                card.leadingAnchor.constraint(equalTo: moreCell.contentView.leadingAnchor, constant: 12),
                card.trailingAnchor.constraint(equalTo: moreCell.contentView.trailingAnchor, constant: -12),
                card.topAnchor.constraint(equalTo: moreCell.contentView.topAnchor, constant: 4),
                card.bottomAnchor.constraint(equalTo: moreCell.contentView.bottomAnchor, constant: -4),
                card.heightAnchor.constraint(equalToConstant: 48),

                lbl.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                lbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),

                arrow.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                arrow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                arrow.widthAnchor.constraint(equalToConstant: 14),
                arrow.heightAnchor.constraint(equalToConstant: 14),
            ])
            return moreCell
        }

        let cell =
            tableView.dequeueReusableCell(withIdentifier: "CellForRequestApps")
            as! CellForRequestApps
        cell.cellDelegate = self
        cell.cons_lblApproved_width.constant = 0
        cell.btnApproved.isHidden = true

        if tableView == self.tblViewRequestApps {
            let data = ChildHomeViewModel.shared.normalRequestedApps[indexPath.row]
            cell.setCellDataWihModelData(
                data: data, aIndex: data.id ?? indexPath.row, isTblReq: true)
            // Store actual request ID in tag so didTapCross receives it unambiguously
            cell.btnCross.tag = data.id ?? -1
            let status = (data.currentStatus ?? data.status ?? "").uppercased()
            switch status {
            case "REJECTED":
                cell.lblStatus.text = "REJECTED"
                cell.lblStatus.textColor = UIColor.systemOrange
                cell.lblStatus.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
                cell.btnCross.isHidden = true  // already rejected — nothing to cancel
            case "APPROVED":
                cell.lblStatus.text = "APPROVED"
                cell.lblStatus.textColor = UIColor(named: "AppGreen") ?? UIColor.systemGreen
                cell.lblStatus.backgroundColor = (UIColor(named: "AppGreen") ?? UIColor.systemGreen)
                    .withAlphaComponent(0.15)
                cell.btnCross.isHidden = true  // already approved — nothing to cancel
            default:  // REQUESTED
                cell.btnCross.isHidden = false  // pending — can cancel
            }
        } else {
            let data = ChildHomeViewModel.shared.noDriveRequestedApps[indexPath.row]
            cell.setCellDataWihModelData(
                data: data, aIndex: data.id ?? indexPath.row, isTblReq: false)
            // Store actual request ID in tag so didTapCross receives it unambiguously
            cell.btnCross.tag = data.id ?? -1
            let status = (data.currentStatus ?? data.status ?? "").uppercased()
            switch status {
            case "APPROVED":
                cell.lblStatus.text = "APPROVED"
                cell.lblStatus.textColor = UIColor(named: "AppGreen") ?? UIColor.systemGreen
                cell.lblStatus.backgroundColor = (UIColor(named: "AppGreen") ?? UIColor.systemGreen)
                    .withAlphaComponent(0.15)
                cell.btnCross.isHidden = true
            case "REJECTED":
                cell.lblStatus.text = "REJECTED"
                cell.lblStatus.textColor = UIColor.systemOrange
                cell.lblStatus.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
                cell.btnCross.isHidden = true
            default:
                cell.btnCross.isHidden = false
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Tap on the "+N more" card → open the full requested apps list
        if tableView == self.tblViewRequestApps,
           ChildHomeViewModel.shared.normalRequestedApps.count > 3,
           indexPath.row == 3 {
            tapToReqAppsViewAll(btnViewAllRequests)
        }
    }
    func tableView(
        _ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath
    ) {}
}

// MARK: - Cancel Request (CellForRequestAppsDelegate)
extension ChildHomeVC: CellForRequestAppsDelegate {
    func didTapCross(index: Int) {
        // `index` is the actual request ID stored as btnCross.tag
        let requestId = index
        guard requestId > 0 else {
            self.view.makeToast("Unable to cancel: invalid request ID")
            return
        }

        let vm = ChildHomeViewModel.shared
        // If this ID belongs to a schedule request, use the no-drive endpoint
        let isSchedule = vm.noDriveModeScheduleList.contains { $0.id == requestId }
        print("🔍 [Cancel] requestId=\(requestId) isSchedule=\(isSchedule)")

        appDelegate.showHud()
        if isSchedule {
            vm.cancelNoDriveModeRequest(requestId: requestId) { [weak self] success in
                DispatchQueue.main.async {
                    appDelegate.hideHud()
                    self?.view.makeToast(
                        success ? "Request cancelled successfully" : "Failed to cancel request")
                    if success {
                        // Remove immediately from local list
                        ChildHomeViewModel.shared.requestedApps.removeAll { $0.id == requestId }
                        self?.tblViewNoDriveRequest.reloadData()
                        self?.updateEmptyLabels()
                        self?.updateTableHeights()
                        self?.refreshAppsData()
                    }
                }
            }
        } else {
            vm.cancelAppRequest(requestId: requestId) { [weak self] success in
                DispatchQueue.main.async {
                    appDelegate.hideHud()
                    self?.view.makeToast(
                        success ? "Request cancelled successfully" : "Failed to cancel request")
                    if success {
                        // Remove immediately from local list so UI updates without waiting
                        // for the server re-fetch (avoids the item lingering in the list)
                        ChildHomeViewModel.shared.requestedApps.removeAll { $0.id == requestId }
                        self?.tblViewRequestApps.reloadData()
                        self?.updateEmptyLabels()
                        self?.updateTableHeights()
                        self?.refreshAppsData()
                    }
                }
            }
        }
    }

    func didTapApprove(index: Int) {
        // Child cannot approve — no-op
    }
}
//MARK: - Api callings...
extension ChildHomeVC {
    //MARK: - Add Child.....
    func apiCallForSendLocationToParent() {
        if let coord = LocationPermissionManager.shared.getCoordinates() {
            print(coord.lat, coord.lng)
            let speedMph = LocationPermissionManager.shared.getSpeedMPH()
            let speedLimit = AppBlockerManager.shared.speedLimitMph
            let isDriving = speedMph > speedLimit

            let driveMode: String
            if isDriving {
                driveMode =
                    ChildHomeViewModel.shared.hasActiveNoDriveApproval
                    ? "No-Drive mode active"
                    : "Drive mode active"
            } else {
                driveMode = "Normal"
            }

            let strUrl =
                WebURL.childAccountApi + "\(AppState.sharedInstance.user!.userId)/current-location"

            let param: [String: Any] = [
                "latitude": coord.lat,
                "longitude": coord.lng,
                "speed": speedMph,
                "driveMode": driveMode,
            ]

            apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: strUrl, param: param) {
                (isSuccess, responseDict, statusCode) in
                appDelegate.hideHud()
                if isSuccess {}
            }
        }
    }
}

// MARK: - App Access Request Logic
extension ChildHomeVC {
    private func extractIconBase64(for token: ApplicationToken) -> String? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow })
        else { return nil }

        let hc = UIHostingController(rootView: AnyView(
            Label(token)
                .labelStyle(.automatic)
                .frame(width: 300, height: 44)
        ))
        hc.view.frame = CGRect(x: -2000, y: 0, width: 300, height: 44)
        hc.view.backgroundColor = .clear
        hc.view.alpha = 0.01
        window.addSubview(hc.view)
        hc.view.layoutIfNeeded()

        // Small wait already happened during name resolution — layout is ready
        let image = findLabelImage(in: hc.view)
        hc.view.removeFromSuperview()

        guard let img = image,
              let data = img.jpegData(compressionQuality: 0.8)
        else { return nil }

        return data.base64EncodedString()
    }
    /// Reads the persisted blocked-app selection from SwiftData and re-applies shields,
    /// excluding any apps that are already approved in ChildHomeViewModel.
    /// Called every time the child home screen appears so shields stay in sync.
    func reEvaluateShields() {
        AppBlockerManager.shared.ensureModelContainer()

        guard let container = AppBlockerManager.shared.modelContainer else {
            print("[Shield] ModelContainer not available, skipping re-evaluation.")
            return
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<BlockingSelection>()

        do {
            let results = try context.fetch(descriptor)
            guard let saved = results.first else {
                print("[Shield] No saved BlockingSelection found.")
                return
            }

            // Rebuild the blocked selection from persisted app statuses
            var selection = saved.selection
            let blockedTokens = saved.appStatuses.filter { $0.isBlocked }.map { $0.token }
            selection.applicationTokens = Set(blockedTokens)

            print("[Shield] Re-applying shields for \(blockedTokens.count) blocked apps.")

            // AppBlockerManager will automatically subtract ChildHomeViewModel.approvedApps
            AppBlockerManager.shared.startMonitoring(selection: selection)

        } catch {
            print("[Shield] Failed to read BlockingSelection: \(error)")
        }
    }

    /// Populates `blockedAppsMap` for the \"Request App Access\" dropdown.
    ///
    /// **Source of truth:** `ChildHomeViewModel.shared.requestedApps` — already fetched
    /// from `GET /child/{userId}/apps` (child-auth, `"apps"` key) on every `viewWillAppear`.
    /// Each entry in that list represents an app the parent has configured; the `a` field
    /// indicates whether it is blocked (`"1"`) and `currentStatus`/`status` tells us
    /// whether the child has already requested or been approved for it.
    ///
    /// Eligible for the dropdown = blocked by parent (`a == "1"`)
    ///                             AND status is neither APPROVED nor REQUESTED.
    ///
    /// If `requestedApps` is still empty (e.g. first-ever open before the background
    /// fetch finishes), we call the server ourselves and wait for the response before
    /// building the map. SwiftData is a last-resort fallback.
    ///
    /// Result is delivered via `completion` on the main thread.
    func fetchBlockedApps(completion: @escaping () -> Void = {}) {
        self.blockedAppsMap.removeAll()
        self.blockedAppTokens.removeAll()
        self.blockedAppTokenStrings.removeAll()
        self.blockedAppNames.removeAll()

        // Helper: deduplicate by decoded ApplicationToken (Hashable) so the same
        // app stored multiple times on the server only appears once in the dropdown.
        var seenAppTokens = Set<ApplicationToken>()
        let addToken: (ApplicationToken, String, String?) -> Void = {
            [weak self] token, tokenStr, name in
            guard let self = self else { return }
            guard !seenAppTokens.contains(token) else { return }
            seenAppTokens.insert(token)
            self.blockedAppTokens.append(token)
            self.blockedAppTokenStrings.append(tokenStr)
            // Always use the re-encoded token as the canonical cache key so that
            // names stored by renderLabelName (which re-encodes) are found here too.
            let canonicalKey = (try? JSONEncoder().encode(token))?.base64EncodedString() ?? tokenStr

            // If the server/SwiftData already has a real name, cache it now so
            // prefetchAndOpenRequestView skips Label(token) resolution entirely.
            if let serverName = name, AppNameResolution.isResolved(serverName) {
                AppNameResolutionCache.store(name: serverName, forTokenStr: canonicalKey)
                AppNameResolutionCache.store(name: serverName, forTokenStr: tokenStr)
            }

            let cachedName = AppNameResolutionCache.cachedName(forTokenStr: canonicalKey)
                ?? AppNameResolutionCache.cachedName(forTokenStr: tokenStr)
            let bestName = cachedName ?? (AppNameResolution.isResolved(name ?? "") ? name : nil) ?? "Unknown App"
            self.blockedAppNames.append(bestName)
        }

        // 1. ALWAYS load from SwiftData as the baseline
        AppBlockerManager.shared.ensureModelContainer()
        if let container = AppBlockerManager.shared.modelContainer {
            let context = ModelContext(container)
            let swiftDataStatuses =
                (try? context.fetch(FetchDescriptor<BlockingSelection>()).first)?.appStatuses ?? []
            for entry in swiftDataStatuses where entry.isBlocked {
                // Exclude if it's explicitly marked as APPROVED in the server cache
                let isApproved = ChildHomeViewModel.shared.requestedApps.contains { app in
                    guard let tokenStr = app.token, let tokenData = Data(base64Encoded: tokenStr),
                          let serverToken = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData) else { return false }
                    let status = (app.currentStatus ?? app.status ?? "").uppercased()
                    return serverToken == entry.token && status == "APPROVED"
                }
                guard !isApproved else { continue }

                if let tokenData = try? JSONEncoder().encode(entry.token) {
                    let tokenStr = tokenData.base64EncodedString()
                    addToken(entry.token, tokenStr, entry.appName)
                }
            }
        }

        // 2. Improve names for SwiftData-confirmed tokens using the server cache.
        // We deliberately do NOT add tokens absent from SwiftData (seenAppTokens).
        // fetchAndSyncServerApps runs before fetchBlockedApps and is the authoritative
        // parent-side state — any app the parent deleted is already absent from SwiftData.
        // Adding tokens from requestedApps regardless of SwiftData was the root cause of
        // deleted apps re-appearing in the "Request App Access" popup and ParentControlView.
        if ChildHomeViewModel.shared.isAppsDataLoaded {
            for app in ChildHomeViewModel.shared.requestedApps {
                let blockFlag = app.a ?? "0"
                let isBlocked = (blockFlag == "1" || blockFlag == "true" || blockFlag == "TRUE")
                let status = (app.currentStatus ?? app.status ?? "").uppercased()
                if !isBlocked { continue }
                if status == "APPROVED" { continue }

                let tokenStr = app.token ?? ""
                guard !tokenStr.isEmpty, Data(base64Encoded: tokenStr) != nil else { continue }
                guard let tokenData = Data(base64Encoded: tokenStr),
                      let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData)
                else { continue }

                // Only process tokens SwiftData (Step 1) already confirmed as blocked.
                // If not in seenAppTokens, the parent deleted this app — skip entirely.
                guard seenAppTokens.contains(token) else {
                    print("⚠️ [fetchBlockedApps] Skipping deleted app not in SwiftData: \(app.displayAppName)")
                    continue
                }

                // Token is already in the list — only improve the name if server has a better one.
                let appName = app.displayAppName
                if AppNameResolution.isResolved(appName),
                   let idx = self.blockedAppTokens.firstIndex(of: token),
                   !AppNameResolution.isResolved(self.blockedAppNames[idx]) {
                    self.blockedAppNames[idx] = appName
                    AppNameResolutionCache.store(name: appName, forTokenStr: tokenStr)
                }
            }
        }

        if !blockedAppTokens.isEmpty {
            DispatchQueue.main.async { completion() }
            return
        }

        // Last resort — fetch directly from server
        guard let userId = AppState.sharedInstance.user?.userId, !userId.isEmpty else {
            DispatchQueue.main.async { completion() }
            return
        }

        let url = WebURL.childAccountApi + "\(userId)/apps"
        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: url, aParams: [:]) {
            [weak self] (isSuccess, responseDict) in
            guard let self = self else { return }

            if isSuccess,
                let appsDataArray = responseDict["apps"] as? [[String: Any]],
                let jsonData = try? JSONSerialization.data(withJSONObject: appsDataArray),
                let decoded = try? JSONDecoder().decode([ChildRequestedApp].self, from: jsonData)
            {
                ChildHomeViewModel.shared.requestedApps = decoded
                for app in decoded {
                    let blockFlag = app.a ?? "0"
                    let isBlocked = (blockFlag == "1" || blockFlag == "true" || blockFlag == "TRUE")
                    let status = (app.currentStatus ?? app.status ?? "").uppercased()
                    guard isBlocked else { continue }
                    guard status != "APPROVED" && status != "REQUESTED" else { continue }

                    let appName = app.displayAppName
                    let tokenStr = app.token ?? ""
                    guard !tokenStr.isEmpty, Data(base64Encoded: tokenStr) != nil else { continue }
                    if let tokenData = Data(base64Encoded: tokenStr),
                        let token = try? JSONDecoder().decode(
                            ApplicationToken.self, from: tokenData)
                    {
                        addToken(token, tokenStr, app.displayAppName)
                    }
                }
            }
            DispatchQueue.main.async { completion() }
        }
    }

    /// Resolves app names locally for any app in `requestedApps` or `blockedAppTokens`
    /// that has an \"Unknown\" name. This ensures the child sees real app names
    /// even if the parent synced them before they were resolved on the parent device.
    //    func resolveUnknownAppNames() {
    //        let appsWithUnknownNames = ChildHomeViewModel.shared.requestedApps.enumerated().filter {
    //            let name = $1.displayAppName
    //            return name == "Unknown" || name == "Unknown App" || name.hasPrefix("com.")
    //        }
    //
    //        guard !appsWithUnknownNames.isEmpty else { return }
    //
    //        // Increase batch size for faster resolution
    //        let batchSize = 10
    //        var index = 0
    //
    //        func processNextBatch() {
    //            guard index < appsWithUnknownNames.count else {
    //                self.collViewAppList.reloadData()
    //                self.tblViewRequestApps.reloadData()
    //                // Sync the newly resolved names back to the server
    //                if ParentControlViewModel.shared.hasChanges {
    //                    ParentControlViewModel.shared.syncAppsWithServer()
    //                }
    //                return
    //            }
    //            let end = min(index + batchSize, appsWithUnknownNames.count)
    //            let batch = appsWithUnknownNames[index..<end]
    //            index = end
    //
    //            var batchPending = batch.count
    //            for (originalIndex, app) in batch {
    //                guard let token = app.getApplicationToken() else {
    //                    batchPending -= 1; continue
    //                }
    //
    //                renderLabelName(for: token) { [weak self] name in
    //                    if let name = name, !name.isEmpty, name != "Unknown" {
    //                        DispatchQueue.main.async {
    //                            ChildHomeViewModel.shared.requestedApps[originalIndex].name = name
    //                            if let mapIndex = self?.blockedAppTokens.firstIndex(of: token) {
    //                                self?.blockedAppNames[mapIndex] = name
    //                            }
    //                            // Also update ParentControlViewModel so the Shields and Parent UI get the name
    //                            ParentControlViewModel.shared.updateAppName(name, for: token)
    //                            // Mark that we have changes so the next background sync or manual save picks it up
    //                            ParentControlViewModel.shared.hasChanges = true
    //                        }
    //                    }
    //
    //                    batchPending -= 1
    //                    if batchPending == 0 {
    //                        // Small pause between batches to keep main thread responsive
    //                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    //                            processNextBatch()
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //
    //        processNextBatch()
    //    }
    /// Resolves unknown app names in parallel batches (8 at a time), captures icon + title,
    /// then syncs all resolved names to the server in a single bulk PUT.
    func resolveUnknownAppNames() {
        // Clean up old entries from recently submitted apps tracking
        let now = Date()
        recentlySubmittedApps = recentlySubmittedApps.filter { 
            now.timeIntervalSince($0.value) < recentSubmissionProtectionWindow 
        }
        
        var appsNeedingResolution: [ChildRequestedApp] = ChildHomeViewModel.shared.requestedApps.filter { app in
            let name = app.name ?? app.appName
            let token = app.getApplicationToken()
            let tokenStr = token.flatMap { tokenData in
                try? JSONEncoder().encode(tokenData).base64EncodedString()
            } ?? ""
            
            // Skip resolution if this app was recently submitted by the user
            if recentlySubmittedApps[tokenStr] != nil {
                print("🛡️ [Child] Skipping resolution for recently submitted app: '\(name ?? "nil")' (token: \(tokenStr.prefix(8)))")
                return false
            }
            
            // Only resolve if it's truly an unresolved placeholder, not a user-provided name
            return AppNameResolution.isUnresolved(name)
        }

        // Also retrieve and merge unresolved blocked apps from ParentControlViewModel
        ParentControlViewModel.shared.loadData()
        let blockedUnresolved = ParentControlViewModel.shared.appStatuses.filter { status in
            let tokenData = try? JSONEncoder().encode(status.token)
            let tokenStr = tokenData?.base64EncodedString() ?? ""
            if recentlySubmittedApps[tokenStr] != nil {
                return false
            }
            return AppNameResolution.isUnresolved(status.appName)
        }.map { status -> ChildRequestedApp in
            let tokenData = try? JSONEncoder().encode(status.token)
            let tokenStr = tokenData?.base64EncodedString() ?? ""
            return ChildRequestedApp(appName: status.appName, token: tokenStr)
        }

        // Add to appsNeedingResolution if not already present
        for app in blockedUnresolved {
            if !appsNeedingResolution.contains(where: { $0.getApplicationToken() == app.getApplicationToken() }) {
                appsNeedingResolution.append(app)
            }
        }

        guard !appsNeedingResolution.isEmpty else { 
            print("🔍 [Child] No apps need resolution - all have valid names or are recently submitted")
            return 
        }

        guard
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first(where: { $0.isKeyWindow })
        else { return }

        print("🔍 [Child] Resolving \(appsNeedingResolution.count) apps with unresolved names in parallel batches")
        
        // Log which apps are being resolved
        for app in appsNeedingResolution {
            let name = app.name ?? app.appName ?? "nil"
            print("🔍 [Child] Will resolve: '\(name)' (unresolved placeholder)")
        }

        let batchSize = 8
        let maxPolls = 6

        let batches = stride(from: 0, to: appsNeedingResolution.count, by: batchSize).map {
            Array(appsNeedingResolution[$0..<min($0 + batchSize, appsNeedingResolution.count)])
        }

        var bulkResolved: [(token: ApplicationToken, tokenStr: String, name: String)] = []

        func processBatch(_ batchIdx: Int) {
            guard batchIdx < batches.count else {
                DispatchQueue.main.async { [weak self] in
                    self?.collViewAppList.reloadData()
                    self?.tblViewRequestApps.reloadData()
                    self?.bulkSyncResolvedNames(bulkResolved)
                    
                    if ParentControlViewModel.shared.hasChanges {
                        ParentControlViewModel.shared.syncAppsWithServer()
                    }
                }
                return
            }

            let batch = batches[batchIdx]
            let group = DispatchGroup()
            var batchResolved: [(token: ApplicationToken, tokenStr: String, name: String)] = []
            let lock = NSLock()

            for app in batch {
                guard let token = app.getApplicationToken(),
                    let tokenData = try? JSONEncoder().encode(token)
                else { continue }
                let tokenStr = tokenData.base64EncodedString()

                group.enter()

                let hc = UIHostingController(
                    rootView: AnyView(
                        Label(token)
                            .labelStyle(.automatic)
                            .frame(width: 300, height: 44)
                    )
                )
                hc.view.frame = CGRect(x: -1200, y: 0, width: 300, height: 44)
                hc.view.backgroundColor = .clear
                hc.view.alpha = 0.01
                window.addSubview(hc.view)
                hc.view.layoutIfNeeded()

                var polls = 0
                func poll() {
                    let name = self.findLabelText(in: hc.view)
                    let icon = self.findLabelImage(in: hc.view)
                    let isResolved = name.map { AppNameResolution.isResolved($0) } ?? false

                    if isResolved, let resolvedName = name {
                        hc.view.removeFromSuperview()

                        DispatchQueue.main.async {
                            if let idx = ChildHomeViewModel.shared.requestedApps.firstIndex(where: {
                                $0.getApplicationToken() == token
                            }) {
                                let currentName = ChildHomeViewModel.shared.requestedApps[idx].name
                                
                                // Double-check: Don't overwrite if this app was recently submitted
                                if self.recentlySubmittedApps[tokenStr] != nil {
                                    print("🛡️ [Child] Skipping resolution update - app was recently submitted: '\(currentName ?? "nil")'")
                                    group.leave()
                                    return
                                }
                                
                                // Only update if current name is still unresolved (don't overwrite user names)
                                if AppNameResolution.isUnresolved(currentName) {
                                    print("✅ [Child] Resolved '\(currentName ?? "nil")' → '\(resolvedName)'")
                                    ChildHomeViewModel.shared.requestedApps[idx].name = resolvedName
                                } else {
                                    print("ℹ️ [Child] Skipping resolution - name already resolved: '\(currentName ?? "nil")'")
                                }
                            }
                            if let mapIdx = self.blockedAppTokens.firstIndex(of: token) {
                                let currentName = self.blockedAppNames[mapIdx]
                                if AppNameResolution.isUnresolved(currentName) {
                                    self.blockedAppNames[mapIdx] = resolvedName
                                }
                            }
                            ParentControlViewModel.shared.updateAppName(resolvedName, for: token)
                            ParentControlViewModel.shared.hasChanges = true
                            if let icon = icon {
                                ParentControlViewModel.shared.storeIcon(icon, forKey: tokenStr)
                            }
                        }

                        lock.lock()
                        batchResolved.append((token, tokenStr, resolvedName))
                        lock.unlock()
                        group.leave()
                    } else if polls >= maxPolls {
                        print("⚠️ [Child] Timeout for token \(tokenStr.prefix(8))")
                        hc.view.removeFromSuperview()
                        group.leave()
                    } else {
                        polls += 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { poll() }
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { poll() }
            }

            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                bulkResolved.append(contentsOf: batchResolved)
                self.collViewAppList.reloadData()
                self.tblViewRequestApps.reloadData()
                processBatch(batchIdx + 1)
            }
        }

        processBatch(0)
    }

    private func findLabelImage(in view: UIView) -> UIImage? {
        if let iv = view as? UIImageView, let img = iv.image { return img }
        for sub in view.subviews {
            if let found = findLabelImage(in: sub) { return found }
        }
        return nil
    }

    /// One fetch + one PUT after all names are resolved — avoids per-app syncSingleApp calls.
    private func bulkSyncResolvedNames(
        _ resolved: [(token: ApplicationToken, tokenStr: String, name: String)]
    ) {
        guard !resolved.isEmpty else { return }
        guard let userId = AppState.sharedInstance.user?.userId else { return }

        let getUrl = WebURL.childAccountApi + "\(userId)/apps"
        let syncUrl = WebURL.childAppsSync(childId: userId)

        var nameMap: [String: String] = [:]
        for item in resolved { nameMap[item.tokenStr] = item.name }

        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: getUrl, aParams: [:]) {
            [weak self] (fetchSuccess, responseDict) in
            guard let self = self else { return }

            var mergedApps: [[String: Any]] = []

            if fetchSuccess, let existing = responseDict["apps"] as? [[String: Any]] {
                for var app in existing {
                    let tok = app["token"] as? String ?? app["_id"] as? String ?? ""
                    let currentName = app["name"] as? String ?? ""
                    
                    // Don't overwrite recently submitted app names
                    if self.recentlySubmittedApps[tok] != nil {
                        print("🛡️ [BulkSync] Preserving recently submitted app name: '\(currentName)' (token: \(tok.prefix(8)))")
                        mergedApps.append(app)
                        continue
                    }
                    
                    if let resolvedName = nameMap[tok], AppNameResolution.isResolved(resolvedName) {
                        // Only update if current name is unresolved (don't overwrite user names)
                        if AppNameResolution.isUnresolved(currentName) {
                            print("✅ [BulkSync] Updating '\(currentName)' → '\(resolvedName)'")
                            app["name"] = resolvedName
                        } else {
                            print("ℹ️ [BulkSync] Preserving user name: '\(currentName)'")
                        }
                    }
                    mergedApps.append(app)
                }
                let serverTokens = Set(
                    existing.compactMap { $0["token"] as? String ?? $0["_id"] as? String })
                for item in resolved where !serverTokens.contains(item.tokenStr) {
                    mergedApps.append([
                        "name": item.name,
                        "token": item.tokenStr,
                        "deviceType": "IOS",
                        "icon": "",
                        "a": "1",
                    ])
                }
            } else {
                mergedApps = resolved.map {
                    [
                        "name": $0.name,
                        "token": $0.tokenStr,
                        "deviceType": "IOS",
                        "icon": "",
                        "a": "1",
                    ]
                }
            }

            guard !mergedApps.isEmpty else { return }

            print("📤 [BulkSync] Syncing \(resolved.count) resolved names in 1 API call")
            self.apiCallViewModel.putMethodApiCallWithDisctionaryResponse(
                aUrl: syncUrl,
                param: ["apps": mergedApps]
            ) { (isSuccess, _) in
                print(
                    isSuccess
                        ? "✅ [BulkSync] Done — \(resolved.count) names synced"
                        : "❌ [BulkSync] Failed")
            }
        }
    }
    //    func resolveUnknownAppNames() {
    //        let appsNeedingResolution = ChildHomeViewModel.shared.requestedApps.enumerated().filter {
    //            let name = $1.displayAppName
    //            return name == "Unknown" || name == "Unknown App" || name.hasPrefix("com.") || name.isEmpty
    //        }
    //
    //        guard !appsNeedingResolution.isEmpty else { return }
    //        guard let parentView = self.view else { return }
    //
    //        print("🔍 Resolving \(appsNeedingResolution.count) app names...")
    //
    //        // Process in batches of 20 simultaneously
    //        let batchSize = 20
    //        let batches = stride(from: 0, to: appsNeedingResolution.count, by: batchSize).map {
    //            Array(appsNeedingResolution[$0..<min($0 + batchSize, appsNeedingResolution.count)])
    //        }
    //
    //        func processBatch(_ batchIndex: Int) {
    //            guard batchIndex < batches.count else {
    //                // All done — reload UI and sync to server
    //                DispatchQueue.main.async {
    //                    self.collViewAppList.reloadData()
    //                    self.tblViewRequestApps.reloadData()
    //                    if ParentControlViewModel.shared.hasChanges {
    //                        ParentControlViewModel.shared.syncAppsWithServer()
    //                    }
    //                }
    //                return
    //            }
    //
    //            let batch = batches[batchIndex]
    //            var resolved = 0
    //
    //            for (originalIndex, app) in batch {
    //                guard let token = app.getApplicationToken() else {
    //                    resolved += 1
    //                    if resolved == batch.count { processBatch(batchIndex + 1) }
    //                    continue
    //                }
    //
    //                // Each token gets its own short-lived host — but all 20 run in parallel
    //                let hc = UIHostingController(rootView: AnyView(
    //                    Label(token).labelStyle(.titleOnly).frame(width: 300, height: 44)
    //                ))
    //                hc.view.frame = CGRect(x: -9999, y: -9999, width: 300, height: 44)
    //                hc.view.alpha = 0.01
    //                parentView.addSubview(hc.view)
    //                hc.view.layoutIfNeeded()
    //
    //                // Shorter timeout: 20 parallel = still only 0.8s per batch of 20
    //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
    //                    guard let self = self else { return }
    //                    let name = self.findLabelText(in: hc.view)
    //                    hc.view.removeFromSuperview()
    //
    //                    if let name = name, !name.isEmpty, name != "Unknown" {
    //                        // Guard against stale index: array may have been replaced by a
    //                        // concurrent fetchRequestedApps call during the 0.8s wait.
    //                        let apps = ChildHomeViewModel.shared.requestedApps
    //                        if originalIndex < apps.count {
    //                            ChildHomeViewModel.shared.requestedApps[originalIndex].name = name
    //                        }
    //                        if let mapIndex = self.blockedAppTokens.firstIndex(of: token) {
    //                            self.blockedAppNames[mapIndex] = name
    //                        }
    //                        ParentControlViewModel.shared.updateAppName(name, for: token)
    //                        ParentControlViewModel.shared.hasChanges = true
    //                    }
    //
    //                    resolved += 1
    //                    if resolved == batch.count {
    //                        // Reload after each batch so user sees names progressively
    //                        DispatchQueue.main.async {
    //                            self.collViewAppList.reloadData()
    //                            self.tblViewRequestApps.reloadData()
    //                        }
    //                        processBatch(batchIndex + 1)
    //                    }
    //                }
    //            }
    //        }
    //
    //        processBatch(0)
    //    }

    /// Resolves any "Unknown App" names in `blockedAppNames` using offscreen Label(token) rendering,
    /// then updates the dropdown table in-place as names come in — one row at a time.
    private func resolveUnknownNamesAndRefresh(reqView: ViewForReqAppSelection) {
        let tokens = self.blockedAppTokens
        let names  = self.blockedAppNames
        guard !tokens.isEmpty else { return }

        // Find tokens that still need resolution
        var unknownTokens: [ApplicationToken] = []
        for (i, name) in names.enumerated() {
            if i < tokens.count && !AppNameResolution.isResolved(name) {
                unknownTokens.append(tokens[i])
            }
        }
        guard !unknownTokens.isEmpty else { return }

        print("🔍 [ChildHomeVC] Resolving \(unknownTokens.count) unknown app names for dropdown...")

        // Ensure authorization first
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        if authStatus == .notDetermined {
            Task { @MainActor in
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                } catch {
                    print("❌ [resolveUnknownNamesAndRefresh] Auth failed: \(error)")
                }
                self.resolveUnknownNamesAndRefreshInternal(
                    reqView: reqView, unknownTokens: unknownTokens)
            }
            return
        }
        guard authStatus == .approved else { return }
        resolveUnknownNamesAndRefreshInternal(reqView: reqView, unknownTokens: unknownTokens)
    }

    private func resolveUnknownNamesAndRefreshInternal(
        reqView: ViewForReqAppSelection,
        unknownTokens: [ApplicationToken]
    ) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow })
        else { return }

        for (loopIndex, token) in unknownTokens.enumerated() {
            guard let tokenData = try? JSONEncoder().encode(token) else { continue }
            let tokenStr = tokenData.base64EncodedString()

            // ── Fast path: check persistent cache before spinning up a view ─
            if let cached = AppNameResolutionCache.cachedName(forTokenStr: tokenStr) {
                print("✅ [ChildHomeVC] Cache hit for token \(tokenStr.prefix(8)): '\(cached)'")
                if let dynamicIndex = self.blockedAppTokens.firstIndex(of: token) {
                    if dynamicIndex < self.blockedAppNames.count {
                        self.blockedAppNames[dynamicIndex] = cached
                    }
                }
                if let vmIndex = ChildHomeViewModel.shared.requestedApps.firstIndex(where: {
                    $0.getApplicationToken() == token
                }) {
                    ChildHomeViewModel.shared.requestedApps[vmIndex].name = cached
                }
                reqView.updateTokenName(cached, for: token)
                continue
            }

            // Signal that one more token needs resolving — disables Submit button
            reqView.trackResolutionPending()

            // Add the hosted view to the key window offscreen to trigger rendering
            let hc = UIHostingController(rootView: AnyView(
                Label(token)
                    .labelStyle(.automatic)
                    .frame(width: 300, height: 44)
            ))
            hc.view.frame = CGRect(x: -2000, y: CGFloat(loopIndex) * 50, width: 300, height: 44)
            hc.view.backgroundColor = .clear
            hc.view.alpha = 0.01
            window.addSubview(hc.view)
            hc.view.layoutIfNeeded()

            var attempts = 0
            let maxAttempts = 20  // 20 × 0.5s = 10s max

            func check() {
                let name = self.findLabelText(in: hc.view)
                if let name = name, AppNameResolution.isResolved(name) {
                    hc.view.removeFromSuperview()
                    print("✅ [ChildHomeVC] Resolved '\(name)' for token \(tokenStr.prefix(8))")
                    // Persist to cache so next launch is instant
                    AppNameResolutionCache.store(name: name, forTokenStr: tokenStr)
                    
                    // Look up current index dynamically
                    if let dynamicIndex = self.blockedAppTokens.firstIndex(of: token) {
                        if dynamicIndex < self.blockedAppNames.count {
                            self.blockedAppNames[dynamicIndex] = name
                        }
                        reqView.updateTokenName(name, for: token)
                    } else {
                        // Not in current list, but decrement pending resolution
                        reqView.trackResolutionComplete()
                    }
                    
                    // Update ChildHomeViewModel so future opens use the real name
                    if let vmIndex = ChildHomeViewModel.shared.requestedApps.firstIndex(where: {
                        $0.getApplicationToken() == token
                    }) {
                        ChildHomeViewModel.shared.requestedApps[vmIndex].name = name
                    }
                } else if attempts >= maxAttempts {
                    hc.view.removeFromSuperview()
                    print("⚠️ [ChildHomeVC] Could not resolve name for token \(tokenStr.prefix(8)) after \(maxAttempts) attempts")
                    // Even on timeout, decrement so Submit re-enables
                    reqView.trackResolutionComplete()
                } else {
                    attempts += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { check() }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { check() }
        }
    }

    /// Renders Label(token) in a nearly-invisible UIHostingController and extracts the text.
    /// Pass `tokenStr` (base64-encoded token) to also write the resolved name to the persistent cache.
    private func renderLabelName(
        for token: ApplicationToken,
        tokenStr: String? = nil,
        completion: @escaping (String?) -> Void
    ) {
        // If FamilyControls not authorized, request it first then retry
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        if authStatus == .notDetermined {
            Task { @MainActor in
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                } catch {
                    print("❌ [renderLabelName] Authorization failed: \(error)")
                }
                self.renderLabelNameInternal(for: token, tokenStr: tokenStr, completion: completion)
            }
            return
        }
        guard authStatus == .approved else {
            completion(nil)
            return
        }
        renderLabelNameInternal(for: token, tokenStr: tokenStr, completion: completion)
    }

    /// Internal implementation — assumes authorization is already approved.
    /// tokenStr: the base64-encoded token string, used to write to AppNameResolutionCache on success.
    private func renderLabelNameInternal(
        for token: ApplicationToken,
        tokenStr: String? = nil,
        completion: @escaping (String?) -> Void
    ) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow })
        else {
            completion(nil)
            return
        }

        // ── Fast path: persistent cache ────────────────────────────────────
        if let ts = tokenStr, let cached = AppNameResolutionCache.cachedName(forTokenStr: ts) {
            print("✅ [renderLabelName] Cache hit: '\(cached)'")
            completion(cached)
            return
        }

        let hc = UIHostingController(
            rootView: AnyView(
                Label(token)
                    .labelStyle(.automatic)
                    .frame(width: 300, height: 44)
            )
        )
        hc.view.frame = CGRect(x: -2000, y: 0, width: 300, height: 44)
        hc.view.backgroundColor = .clear
        hc.view.alpha = 0.01
        window.addSubview(hc.view)
        hc.view.layoutIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var attempts = 0
            let maxAttempts = 20  // 20 × 0.5s = 10s max

            func checkName() {
                let name = self.findLabelText(in: hc.view)
                if let name = name, AppNameResolution.isResolved(name) {
                    hc.view.removeFromSuperview()
                    // Persist so future taps are instant
                    if let ts = tokenStr {
                        AppNameResolutionCache.store(name: name, forTokenStr: ts)
                    }
                    completion(name)
                } else if attempts >= maxAttempts {
                    hc.view.removeFromSuperview()
                    completion(nil)
                } else {
                    attempts += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { checkName() }
                }
            }
            checkName()
        }
    }

    // Delegates to shared helper (AppNameResolutionViews.swift) — handles iOS 15 UILabel
    // and iOS 16+ _UITextLayoutView (text exposed via accessibilityLabel).
    private func findLabelText(in view: UIView) -> String? {
        return findAnyLabelText(in: view)
    }

    /// No-op: previously persisted server apps via SharedAppInfo.
    /// App Group / report extension flow removed — tokens are now managed
    /// directly through FamilyActivityPicker selection.
    private func persistServerAppsToSwiftData(_ apps: [ChildRequestedApp]) {}

    /// - Parameter completion: Called on the main thread with `true` on success, `false` on failure.
    ///   When called from the popup flow the caller handles toast/UI; when `nil` the method shows
    ///   its own toast (legacy call-sites).
//    func apiCallForRequestAppAccess(
//        token: String,
//        appName: String,
//        type: String = "app",
//        completion: ((Bool) -> Void)? = nil
//    ) {
    func apiCallForRequestAppAccess(
        token: String,
        appName: String,
        type: String = "app",
        iconBase64: String? = nil,
        userName: String? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        let user = AppState.sharedInstance.user
        guard let userId = user?.userId else {
            DispatchQueue.main.async { completion?(false) }
            return
        }

        let finalAppName = type == "category" ? "Category" : appName

        // Use token-based fallback name if resolution failed.
        // The parent device can see the real icon via the token — name is for display only.
        // We never hard-abort the request just because FamilyControlsAgent didn't respond.
        let isGarbageName = !AppNameResolution.isResolved(finalAppName)
        let syncAppName = isGarbageName ? "Unknown App" : finalAppName
        
        let requestName: String
        if let userName = userName, !userName.isEmpty {
            requestName = userName
        } else {
            requestName = syncAppName
        }

        if isGarbageName {
            print("⚠️ [RequestAccess] Name unresolved for token '\(token.prefix(12))...' — will submit with placeholder name")
        }

        print("Requesting access for: \(finalAppName)")

        appDelegate.showHud()

        // Step 1: Sync the app to server first to ensure ChildApp entry exists
        // Uses syncAppName (the actual resolved app name) to populate the blocked app list correctly
        ChildHomeViewModel.shared.syncSingleApp(token: token, appName: syncAppName, requestName: requestName) {
            [weak self] syncSuccess in
            guard let self = self else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            if !syncSuccess {
                DispatchQueue.main.async {
                    appDelegate.hideHud()
                    if completion == nil {
                        self.view.makeToast("Failed to sync app. Please try again.")
                    } else {
                        self.view.makeToast("Failed to sync app. Please try again.")
                        completion?(false)
                    }
                }
                return
            }

            // Step 2: Now request access
            let strUrl = WebURL.childAccountApi + "\(userId)/app/request"
            var param: [String: Any] = [
                "token": token,
                "name": requestName,
                "permissionType": "DRIVE_MODE",
            ]
            // Also send userName as a dedicated field so the server stores it
            // and returns it back to the parent in driveModeRequestedApps
            if let uName = userName, !uName.isEmpty {
                param["userName"] = uName
            }
            if let icon = iconBase64, !icon.isEmpty {
                param["icon"] = icon
            }
            print("🔄 [RequestAccess] Making request API call")
            print("🔄 [RequestAccess] URL: \(strUrl)")
            print("🔄 [RequestAccess] Params: \(param)")
            print("🔄 [RequestAccess] Using name: '\(requestName)', userName: '\(userName ?? "nil")'")

            self.apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: strUrl, param: param) {
                [weak self] (isSuccess: Bool, responseDict: [String: Any], statusCode: Int) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    appDelegate.hideHud()
                    if isSuccess {
                        print("✅ [RequestAccess] Request sent successfully with name: '\(requestName)'")
                        print("✅ [RequestAccess] Server response: \(responseDict)")
                        // Show contextual toast (app name instead of generic message)
                        self.view.makeToast("Request sent successfully")
                        if let completion = completion {
                            completion(true)
                        } else {
                            // Legacy path: no popup open, just refresh the home list
                            self.refreshAppsData()
                        }
                    } else {
                        print("❌ [RequestAccess] Failed to send request")
                        print("❌ [RequestAccess] Error response: \(responseDict)")
                        self.view.makeToast("Failed to send request")
                        completion?(false)
                    }
                }
            }
        }
    }

    func apiCallForNoDriveModeRequest(startTime: Date, endTime: Date, reason: String) {
        let user = AppState.sharedInstance.user
        guard let userId = user?.userId else { return }

        // Format ISO8601 string manually for server expectation
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let startTimeStr = formatter.string(from: startTime)
        let endTimeStr = formatter.string(from: endTime)

        let strUrl = WebURL.requestNoDriveMode(childId: userId)

        let param =
            [
                "startTime": startTimeStr,
                "endTime": endTimeStr,
                "reason": reason,
            ] as [String: Any]

        print("Requesting No-Drive Mode")
        print("URL: \(strUrl)")
        print("Params: \(param)")

        appDelegate.showHud()

        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: strUrl, param: param) {
            (isSuccess, responseDict, statusCode) in
            appDelegate.hideHud()
            if isSuccess {
                self.view.makeToast("No-Drive Mode Request sent successfully")
                self.refreshAppsData()
            } else {
                self.view.makeToast("Failed to send request")
            }
        }
    }

    // MARK: - Fetch Requested No-Drive Mode Schedule List
    func apiCallForRequestedNoDriveModeSchedule() {
        print("🚀 [ChildHomeVC] Calling Requested No-Drive Mode Schedule API")

        ChildHomeViewModel.shared.fetchRequestedNoDriveModeSchedule { isSuccess, list in
            DispatchQueue.main.async {
                if isSuccess {
                    print(
                        "✅ [ChildHomeVC] Requested No-Drive Mode Schedule — \(list.count) item(s)")

                    // Pretty-print each item for easy UI binding
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    for (index, item) in list.enumerated() {
                        if let prettyData = try? encoder.encode(item),
                            let prettyStr = String(data: prettyData, encoding: .utf8)
                        {
                            print("📋 Item[\(index)]:\n\(prettyStr)")
                        }
                    }

                    // Refresh table view to properly populate the merged lists
                    self.tblViewNoDriveRequest.reloadData()
                    self.updateEmptyLabels()
                    self.updateTableHeights()
                } else {
                    print("❌ [ChildHomeVC] Failed to fetch requested no-drive mode schedule")
                }
            }
        }
    }

    //MARK: - Get Child policy...
    func apiCallForGetParentAddedPolicy() {

        apiCallViewModel.getApiCallWithDisctionaryResponse(
            aUrl: WebURL.getChildPolicy, aParams: [String: Any]()
        ) {
            (isSuccess, responseDict) in

            if isSuccess {

                self.strPolicyTitle = getStringFromDictionary(
                    dictionary: responseDict, key: "title")
                self.strPolicyDescription = getStringFromDictionary(
                    dictionary: responseDict, key: "description")
            } else {
                self.strPolicyTitle = ""
                self.strPolicyDescription = "No policy added by parent"
            }

            appDelegate.saveDeviceTokenForRegisterUser()
        }
    }
}

struct ChildBlockedAppItem: Identifiable {
    let token: ApplicationToken
    let name: String
    var id: String {
        (try? JSONEncoder().encode(token))?.base64EncodedString() ?? name
    }
}

struct ChildAppRowLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            configuration.title
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("AppDarkBlue"))
        }
    }
}

struct ChildBlockedAppsSwiftUIView: View {
    let apps: [ChildBlockedAppItem]
    let onRequestAccess: (ApplicationToken, String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                if apps.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Blocked Apps")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Your parent hasn't blocked any apps right now.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(apps) { app in
                            Button(action: {
                                onRequestAccess(app.token, app.name)
                            }) {
                                HStack(spacing: 12) {
                                    if AppNameResolution.isResolved(app.name) {
                                        Label(app.token)
                                            .labelStyle(.iconOnly)
                                            .frame(width: 40, height: 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        Text(app.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color("AppDarkBlue"))
                                    } else {
                                        Label(app.token)
                                            .labelStyle(ChildAppRowLabelStyle())
                                    }
                                    Spacer()
                                    Text("Request")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color("AppDarkBlue").opacity(0.1))
                                        .foregroundColor(Color("AppDarkBlue"))
                                        .cornerRadius(12)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("Blocked Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onDismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
