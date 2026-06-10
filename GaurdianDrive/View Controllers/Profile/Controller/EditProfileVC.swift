//
//  EditProfileVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 23/12/25.
//

import UIKit

class EditProfileVC: UIViewController {

    //Outlets...
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var txtName: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtMobile: UITextField!
    @IBOutlet var lblCountryCode: UILabel!
    @IBOutlet var btnVerifyEmail: UIButton!
    @IBOutlet var btnVerifyPhone: UIButton!
    @IBOutlet var imgCountryCode: UIImageView!
    @IBOutlet var viewForEmail: UIView!
    @IBOutlet var viewForName: UIView!
    @IBOutlet var viewForMobile: UIView!

    //Variables..
    
    private var cameraController = UIImagePickerController()
    var isSelectedProfile = false
    var strOrigionalPhoneNo = ""
    var strOrigionalEmail = ""
    var isEmailVerify = true
    var isPhoneVerify = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initialisation()
    }
}

//MARK: - Initialisation functions...
extension EditProfileVC
{
    func initialisation()
    {
        
        self.setUserFieldsData()
    }
    
    //Set profile details...
    func setUserFieldsData()
    {
        if let profileDetails = AppState.sharedInstance.user
        {
            self.txtName.text = profileDetails.name
            self.txtEmail.text = profileDetails.email
            self.txtMobile.text = profileDetails.mobileNo
            self.lblCountryCode.text = profileDetails.countryCode
            self.strOrigionalPhoneNo = profileDetails.mobileNo
            self.strOrigionalEmail = profileDetails.email
            self.isEmailVerify = profileDetails.email == "" ? false : true
            self.isPhoneVerify = profileDetails.mobileNo == "" ? false : true
            if isEmailVerify {
                self.emailVerifiedProfileFromOtherScreen(isVerified: true)
            }
            if isPhoneVerify {
                self.phoneNumberVerifiedProfileFromOtherScreen(isVerified: true)
            }
            setUserProfileImageFromUrl(aImageview: self.imgProfile, aPlaceholderName: "")
        }
    }
}

//MARK: - Click Events.....
extension EditProfileVC
{
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToakeProfile(_ sender: UIControl) {
        self.openGalleryPopUp()
    }
    @IBAction func tapToSave(_ sender: UIButton) {
        self.view.endEditing(true)
        if self.isValidData()
        {
            appDelegate.showHud()

            if self.isSelectedProfile
            {
                let comrpessImageData = self.imgProfile.image!.jpegData(compressionQuality: 0.6)!
                self.apiCalluploadProfilelFile(aDataFile:comrpessImageData)
            }else{
                self.apiCallForEditProfile(aWithDpId:"")
            }
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
        self.apiCallSendOTP(isFromEmail: true)
    }
    @IBAction func tapToVerifyPhone(_ sender: UIButton) {
        self.view.endEditing(true)
        if !(txtMobile.text!.isStringWithoutSpace()){
            appDelegate.window?.rootViewController?.view.makeToast("Please enter your phone number")
            self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return
        }
        else if self.txtMobile.text!.count != 10
        {
            appDelegate.window?.rootViewController?.view.makeToast("Please enter valid phone number")
            self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return
        }
        appDelegate.showHud()
        self.apiCallSendOTP(isFromEmail: false)
    }
    
    func navigateToOtpWith(isEmail:Bool)
    {
        let objOTPVC = storyBoards.Main.instantiateViewController(withIdentifier: "OTPVC") as! OTPVC
        objOTPVC.isFromProfile = true
        objOTPVC.isEmail = isEmail
        objOTPVC.strEmailPhone = isEmail ? self.txtEmail.text! : self.txtMobile.text!
        objOTPVC.strCountyCode = self.lblCountryCode.text!
        self.navigationController?.pushViewController(objOTPVC, animated: true)
    }
 }

//MARK: - Others..
extension EditProfileVC
{
    func emailVerifiedProfileFromOtherScreen(isVerified:Bool)
    {
        self.isEmailVerify = isVerified
        if isVerified{
            self.setupVerificationFlowUIWith(aBtn: btnVerifyEmail, aVerifyTitle: "Verified", aColor: "AppGreen", aUserIntraction: false)
        }else {
            self.setupVerificationFlowUIWith(aBtn: btnVerifyEmail, aVerifyTitle: "Verify", aColor: "AppDarkBlue", aUserIntraction: true)
        }
    }
    func phoneNumberVerifiedProfileFromOtherScreen(isVerified:Bool)
    {
        self.isPhoneVerify = isVerified
        
        if isVerified{
            self.setupVerificationFlowUIWith(aBtn: btnVerifyPhone, aVerifyTitle: "Verified", aColor: "AppGreen", aUserIntraction: false)
        }else
        {
            self.setupVerificationFlowUIWith(aBtn: btnVerifyPhone, aVerifyTitle: "Verify", aColor: "AppDarkBlue", aUserIntraction: true)
        }
    }
    
    func setupVerificationFlowUIWith(aBtn:UIButton,aVerifyTitle:String,aColor:String,aUserIntraction:Bool)
    {
        aBtn.setTitleColor(UIColor(named:aColor), for: .normal)
        aBtn.setTitle(aVerifyTitle, for: .normal)
        aBtn.isUserInteractionEnabled = aUserIntraction
    }
}

//MARK: - Textfield delegates...
extension EditProfileVC : UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //Try to find next responder
        textField.resignFirstResponder()
        return false
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.viewForEmail.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        self.viewForMobile.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        self.viewForName.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.txtEmail
        {
            if let userDetails = AppState.sharedInstance.user
            {
                if self.txtEmail.text! != userDetails.email || self.txtEmail.text! == ""
                {
                    self.emailVerifiedProfileFromOtherScreen(isVerified: false)
                }else
                {
                    self.emailVerifiedProfileFromOtherScreen(isVerified: true)
                }
            }else
            {
                self.emailVerifiedProfileFromOtherScreen(isVerified: false)
            }
        }
        else if textField == self.txtMobile
        {
            if let userDetails = AppState.sharedInstance.user
            {
                if self.txtMobile.text! != userDetails.mobileNo || self.txtMobile.text! == ""
                {
                    self.phoneNumberVerifiedProfileFromOtherScreen(isVerified: false)
                }else
                {
                    self.phoneNumberVerifiedProfileFromOtherScreen(isVerified: true)
                }
            }else
            {
                self.phoneNumberVerifiedProfileFromOtherScreen(isVerified: false)
            }
        }
    }
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if textField == self.txtMobile
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
    
    //MARK: - Validation Method
    func isValidData() -> Bool{
        //        if self.isForEmail
        //        {
        if !(self.txtName.text!.isStringWithoutSpace()){
            appDelegate.window?.rootViewController?.view.makeToast("Please enter your name")
            self.viewForName.layer.borderColor = UIColor(named:"AppRed")?.cgColor

            return false;
        }
        if self.txtEmail.text! != ""
        {
            if self.txtEmail.text != AppState.sharedInstance.user!.email
            {
                if !self.isEmailVerify
                {
                    appDelegate.window?.rootViewController?.view.makeToast("Please verify your email")
                    self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor

                    return false;
                }
            }
        }
        if self.txtMobile.text! != ""
        {
            if self.txtMobile.text != AppState.sharedInstance.user!.mobileNo
            {
                if !self.isPhoneVerify
                {
                    appDelegate.window?.rootViewController?.view.makeToast("Please verify your phone number")
                    self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
                    return false;
                }
            }
        }
        if self.txtEmail.text! == "" && self.txtMobile.text! == ""
        {
            appDelegate.window?.rootViewController?.view.makeToast("Please enter email or phone number")
            self.viewForMobile.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            self.viewForEmail.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return false;
        }
        return true
    }
}

//MARK: - ImagePicker Delegates and Methods...
extension EditProfileVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate
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
extension EditProfileVC
{
    //MARK: - Update user profile details....
    func apiCallForEditProfile(aWithDpId:String)
    {
        let param = ["name":self.txtName.text!,"email":self.txtEmail.text!,"countryCode":self.lblCountryCode.text!,"mobileNo":self.txtMobile.text!,"status":"ACTIVE", "version":"0", "id":AppState.sharedInstance.user!.userId] as [String : Any]
        
        apiCallViewModel.putMethodApiCallWithDisctionaryResponse(aUrl: WebURL.getProfile, param:param) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                setLoginUserData(dicResult: responseDict,isFromProfile: true)
                appDelegate.window?.rootViewController?.view.makeToast("Profile updated successfully")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    //MARK: - Sent OTP for verification...
    func apiCallSendOTP(isFromEmail:Bool)
    {
        var param = [String : Any]()
        var webUrl = ""
        
        if isFromEmail
        {
            webUrl = WebURL.sendProfileEmailOTP
            param = ["email":self.txtEmail.text!] as [String : Any]
        }else{
            webUrl = WebURL.sendProfileMobileOTP
            param = ["mobileNo":self.txtMobile.text!,"countryCode":self.lblCountryCode.text!] as [String : Any]
        }
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: webUrl, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                self.navigateToOtpWith(isEmail: isFromEmail)

            }else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    
    //MARK: - Upload Profile image Data...
    func apiCalluploadProfilelFile(aDataFile:Data)
    {
        apiCallViewModel.postMethodWithMultiPartCall(strUrl:WebURL.uploadProfileImage, param: [String:Any](), mediaKey:"file", isProfileAvail:true, isvideo:false, profileImageData: aDataFile) { (isSuccess, responseDict) in
            
            //appDelegate.hideHud()
            if isSuccess
            {
                let profileImgID = createString(value: responseDict["id"] as AnyObject)
                self.apiCallForEditProfile(aWithDpId:profileImgID)
                //self.profileImageId = profileImgID
            }
            else{
                appDelegate.hideHud()
                appDelegate.window?.rootViewController?.view.makeToast("Something issue in uploading file. Please try again later.")
            }
        }
    }
}
