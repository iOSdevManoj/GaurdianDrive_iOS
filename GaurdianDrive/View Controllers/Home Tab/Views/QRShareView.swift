//
//  QRShareView.swift
//  GaurdianDrive
//
//  Created by KETAN on 24/03/26.
//

import UIKit

class QRShareView: UIView {

    // MARK: - Callbacks
        var onCancel: (() -> Void)?
        var onShare: ((UIImage?) -> Void)?

        // MARK: - UI

        private let containerView: UIView = {
            let view = UIView()
            view.backgroundColor = .white
            view.layer.cornerRadius = 24
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            view.clipsToBounds = true
            return view
        }()

        private let indicatorView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
            view.layer.cornerRadius = 3
            return view
        }()

        private let titleLabel: UILabel = {
            let lbl = UILabel()
            lbl.text = "Share QR"
            lbl.font = UIFont.init(name:FontName.PlusJakartaSansBold, size: 20)
            lbl.textAlignment = .center
            return lbl
        }()

        private let qrImageView: UIImageView = {
            let img = UIImageView()
            img.contentMode = .scaleAspectFit
            img.clipsToBounds = true
            img.layer.cornerRadius = 12
            return img
        }()

        private let cancelButton: UIButton = {
            let btn = UIButton()
            btn.setTitle("Cancel", for: .normal)
//            btn.setTitleColor(.systemBlue, for: .normal)
            btn.setTitleColor(UIColor(named: "AppDarkBlue") ?? .systemBlue, for: .normal)
            btn.backgroundColor = .clear
            btn.titleLabel?.font = UIFont.init(name:FontName.PlusJakartaSansMedium, size: 18)
            return btn
        }()

        private let shareButton: UIButton = {
            let btn = UIButton()
            btn.setTitle("Share", for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = UIColor(named: "AppDarkBlue") ?? .systemBlue
            btn.layer.cornerRadius = 12
            btn.titleLabel?.font = UIFont.init(name:FontName.PlusJakartaSansMedium, size: 18)
            return btn
        }()

        private var bottomConstraint: NSLayoutConstraint!

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
            backgroundColor = UIColor.black.withAlphaComponent(0.4)

            addSubview(containerView)
            containerView.translatesAutoresizingMaskIntoConstraints = false

            bottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 500)

            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
                bottomConstraint,

                // 🔥 Top spacing = 150
                containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 250)
            ])

            [indicatorView, titleLabel, qrImageView, cancelButton, shareButton].forEach {
                containerView.addSubview($0)
                $0.translatesAutoresizingMaskIntoConstraints = false
            }

            NSLayoutConstraint.activate([

                // Indicator
                indicatorView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                indicatorView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                indicatorView.widthAnchor.constraint(equalToConstant: 40),
                indicatorView.heightAnchor.constraint(equalToConstant: 5),

                // Title
                titleLabel.topAnchor.constraint(equalTo: indicatorView.bottomAnchor, constant: 12),
                titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

                // QR Image (dominant area)
                qrImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
                qrImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
                qrImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
                qrImageView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -20),

                
                // Cancel Button
                cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
                cancelButton.heightAnchor.constraint(equalToConstant: 48),

                // Share Button
                shareButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                shareButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
                shareButton.heightAnchor.constraint(equalToConstant: 48),

                // Equal width + spacing
                cancelButton.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor, constant: -20),
                cancelButton.widthAnchor.constraint(equalTo: shareButton.widthAnchor)
            ])

            // Actions
            cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
            shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        }

        // MARK: - Actions
        @objc private func cancelTapped() {
            dismiss()
            onCancel?()
        }

        @objc private func shareTapped() {
            onShare?(qrImageView.image)
        }

        // MARK: - Show / Dismiss
        func show(in parent: UIView) {
            frame = parent.bounds
            parent.addSubview(self)

            layoutIfNeeded()
            bottomConstraint.constant = 0

            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }

        func dismiss() {
            bottomConstraint.constant = 500

            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            }) { _ in
                self.removeFromSuperview()
            }
        }

        // MARK: - Load QR
        func setQR(url: String) {
            guard let url = URL(string: url) else { return }

            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.qrImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }
}
