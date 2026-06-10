import DeviceActivity
import ManagedSettings
import SwiftUI
import os

extension DeviceActivityReport.Context {
    // We create a custom context for our App Name Report
    static let appNameReport = Self("AppNameReport")
}

private let logger = Logger(subsystem: "ReportExtension", category: "DataExtraction")

struct TotalActivityReport: DeviceActivityReportScene {
    // Define which context this report supports
    let context: DeviceActivityReport.Context = .appNameReport

    // Define the custom configuration that valid for this report
    let content: ([SharedAppInfo]) -> TotalActivityView

    // Convert the raw data into the configuration
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async
        -> [SharedAppInfo]
    {
        logger.info("makeConfiguration called")
        var sharedInfos: [SharedAppInfo] = []
        var seenTokens = Set<String>()

        for await result in data {
            for await segment in result.activitySegments {
                for await category in segment.categories {
                    for await application in category.applications {
                        guard let name = application.application.localizedDisplayName else { continue }
                        do {
                            let tokenData = try JSONEncoder().encode(application.application.token)
                            let tokenStr = tokenData.base64EncodedString()
                            if !seenTokens.contains(tokenStr) {
                                logger.info("App found: \(name, privacy: .public)")
                                sharedInfos.append(SharedAppInfo(name: name, token: tokenStr))
                                seenTokens.insert(tokenStr)
                            }
                        } catch {
                            logger.error("Failed to encode token for \(name): \(error.localizedDescription)")
                        }
                    }
                }
            }
        }

        return sharedInfos.filter {
            let n = $0.name.lowercased()
            return !n.contains("gaurdian") && !n.contains("guardiandrive")
        }
    }
}

public struct SharedAppInfo: Codable, Hashable, Identifiable {
    public var id: String { name }
    let name: String
    let token: String
}
