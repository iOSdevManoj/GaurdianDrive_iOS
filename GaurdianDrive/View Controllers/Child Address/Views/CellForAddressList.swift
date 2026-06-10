//
//  CellForAddressList.swift
//  GaurdianDrive
//
//  Created by KETAN on 08/03/26.
//

import UIKit
protocol CellForAddressListDelegate: AnyObject {
    func didTapDeleteAddress(tag: Int)
}
class CellForAddressList: UITableViewCell {

    //Reference Outlets..
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDesc: UILabel!
    @IBOutlet var btnDelete: UIControl!
    
    weak var delegate: CellForAddressListDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func setAddressFromModelWith(ModelData:ChildAddressModel)
    {
        self.lblTitle.text = ModelData.title
        self.lblDesc.text =  (ModelData.addressLine2 == "") ? ModelData.addressLine1 : "\(ModelData.addressLine2), \(ModelData.addressLine1)"
       
    }
}
//MARK: - Click events..
extension CellForAddressList{
    @IBAction func tapToDeleteAddress(_ sender: UIControl) {
        delegate?.didTapDeleteAddress(tag: sender.tag)
    }
}
