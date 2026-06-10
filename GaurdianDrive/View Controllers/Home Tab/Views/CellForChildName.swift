//
//  CellForChildName.swift
//  GaurdianDrive
//
//  Created by KETAN on 18/12/25.
//

import UIKit

class CellForChildName: UICollectionViewCell {

    //Outlets....
    @IBOutlet var lblChildName: UILabel!
    @IBOutlet var viewForBG: UIView!

   
    override func awakeFromNib() {
        super.awakeFromNib()
        lblChildName.numberOfLines = 1
        lblChildName.lineBreakMode = .byClipping
    }
    override func layoutSubviews() {
          super.layoutSubviews()
          contentView.layoutIfNeeded()
      }
    
    func setupChildrenListFrom(userData:UserModel,aSelectedIndex:Int,cellIndex:Int)
    {
        self.lblChildName.text = userData.name
        if aSelectedIndex == cellIndex
        {
            self.viewForBG.backgroundColor = UIColor(named: "AppDarkBlue")
            self.lblChildName.textColor = UIColor(named: "WhiteColor")
        }else {
            self.viewForBG.backgroundColor = UIColor(named: "WhiteColor")
            self.lblChildName.textColor = UIColor(named: "AppDarkBlue")
        }
    }

}
