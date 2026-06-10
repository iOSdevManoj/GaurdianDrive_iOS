//
//  AddChildVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 16/12/25.
//

import UIKit
import CountryPickerView

class AddChildVC: UIViewController {

    //Reference Outlets..
    @IBOutlet var txtName: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtPhone: UITextField!
    @IBOutlet var txtPin: UITextField!
    @IBOutlet var lblCountryCode: UILabel!
    @IBOutlet var imgCountryFlag: UIImageView!
    @IBOutlet var btnAddChild: UIButton!
    @IBOutlet var lblHeaderTitle: UILabel!
    @IBOutlet var lblHeaderDesc: UILabel!
    @IBOutlet var viewForName: UIView!
    @IBOutlet var viewForMobile: UIView!
    @IBOutlet var viewForEmail: UIView!
    @IBOutlet var viewForPin: UIView!

    //Variables..
    let countryPickerView = CountryPickerView()
    var isForEdit = false
    var childDetails = UserModel()
    var isFromSetings = false
    
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

//MARK: - Initialisation functions...
extension AddChildVC
{
    func initialisation()
    {
        self.initialisCountyCodeView()
        if self.isForEdit
        {
            self.setChildDataForEdit()
            self.btnAddChild.setTitle("Edit Child", for: .normal)
            self.lblHeaderTitle.text = "Edit Child Deails"
            self.lblHeaderDesc.text = ""
        }
    }
    
    //MARK: - Country code initialisation..
    func initialisCountyCodeView()
    {
        //let country = countryPickerView.selectedCountry
        countryPickerView.delegate = self
        countryPickerView.dataSource = self
        countryPickerView.showCountryCodeInView = false
        countryPickerView.tintColor = UIColor.black
        countryPickerView.setCountryByCode("US")
        if let country = countryPickerView.getCountryByCode("US") {
            self.imgCountryFlag.image = country.flag
        }
    }
    
    func setChildDataForEdit()
    {
        self.txtName.text = childDetails.name
        self.txtEmail.text = childDetails.email
        self.txtPhone.text = childDetails.mobileNo
        self.lblCountryCode.text = childDetails.countryCode
        self.txtPin.text = childDetails.pin
        
        if childDetails.countryCode == "+1" || childDetails.countryCode == "1" {
            countryPickerView.setCountryByCode("US")
            if let country = countryPickerView.getCountryByCode("US") {
                self.imgCountryFlag.image = country.flag
            }
        } else if let country = countryPickerView.getCountryByPhoneCode(childDetails.countryCode) {
            countryPickerView.setCountryByCode(country.code)
            self.imgCountryFlag.image = country.flag
        }
    }
}

//MARK: - Click Events.....
extension AddChildVC
{
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToCountryCode(_ sender: UIControl) {
        countryPickerView.showCountriesList(from: self)
    }
    @IBAction func tapToAddChild(_ sender: UIButton) {
        self.view.endEditing(true)
        if self.isValidData()
        {
            appDelegate.showHud()
            
            if self.isForEdit
            {
                self.apiCallForEditChildData()
            }else{
                self.apiCallForSaveBasicDetails()
            }
        }
    }
 }

//MARK: - Country Pickerview Delegates and Datasources
extension AddChildVC : CountryPickerViewDelegate, CountryPickerViewDataSource
{
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        self.lblCountryCode.text = country.phoneCode
        self.imgCountryFlag.image = country.flag
    }
    func navigationTitle(in countryPickerView: CountryPickerView) -> String?
    {
        return "Country Code"
    }
    
    func showPhoneCodeInList(in countryPickerView: CountryPickerView) -> Bool
    {
        return true
    }
}

//MARK: - Textfield delegates...
extension AddChildVC : UITextFieldDelegate
{
    //MARK: - UITextField Delegates...
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //Try to find next responder
        textField.resignFirstResponder()
        if let nextField = textField.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        return false
    }
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if textField == self.txtPhone
        {
            // Allow only numbers
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            
            if !allowedCharacters.isSuperset(of: characterSet) {
                return false
            }
            
            // Get updated text
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else {
                return false
            }
            
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            
            // Limit to 10 digits
            return updatedText.count <= 10
        }
       else if textField == self.txtPin
        {
            // Allow only numbers
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            
            if !allowedCharacters.isSuperset(of: characterSet) {
                return false
            }
            
            // Get updated text
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else {
                return false
            }
            
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            
            // Limit to 10 digits
            return updatedText.count <= 4
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.viewForEmail.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        self.viewForMobile.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        self.viewForName.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        self.viewForPin.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor

        return true
    }
    
    //MARK: - Validation Method
    func isValidData() -> Bool {

        if !(txtEmail.text!.isStringWithoutSpace()) && !(txtPhone.text!.isStringWithoutSpace()) {
            appDelegate.window?.rootViewController?.view.makeToast("Please enter your email or phone number to continue!")
            self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return false
        }

        if !(self.txtName.text!.isStringWithoutSpace()) {
            appDelegate.window?.rootViewController?.view.makeToast("Name is required.")
            self.viewForName.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return false
        }

        // ✅ Email validation (independent)
        if !self.txtEmail.text!.isEmpty {
            if !(txtEmail.text!.isValidEmail) {
                appDelegate.window?.rootViewController?.view.makeToast("Enter valid email id")
                self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                return false
            }
        }

        // ✅ Phone validation (independent)
        if !self.txtPhone.text!.isEmpty {
            if self.txtPhone.text!.count != 10 {
                appDelegate.window?.rootViewController?.view.makeToast("Please enter valid phone number")
                self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                return false
            }
        }

        if !(self.txtPin.text!.isStringWithoutSpace()) {
            appDelegate.window?.rootViewController?.view.makeToast("Pin is required.")
            self.viewForPin.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return false
        }else if (self.txtPin.text?.removeWhiteSpace().count ?? 0) != 4 {
            appDelegate.window?.rootViewController?.view.makeToast("PIN must be 4 digits")
            self.viewForPin.layer.borderColor = UIColor(named: "AppRed")?.cgColor
            return false
        }
        return true
    }
}

//MARK: - Api callings...
extension AddChildVC
{
    //MARK: - Add Child.....
    func apiCallForSaveBasicDetails()
    {
        let param = ["email":self.txtEmail.text!, "name":self.txtName.text!, "mobileNo":self.txtPhone.text!, "countryCode":self.lblCountryCode.text!,"pin":self.txtPin.text!] as [String : Any]
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: WebURL.parentAddChild, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                let objAddChildSettingVC = storyBoards.Home.instantiateViewController(withIdentifier: "AddChildSettingVC") as! AddChildSettingVC
                objAddChildSettingVC.strQRCode = getStringFromDictionary(dictionary: responseDict, key: "qrUrl")
                objAddChildSettingVC.strChildID = getStringFromDictionary(dictionary: responseDict, key: "id")
                objAddChildSettingVC.isFromSetting = self.isFromSetings
                self.navigationController?.pushViewController(objAddChildSettingVC, animated: true)
            }else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    
    //MARK: - Get Edit profile....
    func apiCallForEditChildData()
    {
        let strUrl = WebURL.childAccountApi + "\(self.childDetails.userId)/update"
        
        let param = ["email":self.txtEmail.text!, "name":self.txtName.text!, "mobileNo":self.txtPhone.text!, "countryCode":self.lblCountryCode.text!,"pin":self.txtPin.text!] as [String : Any]

        apiCallViewModel.putMethodApiCallWithDisctionaryResponse(aUrl: strUrl, param:param) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                appDelegate.window?.rootViewController?.view.makeToast("Child updated successfully!")
                self.navigationController?.popViewController(animated: true)
            }else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
}
