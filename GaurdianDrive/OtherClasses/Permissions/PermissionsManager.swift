// PermissionsManager.swift
// GaurdianDrive
//
// Unified permissions popup — single card, always opens Settings.
//
// Rules
// ─────
//  • All permissions → "Open Settings" (no inline system prompts).
//  • On foreground return → existing popup is dismissed and rebuilt fresh
//    so it always reflects the current permission state.
//  • Child    : Location + Family Controls = REQUIRED. Notifications = OPTIONAL.
//  • Parent   : ALL permissions are OPTIONAL unless the parent has ≥1 app
//               configured for self-drive blocking (isBlocked == true).
//               Once blocking is configured, Location + Family Controls = REQUIRED.
//
// Usage:
//   PermissionsManager.shared.checkAndShow()   // call on viewWillAppear / didBecomeActive

import CoreLocation
import FamilyControls
import SwiftData
import UIKit
import UserNotifications

@MainActor
final class PermissionsManager: NSObject {

    // MARK: - Singleton
    static let shared = PermissionsManager()
    private override init() { super.init() }

    private let overlayTag = 9901
    private var isChecking = false   // prevents concurrent check+prompt chains

    // MARK: - Permission Status Helpers

    private var locationStatus: CLAuthorizationStatus { CLLocationManager().authorizationStatus }
    private var isLocationGranted: Bool { locationStatus == .authorizedAlways }

    private var isFamilyControlsGranted: Bool {
        AuthorizationCenter.shared.authorizationStatus == .approved
    }

    private var notificationStatus: UNAuthorizationStatus = .notDetermined

    /// True when the parent has at least one app marked for blocking in SwiftData.
    /// If no apps are configured the parent doesn't need permissions yet.
    private var parentHasBlockingApps: Bool {
        // Fast path: check the in-memory view-model (available after first load)
        let vm = ParentControlViewModel.shared
        if !vm.appStatuses.isEmpty {
            return vm.appStatuses.contains { $0.isBlocked }
        }
        // Fallback: read SwiftData directly (e.g. on cold launch before VM finishes loading)
        guard let container = AppBlockerManager.shared.modelContainer else { return false }
        let ctx = ModelContext(container)
        guard let saved = try? ctx.fetch(FetchDescriptor<BlockingSelection>()).first else {
            return false
        }
        return saved.appStatuses.contains { $0.isBlocked }
    }

    private var isParent: Bool { UserDefaults.Main.bool(forKey: .isParent) }

    // MARK: - Entry Point

    /// Call from viewWillAppear, viewDidLoad, and didBecomeActive.
    /// If a popup is already on screen it is removed first so the new one always
    /// shows up-to-date permission data (fixes foreground-return stale state).
    /// Standard check — used by ChildHomeVC on every appear.
    func checkAndShow() {
        show(forceMandatory: false)
    }

    /// Used by SettingsVC when parent taps Self Drive Mode.
    /// Location + Screen Time are mandatory regardless of blocking app count.
    func checkAndShowForSelfDrive() {
        show(forceMandatory: true)
    }

    private func show(forceMandatory: Bool) {
        // Never prompt for permissions on pre-login screens (ChooseRoleVC, IntroVC, LoginVC).
        // autoLogin == false means no active session — permissions are irrelevant until logged in.
        guard UserDefaults.Main.bool(forKey: .autoLogin) else { return }
        guard !isChecking else { return }
        isChecking = true
        dismissExistingOverlay()

        Task {
            defer { Task { @MainActor in self.isChecking = false } }
            // ── Notifications: request inline on first launch ─────────────────
            let notifSettings = await UNUserNotificationCenter.current().notificationSettings()
            self.notificationStatus = notifSettings.authorizationStatus
            if self.notificationStatus == .notDetermined {
                try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                UIApplication.shared.registerForRemoteNotifications()
                let updated = await UNUserNotificationCenter.current().notificationSettings()
                self.notificationStatus = updated.authorizationStatus
            }

            // ── Location: request inline on first launch ──────────────────────
            if CLLocationManager().authorizationStatus == .notDetermined {
                LocationPermissionManager.shared.startUpdating()
            }

            // ── Family Controls: request inline on first launch ───────────────
            if AuthorizationCenter.shared.authorizationStatus == .notDetermined {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    if AuthorizationCenter.shared.authorizationStatus == .approved {
                        print("Family Controls Approved! Posting Notification.")
                        NotificationCenter.default.post(name: NSNotification.Name("FamilyControlsAuthDidApprove"), object: nil)
                    }
                } catch {
                    print("Family Controls authorization failed: \(error)")
                }
            }

            await MainActor.run { self.evaluate(forceMandatory: forceMandatory) }
        }
    }

    // MARK: - Force-dismiss stale overlay

    private func dismissExistingOverlay() {
        guard let window = keyWindow(),
              let old = window.viewWithTag(overlayTag)
        else { return }
        old.removeFromSuperview()
    }

    // MARK: - Evaluate Missing Permissions

    private func evaluate(forceMandatory: Bool = false) {
        guard let window = keyWindow() else { return }
        // Guard: don't stack two popups
        if window.viewWithTag(overlayTag) != nil { return }

        // ── Determine mandatory vs optional per role ──────────────────────────
        // Parent: permissions are optional until they configure ≥1 blocking app.
        // Child: Location + Family Controls always mandatory.
        let parentMandatory = forceMandatory || (isParent && parentHasBlockingApps)

        var missing: [PermissionItem] = []

        // 1. Location — show in popup only when denied or stuck at whenInUse
        let locStatus = locationStatus
        if locStatus == .denied || locStatus == .restricted || locStatus == .authorizedWhenInUse {
            let mandatory = !isParent || parentMandatory
            missing.append(.location(status: locStatus, mandatory: mandatory))
        }

        // 2. Family Controls — show in popup only when DENIED (notDetermined handled inline above)
        if AuthorizationCenter.shared.authorizationStatus == .denied {
            let mandatory = !isParent || parentMandatory
            missing.append(.familyControls(mandatory: mandatory))
        }

        // 3. Notifications — show in popup only when DENIED (notDetermined is handled inline above)
        if notificationStatus == .denied {
            missing.append(.notifications)
        }

        guard !missing.isEmpty else { return }

        present(items: missing, in: window)
    }

    // MARK: - Present Popup

    private func present(items: [PermissionItem], in window: UIWindow) {
        let appBlue = UIColor(named: "AppDarkBlue") ?? UIColor(red: 0.10, green: 0.19, blue: 0.38, alpha: 1)
        let cardWidth: CGFloat = min(window.bounds.width - 48, 340)

        // ── Overlay ───────────────────────────────────────────────────────────
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        overlay.alpha = 0
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.tag = overlayTag
        window.addSubview(overlay)

        // ── Card ──────────────────────────────────────────────────────────────
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

        // ── Outer stack ───────────────────────────────────────────────────────
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

        // ── Icon ──────────────────────────────────────────────────────────────
        let iconName = items.count == 1 ? items[0].systemIconName : "lock.shield.fill"
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = appBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        outer.addArrangedSubview(iconView)

        // ── Title ─────────────────────────────────────────────────────────────
        let titleLbl = UILabel()
        titleLbl.font = UIFont(name: "PlusJakartaSans-Bold", size: 17) ?? .systemFont(ofSize: 17, weight: .bold)
        titleLbl.textColor = appBlue
        titleLbl.textAlignment = .center
        titleLbl.numberOfLines = 0
        titleLbl.text = items.count == 1 ? items[0].title : "Permissions Required"
        outer.addArrangedSubview(titleLbl)

        // ── Subtitle ──────────────────────────────────────────────────────────
        let hasMandatory = items.contains { $0.isMandatory }
        let subLbl = UILabel()
        subLbl.font = UIFont(name: "PlusJakartaSans-Regular", size: 13) ?? .systemFont(ofSize: 13)
        subLbl.textColor = .darkGray
        subLbl.textAlignment = .center
        subLbl.numberOfLines = 0
        subLbl.text = hasMandatory
            ? "GuardianDrive needs the following to work properly. Please grant required permissions in Settings."
            : "These permissions improve your experience. You can skip if you prefer."
        outer.addArrangedSubview(subLbl)

        // ── Permission rows ───────────────────────────────────────────────────
        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.alignment = .fill
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        rowsStack.widthAnchor.constraint(equalToConstant: cardWidth - 40).isActive = true
        outer.addArrangedSubview(rowsStack)

        for item in items {
            rowsStack.addArrangedSubview(buildRow(item: item, appBlue: appBlue))
        }

        // ── Divider ───────────────────────────────────────────────────────────
        let divider = UIView()
        divider.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        divider.widthAnchor.constraint(equalToConstant: cardWidth - 40).isActive = true
        outer.addArrangedSubview(divider)

        // ── Open Settings button ──────────────────────────────────────────────
        let primaryBtn = UIButton(type: .system)
        primaryBtn.setTitle("Open Settings", for: .normal)
        primaryBtn.titleLabel?.font = UIFont(name: "PlusJakartaSans-SemiBold", size: 16)
            ?? .systemFont(ofSize: 16, weight: .semibold)
        primaryBtn.setTitleColor(.white, for: .normal)
        primaryBtn.backgroundColor = appBlue
        primaryBtn.layer.cornerRadius = 12
        primaryBtn.layer.masksToBounds = true
        primaryBtn.translatesAutoresizingMaskIntoConstraints = false
        primaryBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        primaryBtn.widthAnchor.constraint(equalToConstant: cardWidth - 40).isActive = true
        outer.addArrangedSubview(primaryBtn)
        primaryBtn.addAction(UIAction { [weak overlay] _ in
            overlay?.removeFromSuperview()
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }, for: .touchUpInside)

        // ── Skip button — shown when no mandatory items ───────────────────────
        if !hasMandatory {
            let skipBtn = UIButton(type: .system)
            skipBtn.setTitle("Skip for Now", for: .normal)
            skipBtn.titleLabel?.font = UIFont(name: "PlusJakartaSans-Regular", size: 14)
                ?? .systemFont(ofSize: 14)
            skipBtn.setTitleColor(.darkGray, for: .normal)
            skipBtn.translatesAutoresizingMaskIntoConstraints = false
            skipBtn.heightAnchor.constraint(equalToConstant: 36).isActive = true
            outer.addArrangedSubview(skipBtn)
            skipBtn.addAction(UIAction { [weak overlay] _ in
                overlay?.removeFromSuperview()
            }, for: .touchUpInside)
        }

        // ── Animate in ────────────────────────────────────────────────────────
        card.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        DispatchQueue.main.async {
            UIView.animate(
                withDuration: 0.38, delay: 0,
                usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5,
                options: .curveEaseOut
            ) {
                overlay.alpha = 1
                card.transform = .identity
            }
        }
    }

    // MARK: - Permission Row Builder

    private func buildRow(item: PermissionItem, appBlue: UIColor) -> UIView {
        let appRed = UIColor(red: 0.83, green: 0.09, blue: 0.24, alpha: 1)

        let row = UIView()
        row.backgroundColor = item.isMandatory
            ? UIColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1)
            : UIColor(red: 0.97, green: 0.97, blue: 1.0, alpha: 1)
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

        // Icon circle
        let iconBg = UIView()
        iconBg.backgroundColor = appBlue.withAlphaComponent(0.15)
        iconBg.layer.cornerRadius = 18
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.widthAnchor.constraint(equalToConstant: 36).isActive = true
        iconBg.heightAnchor.constraint(equalToConstant: 36).isActive = true
        let icon = UIImageView(image: UIImage(systemName: item.systemIconName))
        icon.tintColor = appBlue
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

        // Text
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let nameLbl = UILabel()
        nameLbl.font = UIFont(name: "PlusJakartaSans-SemiBold", size: 13)
            ?? .systemFont(ofSize: 13, weight: .semibold)
        nameLbl.textColor = appBlue
        nameLbl.text = item.title
        textStack.addArrangedSubview(nameLbl)

        let descLbl = UILabel()
        descLbl.font = UIFont(name: "PlusJakartaSans-Regular", size: 11)
            ?? .systemFont(ofSize: 11)
        descLbl.textColor = .darkGray
        descLbl.numberOfLines = 0
        descLbl.text = item.description
        textStack.addArrangedSubview(descLbl)
        hStack.addArrangedSubview(textStack)

        // Badge
        let badge = PaddedLabel()
        badge.font = UIFont(name: "PlusJakartaSans-SemiBold", size: 9)
            ?? .systemFont(ofSize: 9, weight: .bold)
        badge.textColor = .white
        badge.text = item.isMandatory ? "REQUIRED" : "OPTIONAL"
        badge.backgroundColor = item.isMandatory ? appRed : UIColor.systemOrange
        badge.layer.cornerRadius = 5
        badge.layer.masksToBounds = true
        badge.textAlignment = .center
        badge.textInsets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)
        hStack.addArrangedSubview(badge)

        return row
    }

    // MARK: - Helpers

    private func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
    }
}

// MARK: - PaddedLabel

private class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets.zero
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(
            width: s.width + textInsets.left + textInsets.right,
            height: s.height + textInsets.top + textInsets.bottom)
    }
}

// MARK: - Permission Item

enum PermissionItem {
    case location(status: CLAuthorizationStatus, mandatory: Bool)
    case familyControls(mandatory: Bool)
    case notifications   // always optional

    var title: String {
        switch self {
        case .location:          return "Location (Always)"
        case .familyControls:    return "Screen Time"
        case .notifications:     return "Notifications"
        }
    }

    var description: String {
        switch self {
        case .location(let status, _):
            switch status {
            case .authorizedWhenInUse:
                return "\"Always\" access is required for background speed monitoring."
            default:
                return "Needed to monitor driving speed and activate Drive Mode in the background."
            }
        case .familyControls:
            return "Required to block restricted apps. Enable Screen Time Restrictions in Settings."
        case .notifications:
            return "Get notified when your parent approves or rejects a request."
        }
    }

    var systemIconName: String {
        switch self {
        case .location:       return "location.fill"
        case .familyControls: return "hourglass"
        case .notifications:  return "bell.fill"
        }
    }

    var isMandatory: Bool {
        switch self {
        case .location(_, let mandatory):      return mandatory
        case .familyControls(let mandatory):   return mandatory
        case .notifications:                   return false
        }
    }
}
