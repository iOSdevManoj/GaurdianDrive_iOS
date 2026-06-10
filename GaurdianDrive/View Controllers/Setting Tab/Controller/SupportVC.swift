//
//  SupportVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 05/02/26.
//

import UIKit

class SupportVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: true)

        //Hide tabbar code...
        self.tabBarController?.tabBar.isHidden = true
        if rootTab.cons_bottomBar_height != nil{
            rootTab.cons_bottomBar_height.constant = 0
            rootTab.viewBottomTabMain.isHidden = true
        }
    }

}

//MARK: - Click Events.....
extension SupportVC
{
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToEmail(_ sender: UIControl) {
    }
    @IBAction func tapToWhatsApp(_ sender: UIControl) {
    }
    @IBAction func tapToHelpTicket(_ sender: UIControl) {
        let objHelpTicketVC = storyBoards.Settings.instantiateViewController(withIdentifier:"HelpTicketVC" ) as! HelpTicketVC
        self.navigationController?.pushViewController(objHelpTicketVC, animated: true)
    }
}
