//
//  NSMutableArrayExtension.swift


import UIKit

//MARK: - NSMutableArray Extension
extension NSMutableArray {
    
    //Array shuffle
    func shuffle () {
        
        for i in (0..<self.count).reversed() {
            
            let ix1 = i
            let ix2 = Int(arc4random_uniform(UInt32(i+1)))
            (self[ix1], self[ix2]) = (self[ix2], self[ix1])
        }
    }
}

//Create arrar from any object
func creatArray(value: AnyObject) -> NSMutableArray {
    
    var tempArray = NSMutableArray()
    
    if let arrData: NSArray = value as? NSArray {
        
        tempArray = NSMutableArray.init(array: arrData)
    }
    else if let _: NSNull = value as? NSNull {
        
        tempArray = NSMutableArray.init()
    }
    
    return tempArray
}
