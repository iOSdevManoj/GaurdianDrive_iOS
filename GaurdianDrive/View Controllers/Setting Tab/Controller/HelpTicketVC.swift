//
//  HelpTicketVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 05/02/26.
//

import UIKit

class HelpTicketVC: UIViewController {

    //Outlets....
    @IBOutlet var txtTitle: UITextField!
    @IBOutlet var txtDesc: UITextView!
    @IBOutlet var viewForTitle: UIView!
    @IBOutlet var viewForDesc: UIView!

    //Variables..
    var strChildID = ""

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

//MARK: - Click Events.....
extension HelpTicketVC
{
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToSubmit(_ sender: UIButton) {
        self.view.endEditing(true)
        if self.isValidData()
        {
            appDelegate.showHud()
            self.apiCallForAddHelpTicket()
        }
    }
}

//MARK: - Textfield delegates...
extension HelpTicketVC : UITextFieldDelegate
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
extension HelpTicketVC : UITextViewDelegate
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
extension HelpTicketVC
{
    //MARK: - Send support Ticket...
    func apiCallForAddHelpTicket()
    {
        let param = ["title":self.txtTitle.text!,"description":self.txtDesc.text!] as [String : Any]
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: WebURL.setHelpTicket, param:param) { (isSuccess, responseDict,statusCode) in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                appDelegate.window?.rootViewController?.view.makeToast("Ticket sent to admin successfully!")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
