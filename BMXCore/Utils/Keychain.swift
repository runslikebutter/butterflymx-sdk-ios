//
//  Keychaiт.swift
//  ButterflyMXSDK
//
//  Created by Sviatoslav Belmeha on 1/18/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation

protocol KeyValueStorage {
    func get(key: String) -> String?
    func set(value: String?, key: String)
}

class TempStorage: KeyValueStorage {
    private var dic: [String: String] = [:]

    func get(key: String) -> String? {
        return dic[key]
    }

    func set(value: String?, key: String) {
        dic[key] = value
    }
}

class UDStorage: KeyValueStorage {
    func get(key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }

    func set(value: String?, key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }
}

class Keychain: KeyValueStorage {

    func get(key: String) -> String? {
        let query = createKeychainQuery(forKey: key)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnData as String)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnAttributes as String)

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query, &result)

        guard let dict = result as? NSDictionary,
            let data = dict.value(forKey: kSecValueData as String) as? Data,
            status == noErr
            else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func set(value: String?, key: String) {
        let query = createKeychainQuery(forKey: key)
        let data = value?.data(using: .utf8, allowLossyConversion: false)

        let status = SecItemCopyMatching(query, nil)

        if status == noErr {
            if let data = data {
                _ = SecItemUpdate(query, NSDictionary(dictionary: [kSecValueData: data]))
            } else {
                _ = SecItemDelete(query)
            }
        } else {
            if let data = data {
                query.setValue(data, forKey: kSecValueData as String)
                _ = SecItemAdd(query, nil)
            }
        }
    }

    private func createKeychainQuery(forKey key: String) -> NSMutableDictionary {
        let result = NSMutableDictionary()
        result.setValue(kSecClassGenericPassword, forKey: kSecClass as String)
        result.setValue(service, forKey: kSecAttrService as String)
        result.setValue(key, forKey: kSecAttrAccount as String)
        result.setValue(kSecAttrAccessibleAfterFirstUnlock, forKey: kSecAttrAccessible as String)
        return result
    }

    private let service = "ButterflyMX"

}
