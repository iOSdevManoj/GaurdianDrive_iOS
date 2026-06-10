//
//  ReportExtension.swift
//  ReportExtension
//
//  Created by Krunal on 29/01/26.
//

import DeviceActivity
import SwiftUI

@main
struct ReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { appInfos in
             TotalActivityView(appInfos: appInfos)
        }
        // Add more reports here...
    }
}
