//
//  ChooseRoleVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 12/12/25.
//

import UIKit

class ChooseRoleVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.setHidesBackButton(true, animated: true)
    }
}
//MARK: - Click Events.....
extension ChooseRoleVC
{
    @IBAction func tapToParent(_ sender: UIControl) {
        appDelegate.isFromParent = true
        let objLoginRegisterVC = storyBoards.Main.instantiateViewController(withIdentifier: "LoginRegisterVC") as! LoginRegisterVC
        objLoginRegisterVC.isForLogin = true
        self.navigationController?.pushViewController(objLoginRegisterVC, animated: true)
    }
    @IBAction func tapToChild(_ sender: UIControl) {
        appDelegate.isFromParent = false
        let objLoginRegisterVC = storyBoards.Main.instantiateViewController(withIdentifier: "LoginRegisterVC") as! LoginRegisterVC
        objLoginRegisterVC.isForLogin = true
        self.navigationController?.pushViewController(objLoginRegisterVC, animated: true)
    }
}
