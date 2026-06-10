//
//  FeatureFlag.swift
//  GaurdianDrive
//
//  Created by Antigravity on 02/02/26.
//

import Foundation

struct FeatureFlag {
    /// Controls the visibility of manual "Block Selected" and "Unblock All" buttons
    static let showManualBlockButtons = false
    
    ///True: child can remove app, False: child cant remove app
    static let isChildUserCanRemoveApp = true
    
    /// 🚩 FEATURE FLAG: Set to `false` to disable Sockets entirely and fall back to 100% API polling.
    static let isSocketFeatureEnabled = false
}
