//
//  Auth.swift
//  ButterflyMXSDK
//
//  Created by Sviatoslav Belmeha on 1/16/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation

public final class BMXAuthProvider {

    public var accessToken: String? {
        return storage.get(key: Key.accessToken.rawValue)
    }

    public var refreshToken: String? {
        return storage.get(key: Key.refreshToken.rawValue)
    }

    public var secret: String? {
        return storage.get(key: Key.secret.rawValue)
    }

    public var clientID: String? {
        return storage.get(key: Key.clientID.rawValue)
    }

    func setSession(secret: String?, clientID: String?) {
        storage.set(value: secret, key: Key.secret.rawValue)
        storage.set(value: clientID, key: Key.clientID.rawValue)
    }

    func setUserTokens(accessToken: String?, refreshToken: String?) {
        storage.set(value: accessToken, key: Key.accessToken.rawValue)
        storage.set(value: refreshToken, key: Key.refreshToken.rawValue)
    }

    func invalidateSession() {
        setSession(secret: nil, clientID: nil)
    }

    func invalidateTokens() {
        setUserTokens(accessToken: nil, refreshToken: nil)
    }

    public init(secret: String, clientID: String) {
        self.storage = TempStorage()
        setSession(secret: secret, clientID: clientID)
    }

    public init(secret: String, clientID: String, accessToken: String, refreshToken: String) {
        self.storage = TempStorage()
        setSession(secret: secret, clientID: clientID)
        setUserTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    init(storage: KeyValueStorage) {
        self.storage = storage
    }

    private enum Key: String {
        case accessToken, refreshToken, clientID, secret
    }

    private let storage: KeyValueStorage

}
