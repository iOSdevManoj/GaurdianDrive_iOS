//
//  NoDriveReqListVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 23/12/25.
//

import UIKit

class NoDriveReqListVC: UIViewController {

    //Outlets....
    @IBOutlet var tblViewReqList: UITableView!
    @IBOutlet var lblTitle: UILabel!

    //Variables.
    var isFromNoDriveReq = false
    var isFromApprovedApps = false
    var isFromChild = false
    var childId: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initialisation()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        //Hide tabbar code...
        self.tabBarController?.tabBar.isHidden = true
        if rootTab.cons_bottomBar_height != nil {
            rootTab.cons_bottomBar_height.constant = 0
            rootTab.viewBottomTabMain.isHidden = true
        }

        if isFromApprovedApps {
            self.lblTitle?.text = "Approved Applications"
        } else if !isFromNoDriveReq {
            self.lblTitle?.text = "Requested Apps"
        } else {
            self.lblTitle?.text = "No Drive Requests"
        }

        if isFromChild {
            self.fetchRequestsForChild()
        } else if let id = childId {
            self.fetchRequestsForChild(id: id)
        }
    }

    func fetchRequestsForChild(id: String? = nil) {
        let finalId: String
        if let id = id {
            finalId = id
        } else if let userId = AppState.sharedInstance.user?.userId {
            finalId = userId
        } else {
            return
        }

        if !isFromChild {
            // Parent side: fetch from server using the parent's child ID
            ParentHomeViewModel.shared.fetchChildData(childId: finalId) { [weak self] success in
                guard let self = self else { return }
                if success {
                    DispatchQueue.main.async {
                        self.tblViewReqList.reloadData()
                        // Re-evaluate shields so the newly approved app is instantly unblocked
                        ParentControlViewModel.shared.updateMonitoring()
                    }
                }
            }
        } else {
            // Child side: use the same /apps endpoint as ChildHomeViewModel.
            // Support both standard requested apps and schedule apps for the view-all list.
            let group = DispatchGroup()

            group.enter()
            ChildHomeViewModel.shared.fetchRequestedApps { _ in
                group.leave()
            }

            if isFromNoDriveReq {
                group.enter()
                ChildHomeViewModel.shared.fetchRequestedNoDriveModeSchedule { _, _ in
                    group.leave()
                }
            }

            group.notify(queue: .main) { [weak self] in
                self?.tblViewReqList.reloadData()
            }
        }
    }
}

extension NoDriveReqListVC {
    //MARK: - Initialisation..
    func initialisation() {
        self.tblViewReqList.tableFooterView = UIView()
        self.tblViewReqList.estimatedRowHeight = 80
        self.tblViewReqList.register(
            UINib(nibName: "CellForRequestApps", bundle: nil),
            forCellReuseIdentifier: "CellForRequestApps")

        // Use self as delegate for actions
        // CellForRequestApps is already registered, but we need to set delegate in cellForRowAt
    }
}

//MARK: - Click Events.....
extension NoDriveReqListVC {
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
}

//MARK: - TableView Delegate and DataSources
extension NoDriveReqListVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFromChild {
            // Child side: use ChildHomeViewModel arrays
            if isFromApprovedApps {
                return ChildHomeViewModel.shared.approvedApps.count
            }
            return isFromNoDriveReq
                ? ChildHomeViewModel.shared.noDriveRequestedApps.count
                : ChildHomeViewModel.shared.normalRequestedApps.count
        } else {
            // Parent side: use ParentHomeViewModel arrays
            if isFromApprovedApps {
                return ParentHomeViewModel.shared.arrApprovedApps.count
            }
            return isFromNoDriveReq
                ? ParentHomeViewModel.shared.arrNoDriveRequests.count
                : ParentHomeViewModel.shared.arrAppRequests.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell =
            tableView.dequeueReusableCell(withIdentifier: "CellForRequestApps")
            as! CellForRequestApps
        cell.cellDelegate = self
        let request: ChildRequestedApp

        if isFromChild {
            // Child side: read from ChildHomeViewModel
            if isFromApprovedApps {
                request = ChildHomeViewModel.shared.approvedApps[indexPath.row]
                cell.setCellDataWihModelData(
                    data: request, aIndex: request.id ?? indexPath.row, isTblReq: true)
                cell.lblStatus.text = "APPROVED"
                cell.lblStatus.textColor = UIColor(named: "AppGreen") ?? UIColor.systemGreen
                cell.lblStatus.backgroundColor =
                    (UIColor(named: "AppGreen") ?? UIColor.systemGreen).withAlphaComponent(0.15)
                cell.btnCross.isHidden = false // Child can cancel their own approved app (?)
                cell.btnCross.tag = request.id ?? -1
            } else if !isFromNoDriveReq {
                request = ChildHomeViewModel.shared.normalRequestedApps[indexPath.row]
                cell.setCellDataWihModelData(
                    data: request, aIndex: request.id ?? indexPath.row, isTblReq: true)
// ... truncated logic for brevity ...
                let status = (request.currentStatus ?? request.status ?? "").uppercased()
                switch status {
                case "REJECTED":
                    cell.lblStatus.text = "REJECTED"
                    cell.lblStatus.textColor = UIColor.systemOrange
                    cell.lblStatus.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
                    cell.btnCross.isHidden = true
                case "APPROVED":
                    cell.lblStatus.text = "APPROVED"
                    cell.lblStatus.textColor = UIColor(named: "AppGreen") ?? UIColor.systemGreen
                    cell.lblStatus.backgroundColor =
                        (UIColor(named: "AppGreen") ?? UIColor.systemGreen).withAlphaComponent(0.15)
                    cell.btnCross.isHidden = true
                default:  // REQUESTED
                    cell.btnCross.isHidden = false
                }
                cell.btnCross.tag = request.id ?? -1
            } else {
                request = ChildHomeViewModel.shared.noDriveRequestedApps[indexPath.row]
                cell.setCellDataWihModelData(
                    data: request, aIndex: request.id ?? indexPath.row, isTblReq: false)
                let status = (request.currentStatus ?? request.status ?? "").uppercased()
                switch status {
                case "APPROVED":
                    cell.lblStatus.text = "APPROVED"
                    cell.lblStatus.textColor = UIColor(named: "AppGreen") ?? UIColor.systemGreen
                    cell.lblStatus.backgroundColor =
                        (UIColor(named: "AppGreen") ?? UIColor.systemGreen).withAlphaComponent(0.15)
                case "REJECTED":
                    cell.lblStatus.text = "REJECTED"
                    cell.lblStatus.textColor = UIColor.systemOrange
                    cell.lblStatus.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
                default:
                    break
                }
                // Show ✕ only for REQUESTED (cancellable); tag holds actual ID
                cell.btnCross.tag = request.id ?? -1
                cell.btnCross.isHidden = (status != "REQUESTED")
            }
//            cell.lblApprove.isHidden = true
            cell.cons_lblApproved_width.constant = 0
            cell.btnApproved.isHidden = true
        } else {
            // Parent side: read from ParentHomeViewModel
            if isFromApprovedApps {
                request = ParentHomeViewModel.shared.arrApprovedApps[indexPath.row]
                cell.setCellDataWihModelData(data: request, aIndex: indexPath.row, isTblReq: true)
                cell.lblStatus.text = "APPROVED"
                cell.lblStatus.textColor = UIColor(named: "AppGreen") ?? UIColor.systemGreen
                cell.lblStatus.backgroundColor = (UIColor(named: "AppGreen") ?? UIColor.systemGreen)
                    .withAlphaComponent(0.15)
                cell.btnCross.isHidden = false // Parent can revoke
                cell.cons_lblApproved_width.constant = 0
                cell.btnApproved.isHidden = true
            } else if !isFromNoDriveReq {
                request = ParentHomeViewModel.shared.arrAppRequests[indexPath.row]
                cell.setCellDataWihModelData(data: request, aIndex: indexPath.row, isTblReq: true)
                let status = (request.currentStatus ?? request.status ?? "").uppercased()
                switch status {
                case "APPROVED":
                    cell.cons_lblApproved_width.constant = 0
                    cell.btnApproved.isHidden = true
                    cell.btnCross.isHidden = false
                    cell.lblStatus.text = "APPROVED"
                    cell.lblStatus.textColor = UIColor(named: "AppGreen") ?? UIColor.systemGreen
                    cell.lblStatus.backgroundColor = (UIColor(named: "AppGreen") ?? UIColor.systemGreen)
                        .withAlphaComponent(0.15)
                case "REJECTED":
                    cell.cons_lblApproved_width.constant = 0
                    cell.btnApproved.isHidden = true
                    cell.btnCross.isHidden = true
                    cell.lblStatus.text = "REJECTED"
                    cell.lblStatus.textColor = UIColor.systemOrange
                    cell.lblStatus.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
                default:
                    cell.cons_lblApproved_width.constant = 100
                    cell.btnApproved.isHidden = false
                    cell.btnCross.isHidden = false
                }
            } else {
                request = ParentHomeViewModel.shared.arrNoDriveRequests[indexPath.row]
                cell.setCellDataWihModelData(data: request, aIndex: indexPath.row, isTblReq: false)
                let status = (request.currentStatus ?? request.status ?? "").uppercased()
                switch status {
                case "APPROVED":
                    cell.cons_lblApproved_width.constant = 0
                    cell.btnApproved.isHidden = true
                    cell.btnCross.isHidden = false
                    cell.lblStatus.text = "APPROVED"
                    cell.lblStatus.textColor = UIColor(named: "AppGreen") ?? UIColor.systemGreen
                    cell.lblStatus.backgroundColor = (UIColor(named: "AppGreen") ?? UIColor.systemGreen)
                        .withAlphaComponent(0.15)
                case "REJECTED":
                    cell.cons_lblApproved_width.constant = 0
                    cell.btnApproved.isHidden = true
                    cell.btnCross.isHidden = true
                    cell.lblStatus.text = "REJECTED"
                    cell.lblStatus.textColor = UIColor.systemOrange
                    cell.lblStatus.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
                default:
                    cell.cons_lblApproved_width.constant = 100
                    cell.btnApproved.isHidden = false
                    cell.btnCross.isHidden = false
                }
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

extension NoDriveReqListVC: CellForRequestAppsDelegate {
    func didTapApprove(index: Int) {
        guard let childId = childId else { return }
        let request =
            isFromNoDriveReq
            ? ParentHomeViewModel.shared.arrNoDriveRequests[index]
            : ParentHomeViewModel.shared.arrAppRequests[index]

        appDelegate.showHud()
        if isFromNoDriveReq {
            ParentHomeViewModel.shared.performNoDriveModeAction(
                childId: childId, request: request, action: "approve"
            ) { success, message in
                appDelegate.hideHud()
                if success {
                    self.fetchRequestsForChild(id: childId)
                } else {
                    self.view.makeToast(message ?? "Failed to approve")
                }
            }
        } else {
            let requestId = request.id != nil ? String(request.id!) : (request._id ?? "")
            ParentHomeViewModel.shared.performAppRequestAction(
                childId: childId, requestId: requestId, action: "approve",
                permissionType: request.permissionType ?? "DRIVE_MODE"
            ) { success, message in
                appDelegate.hideHud()
                if success {
                    self.fetchRequestsForChild(id: childId)
                } else {
                    self.view.makeToast(message ?? "Failed to approve")
                }
            }
        }
    }

    func didTapCross(index: Int) {
        if isFromChild {
            let requestId = index
            guard requestId > 0 else {
                self.view.makeToast("Unable to cancel: invalid request ID")
                return
            }
            let vm = ChildHomeViewModel.shared
            let isSchedule = vm.noDriveModeScheduleList.contains { $0.id == requestId }
            print("🔍 [Cancel ViewAll] requestId=\(requestId) isSchedule=\(isSchedule)")

            appDelegate.showHud()
            let cancel: (@escaping (Bool) -> Void) -> Void =
                isSchedule
                ? { vm.cancelNoDriveModeRequest(requestId: requestId, completion: $0) }
                : { vm.cancelAppRequest(requestId: requestId, completion: $0) }

            cancel { [weak self] success in
                DispatchQueue.main.async {
                    appDelegate.hideHud()
                    self?.view.makeToast(
                        success ? "Request cancelled successfully" : "Failed to cancel request")
                    if success { self?.fetchRequestsForChild() }
                }
            }
            return
        }

        guard let childId = childId else { return }
        let request: ChildRequestedApp
        if isFromApprovedApps {
            request = ParentHomeViewModel.shared.arrApprovedApps[index]
        } else if isFromNoDriveReq {
            request = ParentHomeViewModel.shared.arrNoDriveRequests[index]
        } else {
            request = ParentHomeViewModel.shared.arrAppRequests[index]
        }
        
        let isApproved = (request.currentStatus ?? request.status ?? "").uppercased() == "APPROVED" || isFromApprovedApps

        appDelegate.showHud()
        if isFromApprovedApps {
            let requestId = request.id != nil ? String(request.id!) : (request._id ?? "")
            ParentHomeViewModel.shared.cancelApprovedApp(childId: childId, requestId: requestId) { success, message in
                appDelegate.hideHud()
                if success {
                    self.fetchRequestsForChild(id: childId)
                } else {
                    self.view.makeToast(message ?? "Failed to cancel approved app")
                }
            }
        } else if isFromNoDriveReq {
            let isApproved = (request.currentStatus ?? request.status ?? "").uppercased() == "APPROVED"
            if isApproved {
                // Approved request → call cancel endpoint
                ParentHomeViewModel.shared.cancelNoDriveModeAction(
                    childId: childId, request: request
                ) { success, message in
                    appDelegate.hideHud()
                    if success {
                        self.fetchRequestsForChild(id: childId)
                    } else {
                        self.view.makeToast(message ?? "Failed to cancel approved request")
                    }
                }
            } else {
                // Pending/Requested → call reject endpoint
                ParentHomeViewModel.shared.performNoDriveModeAction(
                    childId: childId, request: request, action: "reject"
                ) { success, message in
                    appDelegate.hideHud()
                    if success {
                        self.fetchRequestsForChild(id: childId)
                    } else {
                        self.view.makeToast(message ?? "Failed to reject request")
                    }
                }
            }
        } else {
            let requestId = request.id != nil ? String(request.id!) : (request._id ?? "")
            ParentHomeViewModel.shared.performAppRequestAction(
                childId: childId, requestId: requestId, action: "reject",
                permissionType: request.permissionType ?? "DRIVE_MODE"
            ) { success, message in
                appDelegate.hideHud()
                if success {
                    self.fetchRequestsForChild(id: childId)
                } else {
                    self.view.makeToast(message ?? "Failed to reject")
                }
            }
        }
    }
}
