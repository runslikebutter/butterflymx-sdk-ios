//
//  BackendEnvironment.swift
//  ButterflyMXSDK
//
//  Created by Sviatoslav Belmeha on 1/16/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation

public enum BMXBackendEnvironment {
    case production
    case development
    case sandbox

    var baseURL: String {
        let region = BMXCoreKit.shared.environment.getRegion()
        switch (self, region) {
        case (.development, .na): return "https://api.na.staging.butterflymx.com"
        case (.development, .eu): return "https://api.eu.staging.butterflymx.com"
        case (.production, .na):  return "https://api.butterflymx.com"
        case (.production, .eu):  return "https://eu.api.butterflymx.com"
        case (.sandbox, _): return "https://api.na.sandbox.butterflymx.com"
        }
    }

    var accountURL: String {
        switch self {
        case .development: return "https://accounts.na.staging.butterflymx.com"
        case .sandbox: return "https://accounts.na.sandbox.butterflymx.com"
        case .production: return "https://accounts.butterflymx.com"
        }
    }

    var oauthAuthorize: String {
        switch self {
        case .development: return "https://accounts.na.staging.butterflymx.com/oauth/authorize"
        case .sandbox: return "https://accounts.na.sandbox.butterflymx.com/oauth/authorize"
        case .production: return "https://accounts.butterflymx.com/oauth/authorize"
        }
    }

    var oauthToken: String {
        switch self {
        case .development: return "https://accounts.na.staging.butterflymx.com/oauth/token"
        case .sandbox: return "https://accounts.na.sandbox.butterflymx.com/oauth/token"
        case .production: return "https://accounts.butterflymx.com/oauth/token"
        }
    }

}
