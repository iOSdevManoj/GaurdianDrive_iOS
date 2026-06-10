//
//  CellForIntro.swift
//  GaurdianDrive
//
//  Created by KETAN on 11/12/25.
//

import UIKit

//protocol CellForIntroDelegate:AnyObject{
//    func didTapOnSkip(index:Int)
//    func didTapOnNext(index:Int)
//}

class CellForIntro: UICollectionViewCell {

    //Reference Outlets..
    @IBOutlet weak var imgInfos: UIImageView!
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var lblTitle1: UILabel!
    @IBOutlet weak var lblTitle2: UILabel!

//    //Variables..
//    weak var cellDelegate: CellForIntroDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

