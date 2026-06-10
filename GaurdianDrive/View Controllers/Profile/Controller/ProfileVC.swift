//
//  ProfileVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 22/12/25.
//

import UIKit
import SwiftData
import SwiftUI

class ProfileVC: UIViewController {

    //Outlets...
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var txtName: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtMobile: UITextField!
    @IBOutlet var lblCountryCode: UILabel!
    @IBOutlet var imgCountryCode: UIImageView!
    @IBOutlet var btnParentControl: UIControl!
    @IBOutlet var lblParentControl: UILabel!

    //Variables..
    var viewForLogout = ViewForLogoutAlert() //Swipe up view logout/delete account...
    var isTapLogout = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Initialisation.
        self.initialisation()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: true)

        //Hide tabbar code...
        self.tabBarController?.tabBar.isHidden = true
        if rootTab.cons_bottomBar_height != nil{
            rootTab.cons_bottomBar_height.constant = 0
            rootTab.viewBottomTabMain.isHidden = true
        }
        
        //Get profile detaills..
        appDelegate.showHud()
        self.apiCallForUserProfile()
    }
}

//MARK: - Initialisation functions...
extension ProfileVC
{
    func initialisation()
    {
        self.setupGiftView() // Initalise logout / delete aler view..
        
        // Only show Parent Control button for child
        if !UserDefaults.Main.bool(forKey: .isParent) {
            btnParentControl.isHidden = false
        }
    }
    
    //Set profile details...
    func setUserFieldsData(aUserData:UserModel)
    {
        self.txtName.text = aUserData.name
        self.txtEmail.text = aUserData.email
        self.txtMobile.text = aUserData.mobileNo
        self.lblCountryCode.text = aUserData.countryCode
        setUserProfileImageFromUrl(aImageview: self.imgProfile, aPlaceholderName: "")
    }
}

//MARK: - Set Custom Lougout/ Delete view
extension ProfileVC{
    
    //MARK: - Add swipe up view..
    func setupGiftView()
    {
        self.setupSwipeUpLogoutView()
        self.viewForLogout.isHidden = true
    }
    
    //Custom swipe up view load from xib..
    func setupSwipeUpLogoutView()
    {
        self.viewForLogout = Bundle.main.loadNibNamed("ViewForLogoutAlert", owner: nil, options: nil)![0] as! ViewForLogoutAlert
        self.viewForLogout.frame = CGRect.init(x: 0, y: 0, width: ScreenSize.width, height: ScreenSize.height)
        self.viewForLogout.viewforBottom.roundTopCorners(radius: 16)
        self.viewForLogout.delegate = self
        self.view.addSubview(self.viewForLogout)
    }
    
    func showLogoutDeleteView()
    {
        setView(view: self.viewForLogout, hidden: false)
    }
    func hideLogoutDeleteView()
    {
        setView(view: self.viewForLogout, hidden: true)
    }
}

//MARK: - Set Custom Lougout/ Delete delegate.
extension ProfileVC : ViewForLogoutAlertDelegate{
    func tapToCloseViewAction() {
        self.hideLogoutDeleteView()
    }
    
    func tapToLogoutDeleteAction() {
        if !UserDefaults.Main.bool(forKey: .isParent) {
            self.hideLogoutDeleteView()
            let passcodeVC = ParentControlPasscodeVC()
            let actionStr = self.isTapLogout ? "logout" : "delete account"
            passcodeVC.strCustomTitle = "Enter parent passcode to proceed with \(actionStr)"
            passcodeVC.onSuccess = { [weak self] in
                guard let self = self else { return }
                if self.isTapLogout {
                    appDelegate.showHud()
                    ChildPermissionSyncManager.shared.callThisWhileLogoutChild()
                    self.apiCallForLogout()
                } else {
                    appDelegate.showHud()
                    ChildPermissionSyncManager.shared.callThisWhileLogoutChild()
                    self.apiCallForDeleteAccount()
                }
            }
            self.navigationController?.pushViewController(passcodeVC, animated: true)
        } else {
            if self.isTapLogout {
                appDelegate.showHud()
                self.apiCallForLogout()
            } else {
                appDelegate.showHud()
                self.apiCallForDeleteAccount()
            }
        }
    }
}

//MARK: - Click Events.....
extension ProfileVC
{
    @IBAction func tapToParentControl(_ sender: UIControl) {
        if UserDefaults.Main.bool(forKey: .isParent) {
            do {
                let schema = Schema([BlockingSelection.self])
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                
                AppBlockerManager.shared.modelContainer = container
                
                let parentControlView = ParentControlView(onBack: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
                .modelContainer(container)
                
                let hostingController = UIHostingController(rootView: parentControlView)
                hostingController.navigationItem.hidesBackButton = true
                self.navigationController?.pushViewController(hostingController, animated: true)
            } catch {
                print("Failed to create ModelContainer: \(error)")
            }
        } else {
            let passcodeVC = ParentControlPasscodeVC()
            self.navigationController?.pushViewController(passcodeVC, animated: true)
        }
    }
    
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToLogout(_ sender: UIControl) {
        self.viewForLogout.lblTitle.text = "Logout?"
        self.viewForLogout.lblDesc.text = "Are you sure want to logout?"
        self.viewForLogout.btnLogout.setTitle("Logout", for: .normal)
        self.isTapLogout = true
        self.showLogoutDeleteView()
    }
    @IBAction func tapToDelete(_ sender: UIControl) {
        self.viewForLogout.lblTitle.text = "Delete account?"
        self.viewForLogout.lblDesc.text = "Deleting your account will remove all of your information from our database. This can’t be undo."
        self.viewForLogout.btnLogout.setTitle("Delete", for: .normal)

        self.isTapLogout = false
        self.showLogoutDeleteView()
    }
    @IBAction func tapToEdit(_ sender: UIButton) {
        
        let objEditProfileVC = storyBoards.Settings.instantiateViewController(withIdentifier: "EditProfileVC") as! EditProfileVC
        self.navigationController?.pushViewController(objEditProfileVC, animated: true)
    }
 }
//MARK: - Api callings..
extension ProfileVC{
    
    //MARK: - Get Own user profile details..
    func apiCallForUserProfile()
    {
        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: WebURL.getProfile, aParams: [String : Any]()) { (isSuccess, responseDict) in
            
           appDelegate.hideHud()
            
            if isSuccess
            {
                setLoginUserData(dicResult: responseDict,isFromProfile: true)
                if let profileDetails = AppState.sharedInstance.user
                {
                    self.setUserFieldsData(aUserData: profileDetails)
                }
            }
            
        }
    }
    
    //Logout api...
    func apiCallForLogout()
    {
        apiCallViewModel.deleteMethodApiCallWithDisctionaryResponse(aUrl: WebURL.logout, param:[String:Any]()) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                self.hideLogoutDeleteView()
                appDelegate.logoutUser()
            }
        }
    }
    
    //Delete Account api...
    func apiCallForDeleteAccount()
    {
        apiCallViewModel.deleteMethodApiCallWithDisctionaryResponse(aUrl: WebURL.deleteAccount, param:[String:Any]()) { (isSuccess, responseDict) in
            appDelegate.hideHud()
            
            if isSuccess
            {
               
                self.hideLogoutDeleteView()
                appDelegate.logoutUser()
            }
        }
    }
    
}

extension UIView {
    func findLabel(withText text: String) -> UILabel? {
        if let label = self as? UILabel, label.text == text {
            return label
        }
        for subview in subviews {
            if let found = subview.findLabel(withText: text) {
                return found
            }
        }
        return nil
    }
}
