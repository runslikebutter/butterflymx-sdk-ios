//
//  DiskCaching.swift
//  ButterflyMXSDK
//
//  Created by Sviatoslav Belmeha on 1/21/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation

class DiskCaching {

    enum Errors: Error {
        case noDocumentDirectory
        case noDataToDeserialize
    }

    func save(data: Data, withName name: String) throws {
        guard let url = getDocumentsURL()?.appendingPathComponent("\(name).\(fileFormat)") else {
            throw Errors.noDocumentDirectory
        }

        try data.write(to: url, options: [])
    }

    func getData(withName name: String) throws -> Data {
        guard let url = getDocumentsURL()?.appendingPathComponent("\(name).\(fileFormat)") else {
            throw Errors.noDocumentDirectory
        }

        return try Data(contentsOf: url)
    }

    func deleteObject(withName name: String) throws {
        guard let url = getDocumentsURL()?.appendingPathComponent("\(name).\(fileFormat)") else {
            throw Errors.noDocumentDirectory
        }

        try FileManager.default.removeItem(at: url)
    }

    // MARK: - Private

    private func getDocumentsURL() -> URL? {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return url
        }

        return nil
    }

    private let fileFormat = "json"

}
