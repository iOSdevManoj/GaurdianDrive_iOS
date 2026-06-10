// CellForDurationList.swift
// GaurdianDrive

import FamilyControls
import ManagedSettings
import SwiftUI
import UIKit

// MARK: - Combined cell label style (icon 36×36 + title)

private struct CombinedCellLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            configuration.title
                .font(.system(size: 16, weight: .medium))
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity)
    }
}

class CellForDurationList: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgRight: UIImageView!

    /// Holds either the combined Label(token) HC (tag 997) or the name-only HC (tag 998).
    private var nameHostingController: UIHostingController<AnyView>?
    private var iconContainerView: UIView?

    /// Fires when name resolves — only used on the cached-name slow path.
    var onNameResolved: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.viewWithTag(997)?.removeFromSuperview()
        contentView.viewWithTag(999)?.removeFromSuperview()
        lblTitle.subviews.forEach { $0.removeFromSuperview() }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        lblTitle.text = nil
        lblTitle.isHidden = false
        onNameResolved = nil
        tearDownNameHostingController()
        tearDownIconView()
    }

    // MARK: - Public Configure

    func configureCell(_ text: String, isSelected: Bool) {
        tearDownNameHostingController()
        tearDownIconView()
        lblTitle.text = text
        lblTitle.isHidden = false
        imgRight.isHidden = !isSelected
        resetLabelLeading(hasIcon: false)
    }

    func configureWithToken(_ token: ApplicationToken, isSelected: Bool, fallbackName: String? = nil) {
        imgRight.isHidden = !isSelected
        tearDownNameHostingController()
        tearDownIconView()
        lblTitle.isHidden = false

        let isRealName: Bool = {
            guard let name = fallbackName,
                  !name.isEmpty,
                  name != "Unknown",
                  name != "Unknown App",
                  name != "Removed App",
                  name != "Pending Resolution..." else { return false }
            return true
        }()

        if isRealName, let name = fallbackName {
            // Fast path: name already known — show instantly
            lblTitle.text = name
            lblTitle.font = .systemFont(ofSize: 16, weight: .medium)
            lblTitle.textColor = UIColor(named: "AppDarkBlue") ?? .label
            addIconView(token: token)
            resetLabelLeading(hasIcon: true)
        } else {
            // Slow path: name unknown.
            // Use ONE combined Label(token) for icon + title — a single
            // FamilyControlsAgent request handles both simultaneously.
            // The name appears once FamilyControlsAgent responds (~0.5-2 s).
            // Previously we used iconOnly + LabelWithNameCapture = 2 requests per
            // row; with 30 rows that's 60 concurrent requests → agent overwhelmed.
            lblTitle.isHidden = true
            addCombinedLabelView(token: token)
        }
    }

    // MARK: - Combined label (icon + title in one FamilyControlsAgent request)

    private func addCombinedLabelView(token: ApplicationToken) {
        let view = AnyView(Label(token).labelStyle(CombinedCellLabelStyle()))
        let hc = UIHostingController(rootView: view)
        hc.view.tag = 997
        hc.view.backgroundColor = .clear
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hc.view)
        NSLayoutConstraint.activate([
            hc.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hc.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: imgRight.leadingAnchor, constant: -8),
        ])
        nameHostingController = hc
    }

    // MARK: - Icon View (used only on the fast path when name is cached)

    private func addIconView(token: ApplicationToken) {
        let container = UIView()
        container.tag = 999
        container.translatesAutoresizingMaskIntoConstraints = false
        container.clipsToBounds = true
        container.layer.cornerRadius = 8
        container.backgroundColor = .clear
        contentView.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            container.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 36),
            container.heightAnchor.constraint(equalToConstant: 36),
        ])

        let iconView = AnyView(
            Label(token)
                .labelStyle(.iconOnly)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        )
        let hc = UIHostingController(rootView: iconView)
        hc.view.backgroundColor = .clear
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hc.view)
        NSLayoutConstraint.activate([
            hc.view.topAnchor.constraint(equalTo: container.topAnchor),
            hc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        iconContainerView = container
    }

    private func tearDownIconView() {
        iconContainerView?.removeFromSuperview()
        iconContainerView = nil
        while let stale = contentView.viewWithTag(999) { stale.removeFromSuperview() }
    }

    // MARK: - Name HC teardown

    private func tearDownNameHostingController() {
        nameHostingController?.view.removeFromSuperview()
        nameHostingController = nil
        // Remove combined view (tag 997) and legacy name view (tag 998)
        while let stale = contentView.viewWithTag(997) { stale.removeFromSuperview() }
        lblTitle.viewWithTag(998)?.removeFromSuperview()
        lblTitle.subviews.forEach { $0.removeFromSuperview() }
        lblTitle.isHidden = false
    }

    private func resetLabelLeading(hasIcon: Bool) {
        for constraint in contentView.constraints {
            if constraint.firstItem === lblTitle,
               constraint.firstAttribute == .leading {
                constraint.constant = hasIcon ? 60 : 15
            }
        }
    }
}
