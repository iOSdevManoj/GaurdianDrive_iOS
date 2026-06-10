//
//  CellForNotification.swift
//  GaurdianDrive
//
//  Created by KETAN on 22/12/25.
//

import UIKit

class CellForNotification: UITableViewCell {
    
    //Outlets....
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblTime: UILabel!
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var lblRedDot: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.lblRedDot.layer.masksToBounds = true
        self.lblRedDot.layer.cornerRadius = 2.5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setNotificationCellData(aModelData:NotificationModel)
    {
        self.lblTitle.text = aModelData.body
        let displayTime = getTimeAgo(from: aModelData.time)
        self.lblTime.text = displayTime
        if aModelData.isRead
        {
            self.lblRedDot.isHidden = true
        }else{
            self.lblRedDot.isHidden = false
        }
    }
}
