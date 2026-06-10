//
//  SettingsVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 27/12/25.
//

import UIKit
import SwiftData
import SwiftUI
import CoreLocation
import FamilyControls

class SettingsVC: UIViewController {

    //Outlets....
    @IBOutlet var tblViewChildList: UITableView!
    @IBOutlet var cons_tbl_hight: NSLayoutConstraint!
    @IBOutlet var viewForMainBG: UIView!
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var lblUserName: UILabel!
    @IBOutlet var lblTotalChild: UILabel!
    @IBOutlet var scrollViewMain: UIScrollView!
    @IBOutlet var subscriptionExpireOn: UILabel!

    //Variables..
    private var confirmAlertView: ViewForOptionAlert?
    var arrChildList = [UserModel]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Listen for silent background refreshes triggered by push notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSubscrioptionStatus),
            name: .getSubscriptionStatus,
            object: nil
        )
        self.initialisation()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        //set subscription expire date:
        self.subscriptionExpireOn.text = appDelegate.subscriptionExpireDate
        
        //Set profile data..
        setUserProfileImageFromUrl(aImageview: self.imgProfile, aPlaceholderName: "ic_white_placeholder")
        
        //Set user details...
        if let profileDetails = AppState.sharedInstance.user
        {
            self.lblUserName.text = profileDetails.name
        }
        rootTab.viewBottomTabMain.isHidden = false
        rootTab.cons_bottomBar_height.constant = 60

        appDelegate.showHud()
        self.apiCallForGetMyAddedChild()
        appDelegate.apiCallForMySubscription()
    }
    
    override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        self.cons_tbl_hight.constant = self.tblViewChildList.contentSize.height //+ CGFloat(extraOrderHeight)
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: .getSubscriptionStatus, object: nil)
    }
}

extension SettingsVC
{
    //MARK: - Initialisation..
    func initialisation()
    {
        scrollViewMain.contentInset.bottom = tabBarController?.tabBar.frame.height ?? 50

        self.lblTotalChild.text = "0 child account(s)"
        self.viewForMainBG.roundTopCorners(radius: 16)

        self.tblViewChildList.tableFooterView = UIView()
//        self.tblViewChildList.estimatedRowHeight = 150
//        self.tblViewChildList.rowHeight = UITableView.automaticDimension
        self.tblViewChildList.register(UINib(nibName: "CellForChildList", bundle: nil), forCellReuseIdentifier: "CellForChildList")
        
    }
    // Subscription status update...
    @objc private func onSubscrioptionStatus() {
        //set subscription expire date:
        self.subscriptionExpireOn.text = appDelegate.subscriptionExpireDate
    }
}

//MARK: - Click Events.....
extension SettingsVC
{
    @IBAction func tapToProfile(_ sender: UIControl) {
        let objProfileVC = storyBoards.Settings.instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
        objProfileVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(objProfileVC, animated: true)
    }
    @IBAction func tapToNotification(_ sender: UIControl) {
        let objNotificationListVC = storyBoards.Settings.instantiateViewController(withIdentifier: "NotificationListVC") as! NotificationListVC
        objNotificationListVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(objNotificationListVC, animated: true)
    }
    @IBAction func tapToAddChild(_ sender: UIControl) {
        checkVIPAccess(from: self) {
            let objAddChildVC = storyBoards.Home.instantiateViewController(withIdentifier: "AddChildVC") as! AddChildVC
            objAddChildVC.isFromSetings = true
            self.navigationController?.pushViewController(objAddChildVC, animated: true)
        }
    }

    @IBAction func tapToSelfDriveMode(_ sender: UIControl) {
        checkVIPAccess(from: self) {
            // Location (Always) + Screen Time are required for Self Drive Mode.
            // If either is missing, show the permissions popup instead of navigating.
            let locationOK = CLLocationManager().authorizationStatus == .authorizedAlways
            let screenTimeOK = AuthorizationCenter.shared.authorizationStatus == .approved

            guard locationOK && screenTimeOK else {
                PermissionsManager.shared.checkAndShowForSelfDrive()
                return
            }

            let objParentSelfControlDriveVC = storyBoards.Settings.instantiateViewController(
                withIdentifier: "ParentSelfControlDriveVC") as! ParentSelfControlDriveVC
            self.navigationController?.pushViewController(objParentSelfControlDriveVC, animated: true)
        }

//            do {
//                let schema = Schema([BlockingSelection.self])
//                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
//                
//                AppBlockerManager.shared.modelContainer = container
//                
//                let parentControlView = ParentControlView(onBack: { [weak self] in
//                    self?.navigationController?.popViewController(animated: true)
//                })
//                .modelContainer(container)
//                
//                let hostingController = UIHostingController(rootView: parentControlView)
//                hostingController.navigationItem.hidesBackButton = true
//                self.navigationController?.pushViewController(hostingController, animated: true)
//            } catch {
//                print("Failed to create ModelContainer: \(error)")
//            }
//        } else {
//            let passcodeVC = ParentControlPasscodeVC()
//            self.navigationController?.pushViewController(passcodeVC, animated: true)
//        }
    }


    @IBAction func tapToSupport(_ sender: UIControl) {
        let objSupportVC = storyBoards.Settings.instantiateViewController(withIdentifier:"SupportVC" ) as! SupportVC
        objSupportVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(objSupportVC, animated: true)
    }
    @IBAction func tapToPolicy(_ sender: UIControl) {
        let objWebViewCommonVC = storyBoards.Settings.instantiateViewController(withIdentifier:"WebViewCommonVC" ) as! WebViewCommonVC
        objWebViewCommonVC.strTitle = "Privacy Policy"
        self.navigationController?.pushViewController(objWebViewCommonVC, animated: true)
    }
    @IBAction func tapToTermsCondition(_ sender: UIControl) {
        let objWebViewCommonVC = storyBoards.Settings.instantiateViewController(withIdentifier:"WebViewCommonVC" ) as! WebViewCommonVC
        objWebViewCommonVC.strTitle = "Terms Of Services"
        self.navigationController?.pushViewController(objWebViewCommonVC, animated: true)

    }
    @IBAction func tapToSubscription(_ sender: UIControl) {
        let objSubscriptionListVC = storyBoards.Settings.instantiateViewController(withIdentifier: "SubscriptionListVC") as! SubscriptionListVC
        objSubscriptionListVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(objSubscriptionListVC, animated: true)
    }
}

//MARK: - TableView Delegate and DataSources
extension SettingsVC: UITableViewDataSource , UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return self.arrChildList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellForChildList") as! CellForChildList
        cell.cellDelegate = self
        cell.seupChildrenDetailsFrom(aUserData: self.arrChildList[indexPath.row], aIndex: indexPath.row)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       
    }
}

//MARK: -  Cell custom delegates...
extension SettingsVC: CellForChildListDelegate
{
    func didTapToDelete(index: Int) {
        checkVIPAccess(from: self) {
            self.swipeOpenDeleteOption(aIndex: index)
        }
    }
    
    func didTapToEdit(index: Int) {
        checkVIPAccess(from: self) {
            let objAddChildVC = storyBoards.Home.instantiateViewController(withIdentifier: "AddChildVC") as! AddChildVC
            objAddChildVC.isForEdit = true
            objAddChildVC.isFromSetings = true
            objAddChildVC.childDetails = self.arrChildList[index]
            self.navigationController?.pushViewController(objAddChildVC, animated: true)
        }
    }
    
    func didTapToReInvie(index: Int) {
        checkVIPAccess(from: self) {
            appDelegate.showHud()
            self.apiCallForReInviteChild(aChildId: self.arrChildList[index].userId)
        }
    }
    
    func didTapToStatusSwich(index: Int, status: Bool) {
        checkVIPAccess(from: self) {
            appDelegate.showHud()
            self.apiCallForUpdateStatus(aChildId: self.arrChildList[index].userId, aStatus:(status) ? "ACTIVE" : "INACTIVE", aIndex: index)
        }
    }
}

//MARK: - Delete custom view....
extension SettingsVC
{
    func swipeOpenDeleteOption(aIndex:Int) {
        
        if confirmAlertView != nil { return }
        
        //Hide tabbar code...
//        self.isHideTabbar(isHide: true)
        isHideTabbarGlobally(isHide: true, viewContoller: self)
        
        // 1️⃣ Load from XIB
        let view = ViewForOptionAlert.loadFromXib()
        
        // 2️⃣ Set size (FULL SCREEN)
        view.frame = self.view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 3️⃣ Configure content & actions
        view.configure(
            title: "Delete \(self.arrChildList[aIndex].name)?",
            description: "Are you sure want to delete \(self.arrChildList[aIndex].name)?",
            yesTitle:"Yes, Delete",
            onYes: {
               // print("YES tapped")
//                self.isHideTabbar(isHide: false)
                DispatchQueue.main.async {
                    appDelegate.showHud()
                    self.apiCallForDeleteChild(aChildId: self.arrChildList[aIndex].userId, aSelectedIndex: aIndex)
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

//MARK: - Api callings..
extension SettingsVC{
    
    //MARK: - Get Added Child list..
    func apiCallForGetMyAddedChild()
    {
        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: WebURL.getAddedChilds, aParams: [String : Any]()) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            if isSuccess
            {
                self.arrChildList.removeAll()
                let arrResultData = getArrayFromDictionary(dictionary: responseDict, key: "children")
                if arrResultData.count > 0
                {
                    self.arrChildList = arrResultData.compactMap {
                        UserModel(dict: $0 as! NSDictionary)
                    }
                    self.reloadChildListWithUpdatedCellIndexes() // Reload table view child list...
                    self.lblTotalChild.text = "\(self.arrChildList.count) child account(s)"
                }else{
                    self.cons_tbl_hight.constant = 0
                }
            }else{
                self.cons_tbl_hight.constant = 0
            }
        }
    }
    
    //Children Status changes...
    func apiCallForUpdateStatus(aChildId:String,aStatus:String,aIndex:Int)
    {
        let strUrl = WebURL.childAccountApi + "\(aChildId)/update-status"

        let param = ["status":aStatus]
        
        apiCallViewModel.putMethodApiCallWithDisctionaryResponse(aUrl: strUrl, param:param) { (isSuccess, responseDict) in
            
          appDelegate.hideHud()
            
            if isSuccess
            {
                //print(responseDict)
                self.arrChildList[aIndex].status = aStatus
                self.tblViewChildList.reloadData()
            }else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    
    //Delete chils api...
    func apiCallForDeleteChild(aChildId:String,aSelectedIndex:Int)
    {
        let strUrl = WebURL.childAccountApi + "\(aChildId)"
        
        apiCallViewModel.deleteMethodApiCallWithDisctionaryResponse(aUrl:strUrl, param:[String:Any]()) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                self.arrChildList.remove(at: aSelectedIndex)
                self.lblTotalChild.text = "\(self.arrChildList.count) child account(s)"
                self.reloadChildListWithUpdatedCellIndexes()
                isHideTabbarGlobally(isHide: false, viewContoller: self)
            }
            else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    
    //Children Re-Invite api call...
    func apiCallForReInviteChild(aChildId:String)
    {
        let strUrl = WebURL.childAccountApi + "\(aChildId)/reinvite"

        apiCallViewModel.putMethodApiCallWithDisctionaryResponse(aUrl: strUrl, param:[String:Any]()) { (isSuccess, responseDict) in
            
          appDelegate.hideHud()
            
            if isSuccess
            {
                // Response is logged centrally by APILogger in ApiCallViewModel
            }else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    
    
    func reloadChildListWithUpdatedCellIndexes()
    {
        self.tblViewChildList.reloadData()
        self.tblViewChildList.layoutIfNeeded()

        DispatchQueue.main.async {
            self.view.layoutIfNeeded()
            self.cons_tbl_hight.constant = CGFloat(160 * self.arrChildList.count)
            self.view.layoutIfNeeded()
        }
    }
}

extension UITableView {
    func reloadDataTable(completion:@escaping ()->()) {
        UIView.animate(withDuration: 0, animations: { self.reloadData() })
        { _ in completion() }
    }
}
