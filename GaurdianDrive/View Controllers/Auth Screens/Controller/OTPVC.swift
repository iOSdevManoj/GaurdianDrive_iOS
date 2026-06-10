//
//  OTPVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 15/12/25.
//

import UIKit

class OTPVC: UIViewController {

    //Reference Outlets..
    @IBOutlet private weak var txtOTP1: OTPTextField!
    @IBOutlet private weak var txtOTP2: OTPTextField!
    @IBOutlet private weak var txtOTP3: OTPTextField!
    @IBOutlet private weak var txtOTP4: OTPTextField!
    @IBOutlet private weak var lblTextDesc: UILabel!
    @IBOutlet private weak var lblHeading: UILabel!
    @IBOutlet private weak var lblResendSec: UILabel!
    @IBOutlet private weak var btnResend: UIButton!

    //Variables...
    var strOTPCode = ""
    var isFromLogin = false
    var strEmailPhone = ""
    var isEmail = false
    var isForVerification = false
    var strCountyCode = ""
    var timer: Timer?
    let maxSeconds = 30
    var remainingSeconds = 30
    var isFromProfile = false
    var isFromQR = false
    var strQRData = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        //Initialisation basic things..
        self.initialization()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        
        self.txtOTP1.text = ""
        self.txtOTP2.text = ""
        self.txtOTP3.text = ""
        self.txtOTP4.text = ""

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: true)
        self.navigationController?.setNavigationBarHidden(true, animated: false)

    }
}

// MARK: - Initialization -
extension OTPVC {
    
    private func initialization() {
        // Wire backward navigation for delete key
        txtOTP2.previousTextField = txtOTP1
        txtOTP3.previousTextField = txtOTP2
        txtOTP4.previousTextField = txtOTP3

        self.txtOTP1.becomeFirstResponder()
        if self.isEmail {
            self.lblTextDesc.text = "We have sent you a verification code on \(strEmailPhone) to verify you."
        } else if self.isFromQR {
            self.lblTextDesc.text = "We have sent you a verification code on email or phone number."
        } else {
            self.lblTextDesc.text = " We've sent a code on \(self.strCountyCode) \(strEmailPhone) for verification."
        }
        self.startOTPTimer()
    }
    
    func startOTPTimer() {
        remainingSeconds = maxSeconds
        btnResend.isEnabled = false
        btnResend.alpha = 0.6
        timer?.invalidate()   // invalidate old timer before starting new
        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updateTimer),
            userInfo: nil,
            repeats: true
        )

        updateTimerLabel()
    }
    @objc func updateTimer() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            updateTimerLabel()
        } else {
            // Countdown finished → enable resend
            btnResend.isEnabled = true
            btnResend.alpha = 1.0
            lblResendSec.text = ""
            timer?.invalidate()   // stop THIS cycle only
            timer = nil
        }
    }
    func updateTimerLabel() {
        lblResendSec.text = String(format: "%02d:%02d", 00, remainingSeconds)
    }
}

//MARK: - Action events -
extension OTPVC {
    @IBAction private func tapToBack(_ sender: UIControl) {
//        if self.isForVerification
//        {
//            if let nav = self.navigationController {
//                for controller in nav.viewControllers {
//                    if let basicInfoVC = controller as? BasicInfoVC {
//                        basicInfoVC.setupVerificationFromDetails(isForEmail: self.isEmail)
//                        nav.popToViewController(basicInfoVC, animated: true)
//                        break
//                    }
//                }
//            }
//        }else {
//            self.navigationController?.popViewController(animated: true)
//        }
        self.navigationController?.popViewController(animated: true)
    }
 
    @IBAction private func tapToVerify(_ sender: UIButton) {
        self.view.endEditing(true)
        if isValidData()
        {
            appDelegate.showHud()
            self.strOTPCode = self.txtOTP1.text! +  self.txtOTP2.text! +  self.txtOTP3.text!
            self.strOTPCode = self.strOTPCode + self.txtOTP4.text!
            if self.isFromQR
            {
                self.apiCallForQRCodeVerifyOTP()
            }else {
                self.apiCallForVerifyOTP()
            }
        }
    }
    @IBAction private func tapToResendCode(_ sender: UIControl) {
        
        self.view.endEditing(true)
        
        self.txtOTP1.text = ""
        self.txtOTP2.text = ""
        self.txtOTP3.text = ""
        self.txtOTP4.text = ""
        appDelegate.showHud()
        if self.isFromQR{
            self.apiCallForReSendOTPQRCode(strQRCodeResult: strQRData)
        }else{
            self.apiCallForResendOTP()
        }
    }
}

//MARK: - Textfield delegates...
extension OTPVC : UITextFieldDelegate
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
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.autocorrectionType = .no
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
        self.setOTPFieldBorderColorWithColor(aColorName: "AppBorderGray")
        return true
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        if string.count > 0 {

            textField.text = string

            if let next = textField.superview?.viewWithTag(textField.tag + 1) {
                next.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }

            return false
        }

        return true
    }
    
    //MARK: - Validation Method
    func isValidData() -> Bool{
        
        if !(txtOTP1.text!.isStringWithoutSpace()) || !(txtOTP2.text!.isStringWithoutSpace()) || !(txtOTP3.text!.isStringWithoutSpace()) || !(txtOTP4.text!.isStringWithoutSpace()){
            appDelegate.window?.rootViewController?.view.makeToast("OTP Missing")
            self.setOTPFieldBorderColorWithColor(aColorName: "AppRed")
            return false;
        }
        return true
    }
    
    func setOTPFieldBorderColorWithColor(aColorName:String)
    {
        self.txtOTP1.layer.borderColor = UIColor(named:aColorName)?.cgColor
        self.txtOTP2.layer.borderColor = UIColor(named:aColorName)?.cgColor
        self.txtOTP3.layer.borderColor = UIColor(named:aColorName)?.cgColor
        self.txtOTP4.layer.borderColor = UIColor(named:aColorName)?.cgColor
    }
}
//MARK: - Api callings...
extension OTPVC
{
    //MARK: - Verify OTP...
    func apiCallForVerifyOTP()
    {
        var param = [String : Any]()
        var webUrl = ""

        if self.isEmail
        {
            if isFromProfile
            {
                webUrl = WebURL.verifyEmailOTP
                param = ["email":self.strEmailPhone,"otp":self.strOTPCode] as [String : Any]
            }
            else if !self.isFromLogin{
                webUrl = appDelegate.isFromParent
                ? WebURL.sendValidateEmailCode
                : WebURL.sendChildValidateEmailCode
                param = ["email":self.strEmailPhone,"otp":self.strOTPCode] as [String : Any]
            }else {
                webUrl = WebURL.loginEmailOtpVerify
                param = ["email":self.strEmailPhone,"otp":self.strOTPCode,"timeZoneOffset":getTimeZoneOffsetMinutes()] as [String : Any]
            }
        }else{
            if isFromProfile
            {
                webUrl = WebURL.verifyPhoneNoOTP
                param = ["mobileNo":self.strEmailPhone,"countryCode":self.strCountyCode,"otp":self.strOTPCode] as [String : Any]
            }
            else if !self.isFromLogin{
                webUrl = appDelegate.isFromParent
                ? WebURL.sendValidatePhoneCode
                : WebURL.sendChildValidatePhoneCode
                
                param = ["mobileNo":self.strEmailPhone,"countryCode":self.strCountyCode,"otp":self.strOTPCode] as [String : Any]
            }else{
                webUrl =  WebURL.loginPhoneOtpVerify
                param = ["mobileNo":self.strEmailPhone,"countryCode":self.strCountyCode,"otp":self.strOTPCode, "timeZoneOffset":getTimeZoneOffsetMinutes()] as [String : Any]
            }
        }
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: webUrl, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                if self.isFromProfile
                {
                    if let nav = self.navigationController {
                        for controller in nav.viewControllers {
                            if let editProfileVC = controller as? EditProfileVC {
                                if self.isEmail
                                {
                                    editProfileVC.emailVerifiedProfileFromOtherScreen(isVerified: true)
                                }else{
                                    editProfileVC.phoneNumberVerifiedProfileFromOtherScreen(isVerified: true)
                                }
                                nav.popToViewController(editProfileVC, animated: true)
                                break
                            }
                        }
                    }
                }
                else if self.isForVerification
                {
                    if let nav = self.navigationController {
                        for controller in nav.viewControllers {
                            if let basicInfoVC = controller as? BasicInfoVC {
                                basicInfoVC.setupVerificationFromDetails(isFromEmail: self.isEmail)
                                nav.popToViewController(basicInfoVC, animated: true)
                                break
                            }
                        }
                    }
                }else{
                    if !self.isFromLogin{
                        let objBasicInfoVC = storyBoards.Main.instantiateViewController(withIdentifier: "BasicInfoVC") as! BasicInfoVC
                        objBasicInfoVC.isForEmail = self.isEmail
                        objBasicInfoVC.strEmailPhone = self.strEmailPhone
                        objBasicInfoVC.strCountyCode = self.strCountyCode
                        self.navigationController?.pushViewController(objBasicInfoVC, animated: true)
                    }else{
                        
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
                }
            }else{
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
                self.setOTPFieldBorderColorWithColor(aColorName: "AppRed")
            }
        }
    }
    
    //MARK: - Verify QR Code OTP...
    func apiCallForQRCodeVerifyOTP()
    {
        let param = ["qrCode":self.strQRData,"otp":self.strOTPCode,"timeZoneOffset":getTimeZoneOffsetMinutes()] as [String : Any]

        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl:WebURL.verifyQRCodeOTP, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                setLoginUserData(dicResult: responseDict,isFromProfile: false)
                UserDefaults.Main.set(true, forKey: .autoLogin)
                UserDefaults.Main.set(false, forKey: .isParent)
                let objChildHomeVC = storyBoards.Child.instantiateViewController(withIdentifier: "ChildHomeVC") as! ChildHomeVC
                self.navigationController?.pushViewController(objChildHomeVC, animated: true)
            }else{
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
                self.setOTPFieldBorderColorWithColor(aColorName: "AppRed")
            }
        }
    }
    
    //MARK: - Resend OTP...
    func apiCallForResendOTP()
    {
        //let fcmToken = UserDefaults.Main.string(forKey: .deviceToken)
        var param = [String : Any]()
        var webUrl = ""
        let strType = appDelegate.isFromParent ? "PARENT" : "CHILD"

        if self.isEmail
        {
            if self.isFromProfile
            {
                webUrl = WebURL.sendProfileEmailOTP
                param = ["email":strEmailPhone] as [String : Any]

            }else{
                if self.isFromLogin
                {
                    webUrl = WebURL.loginWithEmail
                    param = ["email":strEmailPhone,"type":strType] as [String : Any]
                }else {
                    webUrl = appDelegate.isFromParent
                    ? WebURL.sendRegisterEmailCode
                    : WebURL.sendChildRegisterEmailCode
                    param = ["email":strEmailPhone] as [String : Any]
                }
            }
        }else{
            if self.isFromProfile
            {
                webUrl = WebURL.sendProfileMobileOTP
                param = ["mobileNo":strEmailPhone,"countryCode":self.strCountyCode] as [String : Any]

            }else {
                if self.isFromLogin
                {
                    webUrl = WebURL.loginWithPhone
                    param = ["mobileNo":strEmailPhone,"countryCode":self.strCountyCode,"type":strType] as [String : Any]

                }else {
                    webUrl = appDelegate.isFromParent
                        ? WebURL.sendRegisterPhoneCode
                    : WebURL.sendChildRegisterPhoneCode
                    param = ["mobileNo":strEmailPhone,"countryCode":self.strCountyCode] as [String : Any]

                }
            }
        }
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: webUrl, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                self.startOTPTimer()   //Restart 30s automatically
                appDelegate.window?.rootViewController?.view.makeToast("OTP sent successfully!")
            }else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
    
    //MARK: - Social Login/Register user...
    func apiCallForReSendOTPQRCode(strQRCodeResult:String)
    {
        //let fcmToken = UserDefaults.Main.string(forKey: .deviceToken)
        let param = ["qrCode":strQRCodeResult] as [String : Any]
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: WebURL.sendQRCodeData, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                self.startOTPTimer()   //Restart 30s automatically
                appDelegate.window?.rootViewController?.view.makeToast("OTP sent successfully!")
            }else {
                let strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
}
