//
//  AddNewAddressVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 08/03/26.
//

import UIKit
import CoreLocation

class AddNewAddressVC: UIViewController {

    //Reference Outlets..
    @IBOutlet var txtAddressType: UITextField!
    @IBOutlet var txtHouseNo: UITextField!
    @IBOutlet var txtStreet: UITextField!
    @IBOutlet var txtPincode: UITextField!
    @IBOutlet var lblMapAddress: UILabel!
    @IBOutlet var viewForAddress: UIView!
    @IBOutlet var viewForMapAddress: UIView!
    @IBOutlet var viewForHouseNo: UIView!
    @IBOutlet var btnAddAddress: UIButton!

    //Variables...
    var childAddressData = ChildAddressModel()
    var locationForChild = CLLocationCoordinate2D()
    var strMapAdress = ""
    var strChildID = ""
    var isForEdit = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialisation()
    }
    

}
//MARK: - Initialisation..
extension AddNewAddressVC
{
    func initialisation()
    {
        if self.isForEdit
        {
            self.txtAddressType.text = childAddressData.title
            self.txtHouseNo.text = childAddressData.addressLine2
            self.lblMapAddress.text = childAddressData.addressLine1
            self.txtPincode.text = childAddressData.zipcode
            self.txtStreet.text = childAddressData.landmark
            self.locationForChild.latitude = Double(childAddressData.latitude)!
            self.locationForChild.longitude = Double(childAddressData.longitude)!
            self.btnAddAddress.setTitle("Edit", for: .normal)
        }
    }
    
    func setupMapAddressFromLocation(locationCordinate:CLLocationCoordinate2D,strAddress:String)
    {
        self.locationForChild = locationCordinate
        self.strMapAdress = strAddress
        self.lblMapAddress.text = strAddress
        self.viewForMapAddress.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
    }
}

//MARK: - Click Events.....
extension AddNewAddressVC
{
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToAddAddress(_ sender: UIButton) {
        if self.isValidData()
        {
            appDelegate.showHud()
            if self.isForEdit
            {
                self.apiCallForEditAddress()
            }else {
                self.apiCallForSaveAddress()
            }
        }
    }
    @IBAction func tapToMapAddress(_ sender: UIButton) {
        let objMapViewVC = storyBoards.Home.instantiateViewController(withIdentifier: "MapViewVC") as! MapViewVC
        objMapViewVC.isFromAddress = true
        self.navigationController?.pushViewController(objMapViewVC, animated: true)
    }
}

//MARK: - Textfield delegates...
extension AddNewAddressVC : UITextFieldDelegate
{
    //MARK: - UITextField Delegates...
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //Try to find next responder
        textField.resignFirstResponder()
        return false
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.viewForAddress.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        self.viewForHouseNo.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        self.viewForMapAddress.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        return true
    }
    func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        if textField == self.txtAddressType || textField == self.txtPincode
        {
            let currentText = textField.text ?? ""
              
              // Create updated text after change
              let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
              
            // Set limit based on textField
            if textField == self.txtPincode {
                return updatedText.count <= 9
            } else if textField == self.txtAddressType {
                return updatedText.count <= 25
            }
        }
        return true
    }
  
    //MARK: - Validation Method
    func isValidData() -> Bool{
        if !(txtAddressType.text!.isStringWithoutSpace())
        {
            appDelegate.window?.rootViewController?.view.makeToast("Address required")
            self.viewForAddress.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return false;
        }
        else if !(self.lblMapAddress.text!.isStringWithoutSpace()){
            appDelegate.window?.rootViewController?.view.makeToast("Map Address required")
            self.viewForMapAddress.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return false;
        }
//        else if !(self.txtHouseNo.text!.isStringWithoutSpace()){
//            appDelegate.window?.rootViewController?.view.makeToast("House number required")
//            self.viewForHouseNo.layer.borderColor = UIColor(named:"AppRed")?.cgColor
//            return false;
//        }
        else if self.locationForChild.latitude == 0.0 && locationForChild.longitude == 0.0 {
               appDelegate.window?.rootViewController?.view.makeToast("Location required. Please select different location from map")
               return false
           }
        return true
    }
}

//MARK: - Api callings...
extension AddNewAddressVC
{
    //MARK: - Add Child.....
    func apiCallForSaveAddress()
    {
        let strUrl = WebURL.childAccountApi + "\(self.strChildID)/address"

        let param = ["title":self.txtAddressType.text!, "addressLine1":self.lblMapAddress.text!, "landmark":self.txtStreet.text!, "zipcode":self.txtPincode.text!, "addressLine2":self.txtHouseNo.text!, "latitude":self.locationForChild.latitude, "longitude":self.locationForChild.longitude] as [String : Any]
        
//        print(param)
//        print(strUrl)
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: strUrl, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                appDelegate.window?.rootViewController?.view.makeToast("Address added successfully")
                self.navigationController?.popViewController(animated: true)
            }else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    
    //MARK: - Get Edit child address....
    func apiCallForEditAddress()
    {
        let strUrl = WebURL.childAccountApi + "\(self.childAddressData.childId)/address"
        
        let param = ["id" : self.childAddressData.id, "title":self.txtAddressType.text!, "addressLine1":self.lblMapAddress.text!, "landmark":self.txtStreet.text!, "zipcode":self.txtPincode.text!, "addressLine2":self.txtHouseNo.text!, "latitude":self.locationForChild.latitude, "longitude":self.locationForChild.longitude] as [String : Any]

        apiCallViewModel.putMethodApiCallWithDisctionaryResponse(aUrl: strUrl, param:param) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                appDelegate.window?.rootViewController?.view.makeToast("Address updated successfully!")
                self.navigationController?.popViewController(animated: true)
            }else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
}
