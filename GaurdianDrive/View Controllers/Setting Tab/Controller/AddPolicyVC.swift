//
//  AddPolicyVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 28/12/25.
//

import UIKit

class AddPolicyVC: UIViewController {
    
    //Outlets....
    @IBOutlet var txtTitle: UITextField!
    @IBOutlet var txtDesc: UITextView!
    @IBOutlet var viewForTitle: UIView!
    @IBOutlet var viewForDesc: UIView!

    //Variables..
    var strChildID = ""
    var strTitle = ""
    var strDesc = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.txtTitle.text = self.strTitle
        self.txtDesc.text = self.strDesc
        if self.strDesc != ""
        {
            self.txtDesc.textColor = UIColor.black
        }else{
            self.textViewDidEndEditing(self.txtDesc)
        }
    }
}

//MARK: - Click Events.....
extension AddPolicyVC
{
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToSubmit(_ sender: UIButton) {
        self.view.endEditing(true)
        if self.isValidData()
        {
            appDelegate.showHud()
            self.apiCallForAddUpdatePolicy()
        }
    }
}

//MARK: - Textfield delegates...
extension AddPolicyVC : UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //Try to find next responder
        textField.resignFirstResponder()
        if let nextField = self.view.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        return false
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        textField.autocorrectionType = .no
        self.viewForTitle.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
        
        return true
    }
}

//MARK: - UITextview Delegates..
extension AddPolicyVC : UITextViewDelegate
{
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.viewForDesc.layer.borderColor = UIColor(named:"AppBorderGray")?.cgColor
        if textView.text == "Enter your message here" {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Enter your message here"
            textView.textColor = UIColor.init(named: "PlaceholderGray")
        }
    }
    
    //MARK: - Validation Method
    func isValidData() -> Bool{
        
        if !(txtTitle.text!.isStringWithoutSpace()){
            appDelegate.window?.rootViewController?.view.makeToast("Please enter title")
            self.viewForTitle.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return false;
        }
        else if self.txtDesc.text == "Enter your message here" || !(txtDesc.text!.isStringWithoutSpace())
        {
            appDelegate.window?.rootViewController?.view.makeToast("Please enter policy description.")
            self.viewForDesc.layer.borderColor = UIColor(named:"AppRed")?.cgColor
            return false;
        }
        return true
    }
}
//MARK: - Api callings...
extension AddPolicyVC
{
    //MARK: - Add/Update child policy..
    func apiCallForAddUpdatePolicy()
    {
        
        let param = ["title":self.txtTitle.text!,"description":self.txtDesc.text!] as [String : Any]
        let strUrl = WebURL.childAccountApi + "\(self.strChildID)/drive-mode-policy/"
        
        apiCallViewModel.putMethodApiCallWithDisctionaryResponse(aUrl: strUrl, param:param) { (isSuccess, responseDict) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                
                if let nav = self.navigationController {
                    for controller in nav.viewControllers {
                        if let homeVC = controller as? HomeVC {
                            homeVC.setupHomeChildPolicyData(aTitle: self.txtTitle.text!, aDesc: self.txtDesc.text!)
                            nav.popToViewController(homeVC, animated: true)
                            break
                        }
                    }
                }
            }
        }
    }
}
