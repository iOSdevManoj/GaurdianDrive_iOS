//
//  AddressListVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 08/03/26.
//

import UIKit

class AddressListVC: UIViewController {

    //Outlets....
    @IBOutlet var tblViewAddressList: UITableView!
    @IBOutlet var lblNoData: UILabel!

    //Variables..
    var childID = ""
    var arrChildAddress = [ChildAddressModel]()
    private var confirmAlertView: ViewForOptionAlert?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initialisation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Hide tabbar code...
        self.tabBarController?.tabBar.isHidden = true
        if rootTab.cons_bottomBar_height != nil{
            rootTab.cons_bottomBar_height.constant = 0
            rootTab.viewBottomTabMain.isHidden = true
        }
        
        appDelegate.showHud()
        self.apiCallForGetChildAddress()
    }
}

extension AddressListVC
{
    //MARK: - Initialisation..
    func initialisation()
    {
        self.tblViewAddressList.tableFooterView = UIView()
        self.tblViewAddressList.estimatedRowHeight = 80
        self.tblViewAddressList.register(UINib(nibName: "CellForAddressList", bundle: nil), forCellReuseIdentifier: "CellForAddressList")
    }
}

//MARK: - Click Events.....
extension AddressListVC
{
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToAddNewAddress(_ sender: UIButton) {
        let objAddNewAddressVC = storyBoards.Home.instantiateViewController(withIdentifier: "AddNewAddressVC") as! AddNewAddressVC
        objAddNewAddressVC.strChildID = self.childID
        self.navigationController?.pushViewController(objAddNewAddressVC, animated: true)
    }
}

//MARK: - TableView Delegate and DataSources
extension AddressListVC: UITableViewDataSource , UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrChildAddress.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellForAddressList") as! CellForAddressList
        cell.btnDelete.tag = indexPath.row
        cell.delegate = self
        if self.arrChildAddress.count > 0
        {
            cell.setAddressFromModelWith(ModelData: self.arrChildAddress[indexPath.row])
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let objAddNewAddressVC = storyBoards.Home.instantiateViewController(withIdentifier: "AddNewAddressVC") as! AddNewAddressVC
        objAddNewAddressVC.childAddressData = self.arrChildAddress[indexPath.row]
        objAddNewAddressVC.isForEdit = true
        self.navigationController?.pushViewController(objAddNewAddressVC, animated: true)
    }
}

//MARK: - Delete custom tag....
extension AddressListVC : CellForAddressListDelegate {
    func didTapDeleteAddress(tag: Int) {
        self.swipeOpenDeleteOption(aIndex: tag)
    }
    func swipeOpenDeleteOption(aIndex:Int) {
        
        if confirmAlertView != nil { return }
        
        //Hide tabbar code...
        //        self.isHideTabbar(isHide: true)
//        isHideTabbarGlobally(isHide: true, viewContoller: self)
        
        // 1️⃣ Load from XIB
        let view = ViewForOptionAlert.loadFromXib()
        
        // 2️⃣ Set size (FULL SCREEN)
        view.frame = self.view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 3️⃣ Configure content & actions
        view.configure(
            title: "Delete",
            description: "Are you sure want to delete address",
            yesTitle:"Yes, Delete",
            onYes: {
                DispatchQueue.main.async {
                    appDelegate.showHud()
                    self.apiCallForDeleteAddress(addressID: self.arrChildAddress[aIndex].id, aSelectedIndex: aIndex)
                }
            },
            onNo: {
                //isHideTabbarGlobally(isHide: true, viewContoller: self)
            },
            onClose: {
                //isHideTabbarGlobally(isHide: true, viewContoller: self)
            }
        )
        
        // 4️⃣ Add as subview (THIS IS WHERE addSubview IS DONE)
        self.view.addSubview(view)
        view.showAnimated()
        
        self.confirmAlertView = view
        
        // 🔥 6️⃣ RELEASE reference WHEN CLOSED
        view.onClose = { [weak self] in
            self?.confirmAlertView = nil
//            isHideTabbarGlobally(isHide: false, viewContoller: self!)
        }
    }
}

//MARK: - Api callings..
extension AddressListVC {
    
    //MARK: - Get Added Child list..
    func apiCallForGetChildAddress() {
        
        let strUrl = WebURL.childAccountApi + "\(self.childID)/addresses"

        apiCallViewModel.getApiCallWithDisctionaryResponse(
            aUrl: strUrl, aParams: [String: Any]()
        ) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            self.arrChildAddress.removeAll()

            if isSuccess {
                
                let arrResultData = getArrayFromDictionary(
                    dictionary: responseDict, key: "addresses")
                
                if arrResultData.count > 0 {
                    self.arrChildAddress = arrResultData.compactMap {
                        ChildAddressModel(dict: $0 as! NSDictionary)
                    }
                }
            }
            self.reloadAddressList()
        }
    }
    
    func apiCallForDeleteAddress(addressID:String,aSelectedIndex:Int)
    {
        let strUrl = WebURL.childAccountApi + "\(self.childID)/address/\(addressID)"
        
        apiCallViewModel.deleteMethodApiCallWithDisctionaryResponse(aUrl:strUrl, param:[String:Any]()) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                self.arrChildAddress.remove(at: aSelectedIndex)
                self.reloadAddressList()
            }
            else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    
    func reloadAddressList()
    {
        if self.arrChildAddress.count > 0
        {
            self.tblViewAddressList.reloadData()
            self.lblNoData.isHidden = true
            self.tblViewAddressList.isHidden = false
        }else{
            self.lblNoData.isHidden = false
            self.tblViewAddressList.isHidden = true
        }
    }
}
