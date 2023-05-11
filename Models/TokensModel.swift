//
//  TokensModel.swift
//  ButterflyMXSDK
//
//  Created by Sviatoslav Belmeha on 1/22/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation

struct Tokens: Decodable {
    let access_token: String
    let refresh_token: String
}
