// IconStorage.swift
import UIKit
import Foundation

public final class IconStorage {
    public static let shared = IconStorage()
    private let directoryURL: URL

    private init() {
        // Locate the app's Documents directory and create a subfolder "AppIcons"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        directoryURL = docs.appendingPathComponent("AppIcons", isDirectory: true)
        // Ensure the directory exists
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    /// Saves a UIImage as a PNG file named by the app's unique identifier.
    /// - Parameters:
    ///   - image: The icon image to store.
    ///   - appId: An integer identifier for the app (e.g., `id` from `ChildRequestedApp`).
    public func saveIcon(_ image: UIImage, for appId: Int) {
        let fileURL = directoryURL.appendingPathComponent("\(appId).png")
        guard let pngData = image.pngData() else { return }
        try? pngData.write(to: fileURL, options: .atomic)
    }

    /// Retrieves the local URL for a stored icon, if it exists.
    /// - Parameter appId: The unique identifier used when saving the icon.
    /// - Returns: File URL to the PNG image, or nil if not found.
    public func iconURL(for appId: Int) -> URL? {
        let fileURL = directoryURL.appendingPathComponent("\(appId).png")
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
}
