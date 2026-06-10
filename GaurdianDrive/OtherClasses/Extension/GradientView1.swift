//
//  GradientView.swift
//  IntixConsumer
//
//  Created by KETAN on 04/03/24.
//

import UIKit

class GradientView1: UIView {

    override open class var layerClass: AnyClass {
            return CAGradientLayer.classForCoder()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            let gradientLayer = self.layer as! CAGradientLayer
            gradientLayer.colors = [
                UIColor.init(named:"AppThemeCyan")!.cgColor,
                UIColor.init(named:"AppThemePink")!.cgColor
            ]
            backgroundColor = UIColor.clear
        }
}
