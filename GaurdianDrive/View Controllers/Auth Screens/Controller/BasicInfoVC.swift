//
//  BasicInfoVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 15/12/25.
//

import UIKit
import CountryPickerView

class BasicInfoVC: UIViewController {

    //Reference Outlets..
    @IBOutlet var txtName: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtPhone: UITextField!
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var lblCountryCode: UILabel!
    @IBOutlet var imgCountryFlag: UIImageView!
    @IBOutlet var btnVerifyEmail: UIButton!
    @IBOutlet var btnVerifyPhone: UIButton!
    @IBOutlet var viewForName: UIView!
    @IBOutlet var viewForMobile: UIView!
    @IBOutlet var viewForEmail: UIView!

    //Variables..
    var isForEmail = false
    private var cameraController = UIImagePickerController()
    var isSelectedProfile = false
    var strEmailPhone = ""
    let countryPickerView = CountryPickerView()
    var isEmailVerify = false
    var isPhoneVerify = false
    var isFromSocial = false
    var dictUserDetails = [String:Any]()
    var strCountyCode = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialisation()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: true)
        self.navigationController?.setNavigationBarHidden(true, animated: false)

    }
}

//MARK: - Click Events.....
extension BasicInfoVC
{
    func initialisation()
    {
        if self.isFromSocial
        {
            self.txtName.text = createString(value:  dictUserDetails["name"] as AnyObject)
            self.txtEmail.text = createString(value:  dictUserDetails["email"] as AnyObject)
            
            if self.txtEmail.text?.removeWhiteSpace() != ""
            {
                self.txtEmail.isUserInteractionEnabled = false
                self.btnVerifyEmail.isHidden = true
                self.isEmailVerify = true
            }else{
                self.btnVerifyEmail.isHidden = false
            }
        }else {
            if self.isForEmail
            {
                self.txtEmail.isUserInteractionEnabled = false
                self.txtEmail.text = self.strEmailPhone
                self.btnVerifyEmail.isHidden = true
            }else{
                self.txtPhone.isUserInteractionEnabled = false
                self.txtPhone.text = self.strEmailPhone
                self.btnVerifyPhone.isHidden = true
            }
        }
        
        self.initialisCountyCodeView()
    }
    
    //MARK: - Country code initialisation..
    func initialisCountyCodeView()
    {
        //let country = countryPickerView.selectedCountry
        self.lblCountryCode.text = self.strCountyCode
        countryPickerView.delegate = self
        countryPickerView.dataSource = self
        countryPickerView.showCountryCodeInView = false
        countryPickerView.tintColor = UIColor.black
       
        if self.strCountyCode == "" || self.strCountyCode == "+1"
        {
            countryPickerView.setCountryByCode("US")
            if let country = countryPickerView.getCountryByCode("US") {
                self.imgCountryFlag.image = country.flag
            }
        }else {
            let countryCode = countryPickerView.getCountryByPhoneCode(self.strCountyCode)
            countryPickerView.setCountryByCode(countryCode!.code)
            if let country = countryPickerView.getCountryByCode(countryCode!.code) {
                self.imgCountryFlag.image = country.flag
            }
        }
    }
    
    //Back from OTP Verification and setup as per verified
    func setupVerificationFromDetails(isFromEmail:Bool)
    {
        if isFromEmail
        {
            self.isEmailVerify = true
            self.setupIntracionAndColorForFields(aTxtField: self.txtEmail, aBtn: self.btnVerifyEmail)
            self.viewForEmail.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor

        }else{
            self.isPhoneVerify = true
            self.setupIntracionAndColorForFields(aTxtField: self.txtPhone, aBtn: self.btnVerifyPhone)
            self.viewForMobile.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        }
    }
    
    func setupIntracionAndColorForFields(aTxtField:UITextField,aBtn:UIButton)
    {
        aBtn.setTitle("Verified", for: .normal)
        aBtn.isUserInteractionEnabled = false
        aBtn.setTitleColor(UIColor(named:"AppGreen"), for: .normal)
        aTxtField.isUserInteractionEnabled = false
    }
}

//MARK: - Click Events.....
extension BasicInfoVC
{
    @IBAction private func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToProfile(_ sender: UIControl) {
        self.openGalleryPopUp()
    }
    @IBAction func tapToSubmit(_ sender: UIButton) {
        if self.isValidData()
        {
            appDelegate.showHud()

            if self.isSelectedProfile
            {
                if self.isFromSocial{
                    if !self.isValidDataForSocialRegister()
                    {
                        appDelegate.hideHud()
                        return
                    }
                }
                let comrpessImageData = self.imgProfile.image!.jpegData(compressionQuality: 0.6)!
                self.apiCalluploadProfilelFile(aDataFile: comrpessImageData)
            }else {
                if self.isFromSocial
                {
                    if self.isValidDataForSocialRegister()
                    {
                        self.apiCallForSocialRegister(aProfileDpId:"")
                    }else{
                        appDelegate.hideHud()
                    }
                }else{
                    self.apiCallForSaveBasicDetails(aProfileDpId: "")
                }
            }
        }
    }
    @IBAction func tapToCountryCode(_ sender: UIControl) {
        if self.isForEmail
        {
            countryPickerView.showCountriesList(from: self)
        }
    }
    @IBAction func tapToVerifyEmail(_ sender: UIButton) {
        self.view.endEditing(true)
        if !(txtEmail.text!.isStringWithoutSpace()){
            appDelegate.window?.rootViewController?.view.makeToast("Please enter your email")
            self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return
        }
        else if !(txtEmail?.text!.isValidEmail)!{
            appDelegate.window?.rootViewController?.view.makeToast("Please enter valid email")
            self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return
        }
        appDelegate.showHud()
        self.apiCallForSendVerificationCode(isEmail: true)
    }
    @IBAction func tapToVerifyPhone(_ sender: UIButton) {
        self.view.endEditing(true)
        if !(txtPhone.text!.isStringWithoutSpace()){
            appDelegate.window?.rootViewController?.view.makeToast("Please enter your phone number")
            self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return
        }
        appDelegate.showHud()
        self.apiCallForSendVerificationCode(isEmail: false)
    }
    
    func navigateToOtpWith(isFromEmail:Bool)
    {
        let objOTPVC = storyBoards.Main.instantiateViewController(withIdentifier: "OTPVC") as! OTPVC
        objOTPVC.isForVerification = true
        objOTPVC.isEmail = isFromEmail
        objOTPVC.strEmailPhone = isFromEmail ? self.txtEmail.text! : self.txtPhone.text!
        objOTPVC.strCountyCode = self.lblCountryCode.text!
        self.navigationController?.pushViewController(objOTPVC, animated: true)
    }
}

//MARK: - Country Pickerview Delegates and Datasources
extension BasicInfoVC : CountryPickerViewDelegate, CountryPickerViewDataSource
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
extension BasicInfoVC : UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //Try to find next responder
        textField.resignFirstResponder()
        return false
    }
    
    //MARK: - Validation Method
    func isValidData() -> Bool{
        if !(self.txtName.text!.isStringWithoutSpace()){
            appDelegate.window?.rootViewController?.view.makeToast("Name is required.")
            self.viewForName.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return false;
        }
        if !self.isForEmail
        {
            if !self.txtEmail.text!.isEmpty
           {
               if !(txtEmail?.text!.isValidEmail)!{
                   appDelegate.window?.rootViewController?.view.makeToast("Enter valid email id")
                   self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                   return false;
               }
                else if !self.isEmailVerify
                {
                    appDelegate.window?.rootViewController?.view.makeToast("Please verify your email!")
                    self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                    return false;
                }
           }
        }
        else if self.isForEmail
        {
            if !self.txtPhone.text!.isEmpty
            {
                if self.txtPhone.text!.count != 10
                {
                    appDelegate.window?.rootViewController?.view.makeToast("Please enter valid phone number")
                    self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                    return false;

                }
                else if !self.isPhoneVerify
                {
                    appDelegate.window?.rootViewController?.view.makeToast("Please verify your phone number!")
                    self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                    return false;
                }
            }
        }
        return true
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.viewForEmail.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        self.viewForMobile.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        self.viewForName.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        return true
    }
    
    //MARK: - Validation Method
    func isValidDataForSocialRegister() -> Bool{
        if !(txtEmail.text!.isStringWithoutSpace()) && !(txtPhone.text!.isStringWithoutSpace())
        {
            appDelegate.window?.rootViewController?.view.makeToast("Please enter your email or phone number to continue!")
            self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return false;
        }
         if !self.txtEmail.text!.isEmpty
        {
            if !(txtEmail?.text!.isValidEmail)!{
                appDelegate.window?.rootViewController?.view.makeToast("Enter valid email id")
                self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                return false;
            }
            else if !self.isEmailVerify
            {
                appDelegate.window?.rootViewController?.view.makeToast("Please verify your email!")
                self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                return false;
            }
        }
        
        if !self.txtPhone.text!.isEmpty
        {
            if self.txtPhone.text!.count != 10
            {
                appDelegate.window?.rootViewController?.view.makeToast("Please enter valid phone number")
                self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                return false;
                
            }
            else if !self.isPhoneVerify
            {
                appDelegate.window?.rootViewController?.view.makeToast("Please verify your phone number!")
                self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                return false;
            }
        }
        return true
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
        return true
    }
}

//MARK: - ImagePicker Delegates and Methods...
extension BasicInfoVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func openGalleryPopUp()
    {    //getLabel(aKey: "txt_cancel")
        let alert = UIAlertController(title:"Profile", message: "Select Option", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Camera", style:UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            _ = self.startCameraFromViewController(self, sourceType:.camera, withDelegate:self as UIImagePickerControllerDelegate & UINavigationControllerDelegate)
        }))
        
        alert.addAction(UIAlertAction(title: "Library", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            let success = self.startCameraFromViewController(self, sourceType: .photoLibrary, withDelegate: self )
            print(success)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK :- Actionsheet Method
    func startCameraFromViewController(_ viewController: UIViewController,sourceType:UIImagePickerController.SourceType, withDelegate delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) -> Bool {
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) == false {
            return false
        }
        cameraController = UIImagePickerController()
        cameraController.sourceType = sourceType
        cameraController.allowsEditing = true
        cameraController.delegate = delegate
        present(cameraController, animated: true, completion: nil)
        return true
    }
    
    //MARK: - ImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.isSelectedProfile = true
            self.imgProfile.image = pickedImage
        }
        cameraController.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        cameraController.dismiss(animated: true, completion: nil)
    }
}

//MARK: - Api callings...
extension BasicInfoVC
{
    //MARK: - Save user details...
    func apiCallForSaveBasicDetails(aProfileDpId:String)
    {
        var param = [String : Any]()
        var webUrl = ""
        
        if self.isForEmail
        {
            webUrl = appDelegate.isFromParent
            ? WebURL.submitBasicData
            : WebURL.submitChildBasicData
        }else{
            webUrl = appDelegate.isFromParent
                ? WebURL.submitPhoneBasicData
            : WebURL.submitChildPhoneBasicData
        }
        
        param = ["email":self.txtEmail.text!, "name":self.txtName.text!, "mobileNo":self.txtPhone.text!, "countryCode":self.lblCountryCode.text!, "timeZoneOffset":getTimeZoneOffsetMinutes(),"dpId":aProfileDpId] as [String : Any]

        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: webUrl, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
//                self.profileImageId = ""
                setLoginUserData(dicResult: responseDict,isFromProfile: false)
                UserDefaults.Main.set(true, forKey: .autoLogin)

                if appDelegate.isFromParent
                {
                    UserDefaults.Main.set(true, forKey: .isParent)
                    appDelegate.setRootController()
                }else{
                    UserDefaults.Main.set(false, forKey: .isParent)
                    let objChildHomeVC = storyBoards.Child.instantiateViewController(withIdentifier: "ChildHomeVC") as! ChildHomeVC
                    self.navigationController?.pushViewController(objChildHomeVC, animated: true)
                }
            }
            else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    
    //MARK: - Social Register...
    func apiCallForSocialRegister(aProfileDpId:String)
    {
        let param = ["email":self.txtEmail.text!, "name":self.txtName.text!, "mobileNo":self.txtPhone.text!, "countryCode":self.lblCountryCode.text!, "timeZoneOffset":getTimeZoneOffsetMinutes(), "socialToken":createString(value:dictUserDetails["socialToken"] as AnyObject), "socialType":createString(value:dictUserDetails["socialType"] as AnyObject),"dpId":aProfileDpId] as [String : Any]

        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: WebURL.socialRegister, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
//                self.profileImageId = ""
                setLoginUserData(dicResult: responseDict,isFromProfile: false)
                UserDefaults.Main.set(true, forKey: .autoLogin)

                if appDelegate.isFromParent
                {
                    UserDefaults.Main.set(true, forKey: .isParent)
                    appDelegate.setRootController()
                }else{
                    UserDefaults.Main.set(false, forKey: .isParent)
                    let objChildHomeVC = storyBoards.Child.instantiateViewController(withIdentifier: "ChildHomeVC") as! ChildHomeVC
                    self.navigationController?.pushViewController(objChildHomeVC, animated: true)
                }
            }
            else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    
    //MARK: - Verification code sent.
    func apiCallForSendVerificationCode(isEmail:Bool)
    {
        var param = [String : Any]()
        var webUrl = ""

        if isEmail
        {
            webUrl = appDelegate.isFromParent
                ? WebURL.sendRegisterEmailCode
                : WebURL.sendChildRegisterEmailCode
            
            param = ["email":self.txtEmail.text!] as [String : Any]
        }else{
            webUrl = appDelegate.isFromParent
                ? WebURL.sendRegisterPhoneCode
            : WebURL.sendChildRegisterPhoneCode
            
            param = ["mobileNo":self.txtPhone.text!,"countryCode":self.lblCountryCode.text!] as [String : Any]
        }
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: webUrl, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                self.navigateToOtpWith(isFromEmail: isEmail)
            }
            else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    //MARK: - Upload Profile image Data...
    func apiCalluploadProfilelFile(aDataFile:Data)
    {
        apiCallViewModel.postMethodWithMultiPartCall(strUrl:WebURL.uploadDPImage, param: [String:Any](), mediaKey:"file", isProfileAvail:true, isvideo:false, profileImageData: aDataFile) { (isSuccess, responseDict) in
            
            //appDelegate.hideHud()
            if isSuccess
            {
                let profileImgID = createString(value: responseDict["id"] as AnyObject)
                //self.profileImageId = profileImgID
                if self.isFromSocial
                {
                    self.apiCallForSocialRegister(aProfileDpId:profileImgID)
                }else {
                    self.apiCallForSaveBasicDetails(aProfileDpId: profileImgID)
                }
            }
            else{
                appDelegate.hideHud()
                appDelegate.window?.rootViewController?.view.makeToast("Something issue in uploading file. Please try again later.")
            }
        }
    }
}
