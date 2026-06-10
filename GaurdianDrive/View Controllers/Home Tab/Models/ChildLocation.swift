//
//  ChildLocation.swift
//  GaurdianDrive
//
//  Created by KETAN on 25/03/26.
//

import UIKit

struct ChildLocation: Codable {
    let childId: String
    let latitude: Double
    let longitude: Double
    let speed: Double
    let version: Int
    /// Drive mode label sent by the child — "Drive mode active", "No-Drive mode active", or nil.
    let driveMode: String?

    enum CodingKeys: String, CodingKey {
        case childId, latitude, longitude, speed, version, driveMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle both Int and String safely
        if let intValue = try? container.decode(Int.self, forKey: .childId) {
            childId = "\(intValue)"
        } else if let stringValue = try? container.decode(String.self, forKey: .childId) {
            childId = stringValue
        } else {
            childId = ""
        }

        latitude  = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        speed     = try container.decode(Double.self, forKey: .speed)
        version   = try container.decode(Int.self,    forKey: .version)
        driveMode = try? container.decode(String.self, forKey: .driveMode)
    }
}

