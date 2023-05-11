//
//  CallModel.swift
//  ButterflyMXSDK
//
//  Created by Zhe Cui on 10/10/18.
//  Copyright © 2018 ButterflyMX. All rights reserved.
//

extension Call: Decodable {

    private enum CodingKeys: String, CodingKey { case status, guid, call_type, panel_xmpp, panel_sip,
        panel_user_type, notification_type, panel_name, thumb_url, medium_url, logged_at
    }

    public convenience init(from decoder: Decoder) throws {
        self.init()

        let container    = try decoder.container(keyedBy: CodingKeys.self)
        status           = try container.decodeIfPresent(Status.self, forKey: .status)
        guid             = try container.decodeIfPresent(String.self, forKey: .guid)
        callType         = try container.decodeIfPresent(String.self, forKey: .call_type)
        panelXmpp        = try container.decodeIfPresent(String.self, forKey: .panel_xmpp)
        panelSip         = try container.decodeIfPresent(String.self, forKey: .panel_sip)
        panelUserType    = try container.decodeIfPresent(String.self, forKey: .panel_user_type)
        notificationType = try container.decodeIfPresent(String.self, forKey: .notification_type)
        panelName        = try container.decodeIfPresent(String.self, forKey: .panel_name)
        thumbUrl         = try container.decodeIfPresent(String.self, forKey: .thumb_url)
        mediumUrl        = try container.decodeIfPresent(String.self, forKey: .medium_url)
        loggedAt         = try container.decodeIfPresent(String.self, forKey: .logged_at)
    }

}

public final class Call {

    public enum Status: String, Decodable {
        case initializing, connecting_sip, canceled, voip_rollover, rejected, timeout_online_signal
    }
    
    public internal(set) var status: Status?
    public internal(set) var guid: String?
    public internal(set) var callType: String?
    public internal(set) var panelXmpp: String?
    public internal(set) var panelSip: String?
    public internal(set) var panelUserType: String?
    public internal(set) var notificationType: String?
    public internal(set) var panelName: String?
    public internal(set) var thumbUrl: String?
    public internal(set) var mediumUrl: String?
    public internal(set) var loggedAt: String?
    public internal(set) var state: BMXCall.CallState = .idle
    public internal(set) var event: BMXCall.CallOrUserEvent? = nil
    public internal(set) var callID: Int = 0
    public internal(set) var accepted: Bool = false
    
    init() {}

    public func getTitle() -> String {
        if self.notificationType == "visitor" {
            return "Visitor"
        } else {
            return "Delivery"
        }
    }
    
    public func getType() -> String {
        if self.callType == "mobile" {
            return "Mobile application call"
        } else {
            return "Phone call"
        }
    }

}
