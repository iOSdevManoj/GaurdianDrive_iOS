//
//  OTPTextField.swift
//  GaurdianDrive
//
//  Created by KETAN on 04/02/26.
//

import UIKit

class OTPTextField: UITextField {

    /// Set this to the field that comes BEFORE this one in the OTP sequence.
    /// When the user presses delete, focus moves to this field automatically.
    weak var previousTextField: UITextField?

    override func deleteBackward() {
        if let text = self.text, !text.isEmpty {
            // Clear current field and move focus back in one press
            self.text = ""
            previousTextField?.becomeFirstResponder()
        } else {
            // Field already empty — just move back
            previousTextField?.becomeFirstResponder()
        }
    }
}
