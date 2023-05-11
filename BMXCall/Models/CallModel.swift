//
//  CallModel.swift
//  ButterflyMXSDK
//
//  Created by Zhe Cui on 10/10/18.
//  Copyright © 2018 ButterflyMX. All rights reserved.
//

public class Call: Codable {
    public enum CallProvider: String, Codable {
        case `internal`, //sip
             twilio
    }
    
    public internal(set) var id: String?
    public internal(set) var type: String?
    public internal(set) var attributes: CallAttributes?
    public var callProvider: CallProvider? {
        if let provider = attributes?.provider {
            return CallProvider(rawValue: provider)
        }
        
        return nil        
    }
    public var status: String?
        
    @available(*, deprecated, message: "This property is deprecated, please use attributes instead.")
    public var callDetails: CallAttributes? {
        return attributes
    }
    
    public enum Status: String, Decodable {
        case initializing, connecting_sip, canceled, voip_rollover, rejected, timeout_online_signal, opened_door
    }

    public var statusEnum: Status? {
        guard let attributes = attributes else {
            return nil
        }
        return attributes.status.isEmpty == false ? Status(rawValue: attributes.status) : nil
    }
        
    public var panelId: Int? {
        return attributes?.panelId
    }
    
    public var panelName: String? {
        return attributes?.panelName
    }
    
    public var guid: String? {
        return attributes?.guid
    }
    
    var providerToken: String? {
        return attributes?.providerToken
    }

}

public class CallAttributes: Codable {
    public internal(set) var guid: String = ""
    public internal(set) var callType: String = ""
    public internal(set) var notificationType: String = ""
    public internal(set) var thumbUrl: String?
    public internal(set) var mediumUrl: String?
    public internal(set) var createdAt: String = ""
    public internal(set) var loggedAt: String = ""
    public internal(set) var status: String = ""
    public internal(set) var displayStatus: String = ""
    public internal(set) var panelName: String = ""
    public internal(set) var panelId: Int = 0
    public internal(set) var provider: String?
    var providerToken: String?
    
    public func getTitle() -> String {
        if notificationType == "visitor" {
            return "Visitor"
        } else {
            return "Delivery"
        }
    }

    public func getType() -> String {
        if callType == "mobile" {
            return "Mobile application call"
        } else {
            return "Phone call"
        }
    }

}
