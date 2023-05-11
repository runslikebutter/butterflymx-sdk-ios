//
//  UserModel.swift
//  ButterflyMXSDK
//
//  Created by Zhe Cui on 10/10/18.
//  Copyright © 2018 ButterflyMX. All rights reserved.
//

import Japx

public struct UserModel: JapxCodable {
    public let type: String
    public let id: String

    public let name: String?
    public let email: String?
    public let phoneNumber: String?
    public let xmppUsername: String?
    public let contactPreference: String?
    private let avatar: [String: String?]?
    public var avatars: [String: String?]? { return avatar }
    public let tenants: [TenantModel]?
}

struct Usernames: Decodable {
    struct SipUsername: Decodable {
        let sip: Int
    }
    let usernames: SipUsername
}
