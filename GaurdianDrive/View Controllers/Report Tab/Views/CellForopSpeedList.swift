//
//  CellForopSpeedList.swift
//  GaurdianDrive
//
//  Created by KETAN on 29/12/25.
//

import UIKit

class CellForopSpeedList: UITableViewCell {

    //Outlets..
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblDay: UILabel!
    @IBOutlet weak var lblMph: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setDataFromServerWithModel(aTopSpeedData:TopSpeedModel)
    {
        if let formatted = formatServerDate(aTopSpeedData.localTime) {
            self.lblDate.text = formatted.dateTime
            self.lblDay.text = formatted.day
        }
        self.lblMph.text = (aTopSpeedData.speed == "") ? "0" : aTopSpeedData.speed
    }
    
}
