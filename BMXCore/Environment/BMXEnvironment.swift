//
//  Environment.swift
//  ButterflyMXSDK
//
//  Created by Sviatoslav Belmeha on 1/16/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation

public let environmentUpdateNotificationName = Notification.Name("com.butterflymx.ButterflyMXSDK.environmentUpdateNotification")

public protocol BMXEnvironmentProtocol {
    var backendEnvironment: BMXBackendEnvironment { get set }
    func getRegion() -> RegionType
    func save(region: RegionType)
}

public final class BMXEnvironment: BMXEnvironmentProtocol {

    private static let regionTypeKey = "regionType"
    public func getRegion() -> RegionType {
        guard let raw = UserDefaults.standard.string(forKey: BMXEnvironment.regionTypeKey), let region = RegionType(rawValue: raw) else {
            return .na
        }
        return region
    }

    public func save(region: RegionType) {
        UserDefaults.standard.set(region.rawValue, forKey: BMXEnvironment.regionTypeKey)
    }

    public var backendEnvironment: BMXBackendEnvironment {
        didSet {
            notifyAboutUpdate()
        }
    }

    public init(backendEnvironment: BMXBackendEnvironment) {
        self.backendEnvironment = backendEnvironment
    }

    private func notifyAboutUpdate() {
        NotificationCenter.default.post(name: environmentUpdateNotificationName, object: nil, userInfo: nil)
    }

}
