//
//  JapxCodableAlamofire.swift
//  BMXCore
//
//  Vendored from Japx (https://github.com/infinum/Japx), file
//  Japx/Classes/Alamofire/JapxCodableAlamofire.swift, plus `JapxAlamofireError`
//  from Japx/Classes/Alamofire/JapxAlamofire.swift.
//  Copyright (c) Infinum. Licensed under the Apache License, Version 2.0
//  (http://www.apache.org/licenses/LICENSE-2.0). The full license text is in
//  THIRD_PARTY_NOTICES.md at the repository root.
//
//  Changes from the original:
//  - Declarations are internal instead of public.
//  - `import Japx` is unconditional, since this file lives outside the Japx module.
//
//  Why vendored: Japx 4.0.1 (latest release) ships a JapxAlamofire module that
//  doesn't compile with Alamofire 5.10+ ('Parameters' is ambiguous). The fix is
//  on Japx master but unreleased, so BMXCore depends on the Japx core module only
//  and keeps the one helper it uses here.
//
//  TODO(MT-3128): Once Japx tags a release with the fix, delete this file and
//  depend on the JapxAlamofire product again. That also means restoring the
//  `#if COCOAPODS` import in APIClient.swift, going back to `Japx/Alamofire` in
//  the podspec, and raising the Japx minimum to the fixed release. See MT-3128
//  for the full checklist.
//

import Foundation
import Alamofire
import Japx

extension DataRequest {

    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:             The queue on which the completion handler is dispatched. Defaults to `.main` .
    /// - parameter includeList:       The include list for deserializing JSON:API relationships.
    /// - parameter keyPath:           The keyPath where object decoding on parsed JSON should be performed.
    /// - parameter decoder:           The decoder that performs the decoding on parsed JSON into requested type.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - returns: The request.
    @discardableResult
    func responseCodableJSONAPI<T: Decodable>(
        queue: DispatchQueue = .main,
        includeList: String? = nil,
        keyPath: String? = nil,
        decoder: JapxDecoder = JapxDecoder(),
        completionHandler: @escaping (AFDataResponse<T>) -> Void
    ) -> Self {
        return response(
            queue: queue,
            responseSerializer: DecodableJSONAPIResponseSerializer(includeList: includeList, keyPath: keyPath, decoder: decoder),
            completionHandler: completionHandler
        )
    }
}

extension DownloadRequest {

    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:             The queue on which the completion handler is dispatched. Defaults to `.main` .
    /// - parameter includeList:       The include list for deserializing JSON:API relationships.
    /// - parameter keyPath:           The keyPath where object decoding on parsed JSON should be performed.
    /// - parameter decoder:           The decoder that performs the decoding on parsed JSON into requested type.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - returns: The request.
    @discardableResult
    func responseCodableJSONAPI<T: Decodable>(
        queue: DispatchQueue = .main,
        includeList: String? = nil,
        keyPath: String? = nil,
        decoder: JapxDecoder = JapxDecoder(),
        completionHandler: @escaping (AFDownloadResponse<T>) -> Void
    ) -> Self {
        return response(
            queue: queue,
            responseSerializer: DecodableJSONAPIResponseSerializer(includeList: includeList, keyPath: keyPath, decoder: decoder),
            completionHandler: completionHandler
        )
    }
}

final class DecodableJSONAPIResponseSerializer<T: Decodable>: ResponseSerializer {

    let includeList: String?
    let keyPath: String?
    let decoder: JapxDecoder

    /// Creates an instance using the values provided.
    ///
    /// - Parameters:
    ///   - includeList:    The include list for deserializing JSON:API relationships.
    ///   - keyPath:        The keyPath where object decoding on parsed JSON should be performed.
    ///   - decoder:        The `DataDecoder`. `JapxDecoder()` by default.
    init(
        includeList: String?,
        keyPath: String?,
        decoder: JapxDecoder
    ) {
        self.includeList = includeList
        self.keyPath = keyPath
        self.decoder = decoder
    }

    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        guard error == nil else { throw error! }

        guard let validData = data, validData.count > 0 else {
            throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        }

        do {
            guard let keyPath = keyPath, !keyPath.isEmpty else  {
                return try decoder.decode(T.self, from: validData, includeList: includeList)
            }

            let json = try JapxKit.Decoder.jsonObject(with: validData, includeList: includeList, options: decoder.options)
            guard let jsonForKeyPath = (json as AnyObject).value(forKeyPath: keyPath) else {
                throw JapxAlamofireError.invalidKeyPath(keyPath: keyPath)
            }
            let data = try JSONSerialization.data(withJSONObject: jsonForKeyPath, options: .init(rawValue: 0))

            return try decoder.jsonDecoder.decode(T.self, from: data)
        } catch {
            throw AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error))
        }
    }
}

enum JapxAlamofireError: Error {

    /// - invalidKeyPath: Returned when a nested JSON object doesn't exist in parsed JSON:API response by provided `keyPath`.
    case invalidKeyPath(keyPath: String)
}

extension JapxAlamofireError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case let .invalidKeyPath(keyPath: keyPath): return "Nested JSON doesn't exist by keyPath: \(keyPath)."
        }
    }
}
