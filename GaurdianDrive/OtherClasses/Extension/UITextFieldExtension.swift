//
//  UITextFieldExtension.swift


import UIKit

//MARK: - UITextfield Extension
private var __maxLengths = [UITextField: Int]()
extension UITextField {
    //Done Accessory
    @IBInspectable var doneAccessory: Bool{
        get{
            return self.doneAccessory
        }
        set (hasDone) {
            if hasDone{
                addDoneButtonOnKeyboard()
            }
        }
    }
    
    
    //Add Done Button On Keyboard
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
    
    //Done Button Action
    @objc func doneButtonAction()
    {
        self.resignFirstResponder()
    }
    
    //Set placeholder font
    func setPlaceholderFont(font: UIFont) {
        
        let lblPlaceHolder:UILabel = self.value(forKey: "_placeholderLabel") as! UILabel
        lblPlaceHolder.font = font
    }
    
    //Set placeholder color
    func setPlaceholderColor(color: UIColor) {
        
        let lblPlaceHolder:UILabel = self.value(forKey: "_placeholderLabel") as! UILabel
        lblPlaceHolder.textColor = color
    }
    
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSAttributedString.Key.foregroundColor: newValue!])
        }
    }
    
    @IBInspectable var maxLength: Int {
        get {
            guard let l = __maxLengths[self] else {
                return 150 // (global default-limit. or just, Int.max)
            }
            return l
        }
        set {
            __maxLengths[self] = newValue
            addTarget(self, action: #selector(fix), for: .editingChanged)
        }
    }
    @objc func fix(textField: UITextField) {
        let t = textField.text
        textField.text = t?.safelyLimitedTo(length: maxLength)
    }
    
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
    
    //Set Corner Radious
    @IBInspectable var leftPadding:CGFloat {
        set {
            self.setLeftPaddingPoints(newValue)
        }
        get {
            return self.leftPadding
        }
    }
    //
    //    //Set TextColor Color
    //    @IBInspectable var customTextColor:UIColor {
    //        set {
    //            self.textColor = UIColor.appTextfieldTextColor()
    //        }
    //        get {
    //            return UIColor(cgColor: self.textColor as! CGColor)
    //        }
    //    }
    
    //MARK: Disable Smart Quotes
    func disableSmartQuotes() {
        if #available(iOS 11.0, *) {
            self.smartQuotesType = .no
            self.smartDashesType = .no
        } else {
            // Fallback on earlier versions
        }
    }
}

extension String
{
    func safelyLimitedTo(length n: Int)->String {
        if (self.count <= n) {
            return self
        }
        return String( Array(self).prefix(upTo: n) )
    }
}
