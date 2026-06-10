//
//  AppIconView.swift
//  GaurdianDrive
//

import FamilyControls
import ManagedSettings
import SwiftUI
import UIKit

// MARK: - App Icon View

private let appIconCornerRadius: CGFloat = 16

struct AppIconView: View {
    let token: ApplicationToken
    let appName: String

    private static let palette: [Color] = [
        Color(red: 0.29, green: 0.56, blue: 0.89),
        Color(red: 0.20, green: 0.74, blue: 0.47),
        Color(red: 0.91, green: 0.43, blue: 0.35),
        Color(red: 0.57, green: 0.36, blue: 0.84),
        Color(red: 0.98, green: 0.69, blue: 0.21),
        Color(red: 0.16, green: 0.71, blue: 0.87),
        Color(red: 0.91, green: 0.30, blue: 0.58),
        Color(red: 0.26, green: 0.63, blue: 0.28),
    ]

    private var safeDisplayName: String {
        AppNameResolution.isResolved(appName) ? appName : "?"
    }

    private var fallbackColor: Color {
        let seed = Int(safeDisplayName.unicodeScalars.first?.value ?? 65)
        return Self.palette[seed % Self.palette.count]
    }

    private var fallbackLetter: String {
        String(safeDisplayName.prefix(1)).uppercased()
    }

    var body: some View {
        GeometryReader { geo in
            let baseSize: CGFloat = 40
            let fillScale = (max(geo.size.width, geo.size.height) / baseSize) * 2.1

            ZStack {
                fallbackColor
                Text(fallbackLetter)
                    .font(.system(size: geo.size.width * 0.42, weight: .bold))
                    .foregroundColor(.white)

                Label(token)
                    .labelStyle(.iconOnly)
                    .font(.system(size: baseSize))
                    .scaleEffect(fillScale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: appIconCornerRadius, style: .continuous))
        }
        .contentShape(Rectangle())
    }
}

// MARK: - UIKit Helpers

extension UIView {
    @discardableResult
    func embed<V: View>(_ hostingController: UIHostingController<V>) -> UIHostingController<V> {
        let hcView = hostingController.view!
        hcView.backgroundColor = .clear
        hcView.translatesAutoresizingMaskIntoConstraints = false
        hcView.isUserInteractionEnabled = false
        addSubview(hcView)
        NSLayoutConstraint.activate([
            hcView.topAnchor.constraint(equalTo: topAnchor),
            hcView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hcView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hcView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        return hostingController
    }
}

// MARK: - Factory
extension AppIconView {
    @MainActor
    static func makeHostingController(
        token: ApplicationToken,
        appName: String,
        embeddedIn container: UIView
    ) -> UIHostingController<AnyView> {
        let view = AnyView(
            AppIconView(token: token, appName: appName)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        let hc = UIHostingController(rootView: view)
        container.embed(hc)
        return hc
    }
}

struct AppNameLabel: View {
    let token: ApplicationToken
    let font: Font
    let color: Color
    let scale: CGFloat
    let alignment: Alignment

    init(
        token: ApplicationToken,
        font: Font = .system(size: 11, weight: .medium),
        color: Color = Color("AppDarkBlue"),
        scale: CGFloat = 1.0,
        alignment: Alignment = .center
    ) {
        self.token = token
        self.font = font
        self.color = color
        self.scale = scale
        self.alignment = alignment
    }

    var body: some View {
        Label(token)
            .font(.headline)
            .labelStyle(.titleOnly)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(alignment == .leading ? .leading : (alignment == .trailing ? .trailing : .center))
            .scaleEffect(scale)
            .frame(maxWidth: .infinity, alignment: alignment)
            .environment(\.colorScheme, color == .white ? .dark : .light)
    }
}

extension AppNameLabel {
    @MainActor
    static func makeHostingController(
        token: ApplicationToken,
        font: Font = .system(size: 11, weight: .medium),
        color: Color = Color("AppDarkBlue"),
        scale: CGFloat = 1.0,
        alignment: Alignment = .center,
        embeddedIn container: UIView
    ) -> UIHostingController<AnyView> {
        let view = AnyView(
            AppNameLabel(token: token, font: font, color: color, scale: scale, alignment: alignment)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        let hc = UIHostingController(rootView: view)
        hc.view.backgroundColor = .clear
        container.embed(hc)
        return hc
    }
}
