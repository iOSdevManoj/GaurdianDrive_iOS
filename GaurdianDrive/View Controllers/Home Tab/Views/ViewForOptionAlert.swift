//
//  ViewForOptionAlert.swift
//  GaurdianDrive
//
//  Created by KETAN on 23/12/25.
//

import UIKit

final class ViewForOptionAlert: UIView {

    //Reference Outlets..
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDesc: UILabel!
    @IBOutlet var btnYes: UIButton!
    @IBOutlet var btnNo: UIButton!
    @IBOutlet var viewforBottom: UIView!
    
    //Variable..
    private var onYes: (() -> Void)?
    private var onNo: (() -> Void)?
    var onClose: (() -> Void)?
    
    // MARK: - XIB Initialisation (IMPORTANT)
       static func loadFromXib() -> ViewForOptionAlert {
           let nib = UINib(nibName: "ViewForOptionAlert", bundle: nil)
           return nib.instantiate(withOwner: nil, options: nil).first as! ViewForOptionAlert
       }
    
    // MARK: - Configure
       func configure(
           title: String,
           description: String,
           yesTitle: String = "Yes, Reject",
           noTitle: String = "No",
           onYes: @escaping () -> Void,
           onNo: (() -> Void)? = nil,
           onClose: (() -> Void)? = nil
       ) {

           self.lblTitle.text = title
           self.lblDesc.text = description

           self.btnYes.setTitle(yesTitle, for: .normal)
           self.btnNo.setTitle(noTitle, for: .normal)

           self.onYes = onYes
           self.onNo = onNo
           self.onClose = onClose
       }
    
    // MARK: - Layout (IMPORTANT)
      override func layoutSubviews() {
          super.layoutSubviews()
          self.viewforBottom.roundTopCorners(radius: 16)
      }
}

//MARK: - Click events..
extension ViewForOptionAlert{
    @IBAction func tapToYes(_ sender: UIButton) {
        onYes?()
        dismiss()
    }
    @IBAction func tapToNo(_ sender: UIButton) {
        onNo?()
        dismiss()
    }
    @IBAction func tapToClose(_ sender: UIButton) {
       // onClose?()
        dismiss()
    }
    private func dismiss() {
        dismissAnimated()
    }
}

// MARK: - Show Animation

extension ViewForOptionAlert{
        func showAnimated() {
            self.alpha = 0
            viewforBottom.transform = CGAffineTransform(translationX: 0, y: 300)

            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.8,
                options: [.curveEaseOut]
            ) {
                self.alpha = 1
                self.viewforBottom.transform = .identity
            }
        }

        // MARK: - Dismiss Animation
        private func dismissAnimated() {
            UIView.animate(withDuration: 0.15, animations: {
                   self.alpha = 0
                   self.viewforBottom.transform = CGAffineTransform(translationX: 0, y: 300)
               }) { _ in
                   self.onClose?()          // 🔥 notify VC
                   self.removeFromSuperview()
               }
        }
}
