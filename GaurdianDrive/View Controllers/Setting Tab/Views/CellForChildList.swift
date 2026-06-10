//
//  CellForChildList.swift
//  GaurdianDrive
//
//  Created by KETAN on 27/12/25.
//

import UIKit
protocol CellForChildListDelegate:AnyObject{
    func didTapToDelete(index:Int)
    func didTapToEdit(index:Int)
    func didTapToReInvie(index:Int)
    func didTapToStatusSwich(index:Int,status:Bool)
}
class CellForChildList: UITableViewCell {

    //Outlets..
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblAdded: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var swichOnOff: UISwitch!
    @IBOutlet weak var btnDelete: UIControl!
    @IBOutlet weak var btnEdit: UIButton!
    @IBOutlet weak var btnReInvite: UIButton!
    @IBOutlet weak var lblPin: UILabel!

    //Variables..
    weak var cellDelegate: CellForChildListDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func seupChildrenDetailsFrom(aUserData:UserModel,aIndex:Int)
    {
        //Set tag for all
        self.swichOnOff.tag = aIndex
        self.btnEdit.tag = aIndex
        self.btnDelete.tag = aIndex
        self.btnReInvite.tag = aIndex

        //Set data from model
        self.lblName.text = aUserData.name
        self.lblEmail.text = aUserData.email
        self.swichOnOff.isOn = (aUserData.status == "ACTIVE") ? true : false
        self.lblStatus.text = aUserData.status
        if aUserData.email == ""
        {
            self.lblEmail.text = "\(aUserData.countryCode) \(aUserData.mobileNo)" 
        }
        if self.swichOnOff.isOn
        {
           self.lblStatus.backgroundColor = UIColor(named: "AppLightGreen")
            self.lblStatus.textColor = UIColor(named: "AppGreen")
        }else {
            self.lblStatus.backgroundColor = UIColor(named: "AppFullLightRed")
            self.lblStatus.textColor = UIColor(named: "AppRed")
        }
        
        let addedDate = UTCToLocal(date: aUserData.localAaddedTime, aDateFormate:"d MMM yyyy")
        self.lblAdded.text = "Added: \(addedDate.aDate)"
        self.lblPin.text = (aUserData.pin == "") ? "" : "Pin: \(aUserData.pin)"
    }
}

//MARK: - Action events -
extension CellForChildList {
    @IBAction private func tapToDelete(_ sender: UIControl) {
        cellDelegate?.didTapToDelete(index: sender.tag)
    }
    @IBAction private func tapToEdit(_ sender: UIButton) {
        cellDelegate?.didTapToEdit(index: sender.tag)
    }
    @IBAction private func tapToReInvite(_ sender: UIButton) {
        cellDelegate?.didTapToReInvie(index: sender.tag)
    }
    @IBAction func switchChildStatusChanged(_ sender: UISwitch) {
        if sender.isOn {
            print("Switch is ON")
            cellDelegate?.didTapToStatusSwich(index: sender.tag, status: true)
        } else {
            print("Switch is OFF")
            cellDelegate?.didTapToStatusSwich(index: sender.tag, status: false)
        }
    }
}
