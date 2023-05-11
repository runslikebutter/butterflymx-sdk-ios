//
//  UserManager.swift
//  ButterflyMXSDK
//
//  Created by Sviatoslav Belmeha on 1/16/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation
import Japx

public class BMXUser {

    public static let shared = BMXUser()

    public func getUser() -> UserModel? {
        if let user = user {
            return user
        }

        if let userData = try? diskCaching.getData(withName: BMXUser.userKey), let user = try? JapxDecoder().decode(UserModel.self, from: userData) {
            self.user = user
            return user
        }

        return nil
    }

    public func getTenants() -> [TenantModel] {
        return user?.tenants ?? []
    }

    public func getPanels(from tenant: TenantModel) -> [PanelModel] {
        return tenant.panels ?? []
    }
    
    public func getDevices(from tenant: TenantModel) -> [DeviceModel] {
        return tenant.devices ?? []
    }

    func logoutUser() {
        try? diskCaching.deleteObject(withName: BMXUser.userKey)
        keychain.set(value: nil, key: BMXUser.userPasswordKey)
    }

    func cache(user: UserModel) throws {
        self.user = user
        let data = try JapxEncoder().jsonEncoder.encode(user)
        try diskCaching.save(data: data, withName: BMXUser.userKey)
    }

    private var user: UserModel?
    private let diskCaching = DiskCaching()
    private let keychain = Keychain()
    private static let userPasswordKey = "user_password"
    static let userKey = "user"
}
