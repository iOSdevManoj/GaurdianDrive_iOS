//
//  HomeVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 16/12/25.
//

import GoogleMaps
import UIKit


class HomeVC: UIViewController {

    //Outlets.
    @IBOutlet var viewForBG: UIView!
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var lblUserName: UILabel!
    @IBOutlet var viewForAddChild: UIView!
    @IBOutlet var collViewChildList: UICollectionView!
    @IBOutlet var collViewAppsList: UICollectionView!
    @IBOutlet var tblViewAppReq: UITableView!
    @IBOutlet var tblViewNoDriveRequest: UITableView!
    @IBOutlet var lblKmMph: UILabel!
    @IBOutlet var viewForChildDetails: UIView!
    @IBOutlet var viewForHeaderAddChild: UIView!
    @IBOutlet var lblChildPolicyTitle: UILabel!
    @IBOutlet var lblChildPolicy: UILabel!
    @IBOutlet var switchStatus: UISwitch!
    @IBOutlet var sliderForRange: UISlider!
    @IBOutlet var scrollViewMain: UIScrollView!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet var lblRequestNoFound: UILabel!
    @IBOutlet var lblNoDriveReqNoFound: UILabel!
    @IBOutlet var lblNoApprovedApps: UILabel!
    @IBOutlet var lblChildCurrentSpeed: UILabel!
    @IBOutlet var btnDriveModeTitle: UIButton!
    @IBOutlet var lblNoLocation: UILabel!
    @IBOutlet var lblLocationUpdateDate: UILabel!
    @IBOutlet var btnTapOnMap: UIButton!

    // Height constraints — connect to the OUTER CONTAINER view's height constraint in the storyboard
    @IBOutlet var consHeightRequestApps: NSLayoutConstraint!
    @IBOutlet var consHeightNoDriveRequest: NSLayoutConstraint!
    @IBOutlet weak var btnViewAllApproved: UIButton!

    // Arrows for collection view
    private let btnLeft = UIButton()
    private let btnRight = UIButton()

    //Variables..
    var childSelectedIndex = 0
    private var confirmAlertView: ViewForOptionAlert?
    var manageAppsView: ViewForManageApps?
    var arrChildList = [UserModel]()
    let marker = GMSMarker()
    private var centerPin: UIImageView?
    var clLocationUpdated = CLLocationCoordinate2D()
    var isForNotReload = false
    private var pollingTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initialisation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        setUserProfileImageFromUrl(
            aImageview: self.imgProfile, aPlaceholderName: "ic_white_placeholder")

        //Set user details...
        if let profileDetails = AppState.sharedInstance.user {
            self.lblUserName.text = profileDetails.name
        }
        rootTab.viewBottomTabMain.isHidden = false
        rootTab.cons_bottomBar_height.constant = 60

        //api for get added child...
        appDelegate.showHud()
        self.apiCallForGetMyAddedChild()
        appDelegate.apiCallForMySubscription()
        
        // Start 5-second fallback polling if Sockets are disabled
        self.startApiPollingIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopApiPolling()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .parentHomeDataDidUpdate, object: nil)
    }
}

//MARK: - Initialisation functions...
extension HomeVC {
    func initialisation() {
        
        //Socket functions..
        if appDelegate.isPurchaseVIP
        {
            self.getSocketConnectionMessage()
        }
        
        self.btnDriveModeTitle.isHidden = true

        scrollViewMain.contentInset.bottom = tabBarController?.tabBar.frame.height ?? 50

        self.viewForBG.roundTopCorners(radius: 16)

        self.collViewChildList.register(
            UINib(nibName: "CellForChildName", bundle: nil),
            forCellWithReuseIdentifier: "CellForChildName")
        self.collViewAppsList.register(
            UINib(nibName: "CellForAppsList", bundle: nil),
            forCellWithReuseIdentifier: "CellForAppsList")
        self.setupArrows()
        self.tblViewAppReq.tableFooterView = UIView()
        self.tblViewNoDriveRequest.tableFooterView = UIView()
        self.tblViewAppReq.estimatedRowHeight = 80
        self.tblViewNoDriveRequest.estimatedRowHeight = 80
        self.tblViewAppReq.register(
            UINib(nibName: "CellForRequestApps", bundle: nil),
            forCellReuseIdentifier: "CellForRequestApps")
        self.tblViewNoDriveRequest.register(
            UINib(nibName: "CellForRequestApps", bundle: nil),
            forCellReuseIdentifier: "CellForRequestApps")

        if let layout = collViewChildList.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.scrollDirection = .horizontal
        }
        
        
        // Listen for silent background refreshes triggered by push notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onParentHomeDataUpdated(_:)),
            name: .parentHomeDataDidUpdate,
            object: nil
        )

    }
    
    // MARK: - 5-Second API Polling (When Sockets are disabled)
    private func startApiPollingIfNeeded() {
        guard !FeatureFlag.isSocketFeatureEnabled else { return }
        stopApiPolling()
        
        // Listen for background / foreground states to pause/resume timer
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        print("⏱️ [HomeVC] Sockets disabled — starting 5-second REST API polling.")
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.arrChildList.isEmpty else { return }
            self.apiCallForGetChildLastLocation()
        }
    }
    
    private func stopApiPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func appDidEnterBackground() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        print("⏸️ [HomeVC] App backgrounded — paused polling.")
    }

    @objc private func appWillEnterForeground() {
        guard !FeatureFlag.isSocketFeatureEnabled else { return }
        if pollingTimer == nil {
            print("▶️ [HomeVC] App foregrounded — resumed polling.")
            pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                guard let self = self, !self.arrChildList.isEmpty else { return }
                self.apiCallForGetChildLastLocation()
            }
        }
    }

    /// Called when a push notification causes a silent background data refresh.
    /// Reloads UI only if the updated child matches the currently selected one.
    @objc private func onParentHomeDataUpdated(_ notification: Notification) {
        guard !arrChildList.isEmpty else { return }

        let currentChildId = arrChildList[childSelectedIndex].userId
        let updatedChildId = notification.userInfo?["childId"] as? String

        // Only refresh UI if the notification is for the currently visible child
        guard updatedChildId == nil || updatedChildId == currentChildId else {
            print("ℹ️ [HomeVC] Data refreshed for child \(updatedChildId ?? "") — not currently selected, skipping UI update")
            return
        }

        print("🔁 [HomeVC] Reloading UI after push-triggered data refresh for childId \(currentChildId)")
        let vm = ParentHomeViewModel.shared

        // Update speed switch/slider
        self.switchStatus.isOn = vm.speedAlert
        let threshold = vm.speedAlertThreshold
        self.lblKmMph.text = "\(Int(threshold)) mph"
        self.sliderForRange.value = Float(threshold)

        // Update policy
        self.setupHomeChildPolicyData(
            aTitle: vm.policyTitle,
            aDesc: vm.policyDescription.isEmpty ? "No Policy Available" : vm.policyDescription
        )

        // Reload lists
        self.tblViewAppReq.reloadData()
        self.tblViewNoDriveRequest.reloadData()
        self.collViewAppsList.reloadData()
        self.updateEmptyLabels()
        self.updateTableHeights()
        self.updateArrowsVisibility()
    }

    func setupHomeChildPolicyData(aTitle: String, aDesc: String) {
        self.lblChildPolicyTitle.text = aTitle
        self.lblChildPolicy.text = aDesc
        if aDesc == "" {
            self.lblChildPolicy.text = "No Policy Available"
        }
    }

    func updateCenterMap(lat: Double, lng: Double, zoom: Float = 15) {

        // add fixed center pin only once
        if mapView.viewWithTag(999) == nil {
            let pin = UIImageView(image: UIImage(named: "ic_map_pin"))
            pin.frame.size = CGSize(width: 25, height: 35)
            pin.center = CGPoint(x: mapView.bounds.midX + 20, y: mapView.bounds.midY - 14)
            pin.contentMode = .scaleAspectFit
            pin.tag = 999
            pin.isUserInteractionEnabled = false
            mapView.addSubview(pin)
        }

        // move map camera (pin stays fixed)
        let target = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let update = GMSCameraUpdate.setTarget(target, zoom: zoom)
        mapView.animate(with: update)
    }

    //Socket connnections.....
    func getSocketConnectionMessage() {
        GuardianSocketManager.shared.onMessage = { [weak self] message in
            print("Received:", message)

            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let data = message.data(using: .utf8) else { return }

                do {
                    let location = try JSONDecoder().decode(ChildLocation.self, from: data)

                    // Only update UI if the message is for the currently selected child
                    guard !self.arrChildList.isEmpty,
                          self.arrChildList[self.childSelectedIndex].userId == location.childId
                    else { return }

                    let coordinate = CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                    self.clLocationUpdated = coordinate
                    self.updateCenterMap(lat: location.latitude, lng: location.longitude)
                    self.lblChildCurrentSpeed.text = String(format: "%.2f mph", location.speed)

                    print("Childs speed current (socket): \(String(format: "%.2f mph", location.speed))")
                    // Use the driveMode sent by the child — it distinguishes regular drive mode
                    // from an approved No-Drive mode exemption.
                    let mode = location.driveMode ?? ""
                    let isActiveMode = !mode.isEmpty && mode != "Normal"
                    if isActiveMode {
                        self.btnDriveModeTitle.isHidden = false
                        self.btnDriveModeTitle.setTitle(mode, for: .normal)
                    } else {
                        self.btnDriveModeTitle.isHidden = true
                    }
                    self.btnTapOnMap.isUserInteractionEnabled = true
                    self.mapView.isHidden = false
                    self.lblNoLocation.isHidden = true
                    let current = formatToDisplay(date: Date())
                    self.lblLocationUpdateDate.text = current
                } catch {
                    print("Decode error:", error)
                }
            }
        }
        GuardianSocketManager.shared.onConnect = {
            print("Connected")
        }
        GuardianSocketManager.shared.connect()
    }
}

//MARK: - Click Events.....
extension HomeVC {
    @IBAction func tapToProfile(_ sender: UIControl) {

        let objProfileVC =
            storyBoards.Settings.instantiateViewController(withIdentifier: "ProfileVC")
            as! ProfileVC
        objProfileVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(objProfileVC, animated: true)
    }
    @IBAction func tapToNotification(_ sender: UIControl) {
        let objNotificationListVC =
            storyBoards.Settings.instantiateViewController(withIdentifier: "NotificationListVC")
            as! NotificationListVC
        objNotificationListVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(objNotificationListVC, animated: true)
    }
    @IBAction func tapToAddChild(_ sender: UIControl) {
        checkVIPAccess(from: self) {
            let objAddChildVC =
                storyBoards.Home.instantiateViewController(withIdentifier: "AddChildVC") as! AddChildVC
            self.navigationController?.pushViewController(objAddChildVC, animated: true)
        }
    }

    @IBAction func sliderSpeedValueChanged(_ sender: UISlider) {
        //        let value = sender.value
        let intValue = Int(round(sender.value))
        self.lblKmMph.text = "\(intValue) mph"
    }
    @IBAction func sliderSpeedValueEnd(_ sender: UISlider) {
        checkVIPAccess(from: self) {
            let intValue = Int(round(sender.value))
            self.apiCallForSetSpeedRange(aSpeedRange: "\(intValue)")
        }
    }
    @IBAction func switchSpeedValueChanged(_ sender: UISwitch) {
        checkVIPAccess(from: self) {
            if sender.isOn {
                //print("Switch is ON")
                self.apiCallForSetSpeedSwitch(aAlertSwich: true)
            } else {
                // print("Switch is OFF")
                self.apiCallForSetSpeedSwitch(aAlertSwich: false)
            }
        }
    }
    @IBAction func tapToViewAllNoDriveReq(_ sender: UIButton) {

        let objNoDriveReqListVC =
            storyBoards.Home.instantiateViewController(withIdentifier: "NoDriveReqListVC")
            as! NoDriveReqListVC
        objNoDriveReqListVC.isFromNoDriveReq = true
        objNoDriveReqListVC.childId = self.arrChildList[self.childSelectedIndex].userId
        self.navigationController?.pushViewController(objNoDriveReqListVC, animated: true)
    }
    @IBAction func tapToViewAllAppAccessRequests(_ sender: UIButton) {
        let objNoDriveReqListVC =
            storyBoards.Home.instantiateViewController(withIdentifier: "NoDriveReqListVC")
            as! NoDriveReqListVC
        objNoDriveReqListVC.isFromNoDriveReq = false
        objNoDriveReqListVC.childId = self.arrChildList[self.childSelectedIndex].userId
        self.navigationController?.pushViewController(objNoDriveReqListVC, animated: true)
    }
    @IBAction func tapToApprovedManageApp(_ sender: UIButton) {
        self.showManageApps()
    }
    @IBAction func tapToViewAllApproved(_ sender: UIButton) {
        let objApprovedListVC =
            storyBoards.Home.instantiateViewController(withIdentifier: "NoDriveReqListVC")
            as! NoDriveReqListVC
        objApprovedListVC.isFromApprovedApps = true
        objApprovedListVC.isFromNoDriveReq = false
        objApprovedListVC.childId = self.arrChildList[self.childSelectedIndex].userId
        self.navigationController?.pushViewController(objApprovedListVC, animated: true)
    }
    @IBAction func tapToMap(_ sender: UIButton) {
        checkVIPAccess(from: self) {
            let objMapViewVC =
            storyBoards.Home.instantiateViewController(withIdentifier: "MapViewVC") as! MapViewVC
            objMapViewVC.childData = self.arrChildList[self.childSelectedIndex]
            objMapViewVC.locationForChild = self.clLocationUpdated
            self.navigationController?.pushViewController(objMapViewVC, animated: true)
        }
    }

    @IBAction func tapToEditPolicy(_ sender: UIButton) {
        checkVIPAccess(from: self) {
            let objAddPolicyVC =
            storyBoards.Home.instantiateViewController(withIdentifier: "AddPolicyVC")
            as! AddPolicyVC
            objAddPolicyVC.strChildID = self.arrChildList[self.childSelectedIndex].userId
            objAddPolicyVC.strTitle = self.lblChildPolicyTitle.text!
            if self.lblChildPolicy.text == "No Policy Available"
            {
                objAddPolicyVC.strDesc = ""
            }else{
                objAddPolicyVC.strDesc = self.lblChildPolicy.text!
            }
            self.navigationController?.pushViewController(objAddPolicyVC, animated: true)
        }
    }

    @IBAction func tapToChildLocations(_ sender: UIButton) {
        checkVIPAccess(from: self) {
            let objAddressListVC =
            storyBoards.Home.instantiateViewController(withIdentifier: "AddressListVC")
            as! AddressListVC
            objAddressListVC.childID = self.arrChildList[self.childSelectedIndex].userId
            self.navigationController?.pushViewController(objAddressListVC, animated: true)
        }
    }
}

//MARK: - Collectionview delegates and datasource...
extension HomeVC: UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
{
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView == collViewAppsList {
            return CGSize(width: 100, height: 100)

        }
        //return CGSize(width: 125, height: self.collViewChildList.frame.height)
        
        let text = self.arrChildList[indexPath.row].name // your data source
        let font = UIFont(name: FontName.PlusJakartaSansSemiBold, size: 16) // match your label font

        let padding: CGFloat = 12 // left + right padding inside cell

        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width

        let width = max(60, min(textWidth + padding, 200))

        return CGSize(width: width, height: self.collViewChildList.frame.height)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        if collectionView == collViewAppsList {
            return ParentHomeViewModel.shared.arrApprovedApps.count
        }
        return self.arrChildList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        if collectionView == collViewChildList {
            let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: "CellForChildName", for: indexPath) as! CellForChildName
            cell.setupChildrenListFrom(
                userData: self.arrChildList[indexPath.row], aSelectedIndex: self.childSelectedIndex,
                cellIndex: indexPath.row)
            return cell
        } else {
            let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: "CellForAppsList", for: indexPath) as! CellForAppsList
//            cell.btnDeleteAdd.isHidden = true

            if indexPath.row < ParentHomeViewModel.shared.arrApprovedApps.count {
                let model = ParentHomeViewModel.shared.arrApprovedApps[indexPath.row]
                cell.configure(app: model, isApproved: true, isFromChild: false)
                cell.onActionTap = { [weak self] in
                    guard let self else { return }
                    let childId = self.arrChildList[self.childSelectedIndex].userId
                    let requestId = model.id != nil ? String(model.id!) : (model._id ?? "")
                    self.setCustomeAlertViewWith(isNoDriveReq: false, isOther: true, request: model, childId: childId, requestId: requestId)
                }
            }
            return cell
        }
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        if collectionView == collViewAppsList {
            return 10
        }
        return 8
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == collViewAppsList {
            self.updateArrowsVisibility()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == collViewChildList {
            self.childSelectedIndex = indexPath.row
            self.collViewChildList.reloadData()
            self.reloadAllDataAsPerChild()
            appDelegate.showHud()
            // Single /apps/all call covers everything
            self.apiCallForGetChildRequests()
        }
    }

    func reloadAllDataAsPerChild() {
        self.clLocationUpdated = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        self.lblChildCurrentSpeed.text = "0.00 mph"
        self.btnDriveModeTitle.isHidden = true
        self.updateCenterMap(lat: 0.0, lng: 0.0)

        // Check if selected child has revoked any permissions
        guard !arrChildList.isEmpty else { return }
        let child = arrChildList[childSelectedIndex]
        ChildPermissionSyncManager.shared.fetchAndShowAlert(
            childId: child.userId,
            childName: child.name,
            from: self
        )
    }
    func selectItem(at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        
        // Select item
        self.collViewChildList.selectItem(at: indexPath, animated: true, scrollPosition: [])
        
        // Scroll to make it visible
        self.collViewChildList.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

//MARK: - TableView Delegate and DataSources
extension HomeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tblViewAppReq {
            // Max 3 on home screen
            return min(ParentHomeViewModel.shared.arrAppRequests.count, 3)
        }
        return min(ParentHomeViewModel.shared.arrNoDriveRequests.count, 3)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell =
            tableView.dequeueReusableCell(withIdentifier: "CellForRequestApps")
            as! CellForRequestApps
        cell.cellDelegate = self
        cell.viewBGWhite.layer.borderWidth = 1
        cell.viewBGWhite.layer.borderColor = UIColor(named: "AppBorderGray")?.cgColor
        //cell.lblApprove.isHidden = false
        cell.cons_lblApproved_width.constant = 100
        if tableView == self.tblViewAppReq {
            let data = ParentHomeViewModel.shared.arrAppRequests[indexPath.row]
            cell.setCellDataWihModelData(data: data, aIndex: indexPath.row, isTblReq: true)
            let status = (data.currentStatus ?? data.status ?? "").uppercased()
            switch status {
            case "APPROVED", "REJECTED":
                cell.btnApproved.isHidden = true
                cell.btnCross.isHidden = true
//                cell.lblApprove.isHidden = true
                cell.cons_lblApproved_width.constant = 0
            default: // REQUESTED
                cell.btnApproved.isHidden = false
                cell.btnCross.isHidden = false
//                cell.lblApprove.isHidden = false
                cell.cons_lblApproved_width.constant = 100
            }
        } else {
            let data = ParentHomeViewModel.shared.arrNoDriveRequests[indexPath.row]
            cell.setCellDataWihModelData(data: data, aIndex: indexPath.row, isTblReq: false)
            cell.btnApproved.tag = 1000 + indexPath.row
            cell.btnCross.tag = 1000 + indexPath.row

            let status = (data.currentStatus ?? data.status ?? "").uppercased()
            switch status {
            case "APPROVED":
                cell.btnApproved.isHidden = true
                //cell.lblApprove.isHidden = true
                cell.cons_lblApproved_width.constant = 0
                cell.btnCross.isHidden = false // Parent can revoke
                cell.lblStatus.text = "APPROVED"
                cell.lblStatus.textColor = UIColor(named: "AppGreen") ?? UIColor.systemGreen
                cell.lblStatus.backgroundColor = (UIColor(named: "AppGreen") ?? UIColor.systemGreen).withAlphaComponent(0.15)
            case "REJECTED":
                cell.btnApproved.isHidden = true
//                cell.lblApprove.isHidden = true
                cell.cons_lblApproved_width.constant = 0
                cell.btnCross.isHidden = true
                cell.lblStatus.text = "REJECTED"
                cell.lblStatus.textColor = UIColor.systemOrange
                cell.lblStatus.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
            default: // REQUESTED
                cell.btnApproved.isHidden = false
//                cell.lblApprove.isHidden = false
                cell.cons_lblApproved_width.constant = 100
                cell.btnCross.isHidden = false
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    func tableView(
        _ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath
    ) {

    }
}

//MARK: - Cell Custom delegate..
extension HomeVC: CellForRequestAppsDelegate {
    func didTapApprove(index: Int) {
        let isNoDriveReq = index >= 1000
        let request: ChildRequestedApp

        if isNoDriveReq {
            request = ParentHomeViewModel.shared.arrNoDriveRequests[index - 1000]
        } else {
            request = ParentHomeViewModel.shared.arrAppRequests[index]
        }

        let childId = self.arrChildList[self.childSelectedIndex].userId
        appDelegate.showHud()

        if isNoDriveReq {
            ParentHomeViewModel.shared.performNoDriveModeAction(
                childId: childId, request: request, action: "approve"
            ) { success, message in
                appDelegate.hideHud()
                if success {
                    self.apiCallForGetChildRequests()
                } else {
                    appDelegate.window?.rootViewController?.view.makeToast(
                        message ?? "Failed to approve request")
                }
            }
        } else {
            guard let requestId = request.id != nil ? String(request.id!) : request._id else {
                appDelegate.hideHud()
                return
            }
            ParentHomeViewModel.shared.performAppRequestAction(
                childId: childId, requestId: requestId, action: "approve",
                permissionType: request.permissionType ?? "DRIVE_MODE"
            ) { success, message in
                appDelegate.hideHud()
                if success {
                    self.apiCallForGetChildRequests()
                } else {
                    appDelegate.window?.rootViewController?.view.makeToast(
                        message ?? "Failed to approve request")
                }
            }
        }
    }

    func didTapCross(index: Int) {

        //if confirmAlertView != nil { return }

        let isNoDriveReq = index >= 1000
        let request: ChildRequestedApp

        if isNoDriveReq {
            request = ParentHomeViewModel.shared.arrNoDriveRequests[index - 1000]
        } else {
            request = ParentHomeViewModel.shared.arrAppRequests[index]
        }
        let childId = self.arrChildList[self.childSelectedIndex].userId
        guard let requestId = request.id != nil ? String(request.id!) : request._id else { return }
        
        self.setCustomeAlertViewWith(isNoDriveReq: isNoDriveReq, isOther: false, request: request, childId: childId, requestId: requestId)

        //isHideTabbarGlobally(isHide: true, viewContoller: self)
        // 1️⃣ Load from XIB
        //let view = ViewForOptionAlert.loadFromXib()

        // 2️⃣ Set size (FULL SCREEN)
//        view.frame = self.view.bounds
//        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//        // 3️⃣ Configure content & actions
//        let isApproved = (request.currentStatus ?? request.status ?? "").uppercased() == "APPROVED"
//        view.configure(
//            title: isApproved ? "Cancel Approval?" : "Reject Request?",
//            description: isApproved
//                ? "Are you sure you want to cancel the approved No-Drive Mode schedule?"
//                : "Are you sure you want to reject the request made by your child?",
//            onYes: { [weak self] in
//                print("YES tapped")
//                guard let self = self else { return }
//                appDelegate.showHud()
//
//                if isNoDriveReq {
//                    ParentHomeViewModel.shared.performNoDriveModeAction(
//                        childId: childId, request: request, action: "reject"
//                    ) { success, message in
//                        appDelegate.hideHud()
//                        if success {
//                            self.apiCallForGetChildRequests()
//                        } else {
//                            appDelegate.window?.rootViewController?.view.makeToast(
//                                message ?? "Failed")
//                        }
//                        isHideTabbarGlobally(isHide: false, viewContoller: self)
//                    }
//                } else {
//                    // requestId already resolved before alert was shown — use captured value
//                    ParentHomeViewModel.shared.performAppRequestAction(
//                        childId: childId, requestId: requestId, action: "reject",
//                        permissionType: request.permissionType ?? "DRIVE_MODE"
//                    ) { success, message in
//                        appDelegate.hideHud()
//                        if success {
//                            self.apiCallForGetChildRequests()
//                        } else {
//                            appDelegate.window?.rootViewController?.view.makeToast(
//                                message ?? "Failed to reject request")
//                        }
//                        isHideTabbarGlobally(isHide: false, viewContoller: self)
//                    }
//                }
//            },
//            onNo: {
//                print("NO tapped")
//                isHideTabbarGlobally(isHide: false, viewContoller: self)
//            },
//            onClose: {
//                isHideTabbarGlobally(isHide: false, viewContoller: self)
//            }
//        )
//
//        // 4️⃣ Add as subview (THIS IS WHERE addSubview IS DONE)
//        self.view.addSubview(view)
//        view.showAnimated()
//
//        self.confirmAlertView = view
//
//        // 🔥 6️⃣ RELEASE reference WHEN CLOSED
//        view.onClose = { [weak self] in
//            self?.confirmAlertView = nil
//            isHideTabbarGlobally(isHide: false, viewContoller: self!)
//        }
    }
    
    func setCustomeAlertViewWith(isNoDriveReq:Bool,isOther:Bool,request:ChildRequestedApp,childId:String,requestId:String)
    {
        if confirmAlertView != nil { return }
        
        isHideTabbarGlobally(isHide: true, viewContoller: self)
        
        // 1️⃣ Load from XIB
        let view = ViewForOptionAlert.loadFromXib()
        
        // 2️⃣ Set size (FULL SCREEN)
        view.frame = self.view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 3️⃣ Configure content & actions
        let isApproved = (request.currentStatus ?? request.status ?? "").uppercased() == "APPROVED"
        
        var title = ""
        var desc = ""
        var yesTitle = ""
        
        if isOther
        {
            title = "Cancel Approval?"
            desc = "Are you sure you want to cancel app from the approved list?"
            yesTitle = "Yes,Cancel"
        }else{
            title = isApproved ? "Cancel Approval?" : "Reject Request?"
            desc = isApproved
            ? "Are you sure you want to cancel the approved No-Drive Mode schedule?"
            : "Are you sure you want to reject the request made by your child?"
            yesTitle = "Yes,Reject"
        }
        
        view.configure(
            title: title,
            description: desc,
            yesTitle: yesTitle,
            onYes: { [weak self] in
                print("YES tapped")
                guard let self = self else { return }
                
                appDelegate.showHud()
                
                if !isOther{
                    if isNoDriveReq {
                        ParentHomeViewModel.shared.performNoDriveModeAction(
                            childId: childId, request: request, action: "reject"
                        ) { success, message in
                            appDelegate.hideHud()
                            if success {
                                self.apiCallForGetChildRequests()
                            } else {
                                appDelegate.window?.rootViewController?.view.makeToast(
                                    message ?? "Failed")
                            }
                            isHideTabbarGlobally(isHide: false, viewContoller: self)
                        }
                    } else {
                        // requestId already resolved before alert was shown — use captured value
                        ParentHomeViewModel.shared.performAppRequestAction(
                            childId: childId, requestId: requestId, action: "reject",
                            permissionType: request.permissionType ?? "DRIVE_MODE"
                        ) { success, message in
                            appDelegate.hideHud()
                            if success {
                                self.apiCallForGetChildRequests()
                            } else {
                                appDelegate.window?.rootViewController?.view.makeToast(
                                    message ?? "Failed to reject request")
                            }
                            isHideTabbarGlobally(isHide: false, viewContoller: self)
                        }
                    }
                } else {
                    // Cancel approved app
                    ParentHomeViewModel.shared.cancelApprovedApp(
                        childId: childId, requestId: requestId
                    ) { success, message in
                        appDelegate.hideHud()
                        if success {
                            self.apiCallForGetChildRequests()
                        } else {
                            appDelegate.window?.rootViewController?.view.makeToast(
                                message ?? "Failed to cancel request")
                        }
                        isHideTabbarGlobally(isHide: false, viewContoller: self)
                    }
                }
            },
            onNo: {
                print("NO tapped")
                isHideTabbarGlobally(isHide: false, viewContoller: self)
            },
            onClose: {
                isHideTabbarGlobally(isHide: false, viewContoller: self)
            }
        )
        
        // 4️⃣ Add as subview (THIS IS WHERE addSubview IS DONE)
        self.view.addSubview(view)
        view.showAnimated()
        
        self.confirmAlertView = view
        
        // 🔥 6️⃣ RELEASE reference WHEN CLOSED
        view.onClose = { [weak self] in
            self?.confirmAlertView = nil
            isHideTabbarGlobally(isHide: false, viewContoller: self!)
        }
    }
}

//MARK: - Manage Apps custom view....
extension HomeVC {
    func showManageApps() {
        let childId = self.arrChildList[self.childSelectedIndex].userId
        // Load latest local data (which may have been synced in the background)
        ParentControlViewModel.shared.loadData(childId: childId)

        //Hide tabbar code...
        isHideTabbarGlobally(isHide: true, viewContoller: self)

        let view =
            Bundle.main.loadNibNamed(
                "ViewForManageApps",
                owner: self,
                options: nil
            )?.first as! ViewForManageApps

        view.frame = self.view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.approvedApps = ParentControlViewModel.shared.appStatuses.filter { !$0.isBlocked }.map {
            status in
            var tokenStr = ""
            if let data = try? JSONEncoder().encode(status.token) {
                tokenStr = data.base64EncodedString()
            }
            let name = AppNameResolutionCache.cachedName(forTokenStr: tokenStr) ?? status.appName
            return ChildRequestedApp(appName: name, token: tokenStr)
        }

        view.otherApps = ParentControlViewModel.shared.appStatuses.filter { $0.isBlocked }.map {
            status in
            var tokenStr = ""
            if let data = try? JSONEncoder().encode(status.token) {
                tokenStr = data.base64EncodedString()
            }
            let name = AppNameResolutionCache.cachedName(forTokenStr: tokenStr) ?? status.appName
            return ChildRequestedApp(appName: name, token: tokenStr)
        }

        view.onClose = { [weak self] in
            self!.closeViewWithTabbarShow()
        }

        view.onUpdate = { [weak self] updatedApprovedApps in
            guard let self = self else { return }
            self.closeViewWithTabbarShow()
            
            let vm = ParentControlViewModel.shared
            let approvedTokens = Set(updatedApprovedApps.compactMap { $0.token })
            
            // Update local appStatuses
            for i in 0..<vm.appStatuses.count {
                if let data = try? JSONEncoder().encode(vm.appStatuses[i].token) {
                    let tokenStr = data.base64EncodedString()
                    // If it is in the "Approved" list, it should NOT be blocked.
                    vm.appStatuses[i].isBlocked = !approvedTokens.contains(tokenStr)
                }
            }
            
            // Save locally and sync to server
            vm.saveData()
            let childId = self.arrChildList[self.childSelectedIndex].userId
            vm.syncAppsWithServer(childId: childId) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.collViewAppsList.reloadData()
                }
            }
        }

        self.view.addSubview(view)
        self.manageAppsView = view
        view.openAnimated()
    }

    func closeViewWithTabbarShow() {
        self.manageAppsView?.removeFromSuperview()
        self.manageAppsView = nil
        isHideTabbarGlobally(isHide: false, viewContoller: self)
    }
}

//MARK: - Api callings..
extension HomeVC {

    //MARK: - Get Added Child list..
    func apiCallForGetMyAddedChild() {
        apiCallViewModel.getApiCallWithDisctionaryResponse(
            aUrl: WebURL.getAddedChilds, aParams: [String: Any]()
        ) { (isSuccess, responseDict) in

            if isSuccess {
                //self.childSelectedIndex = 0  // reset before loading fresh list
                self.arrChildList.removeAll()
                let arrResultData = getArrayFromDictionary(
                    dictionary: responseDict, key: "children")
                if arrResultData.count > 0 {
                   
                    self.viewForChildDetails.isHidden = false
                    self.viewForHeaderAddChild.isHidden = false

                    self.arrChildList = arrResultData.compactMap {
                        UserModel(dict: $0 as! NSDictionary)
                    }
                    if appDelegate.isAddNewChild
                    {
                        appDelegate.isAddNewChild = false
                        self.childSelectedIndex = self.arrChildList.count - 1
                    }
                    self.collViewChildList.reloadData()
                    DispatchQueue.main.async {
                        self.selectItem(at: self.childSelectedIndex)
                    }
                    // Single call to /apps/all covers policy, speed, location, and all app lists
                    self.apiCallForGetChildRequests()

                    // Check if first child has revoked any permissions
                    let firstChild = self.arrChildList[self.childSelectedIndex]
                    ChildPermissionSyncManager.shared.fetchAndShowAlert(
                        childId: firstChild.userId,
                        childName: firstChild.name,
                        from: self
                    )
                } else {
                    appDelegate.hideHud()
                    self.viewForChildDetails.isHidden = true
                    self.viewForHeaderAddChild.isHidden = true
                }
            } else {
                appDelegate.hideHud()
                self.viewForChildDetails.isHidden = true
                self.viewForHeaderAddChild.isHidden = true
            }
        }
    }

    func apiCallForGetChildRequests(isLoader: Bool = true) {
        let safeIndex = arrChildList.indices.contains(childSelectedIndex) ? childSelectedIndex : 0
        self.childSelectedIndex = safeIndex
        let userId = self.arrChildList[self.childSelectedIndex].userId

        if isLoader && appDelegate.window?.viewWithTag(9999) == nil {
             // Only show hud if requested and not already showing
             // We rely on caller to show hud if needed globally, or we just silently load
        }

        ParentHomeViewModel.shared.fetchChildData(childId: userId) { [weak self] success in
            guard let self = self else { return }
            
            // Also sync app block data for the selected child
            AppBlockerManager.shared.fetchAndSyncServerApps(childId: userId)
            
            appDelegate.hideHud()
            DispatchQueue.main.async {
                let vm = ParentHomeViewModel.shared

                // Update speed switch and slider from /apps/all
                self.switchStatus.isOn = vm.speedAlert
                let threshold = vm.speedAlertThreshold
                self.lblKmMph.text = "\(Int(threshold)) mph"
                self.sliderForRange.value = Float(threshold)

                // Update policy labels from /apps/all
                self.setupHomeChildPolicyData(
                    aTitle: vm.policyTitle,
                    aDesc: vm.policyDescription.isEmpty ? "No Policy Available" : vm.policyDescription
                )

                // Update map and speed label from /apps/all
                if vm.lastLocationLat == 0.0 && vm.lastLocationLng == 0.0
                {
                    self.mapView.isHidden = true
                    self.lblNoLocation.isHidden = false
                    self.lblLocationUpdateDate.text = "Not updated"
                    self.btnTapOnMap.isUserInteractionEnabled = false
                }else {
                    self.btnTapOnMap.isUserInteractionEnabled = true
                    let formatted = formatToDisplay(dateString: vm.localTime)
                    self.lblLocationUpdateDate.text = formatted
                    self.mapView.isHidden = false
                    self.lblNoLocation.isHidden = true
                    self.clLocationUpdated = CLLocationCoordinate2D(
                        latitude: vm.lastLocationLat, longitude: vm.lastLocationLng)
                    self.updateCenterMap(lat: vm.lastLocationLat, lng: vm.lastLocationLng)
                    let speed = vm.lastLocationSpeed
                    self.lblChildCurrentSpeed.text = String(format: "%.2f mph", speed)
                    
                    print("childs speed current: \(String(format: "%.2f mph", speed))")
                    // Use driveMode sent by the child — same logic as the socket path
                    let mode = vm.lastDriveMode
                    let isActiveMode = !mode.isEmpty && mode != "Normal"
                    self.btnDriveModeTitle.isHidden = !isActiveMode
                    if isActiveMode {
                        self.btnDriveModeTitle.setTitle(mode, for: .normal)
                    }
                }

                // Reload app/request lists
                self.tblViewAppReq.reloadData()
                self.tblViewNoDriveRequest.reloadData()
                self.collViewAppsList.reloadData()
                self.updateEmptyLabels()
                self.updateTableHeights()
                self.updateArrowsVisibility()
                ParentControlViewModel.shared.updateMonitoring()
            }
        }
    }

    /// Show/hide the "no data" labels based on current array counts.
    func updateEmptyLabels() {
        let vm = ParentHomeViewModel.shared
        lblRequestNoFound?.isHidden = !vm.arrAppRequests.isEmpty
        lblNoDriveReqNoFound?.isHidden = !vm.arrNoDriveRequests.isEmpty
        lblNoApprovedApps?.isHidden = !vm.arrApprovedApps.isEmpty
    }

    /// Resize outer container views so height = actual table content + header + padding.
    func updateTableHeights() {
        tblViewAppReq.layoutIfNeeded()
        tblViewNoDriveRequest.layoutIfNeeded()

        let headerHeight: CGFloat = 44  // title label height inside the container
        let paddingVertical: CGFloat = 16  // top + bottom padding inside the container
        let emptyFallback: CGFloat = 160  // height when empty (shows "no records" label)

        let overhead = headerHeight + paddingVertical

        let reqH =
            tblViewAppReq.contentSize.height > 0
            ? tblViewAppReq.contentSize.height : emptyFallback
        let noDriveH =
            tblViewNoDriveRequest.contentSize.height > 0
            ? tblViewNoDriveRequest.contentSize.height : emptyFallback

        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.consHeightRequestApps?.constant = reqH + overhead
            self?.consHeightNoDriveRequest?.constant = noDriveH + overhead
            self?.view.layoutIfNeeded()
        }
    }

    //MARK: - Add/Update child speed swicth..
    func apiCallForSetSpeedSwitch(aAlertSwich: Bool) {
        let param = ["speedAlert": aAlertSwich] as [String: Any]
        let strUrl =
            WebURL.childAccountApi
            + "\(self.arrChildList[self.childSelectedIndex].userId)/speed-alert"

        apiCallViewModel.putMethodApiCallWithDisctionaryResponse(aUrl: strUrl, param: param) {
            (isSuccess, responseDict) in

            appDelegate.hideHud()

            if isSuccess {
                print(responseDict)
            }
        }
    }

    //MARK: - Add/Update child speed range...
    func apiCallForSetSpeedRange(aSpeedRange: String) {
        let param = ["speedAlertThreshold": aSpeedRange] as [String: Any]
        let strUrl =
            WebURL.childAccountApi
            + "\(self.arrChildList[self.childSelectedIndex].userId)/speed-alert-threshold"

        apiCallViewModel.putMethodApiCallWithDisctionaryResponse(aUrl: strUrl, param: param) {
            (isSuccess, responseDict) in

            appDelegate.hideHud()

            if isSuccess {
                print(responseDict)
            }
        }
    }
    
//    //MARK: - Get Child Speed Switch Status...
//    func apiCallForGetChildSpeedSwitchStatus() {
//        appDelegate.showHud()
//
//        let strUrl =
//            WebURL.childAccountApi
//            + "\(self.arrChildList[self.childSelectedIndex].userId)/speed-alert"
//
//        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: strUrl, aParams: [String: Any]()) {
//            (isSuccess, responseDict) in
//
//            //appDelegate.hideHud()
//
//            if isSuccess {
//                let switchStatus = getBoolFromDictionary(
//                    dictionary: responseDict as NSDictionary, key: "speedAlert")
//                self.switchStatus.isOn = (switchStatus) ? true : false
//            }
//            appDelegate.hideHud()
//            self.apiCallForGetChildSpeedRange()
//        }
//    }
//
//    //MARK: - Get Child Speed Range..
//    func apiCallForGetChildSpeedRange() {
//        let strUrl =
//            WebURL.childAccountApi
//            + "\(self.arrChildList[self.childSelectedIndex].userId)/speed-alert-threshold"
//
//        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: strUrl, aParams: [String: Any]()) {
//            (isSuccess, responseDict) in
//
//            //  appDelegate.hideHud()
//
//            if isSuccess {
//                let childSpeedRange = getStringFromDictionary(
//                    dictionary: responseDict, key: "speedAlertThreshold")
//                self.lblKmMph.text = "\(childSpeedRange) mph"
//                self.sliderForRange.value = Float(childSpeedRange)!
//            }
//            appDelegate.hideHud()
//            
//        }
//    }
//    
    //MARK: - Get Child Last Location
    func apiCallForGetChildLastLocation() {
        guard self.arrChildList.indices.contains(self.childSelectedIndex) else { return }
        let childId = self.arrChildList[self.childSelectedIndex].userId
        
        let strUrl = WebURL.getLastLocation(childId: childId)

        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: strUrl, aParams: [String: Any]()) { [weak self] (isSuccess, responseDict) in
            guard let self = self else { return }
            if isSuccess {
                let lat = Double("\(responseDict["latitude"] ?? 0.0)") ?? 0.0
                let lng = Double("\(responseDict["longitude"] ?? 0.0)") ?? 0.0
                let speed = Double("\(responseDict["speed"] ?? 0.0)") ?? 0.0
                let mode = responseDict["driveMode"] as? String ?? ""
                
                if lat != 0 && lng != 0 {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    self.clLocationUpdated = coordinate
                    self.updateCenterMap(lat: lat, lng: lng)
                    self.lblChildCurrentSpeed.text = String(format: "%.2f mph", speed)
                    
                    let isActiveMode = !mode.isEmpty && mode != "Normal"
                    if isActiveMode {
                        self.btnDriveModeTitle.isHidden = false
                        self.btnDriveModeTitle.setTitle(mode, for: .normal)
                    } else {
                        self.btnDriveModeTitle.isHidden = true
                    }
                    
                    self.btnTapOnMap.isUserInteractionEnabled = true
                    self.mapView.isHidden = false
                    self.lblNoLocation.isHidden = true
                    let current = formatToDisplay(date: Date())
                    self.lblLocationUpdateDate.text = current
                }
            }
        }
    }
}

extension HomeVC {
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
            (collViewAppsList.superview ?? self.view).addSubview($0)
        }

        btnLeft.setImage(UIImage(systemName: "chevron.left.circle.fill"), for: .normal)
        btnRight.setImage(UIImage(systemName: "chevron.right.circle.fill"), for: .normal)

        NSLayoutConstraint.activate([
            btnLeft.leadingAnchor.constraint(equalTo: collViewAppsList.leadingAnchor, constant: 5),
            btnLeft.centerYAnchor.constraint(equalTo: collViewAppsList.centerYAnchor),
            btnLeft.widthAnchor.constraint(equalToConstant: 30),
            btnLeft.heightAnchor.constraint(equalToConstant: 30),

            btnRight.trailingAnchor.constraint(equalTo: collViewAppsList.trailingAnchor, constant: -5),
            btnRight.centerYAnchor.constraint(equalTo: collViewAppsList.centerYAnchor),
            btnRight.widthAnchor.constraint(equalToConstant: 30),
            btnRight.heightAnchor.constraint(equalToConstant: 30)
        ])

        btnLeft.addTarget(self, action: #selector(scrollLeft), for: .touchUpInside)
        btnRight.addTarget(self, action: #selector(scrollRight), for: .touchUpInside)

        btnLeft.isHidden = true
        btnRight.isHidden = true
    }

    @objc private func scrollLeft() {
        let currentOffset = collViewAppsList.contentOffset.x
        let newOffset = max(0, currentOffset - 200)
        collViewAppsList.setContentOffset(CGPoint(x: newOffset, y: 0), animated: true)
    }

    @objc private func scrollRight() {
        let currentOffset = collViewAppsList.contentOffset.x
        let maxOffset = collViewAppsList.contentSize.width - collViewAppsList.frame.width
        let newOffset = min(maxOffset, currentOffset + 200)
        collViewAppsList.setContentOffset(CGPoint(x: newOffset, y: 0), animated: true)
    }

    private func updateArrowsVisibility() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            let contentWidth = self.collViewAppsList.contentSize.width
            let frameWidth = self.collViewAppsList.frame.width
            let currentOffset = self.collViewAppsList.contentOffset.x

            self.btnLeft.isHidden = currentOffset <= 0
            self.btnRight.isHidden = currentOffset >= (contentWidth - frameWidth - 5)

            if contentWidth <= frameWidth {
                self.btnLeft.isHidden = true
                self.btnRight.isHidden = true
            }
        }
    }
}

extension GMSMarker {
    func setIconSize(scaledToSize newSize: CGSize) {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        icon?.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        icon = newImage
    }
}
