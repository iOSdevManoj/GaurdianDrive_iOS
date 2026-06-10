import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AppBorderGray" asset catalog color resource.
    static let appBorderGray = DeveloperToolsSupport.ColorResource(name: "AppBorderGray", bundle: resourceBundle)

    /// The "AppDarkBlue" asset catalog color resource.
    static let appDarkBlue = DeveloperToolsSupport.ColorResource(name: "AppDarkBlue", bundle: resourceBundle)

    /// The "AppDarkGreen" asset catalog color resource.
    static let appDarkGreen = DeveloperToolsSupport.ColorResource(name: "AppDarkGreen", bundle: resourceBundle)

    /// The "AppExtraDarkBlue" asset catalog color resource.
    static let appExtraDarkBlue = DeveloperToolsSupport.ColorResource(name: "AppExtraDarkBlue", bundle: resourceBundle)

    /// The "AppFontBlue" asset catalog color resource.
    static let appFontBlue = DeveloperToolsSupport.ColorResource(name: "AppFontBlue", bundle: resourceBundle)

    /// The "AppFullLightRed" asset catalog color resource.
    static let appFullLightRed = DeveloperToolsSupport.ColorResource(name: "AppFullLightRed", bundle: resourceBundle)

    /// The "AppGreen" asset catalog color resource.
    static let appGreen = DeveloperToolsSupport.ColorResource(name: "AppGreen", bundle: resourceBundle)

    /// The "AppLightBlue" asset catalog color resource.
    static let appLightBlue = DeveloperToolsSupport.ColorResource(name: "AppLightBlue", bundle: resourceBundle)

    /// The "AppLightGreen" asset catalog color resource.
    static let appLightGreen = DeveloperToolsSupport.ColorResource(name: "AppLightGreen", bundle: resourceBundle)

    /// The "AppLightPurple" asset catalog color resource.
    static let appLightPurple = DeveloperToolsSupport.ColorResource(name: "AppLightPurple", bundle: resourceBundle)

    /// The "AppLightYellow" asset catalog color resource.
    static let appLightYellow = DeveloperToolsSupport.ColorResource(name: "AppLightYellow", bundle: resourceBundle)

    /// The "AppPink" asset catalog color resource.
    static let appPink = DeveloperToolsSupport.ColorResource(name: "AppPink", bundle: resourceBundle)

    /// The "AppRed" asset catalog color resource.
    static let appRed = DeveloperToolsSupport.ColorResource(name: "AppRed", bundle: resourceBundle)

    /// The "BGLighGray" asset catalog color resource.
    static let bgLighGray = DeveloperToolsSupport.ColorResource(name: "BGLighGray", bundle: resourceBundle)

    /// The "BlackColor" asset catalog color resource.
    static let black = DeveloperToolsSupport.ColorResource(name: "BlackColor", bundle: resourceBundle)

    /// The "PlaceholderGray" asset catalog color resource.
    static let placeholderGray = DeveloperToolsSupport.ColorResource(name: "PlaceholderGray", bundle: resourceBundle)

    /// The "WhiteColor" asset catalog color resource.
    static let white = DeveloperToolsSupport.ColorResource(name: "WhiteColor", bundle: resourceBundle)

    /// The "lightTransparentColor" asset catalog color resource.
    static let lightTransparent = DeveloperToolsSupport.ColorResource(name: "lightTransparentColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "Img_Intro" asset catalog image resource.
    static let imgIntro = DeveloperToolsSupport.ImageResource(name: "Img_Intro", bundle: resourceBundle)

    /// The "Splash" asset catalog image resource.
    static let splash = DeveloperToolsSupport.ImageResource(name: "Splash", bundle: resourceBundle)

    /// The "ic_addApp_green" asset catalog image resource.
    static let icAddAppGreen = DeveloperToolsSupport.ImageResource(name: "ic_addApp_green", bundle: resourceBundle)

    /// The "ic_add_child" asset catalog image resource.
    static let icAddChild = DeveloperToolsSupport.ImageResource(name: "ic_add_child", bundle: resourceBundle)

    /// The "ic_apple" asset catalog image resource.
    static let icApple = DeveloperToolsSupport.ImageResource(name: "ic_apple", bundle: resourceBundle)

    /// The "ic_arrow_red" asset catalog image resource.
    static let icArrowRed = DeveloperToolsSupport.ImageResource(name: "ic_arrow_red", bundle: resourceBundle)

    /// The "ic_back_blue" asset catalog image resource.
    static let icBackBlue = DeveloperToolsSupport.ImageResource(name: "ic_back_blue", bundle: resourceBundle)

    /// The "ic_backword_blue" asset catalog image resource.
    static let icBackwordBlue = DeveloperToolsSupport.ImageResource(name: "ic_backword_blue", bundle: resourceBundle)

    /// The "ic_bell_white" asset catalog image resource.
    static let icBellWhite = DeveloperToolsSupport.ImageResource(name: "ic_bell_white", bundle: resourceBundle)

    /// The "ic_child_blue" asset catalog image resource.
    static let icChildBlue = DeveloperToolsSupport.ImageResource(name: "ic_child_blue", bundle: resourceBundle)

    /// The "ic_child_privacy" asset catalog image resource.
    static let icChildPrivacy = DeveloperToolsSupport.ImageResource(name: "ic_child_privacy", bundle: resourceBundle)

    /// The "ic_cross_blue" asset catalog image resource.
    static let icCrossBlue = DeveloperToolsSupport.ImageResource(name: "ic_cross_blue", bundle: resourceBundle)

    /// The "ic_cross_red" asset catalog image resource.
    static let icCrossRed = DeveloperToolsSupport.ImageResource(name: "ic_cross_red", bundle: resourceBundle)

    /// The "ic_delete_red" asset catalog image resource.
    static let icDeleteRed = DeveloperToolsSupport.ImageResource(name: "ic_delete_red", bundle: resourceBundle)

    /// The "ic_down_blue" asset catalog image resource.
    static let icDownBlue = DeveloperToolsSupport.ImageResource(name: "ic_down_blue", bundle: resourceBundle)

    /// The "ic_down_gray" asset catalog image resource.
    static let icDownGray = DeveloperToolsSupport.ImageResource(name: "ic_down_gray", bundle: resourceBundle)

    /// The "ic_forward_gray" asset catalog image resource.
    static let icForwardGray = DeveloperToolsSupport.ImageResource(name: "ic_forward_gray", bundle: resourceBundle)

    /// The "ic_google" asset catalog image resource.
    static let icGoogle = DeveloperToolsSupport.ImageResource(name: "ic_google", bundle: resourceBundle)

    /// The "ic_logo_blue" asset catalog image resource.
    static let icLogoBlue = DeveloperToolsSupport.ImageResource(name: "ic_logo_blue", bundle: resourceBundle)

    /// The "ic_logo_name" asset catalog image resource.
    static let icLogoName = DeveloperToolsSupport.ImageResource(name: "ic_logo_name", bundle: resourceBundle)

    /// The "ic_map_pin" asset catalog image resource.
    static let icMapPin = DeveloperToolsSupport.ImageResource(name: "ic_map_pin", bundle: resourceBundle)

    /// The "ic_notification_temp" asset catalog image resource.
    static let icNotificationTemp = DeveloperToolsSupport.ImageResource(name: "ic_notification_temp", bundle: resourceBundle)

    /// The "ic_parent_blue" asset catalog image resource.
    static let icParentBlue = DeveloperToolsSupport.ImageResource(name: "ic_parent_blue", bundle: resourceBundle)

    /// The "ic_placeholder_gray" asset catalog image resource.
    static let icPlaceholderGray = DeveloperToolsSupport.ImageResource(name: "ic_placeholder_gray", bundle: resourceBundle)

    /// The "ic_plus_white" asset catalog image resource.
    static let icPlusWhite = DeveloperToolsSupport.ImageResource(name: "ic_plus_white", bundle: resourceBundle)

    /// The "ic_profile_blue" asset catalog image resource.
    static let icProfileBlue = DeveloperToolsSupport.ImageResource(name: "ic_profile_blue", bundle: resourceBundle)

    /// The "ic_removeApp_red" asset catalog image resource.
    static let icRemoveAppRed = DeveloperToolsSupport.ImageResource(name: "ic_removeApp_red", bundle: resourceBundle)

    /// The "ic_right_green" asset catalog image resource.
    static let icRightGreen = DeveloperToolsSupport.ImageResource(name: "ic_right_green", bundle: resourceBundle)

    /// The "ic_wheel_gray" asset catalog image resource.
    static let icWheelGray = DeveloperToolsSupport.ImageResource(name: "ic_wheel_gray", bundle: resourceBundle)

    /// The "ic_white_placeholder" asset catalog image resource.
    static let icWhitePlaceholder = DeveloperToolsSupport.ImageResource(name: "ic_white_placeholder", bundle: resourceBundle)

    /// The "icon_remove" asset catalog image resource.
    static let iconRemove = DeveloperToolsSupport.ImageResource(name: "icon_remove", bundle: resourceBundle)

    /// The "img_locations" asset catalog image resource.
    static let imgLocations = DeveloperToolsSupport.ImageResource(name: "img_locations", bundle: resourceBundle)

    /// The "img_temp_flag" asset catalog image resource.
    static let imgTempFlag = DeveloperToolsSupport.ImageResource(name: "img_temp_flag", bundle: resourceBundle)

    /// The "img_white_bg" asset catalog image resource.
    static let imgWhiteBg = DeveloperToolsSupport.ImageResource(name: "img_white_bg", bundle: resourceBundle)

    /// The "tab_home_light" asset catalog image resource.
    static let tabHomeLight = DeveloperToolsSupport.ImageResource(name: "tab_home_light", bundle: resourceBundle)

    /// The "tab_home_white" asset catalog image resource.
    static let tabHomeWhite = DeveloperToolsSupport.ImageResource(name: "tab_home_white", bundle: resourceBundle)

    /// The "tab_report_light" asset catalog image resource.
    static let tabReportLight = DeveloperToolsSupport.ImageResource(name: "tab_report_light", bundle: resourceBundle)

    /// The "tab_report_white" asset catalog image resource.
    static let tabReportWhite = DeveloperToolsSupport.ImageResource(name: "tab_report_white", bundle: resourceBundle)

    /// The "tab_setting_light" asset catalog image resource.
    static let tabSettingLight = DeveloperToolsSupport.ImageResource(name: "tab_setting_light", bundle: resourceBundle)

    /// The "tab_setting_white" asset catalog image resource.
    static let tabSettingWhite = DeveloperToolsSupport.ImageResource(name: "tab_setting_white", bundle: resourceBundle)

    /// The "temp_app_img" asset catalog image resource.
    static let tempAppImg = DeveloperToolsSupport.ImageResource(name: "temp_app_img", bundle: resourceBundle)

    /// The "temp_profile" asset catalog image resource.
    static let tempProfile = DeveloperToolsSupport.ImageResource(name: "temp_profile", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AppBorderGray" asset catalog color.
    static var appBorderGray: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appBorderGray)
#else
        .init()
#endif
    }

    /// The "AppDarkBlue" asset catalog color.
    static var appDarkBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appDarkBlue)
#else
        .init()
#endif
    }

    /// The "AppDarkGreen" asset catalog color.
    static var appDarkGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appDarkGreen)
#else
        .init()
#endif
    }

    /// The "AppExtraDarkBlue" asset catalog color.
    static var appExtraDarkBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appExtraDarkBlue)
#else
        .init()
#endif
    }

    /// The "AppFontBlue" asset catalog color.
    static var appFontBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appFontBlue)
#else
        .init()
#endif
    }

    /// The "AppFullLightRed" asset catalog color.
    static var appFullLightRed: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appFullLightRed)
#else
        .init()
#endif
    }

    /// The "AppGreen" asset catalog color.
    static var appGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appGreen)
#else
        .init()
#endif
    }

    /// The "AppLightBlue" asset catalog color.
    static var appLightBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appLightBlue)
#else
        .init()
#endif
    }

    /// The "AppLightGreen" asset catalog color.
    static var appLightGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appLightGreen)
#else
        .init()
#endif
    }

    /// The "AppLightPurple" asset catalog color.
    static var appLightPurple: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appLightPurple)
#else
        .init()
#endif
    }

    /// The "AppLightYellow" asset catalog color.
    static var appLightYellow: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appLightYellow)
#else
        .init()
#endif
    }

    /// The "AppPink" asset catalog color.
    static var appPink: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appPink)
#else
        .init()
#endif
    }

    /// The "AppRed" asset catalog color.
    static var appRed: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appRed)
#else
        .init()
#endif
    }

    /// The "BGLighGray" asset catalog color.
    static var bgLighGray: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bgLighGray)
#else
        .init()
#endif
    }

    #warning("The \"BlackColor\" color asset name resolves to a conflicting NSColor symbol \"black\". Try renaming the asset.")

    /// The "PlaceholderGray" asset catalog color.
    static var placeholderGray: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .placeholderGray)
#else
        .init()
#endif
    }

    #warning("The \"WhiteColor\" color asset name resolves to a conflicting NSColor symbol \"white\". Try renaming the asset.")

    /// The "lightTransparentColor" asset catalog color.
    static var lightTransparent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lightTransparent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AppBorderGray" asset catalog color.
    static var appBorderGray: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appBorderGray)
#else
        .init()
#endif
    }

    /// The "AppDarkBlue" asset catalog color.
    static var appDarkBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appDarkBlue)
#else
        .init()
#endif
    }

    /// The "AppDarkGreen" asset catalog color.
    static var appDarkGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appDarkGreen)
#else
        .init()
#endif
    }

    /// The "AppExtraDarkBlue" asset catalog color.
    static var appExtraDarkBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appExtraDarkBlue)
#else
        .init()
#endif
    }

    /// The "AppFontBlue" asset catalog color.
    static var appFontBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appFontBlue)
#else
        .init()
#endif
    }

    /// The "AppFullLightRed" asset catalog color.
    static var appFullLightRed: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appFullLightRed)
#else
        .init()
#endif
    }

    /// The "AppGreen" asset catalog color.
    static var appGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appGreen)
#else
        .init()
#endif
    }

    /// The "AppLightBlue" asset catalog color.
    static var appLightBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appLightBlue)
#else
        .init()
#endif
    }

    /// The "AppLightGreen" asset catalog color.
    static var appLightGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appLightGreen)
#else
        .init()
#endif
    }

    /// The "AppLightPurple" asset catalog color.
    static var appLightPurple: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appLightPurple)
#else
        .init()
#endif
    }

    /// The "AppLightYellow" asset catalog color.
    static var appLightYellow: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appLightYellow)
#else
        .init()
#endif
    }

    /// The "AppPink" asset catalog color.
    static var appPink: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appPink)
#else
        .init()
#endif
    }

    /// The "AppRed" asset catalog color.
    static var appRed: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appRed)
#else
        .init()
#endif
    }

    /// The "BGLighGray" asset catalog color.
    static var bgLighGray: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .bgLighGray)
#else
        .init()
#endif
    }

    #warning("The \"BlackColor\" color asset name resolves to a conflicting UIColor symbol \"black\". Try renaming the asset.")

    /// The "PlaceholderGray" asset catalog color.
    static var placeholderGray: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .placeholderGray)
#else
        .init()
#endif
    }

    #warning("The \"WhiteColor\" color asset name resolves to a conflicting UIColor symbol \"white\". Try renaming the asset.")

    /// The "lightTransparentColor" asset catalog color.
    static var lightTransparent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .lightTransparent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AppBorderGray" asset catalog color.
    static var appBorderGray: SwiftUI.Color { .init(.appBorderGray) }

    /// The "AppDarkBlue" asset catalog color.
    static var appDarkBlue: SwiftUI.Color { .init(.appDarkBlue) }

    /// The "AppDarkGreen" asset catalog color.
    static var appDarkGreen: SwiftUI.Color { .init(.appDarkGreen) }

    /// The "AppExtraDarkBlue" asset catalog color.
    static var appExtraDarkBlue: SwiftUI.Color { .init(.appExtraDarkBlue) }

    /// The "AppFontBlue" asset catalog color.
    static var appFontBlue: SwiftUI.Color { .init(.appFontBlue) }

    /// The "AppFullLightRed" asset catalog color.
    static var appFullLightRed: SwiftUI.Color { .init(.appFullLightRed) }

    /// The "AppGreen" asset catalog color.
    static var appGreen: SwiftUI.Color { .init(.appGreen) }

    /// The "AppLightBlue" asset catalog color.
    static var appLightBlue: SwiftUI.Color { .init(.appLightBlue) }

    /// The "AppLightGreen" asset catalog color.
    static var appLightGreen: SwiftUI.Color { .init(.appLightGreen) }

    /// The "AppLightPurple" asset catalog color.
    static var appLightPurple: SwiftUI.Color { .init(.appLightPurple) }

    /// The "AppLightYellow" asset catalog color.
    static var appLightYellow: SwiftUI.Color { .init(.appLightYellow) }

    /// The "AppPink" asset catalog color.
    static var appPink: SwiftUI.Color { .init(.appPink) }

    /// The "AppRed" asset catalog color.
    static var appRed: SwiftUI.Color { .init(.appRed) }

    /// The "BGLighGray" asset catalog color.
    static var bgLighGray: SwiftUI.Color { .init(.bgLighGray) }

    #warning("The \"BlackColor\" color asset name resolves to a conflicting Color symbol \"black\". Try renaming the asset.")

    /// The "PlaceholderGray" asset catalog color.
    static var placeholderGray: SwiftUI.Color { .init(.placeholderGray) }

    #warning("The \"WhiteColor\" color asset name resolves to a conflicting Color symbol \"white\". Try renaming the asset.")

    /// The "lightTransparentColor" asset catalog color.
    static var lightTransparent: SwiftUI.Color { .init(.lightTransparent) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AppBorderGray" asset catalog color.
    static var appBorderGray: SwiftUI.Color { .init(.appBorderGray) }

    /// The "AppDarkBlue" asset catalog color.
    static var appDarkBlue: SwiftUI.Color { .init(.appDarkBlue) }

    /// The "AppDarkGreen" asset catalog color.
    static var appDarkGreen: SwiftUI.Color { .init(.appDarkGreen) }

    /// The "AppExtraDarkBlue" asset catalog color.
    static var appExtraDarkBlue: SwiftUI.Color { .init(.appExtraDarkBlue) }

    /// The "AppFontBlue" asset catalog color.
    static var appFontBlue: SwiftUI.Color { .init(.appFontBlue) }

    /// The "AppFullLightRed" asset catalog color.
    static var appFullLightRed: SwiftUI.Color { .init(.appFullLightRed) }

    /// The "AppGreen" asset catalog color.
    static var appGreen: SwiftUI.Color { .init(.appGreen) }

    /// The "AppLightBlue" asset catalog color.
    static var appLightBlue: SwiftUI.Color { .init(.appLightBlue) }

    /// The "AppLightGreen" asset catalog color.
    static var appLightGreen: SwiftUI.Color { .init(.appLightGreen) }

    /// The "AppLightPurple" asset catalog color.
    static var appLightPurple: SwiftUI.Color { .init(.appLightPurple) }

    /// The "AppLightYellow" asset catalog color.
    static var appLightYellow: SwiftUI.Color { .init(.appLightYellow) }

    /// The "AppPink" asset catalog color.
    static var appPink: SwiftUI.Color { .init(.appPink) }

    /// The "AppRed" asset catalog color.
    static var appRed: SwiftUI.Color { .init(.appRed) }

    /// The "BGLighGray" asset catalog color.
    static var bgLighGray: SwiftUI.Color { .init(.bgLighGray) }

    /// The "PlaceholderGray" asset catalog color.
    static var placeholderGray: SwiftUI.Color { .init(.placeholderGray) }

    /// The "lightTransparentColor" asset catalog color.
    static var lightTransparent: SwiftUI.Color { .init(.lightTransparent) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Img_Intro" asset catalog image.
    static var imgIntro: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .imgIntro)
#else
        .init()
#endif
    }

    /// The "Splash" asset catalog image.
    static var splash: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .splash)
#else
        .init()
#endif
    }

    /// The "ic_addApp_green" asset catalog image.
    static var icAddAppGreen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icAddAppGreen)
#else
        .init()
#endif
    }

    /// The "ic_add_child" asset catalog image.
    static var icAddChild: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icAddChild)
#else
        .init()
#endif
    }

    /// The "ic_apple" asset catalog image.
    static var icApple: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icApple)
#else
        .init()
#endif
    }

    /// The "ic_arrow_red" asset catalog image.
    static var icArrowRed: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icArrowRed)
#else
        .init()
#endif
    }

    /// The "ic_back_blue" asset catalog image.
    static var icBackBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icBackBlue)
#else
        .init()
#endif
    }

    /// The "ic_backword_blue" asset catalog image.
    static var icBackwordBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icBackwordBlue)
#else
        .init()
#endif
    }

    /// The "ic_bell_white" asset catalog image.
    static var icBellWhite: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icBellWhite)
#else
        .init()
#endif
    }

    /// The "ic_child_blue" asset catalog image.
    static var icChildBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icChildBlue)
#else
        .init()
#endif
    }

    /// The "ic_child_privacy" asset catalog image.
    static var icChildPrivacy: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icChildPrivacy)
#else
        .init()
#endif
    }

    /// The "ic_cross_blue" asset catalog image.
    static var icCrossBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icCrossBlue)
#else
        .init()
#endif
    }

    /// The "ic_cross_red" asset catalog image.
    static var icCrossRed: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icCrossRed)
#else
        .init()
#endif
    }

    /// The "ic_delete_red" asset catalog image.
    static var icDeleteRed: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icDeleteRed)
#else
        .init()
#endif
    }

    /// The "ic_down_blue" asset catalog image.
    static var icDownBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icDownBlue)
#else
        .init()
#endif
    }

    /// The "ic_down_gray" asset catalog image.
    static var icDownGray: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icDownGray)
#else
        .init()
#endif
    }

    /// The "ic_forward_gray" asset catalog image.
    static var icForwardGray: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icForwardGray)
#else
        .init()
#endif
    }

    /// The "ic_google" asset catalog image.
    static var icGoogle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icGoogle)
#else
        .init()
#endif
    }

    /// The "ic_logo_blue" asset catalog image.
    static var icLogoBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icLogoBlue)
#else
        .init()
#endif
    }

    /// The "ic_logo_name" asset catalog image.
    static var icLogoName: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icLogoName)
#else
        .init()
#endif
    }

    /// The "ic_map_pin" asset catalog image.
    static var icMapPin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icMapPin)
#else
        .init()
#endif
    }

    /// The "ic_notification_temp" asset catalog image.
    static var icNotificationTemp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icNotificationTemp)
#else
        .init()
#endif
    }

    /// The "ic_parent_blue" asset catalog image.
    static var icParentBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icParentBlue)
#else
        .init()
#endif
    }

    /// The "ic_placeholder_gray" asset catalog image.
    static var icPlaceholderGray: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icPlaceholderGray)
#else
        .init()
#endif
    }

    /// The "ic_plus_white" asset catalog image.
    static var icPlusWhite: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icPlusWhite)
#else
        .init()
#endif
    }

    /// The "ic_profile_blue" asset catalog image.
    static var icProfileBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icProfileBlue)
#else
        .init()
#endif
    }

    /// The "ic_removeApp_red" asset catalog image.
    static var icRemoveAppRed: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icRemoveAppRed)
#else
        .init()
#endif
    }

    /// The "ic_right_green" asset catalog image.
    static var icRightGreen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icRightGreen)
#else
        .init()
#endif
    }

    /// The "ic_wheel_gray" asset catalog image.
    static var icWheelGray: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icWheelGray)
#else
        .init()
#endif
    }

    /// The "ic_white_placeholder" asset catalog image.
    static var icWhitePlaceholder: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icWhitePlaceholder)
#else
        .init()
#endif
    }

    /// The "icon_remove" asset catalog image.
    static var iconRemove: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .iconRemove)
#else
        .init()
#endif
    }

    /// The "img_locations" asset catalog image.
    static var imgLocations: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .imgLocations)
#else
        .init()
#endif
    }

    /// The "img_temp_flag" asset catalog image.
    static var imgTempFlag: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .imgTempFlag)
#else
        .init()
#endif
    }

    /// The "img_white_bg" asset catalog image.
    static var imgWhiteBg: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .imgWhiteBg)
#else
        .init()
#endif
    }

    /// The "tab_home_light" asset catalog image.
    static var tabHomeLight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabHomeLight)
#else
        .init()
#endif
    }

    /// The "tab_home_white" asset catalog image.
    static var tabHomeWhite: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabHomeWhite)
#else
        .init()
#endif
    }

    /// The "tab_report_light" asset catalog image.
    static var tabReportLight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabReportLight)
#else
        .init()
#endif
    }

    /// The "tab_report_white" asset catalog image.
    static var tabReportWhite: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabReportWhite)
#else
        .init()
#endif
    }

    /// The "tab_setting_light" asset catalog image.
    static var tabSettingLight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabSettingLight)
#else
        .init()
#endif
    }

    /// The "tab_setting_white" asset catalog image.
    static var tabSettingWhite: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tabSettingWhite)
#else
        .init()
#endif
    }

    /// The "temp_app_img" asset catalog image.
    static var tempAppImg: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tempAppImg)
#else
        .init()
#endif
    }

    /// The "temp_profile" asset catalog image.
    static var tempProfile: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tempProfile)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Img_Intro" asset catalog image.
    static var imgIntro: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .imgIntro)
#else
        .init()
#endif
    }

    /// The "Splash" asset catalog image.
    static var splash: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .splash)
#else
        .init()
#endif
    }

    /// The "ic_addApp_green" asset catalog image.
    static var icAddAppGreen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icAddAppGreen)
#else
        .init()
#endif
    }

    /// The "ic_add_child" asset catalog image.
    static var icAddChild: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icAddChild)
#else
        .init()
#endif
    }

    /// The "ic_apple" asset catalog image.
    static var icApple: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icApple)
#else
        .init()
#endif
    }

    /// The "ic_arrow_red" asset catalog image.
    static var icArrowRed: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icArrowRed)
#else
        .init()
#endif
    }

    /// The "ic_back_blue" asset catalog image.
    static var icBackBlue: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icBackBlue)
#else
        .init()
#endif
    }

    /// The "ic_backword_blue" asset catalog image.
    static var icBackwordBlue: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icBackwordBlue)
#else
        .init()
#endif
    }

    /// The "ic_bell_white" asset catalog image.
    static var icBellWhite: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icBellWhite)
#else
        .init()
#endif
    }

    /// The "ic_child_blue" asset catalog image.
    static var icChildBlue: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icChildBlue)
#else
        .init()
#endif
    }

    /// The "ic_child_privacy" asset catalog image.
    static var icChildPrivacy: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icChildPrivacy)
#else
        .init()
#endif
    }

    /// The "ic_cross_blue" asset catalog image.
    static var icCrossBlue: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icCrossBlue)
#else
        .init()
#endif
    }

    /// The "ic_cross_red" asset catalog image.
    static var icCrossRed: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icCrossRed)
#else
        .init()
#endif
    }

    /// The "ic_delete_red" asset catalog image.
    static var icDeleteRed: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icDeleteRed)
#else
        .init()
#endif
    }

    /// The "ic_down_blue" asset catalog image.
    static var icDownBlue: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icDownBlue)
#else
        .init()
#endif
    }

    /// The "ic_down_gray" asset catalog image.
    static var icDownGray: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icDownGray)
#else
        .init()
#endif
    }

    /// The "ic_forward_gray" asset catalog image.
    static var icForwardGray: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icForwardGray)
#else
        .init()
#endif
    }

    /// The "ic_google" asset catalog image.
    static var icGoogle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icGoogle)
#else
        .init()
#endif
    }

    /// The "ic_logo_blue" asset catalog image.
    static var icLogoBlue: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icLogoBlue)
#else
        .init()
#endif
    }

    /// The "ic_logo_name" asset catalog image.
    static var icLogoName: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icLogoName)
#else
        .init()
#endif
    }

    /// The "ic_map_pin" asset catalog image.
    static var icMapPin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icMapPin)
#else
        .init()
#endif
    }

    /// The "ic_notification_temp" asset catalog image.
    static var icNotificationTemp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icNotificationTemp)
#else
        .init()
#endif
    }

    /// The "ic_parent_blue" asset catalog image.
    static var icParentBlue: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icParentBlue)
#else
        .init()
#endif
    }

    /// The "ic_placeholder_gray" asset catalog image.
    static var icPlaceholderGray: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icPlaceholderGray)
#else
        .init()
#endif
    }

    /// The "ic_plus_white" asset catalog image.
    static var icPlusWhite: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icPlusWhite)
#else
        .init()
#endif
    }

    /// The "ic_profile_blue" asset catalog image.
    static var icProfileBlue: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icProfileBlue)
#else
        .init()
#endif
    }

    /// The "ic_removeApp_red" asset catalog image.
    static var icRemoveAppRed: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icRemoveAppRed)
#else
        .init()
#endif
    }

    /// The "ic_right_green" asset catalog image.
    static var icRightGreen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icRightGreen)
#else
        .init()
#endif
    }

    /// The "ic_wheel_gray" asset catalog image.
    static var icWheelGray: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icWheelGray)
#else
        .init()
#endif
    }

    /// The "ic_white_placeholder" asset catalog image.
    static var icWhitePlaceholder: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icWhitePlaceholder)
#else
        .init()
#endif
    }

    /// The "icon_remove" asset catalog image.
    static var iconRemove: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .iconRemove)
#else
        .init()
#endif
    }

    /// The "img_locations" asset catalog image.
    static var imgLocations: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .imgLocations)
#else
        .init()
#endif
    }

    /// The "img_temp_flag" asset catalog image.
    static var imgTempFlag: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .imgTempFlag)
#else
        .init()
#endif
    }

    /// The "img_white_bg" asset catalog image.
    static var imgWhiteBg: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .imgWhiteBg)
#else
        .init()
#endif
    }

    /// The "tab_home_light" asset catalog image.
    static var tabHomeLight: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabHomeLight)
#else
        .init()
#endif
    }

    /// The "tab_home_white" asset catalog image.
    static var tabHomeWhite: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabHomeWhite)
#else
        .init()
#endif
    }

    /// The "tab_report_light" asset catalog image.
    static var tabReportLight: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabReportLight)
#else
        .init()
#endif
    }

    /// The "tab_report_white" asset catalog image.
    static var tabReportWhite: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabReportWhite)
#else
        .init()
#endif
    }

    /// The "tab_setting_light" asset catalog image.
    static var tabSettingLight: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabSettingLight)
#else
        .init()
#endif
    }

    /// The "tab_setting_white" asset catalog image.
    static var tabSettingWhite: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tabSettingWhite)
#else
        .init()
#endif
    }

    /// The "temp_app_img" asset catalog image.
    static var tempAppImg: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tempAppImg)
#else
        .init()
#endif
    }

    /// The "temp_profile" asset catalog image.
    static var tempProfile: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tempProfile)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

