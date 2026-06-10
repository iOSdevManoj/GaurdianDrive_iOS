//
//  ViewForLogoutAlert.swift
//  GaurdianDrive
//
//  Created by KETAN on 23/12/25.
//

import UIKit

protocol ViewForLogoutAlertDelegate:AnyObject{
    func tapToLogoutDeleteAction()
    func tapToCloseViewAction()

}
class ViewForLogoutAlert: UIView {
    //Reference Outlets..
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDesc: UILabel!
    @IBOutlet var btnLogout: UIButton!
    @IBOutlet var viewforBottom: UIView!

    //Variable..
    weak var delegate: ViewForLogoutAlertDelegate?
}

//MARK: - Click events..
extension ViewForLogoutAlert{
    @IBAction func tapToLogout(_ sender: UIButton) {
        delegate?.tapToLogoutDeleteAction()
    }
    @IBAction func tapToCloseView(_ sender: UIButton) {
        delegate?.tapToCloseViewAction()
    }
}
