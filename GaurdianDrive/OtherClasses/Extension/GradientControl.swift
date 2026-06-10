//
//  GradientButton.swift
//  Phobexx
//
//  Created by KETAN on 08/02/24.
//

import UIKit
@IBDesignable
class GradientControl: UIButton {

    @IBInspectable override var cornerRadius: CGFloat {
        didSet {
            self.setupUI(aFirstColor: firstColor, secondColor: secondColor)
        }
    }
    @IBInspectable var firstColor:UIColor = UIColor.init(named:"AppThemeCyan")! {
        didSet {
            self.setupUI(aFirstColor: firstColor, secondColor: secondColor)
//            gradientLayer.frame = bounds
        }
    }
    @IBInspectable var secondColor:UIColor = UIColor.init(named:"AppThemePink")! {
        didSet{
            self.setupUI(aFirstColor: firstColor, secondColor: secondColor)
//            gradientLayer.frame = bounds
        }
    }
    
    private var gradientLayer = CAGradientLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
//        gradientLayer.frame = bounds
    }
    
   
//    private lazy var gradientLayer: CAGradientLayer = {
//        let l = CAGradientLayer()
//        l.frame = self.bounds
//        l.colors = [firstColor.cgColor, secondColor.cgColor]
//        l.startPoint = CGPoint(x: 0, y: 0.5)
//        l.endPoint = CGPoint(x: 1, y: 0.5)
//        l.cornerRadius = 22
//        layer.insertSublayer(l, at: 0)
//        return l
//    }()
    
    func setupUI(aFirstColor:UIColor,secondColor:UIColor)
    {
//        let l = CAGradientLayer()
//        gradientLayer.frame = bounds
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [aFirstColor.cgColor, secondColor.cgColor]
//        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
//        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = cornerRadius
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
