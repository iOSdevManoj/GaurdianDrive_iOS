//
//  NotificationListVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 22/12/25.
//

import UIKit

class NotificationListVC: UIViewController {

    //Outlets....
    @IBOutlet var tblViewNotiList: UITableView!
    @IBOutlet var lblNoData: UILabel!

    //Variables...
    var arrNotificationList = [NotificationModel]()
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Hide tabbar code...
        self.tabBarController?.tabBar.isHidden = true
        if rootTab.cons_bottomBar_height != nil{
            rootTab.cons_bottomBar_height.constant = 0
            rootTab.viewBottomTabMain.isHidden = true
        }
        
        self.initialisation()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: true)
        
        //Api calling for list..
        appDelegate.showHud()
        self.apiCallForGetNotificaions()
    }
}

extension NotificationListVC
{
    //MARK: - Initialisation..
    func initialisation()
    {
        self.tblViewNotiList.tableFooterView = UIView()
        self.tblViewNotiList.estimatedRowHeight = 80
        self.tblViewNotiList.register(UINib(nibName: "CellForNotification", bundle: nil), forCellReuseIdentifier: "CellForNotification")
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing...")
        if #available(iOS 10.0, *) {
            self.tblViewNotiList.refreshControl = refreshControl
        } else {
            self.tblViewNotiList.addSubview(refreshControl)
        }
    }
}

//MARK: - Click Events.....
extension NotificationListVC
{
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func refreshData() {
        
        //Api calling for list..
        appDelegate.showHud()
        self.apiCallForGetNotificaions()
    }
}

//MARK: - TableView Delegate and DataSources
extension NotificationListVC: UITableViewDataSource , UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return self.arrNotificationList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellForNotification") as! CellForNotification
        cell.setNotificationCellData(aModelData: self.arrNotificationList[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.arrNotificationList[indexPath.row].isRead = true
        appDelegate.readNotificationViews(notificationID: self.arrNotificationList[indexPath.row].id)
        self.tblViewNotiList.reloadRows(at: [indexPath], with: .automatic)
        
        if UserDefaults.Main.bool(forKey: .isParent) {
            
        }else {
            
        }
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
       
    }
}

//MARK: - Api callings..
extension NotificationListVC {
    
    func apiCallForGetNotificaions() {

        apiCallViewModel.getApiCallWithDisctionaryResponse(
            aUrl: WebURL.allNotification, aParams: [String: Any]()
        ) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            
            self.arrNotificationList.removeAll()

            if isSuccess {
                
                let arrResultData = getArrayFromDictionary(
                    dictionary: responseDict, key: "notifications")
                
                if arrResultData.count > 0 {
                    self.arrNotificationList = arrResultData.compactMap {
                        NotificationModel(dict: $0 as! NSDictionary)
                    }
                }
            }
            self.reloadAddressList()
        }
    }
    
    func reloadAddressList()
    {
        self.refreshControl.endRefreshing()
        
        if self.arrNotificationList.count > 0
        {
            self.tblViewNotiList.reloadData()
            self.lblNoData.isHidden = true
            self.tblViewNotiList.isHidden = false
        }else{
            self.lblNoData.isHidden = false
            self.tblViewNotiList.isHidden = true
        }
    }
}
