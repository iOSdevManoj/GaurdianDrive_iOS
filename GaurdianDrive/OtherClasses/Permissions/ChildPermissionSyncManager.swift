// ChildPermissionSyncManager.swift
// GaurdianDrive
//
// Child: PUT  /child/{childId}/app/custom-data  — sends current permission booleans
// Parent: GET /child/{childId}/app/custom-data  — reads and shows which child removed
//
// Usage:
//   Child:  ChildPermissionSyncManager.shared.syncIfNeeded()
//   Parent: ChildPermissionSyncManager.shared.fetchAndShowAlert(childId:childName:from:)

import CoreLocation
import FamilyControls
import UIKit
import UserNotifications

final class ChildPermissionSyncManager {

    static let shared = ChildPermissionSyncManager()
    private init() {}

    private let api = ApiCallViewModel()

    // MARK: - Child: PUT permission state

    /// Call on viewDidLoad / didBecomeActive from ChildHomeVC.
    /// Only sends when at least one permission is disabled (no spam on happy path).
    func syncIfNeeded() {
        guard let userId = AppState.sharedInstance.user?.userId, !userId.isEmpty else { return }

        let locationGranted  = CLLocationManager().authorizationStatus == .authorizedAlways
        let screenTimeGranted = AuthorizationCenter.shared.authorizationStatus == .approved

        // Always sync current state — not just when something is OFF.
        // If we only sync on revoke, the server retains stale "False" values after
        // the child re-grants permission, causing the parent to see a false alert.
        let params: [String: Any] = [
            "custom-data": [
                ["Location": locationGranted ? "True" : "False"],
                ["ScreenTime": screenTimeGranted ? "True" : "False"]
            ],
            "appTampered": !locationGranted || !screenTimeGranted
        ]

        let url = WebURL.childCustomData(childId: userId)
        api.putMethodApiCallWithDisctionaryResponse(aUrl: url, param: params) { _, _ in }
    }
    func callThisWhileLogoutChild() {
        guard let userId = AppState.sharedInstance.user?.userId, !userId.isEmpty else { return }

        let params: [String: Any] = [
            "custom-data": [
                ["Location":"True"],
                ["ScreenTime":"True"]
            ],
            "appTampered": false //!locationGranted || !screenTimeGranted
        ]

        let url = WebURL.childCustomData(childId: userId)
        api.putMethodApiCallWithDisctionaryResponse(aUrl: url, param: params) { _, _ in }
    }

    // MARK: - Parent: GET + show alert

    struct RevokedPermission {
        let name: String
        let icon: String
    }

    /// Call from HomeVC when child is selected or on viewWillAppear.
    func fetchAndShowAlert(childId: String, childName: String, from vc: UIViewController) {
        let url = WebURL.childCustomData(childId: childId)
        api.getApiCallWithDisctionaryResponse(aUrl: url, aParams: [:]) { isSuccess, responseDict in
            guard isSuccess else { return }

            var revoked: [RevokedPermission] = []

            let dataArray = (responseDict["custom-data"] as? [[String: Any]])
                         ?? (responseDict["data"] as? [[String: Any]])
                         ?? []

            for item in dataArray {
                if let val = item["Location"] as? String, val.lowercased() == "false" {
                    revoked.append(RevokedPermission(name: "Location (Always)", icon: "location.fill"))
                }
                if let val = item["ScreenTime"] as? String, val.lowercased() == "false" {
                    revoked.append(RevokedPermission(name: "Screen Time", icon: "hourglass"))
                }
            }

            guard !revoked.isEmpty else { return }

            DispatchQueue.main.async {
                self.showRevokedAlert(revoked: revoked, childName: childName, from: vc)
            }
        }
    }

    // MARK: - Alert popup

    private func showRevokedAlert(revoked: [RevokedPermission], childName: String, from vc: UIViewController) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })
        else { return }

        let appBlue = UIColor(named: "AppDarkBlue") ?? UIColor(red: 0.10, green: 0.19, blue: 0.38, alpha: 1)
        let cardWidth: CGFloat = min(window.bounds.width - 48, 340)

        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        overlay.alpha = 0
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.tag = 9902
        window.addSubview(overlay)

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(card)
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -20),
            card.widthAnchor.constraint(equalToConstant: cardWidth),
        ])

        let outer = UIStackView()
        outer.axis = .vertical
        outer.alignment = .center
        outer.spacing = 14
        outer.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(outer)
        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            outer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            outer.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            outer.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
        ])

        // Icon
        let iconView = UIImageView(image: UIImage(systemName: "exclamationmark.shield.fill"))
        iconView.tintColor = UIColor(red: 0.83, green: 0.09, blue: 0.24, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        outer.addArrangedSubview(iconView)

        // Title
        let titleLbl = UILabel()
        titleLbl.font = UIFont(name: "PlusJakartaSans-Bold", size: 17) ?? .systemFont(ofSize: 17, weight: .bold)
        titleLbl.textColor = appBlue
        titleLbl.textAlignment = .center
        titleLbl.numberOfLines = 0
        titleLbl.text = "Permission Revoked"
        outer.addArrangedSubview(titleLbl)

        // Subtitle
        let subLbl = UILabel()
        subLbl.font = UIFont(name: "PlusJakartaSans-Regular", size: 13) ?? .systemFont(ofSize: 13)
        subLbl.textColor = .darkGray
        subLbl.textAlignment = .center
        subLbl.numberOfLines = 0
        let permNames = revoked.map { $0.name }.joined(separator: " & ")
        subLbl.text = "\(childName) has removed \(permNames) permission\(revoked.count > 1 ? "s" : "") from GuardianDrive."
        outer.addArrangedSubview(subLbl)

        // Permission rows
        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.alignment = .fill
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        rowsStack.widthAnchor.constraint(equalToConstant: cardWidth - 40).isActive = true
        outer.addArrangedSubview(rowsStack)

        for p in revoked {
            rowsStack.addArrangedSubview(buildRevokedRow(p: p, appBlue: appBlue, cardWidth: cardWidth))
        }

        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        divider.widthAnchor.constraint(equalToConstant: cardWidth - 40).isActive = true
        outer.addArrangedSubview(divider)

        // OK button
        let okBtn = UIButton(type: .system)
        okBtn.setTitle("OK, Got It", for: .normal)
        okBtn.titleLabel?.font = UIFont(name: "PlusJakartaSans-SemiBold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        okBtn.setTitleColor(.white, for: .normal)
        okBtn.backgroundColor = appBlue
        okBtn.layer.cornerRadius = 12
        okBtn.layer.masksToBounds = true
        okBtn.translatesAutoresizingMaskIntoConstraints = false
        okBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        okBtn.widthAnchor.constraint(equalToConstant: cardWidth - 40).isActive = true
        outer.addArrangedSubview(okBtn)
        okBtn.addAction(UIAction { [weak overlay] _ in
            UIView.animate(withDuration: 0.2) { overlay?.alpha = 0 }
            completion: { _ in overlay?.removeFromSuperview() }
        }, for: .touchUpInside)

        // Animate in
        card.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.38, delay: 0,
                           usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5,
                           options: .curveEaseOut) {
                overlay.alpha = 1
                card.transform = .identity
            }
        }
    }

    private func buildRevokedRow(p: RevokedPermission, appBlue: UIColor, cardWidth: CGFloat) -> UIView {
        let appRed = UIColor(red: 0.83, green: 0.09, blue: 0.24, alpha: 1)

        let row = UIView()
        row.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1)
        row.layer.cornerRadius = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 10
        hStack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            hStack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            hStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12),
        ])

        let iconBg = UIView()
        iconBg.backgroundColor = appRed.withAlphaComponent(0.15)
        iconBg.layer.cornerRadius = 18
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.widthAnchor.constraint(equalToConstant: 36).isActive = true
        iconBg.heightAnchor.constraint(equalToConstant: 36).isActive = true
        let icon = UIImageView(image: UIImage(systemName: p.icon))
        icon.tintColor = appRed
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
        ])
        hStack.addArrangedSubview(iconBg)

        let nameLbl = UILabel()
        nameLbl.font = UIFont(name: "PlusJakartaSans-SemiBold", size: 13) ?? .systemFont(ofSize: 13, weight: .semibold)
        nameLbl.textColor = appBlue
        nameLbl.text = p.name
        nameLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)
        hStack.addArrangedSubview(nameLbl)

        let badge = PaddedLabel()
        badge.font = UIFont(name: "PlusJakartaSans-SemiBold", size: 9) ?? .systemFont(ofSize: 9, weight: .bold)
        badge.textColor = .white
        badge.text = "REVOKED"
        badge.backgroundColor = appRed
        badge.layer.cornerRadius = 5
        badge.layer.masksToBounds = true
        badge.textInsets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
        badge.setContentHuggingPriority(.required, for: .horizontal)
        hStack.addArrangedSubview(badge)

        return row
    }
}

// MARK: - PaddedLabel
private class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets.zero
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: textInsets)) }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + textInsets.left + textInsets.right,
                      height: s.height + textInsets.top + textInsets.bottom)
    }
}
