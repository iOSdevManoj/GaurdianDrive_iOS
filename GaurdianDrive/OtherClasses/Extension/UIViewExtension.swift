//
//  UIViewExtension.swift

import UIKit

//MARK: - UIView Extension
extension UIView {
    
    //MARK: - IBInspectable
    @IBInspectable var shadowGray: Bool {
        get {
            return layer.shadowOpacity > 0.0
        }
        set {
            if newValue == true {
                self.addShadow()
            }
        }
    }
    @IBInspectable var shadowTopGray: Bool {
        get {
            return layer.shadowOpacity > 0.0
        }
        set {
            if newValue == true {
                self.addShadowTopGray()
            }
        }
    }
    @IBInspectable var shadowBottomBlue: Bool {
        get {
            return layer.shadowOpacity > 0.0
        }
        set {
            if newValue == true {
                self.addGreenShadowBottom()
            }
        }
    }
    @IBInspectable var SmallShadow: Bool {
        get {
            return layer.shadowOpacity > 0.0
        }
        set {
            if newValue == true {
                self.addShadowSmall()
            }
        }
    }
    func add_shadow(demoView : UIView,height : CGFloat){
        
        let radius: CGFloat = demoView.frame.width //change it to .height if you need spread for height
        let shadowPath = UIBezierPath(rect: CGRect(x: -1, y: -1, width: radius + 0.5 , height:height - 4.0))
        //Change 2.1 to amount of spread you need and for height replace the code for height
        
        demoView.layer.cornerRadius = 0.0
        demoView.layer.shadowColor = UIColor.darkGray.cgColor
        demoView.layer.shadowOffset = CGSize(width: 0.1, height: 0.2)  //Here you control x and y
        demoView.layer.shadowOpacity = 0.2
        demoView.layer.shadowRadius = 2.0 //Here your control your blur
        demoView.layer.masksToBounds =  false
        demoView.layer.shadowPath = shadowPath.cgPath
    }
    func addShadow(shadowColor: CGColor = UIColor.gray.cgColor,
                       shadowOffset: CGSize = CGSize(width: 3.0, height: 3.0),
                       shadowOpacity: Float = 0.3,
                       shadowRadius: CGFloat = 5.0) {
            self.layer.masksToBounds = false
            layer.shadowColor = shadowColor
            layer.shadowOffset = shadowOffset
            layer.shadowOpacity = shadowOpacity
            layer.shadowRadius = shadowRadius
    }
    func addGreenShadowBottom(shadowColor: CGColor = UIColor.lightGray.cgColor,
                           shadowOffset: CGSize = CGSize(width: 0.0, height: 3.0),
                       shadowOpacity: Float = 0.5,
                       shadowRadius: CGFloat = 5.0) {
           self.layer.masksToBounds = false
            layer.shadowColor = shadowColor
            layer.shadowOffset = shadowOffset
            layer.shadowOpacity = shadowOpacity
            layer.shadowRadius = shadowRadius
    }
    func addShadowTopGray(shadowColor: CGColor = UIColor.darkGray.cgColor,
                   shadowOffset: CGSize = CGSize(width: 0.0, height: -15),
                   shadowOpacity: Float = 0.25,
                   shadowRadius: CGFloat = 5.0) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = shadowColor
        self.layer.shadowOffset = shadowOffset
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowRadius = shadowRadius
    }
    func addShadowSmall(shadowColor: CGColor = UIColor.darkGray.cgColor,
                        shadowOffset: CGSize = CGSize(width: 0.0, height: 0.0),
                        shadowOpacity: Float = 0.2,
                        shadowRadius: CGFloat = 2.0) {
        
        layer.shadowColor = shadowColor
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
    }
    
    //Set Corner Radious
    @IBInspectable var cornerRadius:CGFloat {
        set {
            self.layer.cornerRadius = newValue
        }
        get {
            return self.layer.cornerRadius
        }
    }
    
    //Set Round
    @IBInspectable var Round:Bool {
        set {
            self.layer.cornerRadius = self.frame.size.height / 2.0
        }
        get {
            return self.layer.cornerRadius == self.frame.size.height / 2.0
        }
    }
    //Set Border Color
    @IBInspectable var borderColor:UIColor {
        set {
            self.layer.borderColor = newValue.cgColor
        }
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
    }
    //Set Border width
    @IBInspectable var borderwidth:CGFloat {
        set {
            self.layer.borderWidth = newValue
        }
        get {
            return self.layer.borderWidth
        }
    }
    
    //Set Shadow in View
    func addShadowView(width:CGFloat=0.2, height:CGFloat=0.2, opacity:Float=0.7, maskToBounds:Bool=false, radius:CGFloat=0.5) {
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: width, height: height)
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
        self.layer.masksToBounds = maskToBounds
    }
    struct NLInnerShadowDirection: OptionSet {
        let rawValue: Int
        
        static let None = NLInnerShadowDirection(rawValue: 0)
        static let Left = NLInnerShadowDirection(rawValue: 1 << 0)
        static let Right = NLInnerShadowDirection(rawValue: 1 << 1)
        static let Top = NLInnerShadowDirection(rawValue: 1 << 2)
        static let Bottom = NLInnerShadowDirection(rawValue: 1 << 3)
        static let All = NLInnerShadowDirection(rawValue: 15)
    }
    
    //Remove Inner Shadow
    func removeInnerShadow() {
        
        for view in self.subviews {
            
            if (view.tag == 2639) {
                
                view.removeFromSuperview()
                break
            }
        }
    }
    
    //Add Inner Shadow
    func addInnerShadow() {
        
        let c = UIColor()
        let color = c.withAlphaComponent(0.5)
        let frame = CGRect(x: 0,y: 0,width: self.bounds.size.width,height: self.bounds.size.height)
        self.addInnerShadowWithRadius(frame: frame, radius: 3.0, color: color, inDirection: NLInnerShadowDirection.All)
    }
    
    //Add Inner Shadow With Radius
    func addInnerShadowWithRadius(radius: CGFloat, andAlpha: CGFloat) {
        
        let c = UIColor()
        let color = c.withAlphaComponent(alpha)
        
        let frame = CGRect(x: 0,y: 0,width: self.bounds.size.width,height: self.bounds.size.height)
        self.addInnerShadowWithRadius(frame: frame, radius: radius, color: color, inDirection: NLInnerShadowDirection.All)
    }
    
    //Add Inner Shadow With Radius
    func addInnerShadowWithRadius(radius: CGFloat, andColor: UIColor) {
        
        let frame = CGRect(x: 0,y: 0,width: self.bounds.size.width,height: self.bounds.size.height)
        self.addInnerShadowWithRadius(frame: frame, radius: radius, color: andColor, inDirection: NLInnerShadowDirection.All)
    }
    
    //Add Inner Shadow With Radius
    func addInnerShadowWithRadius(frame:CGRect,radius: CGFloat, color: UIColor, inDirection: NLInnerShadowDirection) {
        
        self.removeInnerShadow()
        
        let shadowView = self.createShadowViewWithRadius(frame: frame,radius: radius, andColor: color, direction: inDirection)
        
        self.addSubview(shadowView)
    }
    
    //Create Shadow View With Radius
    func createShadowViewWithRadius(frame:CGRect,radius: CGFloat, andColor: UIColor, direction: NLInnerShadowDirection) -> UIView {
        
        let shadowView = UIView(frame: frame)
        shadowView.backgroundColor = UIColor.clear
        shadowView.tag = 2639
        
        let colorsArray: Array = [ andColor.cgColor, UIColor.clear.cgColor ]
        
        if direction.contains(.Top) {
            
            let xOffset: CGFloat = 0.0
            let topwidth = frame.size.width
            
            let shadow = CAGradientLayer()
            shadow.colors = colorsArray
            shadow.startPoint = CGPoint(x:0.5,y: 0.0)
            shadow.endPoint = CGPoint(x:0.5,y: 1.0)
            shadow.frame = CGRect(x: xOffset,y: 0,width: topwidth,height: radius)
            shadowView.layer.insertSublayer(shadow, at: 0)
        }
        
        if direction.contains(.Bottom) {
            
            let xOffset: CGFloat = 0.0
            let bottomwidth = frame.size.width
            
            let shadow = CAGradientLayer()
            shadow.colors = colorsArray
            shadow.startPoint = CGPoint(x:0.5,y: 1.0)
            shadow.endPoint = CGPoint(x:0.5,y: 0.0)
            shadow.frame = CGRect(x:xOffset,y: frame.size.height - radius, width: bottomwidth,height: radius)
            shadowView.layer.insertSublayer(shadow, at: 0)
        }
        
        if direction.contains(.Left) {
            
            let yOffset: CGFloat = 0.0
            let leftheight = frame.size.height
            
            let shadow = CAGradientLayer()
            shadow.colors = colorsArray
            shadow.frame = CGRect(x:0,y: yOffset,width: radius,height: leftheight)
            shadow.startPoint = CGPoint(x:0.0,y: 0.5)
            shadow.endPoint = CGPoint(x:1.0,y: 0.5)
            shadowView.layer.insertSublayer(shadow, at: 0)
        }
        
        if direction.contains(.Right) {
            
            let yOffset: CGFloat = 0.0
            let rightheight = frame.size.height
            
            let shadow = CAGradientLayer()
            shadow.colors = colorsArray
            shadow.frame = CGRect(x:frame.size.width - radius,y: yOffset,width: radius,height: rightheight)
            shadow.startPoint = CGPoint(x:1.0,y: 0.5)
            shadow.endPoint = CGPoint(x:0.0,y: 0.5)
            shadowView.layer.insertSublayer(shadow, at: 0)
        }
        return shadowView
    }
    
    //Rotate Animation
    func rotate(_ toValue: CGFloat, duration: CFTimeInterval = 0.2) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        
        animation.toValue = toValue
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        
        self.layer.add(animation, forKey: nil)
    }
    
    /**
     Simply zooming in of a view: set view scale to 0 and zoom to Identity on 'duration' time interval.
     
     - parameter duration: animation duration
     */
    func zoomIn(duration: TimeInterval = 0.2) {
        self.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        UIView.animate(withDuration: duration, delay: 0.0, options: [.curveLinear], animations: { () -> Void in
            self.transform = CGAffineTransform.identity
        }) { (animationCompleted: Bool) -> Void in
        }
    }
    
    /**
     Simply zooming out of a view: set view scale to Identity and zoom out to 0 on 'duration' time interval.
     
     - parameter duration: animation duration
     */
    func zoomOut(duration: TimeInterval = 0.2) {
        self.transform = CGAffineTransform.identity
        UIView.animate(withDuration: duration, delay: 0.0, options: [.curveLinear], animations: { () -> Void in
            self.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        }) { (animationCompleted: Bool) -> Void in
        }
    }
    
    /**
     Zoom in any view with specified offset magnification.
     
     - parameter duration:     animation duration.
     - parameter easingOffset: easing offset.
     */
    func zoomInWithEasing(duration: TimeInterval = 0.2, easingOffset: CGFloat = 0.2) {
        let easeScale = 1.0 + easingOffset
        let easingDuration = TimeInterval(easingOffset) * duration / TimeInterval(easeScale)
        let scalingDuration = duration - easingDuration
        UIView.animate(withDuration: scalingDuration, delay: 0.0, options: .curveEaseIn, animations: { () -> Void in
            self.transform = CGAffineTransform(scaleX: easeScale, y: easeScale)
        }, completion: { (completed: Bool) -> Void in
            UIView.animate(withDuration: easingDuration, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in
                self.transform = CGAffineTransform.identity
            }, completion: { (completed: Bool) -> Void in
            })
        })
    }
    
    /**
     Zoom out any view with specified offset magnification.
     
     - parameter duration:     animation duration.
     - parameter easingOffset: easing offset.
     */
    func zoomOutWithEasing(duration: TimeInterval = 0.2, easingOffset: CGFloat = 0.2) {
        let easeScale = 1.0 + easingOffset
        let easingDuration = TimeInterval(easingOffset) * duration / TimeInterval(easeScale)
        let scalingDuration = duration - easingDuration
        UIView.animate(withDuration: easingDuration, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in
            self.transform = CGAffineTransform(scaleX: easeScale, y: easeScale)
        }, completion: { (completed: Bool) -> Void in
            UIView.animate(withDuration: scalingDuration, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in
                self.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
            }, completion: { (completed: Bool) -> Void in
            })
        })
    }
    //Set Top Corner Radious
    @IBInspectable var onlyTopCornerRadius:CGFloat {
        set {
            self.roundCorners(corners: [.topLeft, .topRight], radius: newValue)
        }get {
            return self.layer.cornerRadius
        }
    }
    
    @IBInspectable var onlyBottomCornerRadius:CGFloat {
        set {
            self.roundCorners(corners: [.bottomLeft, .bottomRight], radius: newValue)
        }get {
            return self.layer.cornerRadius
        }
    }
    
    private func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
        // If Swift version is lower than 4.2,
        // You should change the name. (ex. var renderedImage: UIImage?)
        var image1: UIImage? {
            let renderer = UIGraphicsImageRenderer(size: bounds.size, format: UIGraphicsImageRendererFormat())
            return renderer.image { rendererContext in layer.render(in: rendererContext.cgContext) }
    }
    
    func addDashedBorder(aColor:UIColor,xPoint:Int,yPoint:Int) {
            //Create a CAShapeLayer
            let shapeLayer = CAShapeLayer()
            shapeLayer.strokeColor = aColor.cgColor
            shapeLayer.lineWidth = 2
            // passing an array with the values [2,3] sets a dash pattern that alternates between a 2-user-space-unit-long painted segment and a 3-user-space-unit-long unpainted segment
            shapeLayer.lineDashPattern = [2,3]

            let path = CGMutablePath()
            path.addLines(between: [CGPoint(x: 0, y: 0),
                                    CGPoint(x: xPoint, y: yPoint)])
            shapeLayer.path = path
            layer.addSublayer(shapeLayer)
        }
    
//    func applyGradient(colours: [UIColor]) -> CAGradientLayer {
//           return self.applyGradient(colours: colours, locations: nil)
//       }

    func addVerticalGradientLayer(colors: [CGColor]) {
        layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = bounds
        layer.addSublayer(gradientLayer)
    }
    
    func roundTopCorners(radius: CGFloat) {
           layer.cornerRadius = radius
           layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
           layer.masksToBounds = true
       }
}
//MARK: - Layout Extension
extension NSLayoutConstraint {
    
    //Set Corner Radious
    @IBInspectable var manageBottomSafeArea: Bool {
        set {
            if newValue {
                if DeviceType.IS_IPHONE_X || DeviceType.IS_IPHONE_XSMax_XR {
                    self.constant += 20
                }
            }
        }get {
            return false
        }
    }
    
    //Set Corner Radious
    @IBInspectable var manageTopConstraintAsperHeight: Bool {
        set {
            if newValue {
                if DeviceType.IS_IPHONE_X || DeviceType.IS_IPHONE_XSMax_XR {
                    self.constant = ((self.constant * ScreenSize.height) / 667 ) + 20
                }
            }
        }get {
            return false
        }
    }
}
