//
//  CellForPlans.swift
//  GaurdianDrive
//
//  Created by KETAN on 23/02/26.
//

import UIKit

class CellForPlans: UICollectionViewCell {

    //Outlets..
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblMonthly: UILabel!
    @IBOutlet weak var lblYearly: UILabel!
    @IBOutlet weak var lblIncludeChild: UILabel!
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var viewTitle: UIView!
    @IBOutlet weak var viewBottom: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupCellDataFromModelDataWith(dataModel:SubscriptionModel,selectedIndex:Int,currentIndex:Int)
    {
        self.lblTitle.text = dataModel.name
        self.lblIncludeChild.text = "\(dataModel.childCount) Child Included"
        if dataModel.yearly != ""
        {
            self.lblYearly.text = "or \(dataModel.yearly)/Yearly"
            self.lblMonthly.text = "\(dataModel.price)/Month"

        }else {
            self.lblYearly.text = ""
            self.lblMonthly.text = "\(dataModel.price)/Yearly"
        }
        
        if selectedIndex == currentIndex
        {
            self.viewMain.borderColor = UIColor.init(named:"AppGreen")!
            self.viewTitle.backgroundColor = UIColor.init(named:"AppGreen")!
            self.viewBottom.backgroundColor = UIColor.init(named:"AppGreen")!
        }else {
            self.viewMain.borderColor = UIColor.init(named:"AppDarkBlue")!
            self.viewTitle.backgroundColor = UIColor.init(named:"AppDarkBlue")!
            self.viewBottom.backgroundColor = UIColor.init(named:"AppDarkBlue")!
        }
    }
}
