//
//  CellForRequestApps.swift
//  GaurdianDrive
//
//  Created by KETAN on 18/12/25.
//

import FamilyControls
import ManagedSettings
import SwiftUI
import UIKit

protocol CellForRequestAppsDelegate: AnyObject {
    func didTapCross(index: Int)
    func didTapApprove(index: Int)
}

class CellForRequestApps: UITableViewCell {

    // Reference Outlets
    @IBOutlet var lblAppName: UILabel!
    @IBOutlet var lblTime: UILabel!
    @IBOutlet var lblReason: UILabel!
    @IBOutlet var lblStatus: UILabel!
    @IBOutlet var btnCross: UIControl!
    @IBOutlet var viewBGWhite: UIView!
    @IBOutlet var lblApprove: UILabel!
    @IBOutlet var btnApproved: UIButton!
    @IBOutlet var imgAppIcon: UIImageView!
    @IBOutlet weak var imagIconWidth: NSLayoutConstraint!
    @IBOutlet weak var cons_lblApproved_width: NSLayoutConstraint!

    // Variables
    weak var cellDelegate: CellForRequestAppsDelegate?
    private var iconHostingController: UIHostingController<AnyView>?
    private var nameHostingController: UIHostingController<AnyView>?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.lblStatus.layer.masksToBounds = true
        self.lblStatus.layer.cornerRadius = 4
        self.lblApprove.layer.masksToBounds = true
        self.lblApprove.layer.cornerRadius = 4
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imgAppIcon.image = nil
        imgAppIcon.backgroundColor = .clear
        imgAppIcon.layer.cornerRadius = 0
        imgAppIcon.subviews.forEach { $0.removeFromSuperview() }
        lblAppName.text = nil
        // Fully tear down SwiftUI hosted views — same fix as CellForDurationList.
        // Prevents stale nameHostingController views from stacking on reuse.
        tearDownNameHostingController()
        tearDownIconHostingController()
    }

    // MARK: - Cell Configuration

    func setCellDataWihModelData(data: ChildRequestedApp, aIndex: Int, isTblReq: Bool) {
        self.btnCross.tag = aIndex
        self.btnApproved.tag = aIndex
        self.viewBGWhite.layer.borderWidth = 1
        self.viewBGWhite.layer.borderColor = UIColor(named: "AppBorderGray")?.cgColor

        self.lblStatus.text = data.displayStatus.uppercased()

        if isTblReq {
            self.lblTime.text = data.displayDate
            self.lblStatus.textColor = UIColor(named: "AppFontBlue")
            self.lblStatus.backgroundColor = UIColor(named: "AppLightBlue")
            imgAppIcon.isHidden = false
            imagIconWidth.constant = 44

            let isParent = UserDefaults.Main.bool(forKey: .isParent)
            let serverName = data.displayAppName
            let isRealName = AppNameResolution.isResolved(serverName)

            // Setup common subtitle text
            let rawName = data.name ?? ""
            let rawAppName = data.appName ?? ""
            let subtitleText: String
            if AppNameResolution.isResolved(rawName) && AppNameResolution.isResolved(rawAppName) && rawName != rawAppName {
                if serverName == rawName {
                    subtitleText = "App: \(rawAppName)"
                } else {
                    subtitleText = "App: \(rawName)"
                }
            } else if let uName = data.userName ?? data.username, !uName.isEmpty {
                subtitleText = "Requested by: \(uName)"
            } else {
                subtitleText = ""
            }

            if isParent {
                // Parent device: the app may not be installed here, so Label(token)
                // won't resolve. Use the server-stored name and a letter-avatar icon.
                // Priority: userName (child-provided) > displayAppName > "Unknown App"
                tearDownIconHostingController()
                tearDownNameHostingController()
                let userProvidedName = data.userName ?? data.username ?? ""
                let displayName: String
                if AppNameResolution.isResolved(userProvidedName) {
                    displayName = userProvidedName
                } else if isRealName {
                    displayName = serverName
                } else {
                    displayName = "Unknown App"
                }
                self.lblAppName.text = displayName
                showLetterAvatar(for: displayName != "Unknown App" ? displayName : "?")
                self.lblReason.text = subtitleText
            } else {
                self.lblReason.text = subtitleText

                if let token = data.getApplicationToken() {
                    // Child device: app is installed — use FamilyControls Label(token)
                    imgAppIcon.image = nil
                    updateOrCreateIconHostingController(token: token, appName: serverName)

                    if isRealName {
                        tearDownNameHostingController()
                        self.lblAppName.text = serverName
                    } else {
                        lblAppName.text = " "
                        updateOrCreateNameHostingController(token: token)
                    }
                } else {
                    // No token — plain UIKit fallback
                    tearDownIconHostingController()
                    tearDownNameHostingController()
                    self.lblAppName.text = serverName
                    imgAppIcon.isHidden = true
                }
            }
        } else {
            // No-drive mode row — no token-based views needed
            tearDownIconHostingController()
            tearDownNameHostingController()
            self.lblAppName.text = data.durationString
            self.lblTime.text = data.formattedTime
            self.lblStatus.textColor = UIColor(named: "AppPink")
            self.lblStatus.backgroundColor = UIColor(named: "AppLightPurple")
            self.lblReason.text = "Reason: \(data.reason ?? "N/A")"
            imgAppIcon.isHidden = true
            imagIconWidth.constant = 0
        }
    }

    // MARK: - Private helpers

    private func updateOrCreateIconHostingController(token: ApplicationToken, appName: String) {
        let newView = AnyView(
            AppIconView(token: token, appName: appName)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        imgAppIcon.viewWithTag(999)?.removeFromSuperview()
        imgAppIcon.subviews.forEach { $0.removeFromSuperview() }
        if let hc = iconHostingController {
            hc.rootView = newView
            if hc.view.superview == nil { imgAppIcon.embed(hc) }
        } else {
            let hc = UIHostingController(rootView: newView)
            hc.view.tag = 999
            hc.view.backgroundColor = .clear
            imgAppIcon.embed(hc)
            iconHostingController = hc
        }
    }

    private func updateOrCreateNameHostingController(token: ApplicationToken) {
        let newView = AnyView(
            AppNameLabel(token: token, font: .system(size: 14, weight: .medium), color: .primary, scale: 1.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        lblAppName.viewWithTag(998)?.removeFromSuperview()
        lblAppName.subviews.forEach { $0.removeFromSuperview() }
        if let hc = nameHostingController {
            hc.rootView = newView
            if hc.view.superview == nil { lblAppName.embed(hc) }
        } else {
            let hc = UIHostingController(rootView: newView)
            hc.view.tag = 998
            hc.view.backgroundColor = .clear
            lblAppName.embed(hc)
            nameHostingController = hc
        }
    }

    /// Shows a colored letter-avatar in imgAppIcon — used on the parent device
    /// where FamilyControls Label(token) won't resolve because the app isn't installed.
    private func showLetterAvatar(for name: String) {
        imgAppIcon.isHidden = false
        imgAppIcon.image = nil
        imgAppIcon.subviews.forEach { $0.removeFromSuperview() }

        let palette: [UIColor] = [
            UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1),
            UIColor(red: 0.20, green: 0.74, blue: 0.47, alpha: 1),
            UIColor(red: 0.91, green: 0.43, blue: 0.35, alpha: 1),
            UIColor(red: 0.57, green: 0.36, blue: 0.84, alpha: 1),
            UIColor(red: 0.98, green: 0.69, blue: 0.21, alpha: 1),
            UIColor(red: 0.16, green: 0.71, blue: 0.87, alpha: 1),
            UIColor(red: 0.91, green: 0.30, blue: 0.58, alpha: 1),
            UIColor(red: 0.26, green: 0.63, blue: 0.28, alpha: 1),
        ]
        let seed = Int(name.unicodeScalars.first?.value ?? 65)
        let bgColor = palette[seed % palette.count]
        let letter = String(name.prefix(1)).uppercased()

        imgAppIcon.backgroundColor = bgColor
        imgAppIcon.layer.cornerRadius = 10
        imgAppIcon.clipsToBounds = true

        let lbl = UILabel()
        lbl.text = letter
        lbl.textColor = .white
        lbl.font = .systemFont(ofSize: 18, weight: .bold)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        imgAppIcon.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: imgAppIcon.centerXAnchor),
            lbl.centerYAnchor.constraint(equalTo: imgAppIcon.centerYAnchor),
        ])
    }

    private func tearDownIconHostingController() {
        iconHostingController?.view.removeFromSuperview()
        iconHostingController = nil
        imgAppIcon.viewWithTag(999)?.removeFromSuperview()
        imgAppIcon.subviews.forEach { $0.removeFromSuperview() }
    }

    private func tearDownNameHostingController() {
        nameHostingController?.view.removeFromSuperview()
        nameHostingController = nil
        lblAppName.viewWithTag(998)?.removeFromSuperview()
        lblAppName.subviews.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - Click Events
extension CellForRequestApps {
    @IBAction func tapToCrossClose(_ sender: UIControl) {
        cellDelegate?.didTapCross(index: sender.tag)
    }
    @IBAction func tapToApprove(_ sender: UIButton) {
        cellDelegate?.didTapApprove(index: sender.tag)
    }
}
