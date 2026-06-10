//
//  UITabBarControllerExtension.swift

import UIKit

extension UITabBarController {
    
    //Remove extra padding when text remove
    func removeTabbarItemsText() {
        
        tabBar.items?.forEach {
            $0.title = ""
            $0.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        }
    }
}
