//
//  UILabelExtension.swift


import UIKit

//MARK: - UILabel Extension
extension UILabel {
    
    //Set line spacing between two lines.
    func setLineheight(lineheight: CGFloat) {
        
        let text = self.text
        if let text = text {
            
            let attributeString = NSMutableAttributedString(string: text)
            let style = NSMutableParagraphStyle()
            
            style.lineSpacing = lineheight
            attributeString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, text.count))
            self.attributedText = attributeString
        }
    }
    
    //Set notification counter with dynamic width calculate
    func setNotificationCounter(counter: String) {
        
        if counter.length == 0 {
            
            self.isHidden = true
            
        } else {
            
            self.isHidden = false
            let strCounter:String = ":\(counter)|"
            
            self.clipsToBounds = true
            self.layer.cornerRadius = (self.frame.size.height / 2.0) * DeviceScale.y
            
            let string_to_color1 = ":"
            let range1 = (strCounter as NSString).range(of: string_to_color1)
            let attributedString1 = NSMutableAttributedString(string:strCounter)
            attributedString1.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear , range: range1)
            
            let string_to_color2 = "|"
            let range2 = (strCounter as NSString).range(of: string_to_color2)
            attributedString1.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear , range: range2)
            self.attributedText = attributedString1
        }
    }
    
    //Get notification counter
    func getNotificationCounter() -> String {
        
        if self.text?.length == 0 {
            
            return ""
            
        } else {
            
            var strCounter = self.text
            strCounter = strCounter?.replacingOccurrences(of: ":", with: "")
            strCounter = strCounter?.replacingOccurrences(of: "|", with: "")
            return strCounter!
        }
    }
    //Get dynamic height
    func requiredheight() -> CGFloat {
        
        let label:UILabel = UILabel(frame: CGRect(x: 0,y: 0,width: self.frame.width, height : CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = self.font
        label.text = self.text
        label.sizeToFit()
        return label.frame.height
    }
    //Get dynamic width
    func requiredwidth() -> CGFloat {
        
        let label:UILabel = UILabel(frame: CGRect(x: 0,y: 0,width: self.frame.width,height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = self.font
        label.text = self.text
        label.sizeToFit()
        return label.frame.width
    }
    //Set Strike Through With Text
    func setStrikeThroughWithText(string:String, lineHeight:Double) {
        
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: string)
        attributeString.addAttribute(NSAttributedString.Key.baselineOffset, value: 0, range: NSMakeRange(0, attributeString.length))
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: lineHeight, range: NSMakeRange(0, attributeString.length))
        self.attributedText = attributeString
    }
}

//Get dynamic label width
func widthForLabel(label:UILabel,text:String) ->CGFloat {
    
    let fontName = label.font.fontName;
    let fontSize = label.font.pointSize;
    
    let attributedText = NSMutableAttributedString(string: text,attributes: [NSAttributedString.Key.font:UIFont(name: fontName,size: fontSize)!])
    let rect: CGRect = attributedText.boundingRect(with: CGSize(width: label.frame.size.width, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    
    return ceil(rect.size.width)
}
