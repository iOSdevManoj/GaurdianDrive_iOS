//
//  ReportVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 29/12/25.
//

import UIKit

class ReportVC: UIViewController {

    //Outlets....
    @IBOutlet weak var tblViewTopSpeedList: UITableView!
    @IBOutlet weak var viewForBG: UIView!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var collViewChildList: UICollectionView!
    @IBOutlet weak var cons_tblview_hight: NSLayoutConstraint!
    @IBOutlet weak var chartView: WeeklyLineChartView!
    @IBOutlet weak var weeklyChartView: WeeklyBarChartView!
    @IBOutlet var scrollViewMain: UIScrollView!
    @IBOutlet weak var lblNoData: UILabel!
    @IBOutlet weak var lblAvgSpeed: UILabel!
    @IBOutlet weak var lblHighSpeed: UILabel!
    @IBOutlet weak var lblDriveActivation: UILabel!
    @IBOutlet weak var lblTimeToDrive: UILabel!
    @IBOutlet weak var lblNightDriving: UILabel!
    @IBOutlet weak var segmentDayRange: UISegmentedControl!
    
    //Variables..
    var childSelectedIndex = 0
    var arrChildList = [UserModel]()
    var reportData = ReportDataModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initialisation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUserProfileImageFromUrl(aImageview: self.imgProfile, aPlaceholderName: "ic_white_placeholder")
        //Set user details...
        if let profileDetails = AppState.sharedInstance.user
        {
            self.lblUserName.text = profileDetails.name
        }
        rootTab.viewBottomTabMain.isHidden = false
        rootTab.cons_bottomBar_height.constant = 60

        //Get child list..
        appDelegate.showHud()
        self.apiCallForGetMyAddedChild()
        appDelegate.apiCallForMySubscription()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
extension ReportVC
{
    //MARK: - Initialisation..
    func initialisation()
    {
        scrollViewMain.contentInset.bottom = tabBarController?.tabBar.frame.height ?? 50

        self.viewForBG.roundTopCorners(radius: 16)

        self.collViewChildList.register(UINib(nibName: "CellForChildName", bundle: nil), forCellWithReuseIdentifier: "CellForChildName")
        if let layout = collViewChildList.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.scrollDirection = .horizontal
        }
        
        self.tblViewTopSpeedList.tableFooterView = UIView()
        self.tblViewTopSpeedList.estimatedRowHeight = 80
        self.tblViewTopSpeedList.register(UINib(nibName: "CellForopSpeedList", bundle: nil), forCellReuseIdentifier: "CellForopSpeedList")
        
        //Day range segment UI....
        segmentDayRange.selectedSegmentTintColor = UIColor(named: "AppDarkBlue")
        segmentDayRange.setTitleTextAttributes(
               [.foregroundColor: UIColor.white],
               for: .selected
           )
        segmentDayRange.setTitleTextAttributes(
               [.foregroundColor: UIColor(named: "AppDarkBlue") ?? UIColor.blue],
               for: .normal
           )
        segmentDayRange.backgroundColor = UIColor(named: "BGLighGray")
        segmentDayRange.layer.cornerRadius = 8
        segmentDayRange.layer.masksToBounds = true
    }
    
    //Setup All screen data from api response..
    func setupReportDataAsPerChild()
    {
        let speedData = (self.reportData.averageSpeed == "") ? "0.0" : self.reportData.averageSpeed
        let speed = Double(speedData)
        self.lblAvgSpeed.text = String(format: "%.2f", speed!) + " mph"
        self.lblHighSpeed.text = (self.reportData.highestSpeed == "") ? "0" : self.reportData.highestSpeed + " mph"
        self.lblDriveActivation.text = (self.reportData.noOfActiveDriveMode == "") ? "0" : self.reportData.noOfActiveDriveMode
        self.lblTimeToDrive.text = (self.reportData.durationOfActiveDriveMode == "") ? "0 min" : self.reportData.durationOfActiveDriveMode + " min"
        self.lblNightDriving.text = (self.reportData.percentageOfNightDrive == "") ? "0%" : self.reportData.percentageOfNightDrive + "%"
        
        self.tblViewTopSpeedList.reloadData()
        DispatchQueue.main.async {
            self.tblViewTopSpeedList.layoutIfNeeded()
            self.cons_tblview_hight.constant = self.tblViewTopSpeedList.contentSize.height
        }
        
        //Daily Avg Speed Load chart data....
        self.loadChart()
        
        //Drive activity per day chart....
        self.prepareBarChartData(from: reportData.dailyHistories)
    }
    
    func loadChart() {
        let values = reportData.dailyHistories.map {
            CGFloat(Double($0.averageSpeed) ?? 0)
        }

        let days = reportData.dailyHistories.map {
            String($0.day.prefix(1))   // M T W T F S S
        }

        chartView.setData(values: values, days: days)
    }
    
    func prepareBarChartData(from histories: [DailyHistories]) {

        let days: [String] = histories.map {
               String($0.day.prefix(1))   // M T W T F S S
           }

           // ✅ GREEN → noOfActiveDriveMode
           let greenValues: [CGFloat] = histories.map {
               CGFloat(Double($0.noOfActiveDriveMode) ?? 0)
           }

           // ✅ RED → durationOfActiveDriveMode
           let redValues: [CGFloat] = histories.map {
               CGFloat(Double($0.durationOfActiveDriveMode) ?? 0)
           }

           weeklyChartView.configure(
               days: days,
               greenValues: greenValues,
               redValues: redValues
           )
    }
}

//MARK: - Click Events.....
extension ReportVC
{
    @IBAction func tapToNotificaion(_ sender: UIControl) {
        let objNotificationListVC = storyBoards.Settings.instantiateViewController(withIdentifier: "NotificationListVC") as! NotificationListVC
        objNotificationListVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(objNotificationListVC, animated: true)
    }
    @IBAction func tapToProfile(_ sender: UIControl) {
        let objProfileVC = storyBoards.Settings.instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
        objProfileVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(objProfileVC, animated: true)
    }
    
    @IBAction func segmentDayChanged(_ sender: UISegmentedControl) {

        if sender.selectedSegmentIndex == 0 {
            self.apiCallForGetChildMerixData(withDays:"7")
        } else {
            self.apiCallForGetChildMerixData(withDays:"15")
        }
    }
}

//MARK: - TableView Delegate and DataSources
extension ReportVC: UITableViewDataSource , UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return self.reportData.topSpeeds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellForopSpeedList") as! CellForopSpeedList
        cell.setDataFromServerWithModel(aTopSpeedData: self.reportData.topSpeeds[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    }
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//       
//    }
}

//MARK: - Collectionview delegates and datasource...
extension ReportVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = self.arrChildList[indexPath.row].name // your data source
        let font = UIFont(name: FontName.PlusJakartaSansSemiBold, size: 16) // match your label font

        let padding: CGFloat = 12 // left + right padding inside cell

        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width

        let width = max(60, min(textWidth + padding, 200))

        return CGSize(width: width, height: self.collViewChildList.frame.height)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrChildList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellForChildName", for: indexPath) as! CellForChildName
        cell.setupChildrenListFrom(userData: self.arrChildList[indexPath.row], aSelectedIndex: self.childSelectedIndex, cellIndex: indexPath.row)
        return cell
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == collViewChildList
        {
            self.childSelectedIndex = indexPath.row
            self.segmentDayRange.selectedSegmentIndex = 0
            self.collViewChildList.reloadData()
            self.apiCallForGetChildMerixData(withDays:"7")
        }
    }
}

//MARK: - Collectionview delegates and datasource...
extension ReportVC
{
    //MARK: - Get Added Child list..
    func apiCallForGetMyAddedChild()
    {
        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: WebURL.getAddedChilds, aParams: [String : Any]()) { (isSuccess, responseDict) in
            if isSuccess
            {
                self.arrChildList.removeAll()
                let arrResultData = getArrayFromDictionary(dictionary: responseDict, key: "children")
                if arrResultData.count > 0
                {
                    self.scrollViewMain.isHidden = false
                    self.lblNoData.isHidden = true

                    self.arrChildList = arrResultData.compactMap {
                        UserModel(dict: $0 as! NSDictionary)
                    }
                    self.collViewChildList.reloadData()
                    self.apiCallForGetChildMerixData(withDays:"7")
                }else
                {
                    appDelegate.hideHud()
                    self.scrollViewMain.isHidden = true
                    self.lblNoData.isHidden = false
                }
            }else {
                appDelegate.hideHud()
                self.scrollViewMain.isHidden = true
                self.lblNoData.isHidden = false
            }
        }
    }
    
    //MARK: - Get Child All Report Data...
    func apiCallForGetChildMerixData(withDays:String)
    {
        let strUrl = WebURL.childAccountApi + "\(self.arrChildList[self.childSelectedIndex].userId)/key-metrics/\(withDays)"

        apiCallViewModel.getApiCallWithDisctionaryResponse(aUrl: strUrl, aParams: [String : Any]()) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                self.reportData = ReportDataModel.init(dict: responseDict as NSDictionary)
                self.setupReportDataAsPerChild()
            }
        }
    }
}

