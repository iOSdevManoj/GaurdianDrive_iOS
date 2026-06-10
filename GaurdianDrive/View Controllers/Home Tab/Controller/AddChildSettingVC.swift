//
//  AddChildSettingVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 17/12/25.
//

import UIKit

class AddChildSettingVC: UIViewController {
    
    //Reference Outlets..
    @IBOutlet var collViewAppList: UICollectionView!
    @IBOutlet var lblKmMph: UILabel!
    
    //Variables..
    var strChildID = ""
    var strQRCode = ""
    var speedRange = "35"
    var isFromSetting = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.tabBar.isHidden = true
        if rootTab.cons_bottomBar_height != nil{
            rootTab.cons_bottomBar_height.constant = 0
            rootTab.viewBottomTabMain.isHidden = true
        }
        self.initialisation()
    }
}

extension AddChildSettingVC
{
    //MARK: - Initialisation..
    func initialisation()
    {
        self.collViewAppList.register(UINib(nibName: "CellForAppsList", bundle: nil), forCellWithReuseIdentifier: "CellForAppsList")
    }
}
//MARK: - Click Events.....
extension AddChildSettingVC
{
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToAddMore(_ sender: UIButton) {
        
    }
    @IBAction func tapToSetPreference(_ sender: UIButton) {
        appDelegate.showHud()
        self.apiCallForSetSpeedRange(aSpeedRange: self.speedRange)
    }
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let intValue = Int(round(sender.value))
        self.lblKmMph.text = "\(intValue) mph"
        self.speedRange = "\(intValue)"
    }
}
//MARK: - Collectionview delegates and datasource...
extension AddChildSettingVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return 3//self.arrIntroImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellForAppsList", for: indexPath) as! CellForAppsList
        cell.btnDeleteAdd.isHidden = true
//        cell.setupImagesAndSetTags(aImage: self.arrIntroImages[indexPath.row], aTag: indexPath.row)
        return cell
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 3
    }
}

//MARK: - QR code and share funcionality
extension AddChildSettingVC
{
    func shareQRCode(aQRCode: String) {

        guard let url = URL(string: aQRCode) else { return }

        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {

                DispatchQueue.main.async {

                    let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)

                    activityVC.completionWithItemsHandler = { _, completed, _, _ in
                        if completed {
                            // ✅ Navigate ONLY after successful share
                            self.setBackToHomeScreen()
                        }
                    }

                    // iPad safety (optional)
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = self.view
                        popover.sourceRect = CGRect(x: self.view.bounds.midX,
                                                    y: self.view.bounds.midY,
                                                    width: 0,
                                                    height: 0)
                        popover.permittedArrowDirections = []
                    }

                    self.present(activityVC, animated: true)
                }
            }
        }
    }
    
    func setBackToHomeScreen()
    {
        appDelegate.isAddNewChild = !self.isFromSetting
        self.navigationController?.popToRootViewController(animated: true)
//        for controller in self.navigationController?.viewControllers ?? [] {
//            if controller is HomeVC {
//                self.navigationController?.popToViewController(controller, animated: true)
//                break
//            }
//        }
    }
}

//MARK: - Api callings...
extension AddChildSettingVC
{
    func apiCallForSetSpeedRange(aSpeedRange:String)
    {
        let param = ["speedAlertThreshold": aSpeedRange] as [String: Any]
        let strUrl = WebURL.childAccountApi + "\(self.strChildID)/speed-alert-threshold"

        apiCallViewModel.putMethodApiCallWithDisctionaryResponse(aUrl: strUrl, param: param) {
            (isSuccess, responseDict) in

            appDelegate.hideHud()

            if isSuccess {
//                self.popupAlert(title: "Child added successfully!", message:"Do you want to share QR code with child?", actionTitles: ["Cancel","Share QR"], actions:[{action1 in
//                    self.setBackToHomeScreen()
//                },{action2 in
//                    self.shareQRCode(aQRCode: self.strQRCode)
//                },nil])
                
                let qrView = QRShareView()

                qrView.setQR(url:self.strQRCode)

//                qrView.onShare = { [weak self] image in
//                    guard let image = image else { return }
//                    self!.shareQRCode(aQRCode: self!.strQRCode)
//                }
                
                qrView.onShare = { [weak self] image in
                    guard let self = self, let image = image else { return }

                    let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)

                    activityVC.completionWithItemsHandler = { _, completed, _, _ in
                        if completed {
                            self.setBackToHomeScreen()
                        }
                    }

                    self.present(activityVC, animated: true)
                }

                qrView.onCancel = {
                    self.setBackToHomeScreen()
                }

                qrView.show(in: self.view)
            }else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
}
