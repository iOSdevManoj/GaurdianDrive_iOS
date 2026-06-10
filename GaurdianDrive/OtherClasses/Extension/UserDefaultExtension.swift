//
//  UserDefaultExtension.swift


import UIKit

// Add your userdefault key here :
extension UserDefaults
{
    struct Main : UserDefaultable {
        private init() { }
        
        enum BoolDefaultKey : String {
            case autoLogin
            case isLocationON
            case isInfoDone
            case isPhoto
            case isParent

        }
        enum FloatDefaultKey:String {
            case floatKey
        }
        enum DoubleDefaultKey: String {
            case doubleKey
            case longitude
            case latitude
        }
        enum IntegerDefaultKey: String {
            case IntKey
            case profileStatus
        }
        enum StringDefaultKey: String {
            case deviceToken
            case userID
            case userToken
            case Language
            case appleID
            case appleIDName
        }
        enum URLDefaultKey: String {
            case urlKey
        }
        enum ObjectDefaultKey: String {
            case profile
        }
    }
}
class CustomSlider: UISlider {
    
    @IBInspectable var trackHeight: CGFloat = 3
    
    @IBInspectable var thumbRadius: CGFloat = 20
    
    // Custom thumb view which will be converted to UIImage
    // and set as thumb. You can customize it's colors, border, etc.
    private lazy var thumbView: UIView = {
        let thumb = UIView()
        thumb.backgroundColor = .white//thumbTintColor
        thumb.layer.borderWidth = 1
        thumb.layer.masksToBounds = true
        thumb.layer.borderColor = UIColor(named: "PlaceholderGray")!.cgColor
        return thumb
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let thumb = thumbImage(radius: thumbRadius)
        setThumbImage(thumb, for: .normal)
        setThumbImage(thumb, for: .highlighted)
    }
    
    private func thumbImage(radius: CGFloat) -> UIImage {
        // Set proper frame
        // y: radius / 2 will correctly offset the thumb
        
        thumbView.frame = CGRect(x: 0, y: radius / 2, width: radius, height: radius)
        thumbView.layer.cornerRadius = radius / 2
        
        // Convert thumbView to UIImage
        let renderer = UIGraphicsImageRenderer(bounds: thumbView.bounds)
        return renderer.image { rendererContext in
            thumbView.layer.render(in: rendererContext.cgContext)
        }
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        // Set custom track height
        var newRect = super.trackRect(forBounds: bounds)
        newRect.size.height = trackHeight
        return newRect
    }
    
}
