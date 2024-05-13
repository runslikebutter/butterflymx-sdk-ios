//
//  OAuth2Handler.swift
//  ButterflyMXSDK
//
//  Created by Zhe Cui on 10/10/18.
//  Copyright © 2018 ButterflyMX. All rights reserved.
//

import Foundation
import Alamofire

class AuthSessionManager {
    static let shared = AuthSessionManager()

    let sessionManager: Session = {
        let configuration = URLSessionConfiguration.default
        return Session(configuration: configuration, interceptor: OAuth2Handler())
    }()
}

class OAuth2Handler: RequestInterceptor {
    private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?, _ refreshToken: String?) -> Void

    private let lock = NSLock()
    
    private var isRefreshing = false
    private static var requestsToRetry: [(RetryResult) -> Void] = []

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        guard let accessToken = BMXCoreKit.shared.authProvider.accessToken else {
            completion(.failure(ServiceError.unableToCreateRequest(message: "accessToken is nil")))
            return
        }

        urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        lock.lock() ; defer { lock.unlock() }
        
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            OAuth2Handler.requestsToRetry.append(completion)
            
            if !isRefreshing {
                refreshTokens { [weak self] succeeded in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                    
                    OAuth2Handler.requestsToRetry.forEach {
                        $0(.retry)
                    }
                    OAuth2Handler.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(.doNotRetry)
        }
    }
    
    // MARK: - Private - Refresh Tokens
    
    private func refreshTokens(completion: @escaping (Bool) -> Void) {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        APIClient.refreshTokens { [weak self] result in
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
            
            self?.isRefreshing = false
        }
    }
    
}
