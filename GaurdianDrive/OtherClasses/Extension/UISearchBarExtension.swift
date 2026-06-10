//
//  UISearchbarExtension.swift


import UIKit

//MARK: - UISearchBar Class Modify
extension UISearchBar
{
    //UISearchBar Text Color
    func setTextColor(color: UIColor) {
        
        let svs = subviews.flatMap { $0.subviews }
        guard let tf = (svs.filter { $0 is UITextField }).first as? UITextField else { return }
        tf.textColor = color
    }
    
    //UISearchBar Set Font
    func setFont(font: UIFont) {
        
        let svs = subviews.flatMap { $0.subviews }
        guard let tf = (svs.filter { $0 is UITextField }).first as? UITextField else { return }
        tf.font = font
    }
    
    //UISearchBar Placeholder Text Color
    func setPlaceholderColor(color: UIColor) {
        
        let svs = subviews.flatMap { $0.subviews }
        guard let tf = (svs.filter { $0 is UITextField }).first as? UITextField else { return }
        tf .setValue(color, forKeyPath: "_placeholderLabel.textColor")
    }
}
