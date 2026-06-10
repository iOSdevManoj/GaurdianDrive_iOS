//
//  SuccessMessageVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 16/12/25.
//

import UIKit

class SuccessMessageVC: UIViewController {

    //Reference Outlets..
    @IBOutlet var imgMainHeader: UIImageView!
    @IBOutlet var imgIcon: UIImageView!
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDesc: UILabel!
    @IBOutlet var btnDone: UIButton!
    
    //Variables.
    var isComesFrom = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: true)
        self.navigationController?.setNavigationBarHidden(true, animated: false)

    }
}
//MARK: - Click Events.....
extension SuccessMessageVC
{
    @IBAction func tapToDone(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
}
