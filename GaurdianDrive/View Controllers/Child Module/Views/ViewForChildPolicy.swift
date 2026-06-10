//
//  ViewForChildPolicy.swift
//  GaurdianDrive
//
//  Created by KETAN on 18/03/26.
//

import UIKit

class ViewForChildPolicy: UIView {

    // MARK: - UI
       private let containerView = UIView()
       private let lblDescription = UILabel()
       private let btnClose = UIButton()
       private let lblTitle = UILabel()
    
       // MARK: - Init
       override init(frame: CGRect) {
           super.init(frame: frame)
           setupUI()
       }

       required init?(coder: NSCoder) {
           super.init(coder: coder)
           setupUI()
       }

       // MARK: - Setup
       private func setupUI() {

           self.backgroundColor = UIColor.black.withAlphaComponent(0.4)

           // Container
           containerView.backgroundColor = .white
           containerView.layer.cornerRadius = 16
           containerView.translatesAutoresizingMaskIntoConstraints = false
           addSubview(containerView)

         
           
           // Label
           lblTitle.textAlignment = .center
           lblTitle.font = UIFont(name: FontName.PlusJakartaSansBold, size: 16)
           lblTitle.textColor = .black
           lblTitle.translatesAutoresizingMaskIntoConstraints = false
           
           lblDescription.numberOfLines = 0
           lblDescription.textAlignment = .center
           lblDescription.translatesAutoresizingMaskIntoConstraints = false
           lblDescription.font = UIFont(name: FontName.PlusJakartaSansMedium, size: 16)
           // Button
           btnClose.setTitle("Close", for: .normal)
           btnClose.setTitleColor(.white, for: .normal)
           btnClose.backgroundColor = .systemBlue
           btnClose.layer.cornerRadius = 8
           btnClose.translatesAutoresizingMaskIntoConstraints = false
           btnClose.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

           containerView.addSubview(lblDescription)
           containerView.addSubview(btnClose)
           containerView.addSubview(lblTitle)

           // Constraints
           NSLayoutConstraint.activate([

               containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
               containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
               containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),

               // Title
               lblTitle.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
               lblTitle.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
               lblTitle.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

               // Description
               lblDescription.topAnchor.constraint(equalTo: lblTitle.bottomAnchor, constant: 10),
               lblDescription.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
               lblDescription.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

               // Button
               btnClose.topAnchor.constraint(equalTo: lblDescription.bottomAnchor, constant: 20),
               btnClose.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
               btnClose.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
               btnClose.widthAnchor.constraint(equalToConstant: 100),
               btnClose.heightAnchor.constraint(equalToConstant: 40)
           ])
       }

       // MARK: - Configure
    func configure(title: String, description: String) {
        lblTitle.text = title
        lblDescription.text = (description == "") ? "No policy added by parent" :  description
    }

       // MARK: - Show Animation
       func show(in view: UIView) {

           self.frame = view.bounds
           self.alpha = 0
           view.addSubview(self)

           containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

           UIView.animate(withDuration: 0.3,
                          delay: 0,
                          usingSpringWithDamping: 0.7,
                          initialSpringVelocity: 0.5,
                          options: .curveEaseInOut) {

               self.alpha = 1
               self.containerView.transform = .identity
           }
       }

       // MARK: - Close
       @objc private func closeTapped() {
           dismiss()
       }

       func dismiss() {
           UIView.animate(withDuration: 0.25, animations: {
               self.alpha = 0
               self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
           }) { _ in
               self.removeFromSuperview()
           }
       }
   }
