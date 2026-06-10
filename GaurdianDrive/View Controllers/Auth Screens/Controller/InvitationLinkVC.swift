//
//  InvitationLinkVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 15/12/25.
//

import UIKit
import CountryPickerView

class InvitationLinkVC: UIViewController {
    
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtMobile: UITextField!
    @IBOutlet var lblEmail: UILabel!
    @IBOutlet var lblPhone: UILabel!
    @IBOutlet var viewForPhone: UIView!
    @IBOutlet var viewForEmail: UIView!
    @IBOutlet var lblCountryCode: UILabel!
    @IBOutlet var imgCountryFlag: UIImageView!

    //Variables...
    var isForEmail = true
    let countryPickerView = CountryPickerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initialisation() // Basic intialisation...
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: true)
        self.navigationController?.setNavigationBarHidden(true, animated: false)

    }
}

//MARK: - Initialisation functions...
extension InvitationLinkVC
{
    func initialisation()
    {
        self.initialisCountyCodeView()
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
}

//MARK: - Click Events.....
extension InvitationLinkVC
{
    @IBAction func tapToEmail(_ sender: UIControl) {
        self.setPhoneOrEmailUIData(isFromEmail: true)
    }
    @IBAction func tapToPhone(_ sender: UIControl) {
        self.setPhoneOrEmailUIData(isFromEmail: false)
    }
    @IBAction func tapToCountryCode(_ sender: UIControl) {
        countryPickerView.showCountriesList(from: self)

    }
    @IBAction func tapToInviteNow(_ sender: UIButton) {
        let objSuccessMessageVC = storyBoards.Main.instantiateViewController(withIdentifier: "SuccessMessageVC") as! SuccessMessageVC
        objSuccessMessageVC.isComesFrom = "Invite"
        self.navigationController?.pushViewController(objSuccessMessageVC, animated: true)
    }
    
    //Email / Phone UI setup.....
    func setPhoneOrEmailUIData(isFromEmail:Bool)
    {
        self.isForEmail = isFromEmail
        self.lblPhone.isHidden = isFromEmail
        self.lblEmail.isHidden = !isFromEmail
        self.viewForPhone.isHidden = isFromEmail
        self.viewForEmail.isHidden = !isFromEmail
    }
}

//MARK: - Country Pickerview Delegates and Datasources
extension InvitationLinkVC : CountryPickerViewDelegate, CountryPickerViewDataSource
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
extension InvitationLinkVC : UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //Try to find next responder
        textField.resignFirstResponder()
        return false
    }
    
    //MARK: - Validation Method
    func isValidData() -> Bool{
        if self.isForEmail
        {
            if !(self.txtEmail.text!.isStringWithoutSpace()){
                appDelegate.window?.rootViewController?.view.makeToast("Please enter email")
                return false;
            }
            else if !(txtEmail?.text!.isValidEmail)!{
                appDelegate.window?.rootViewController?.view.makeToast("Please enter valid email id")
                return false;
            }
        }else{
            if !(self.txtMobile.text!.isStringWithoutSpace()){
                appDelegate.window?.rootViewController?.view.makeToast("Please enter phone number")
                return false;
            }
        }
        return true
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if !self.isForEmail
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
        return true
    }
}
