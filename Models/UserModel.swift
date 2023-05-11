//
//  UserModel.swift
//  ButterflyMXSDK
//
//  Created by Zhe Cui on 10/10/18.
//  Copyright © 2018 ButterflyMX. All rights reserved.
//

extension User: Codable {

    private enum CodingKeys: String, CodingKey { case name, email, phone_number, sip_username, xmpp_username,
        contact_preference, avatar
    }

    public convenience init(from decoder: Decoder) throws {
        self.init()

        let container     = try decoder.container(keyedBy: CodingKeys.self)
        name              = try container.decodeIfPresent(String.self, forKey: .name)
        email             = try container.decodeIfPresent(String.self, forKey: .email)
        phoneNumber       = try container.decodeIfPresent(String.self, forKey: .phone_number)
        sipUsername       = try container.decodeIfPresent(String.self, forKey: .sip_username)
        xmppUsername      = try container.decodeIfPresent(String.self, forKey: .xmpp_username)
        contactPreference = try container.decodeIfPresent(String.self, forKey: .contact_preference)
        avatar            = try container.decodeIfPresent([String: String?].self, forKey: .avatar)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(phoneNumber, forKey: .phone_number)
        try container.encode(sipUsername, forKey: .sip_username)
        try container.encode(xmppUsername, forKey: .xmpp_username)
        try container.encode(contactPreference, forKey: .contact_preference)
        try container.encode(avatar, forKey: .avatar)
    }

}

public final class User {

    public private(set) var name: String?
    public private(set) var email: String?
    public private(set) var phoneNumber: String?
    public private(set) var sipUsername: String?
    public private(set) var xmppUsername: String?
    public private(set) var contactPreference: String?
    public private(set) var avatar: [String: String?]?
    public internal(set) var password: String?
    
    init() {}

}
