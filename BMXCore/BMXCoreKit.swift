//
//  BMXCore.swift
//  ButterflyMXSDK
//
//  Created by Zhe Cui on 10/10/18.
//  Copyright © 2018 ButterflyMX. All rights reserved.
//

import Foundation
import OAuthSwift
import os.log
import SafariServices

public protocol BMXCoreDelegate: AnyObject {
    func logging(_ data: String)
    func didCancelAuthorization()
}

public extension BMXCoreDelegate {
    func didCancelAuthorization() {}
}

public enum ServiceError: Error {
    // MARK: Internal
    case unableToCreateRequest(message: String)
    case unableToProcessResponse(message: String)
    case runtime(error: Error)
}

extension OSLog {
    static var subsystem = Bundle.main.bundleIdentifier!
}

public class BMXCoreKit {

    private var logger = OSLog(subsystem: OSLog.subsystem, category: "BMXSDK")

    public static let shared = BMXCoreKit()

    /// Service's backend environment. Default value is `.development`. Make sure to use `.production` in you release (App Store)
    public private(set) var environment: BMXEnvironmentProtocol = BMXEnvironment(backendEnvironment: .development)

    public weak var delegate: BMXCoreDelegate?
    public weak var authorizationWebViewDelegate: SFSafariViewControllerDelegate?

    /// All data in `authProvider` is saved in encrypted Keychain
    public let authProvider = BMXAuthProvider(storage: Keychain())

    public var isUserLoggedIn: Bool {
        return BMXUser.shared.getUser() != nil
            && authProvider.accessToken != nil
            && authProvider.refreshToken != nil
    }

    private init() {}
    
    public func log(format: StaticString = "%@", message: String, type: OSLogType = .info) {
        os_log(format, log: logger, type: type, message)
        delegate?.logging(message)
    }

    public func configure(withEnvironment environment: BMXEnvironmentProtocol, logger: OSLog? = nil) {
        self.environment = environment
        if let logger = logger {
            self.logger = logger
        }
    }

    public func handle(url: URL) {
        OAuthSwift.handle(url: url)
    }

    /// Presents an authorization form to authenticate a user using either pre-existing tokens.
    /// Use this method if you have you onw OAuth flow implemented
    /// - Parameters:
    ///   - authProvider: Auth provider with secret and client ID and user tokens
    ///   - completion: A completion handler that returns a Result containing either a UserModel on success or a ServiceError on failure.
    public func authorize(withAuthProvider authProvider: BMXAuthProvider, completion: @escaping (Result<UserModel, ServiceError>) -> Void) {
        authorize(withAuthProvider: authProvider, callbackURL: nil, viewController: nil, completion: completion)
    }

    /// Presents an authorization form to authenticate a user using either pre-existing tokens or the OAuth2 protocol.
    /// Use this method if you do not have you onw OAuth flow implemented
    /// - Parameters:
    ///   - authProvider: Auth provider with secret and client ID
    ///   - callbackURL: URL to handle OAuth2 callback. This is required for SDK's built in OAuth2 authentication
    ///   - viewController: View controller to present the authorization form.  This is required for SDK's built in OAuth2 authentication
    ///   - promptLogin: Boolean flag indicating whether the user should be prompted to log in. Default value is true.
    ///   - completion: A completion handler that returns a Result containing either a UserModel on success or a ServiceError on failure.
    public func authorize(withAuthProvider authProvider: BMXAuthProvider, callbackURL: URL?, viewController: UIViewController?, promptLogin: Bool = true, completion: @escaping (Result<UserModel, ServiceError>) -> Void) {
        let promise: Future<TokensModel>
        self.authProvider.setSession(secret: authProvider.secret, clientID: authProvider.clientID)
        BMXCoreKit.shared.log(message: "Client and Secret IDs are saved to keycain")

        if let accessToken = authProvider.accessToken, let refreshToken = authProvider.refreshToken {
            BMXCoreKit.shared.log(message: "Authorize user using provided tokens")
            promise = Promise<TokensModel>().resolve(with: TokensModel(access_token: accessToken, refresh_token: refreshToken))
        } else if let callbackURL = callbackURL, let viewController = viewController {
            BMXCoreKit.shared.log(message: "Authorize user using OAuth2")
            promise = authorize(with: callbackURL, viewController: viewController, promptLogin: promptLogin)
        } else {
            completion(.failure(ServiceError.unableToCreateRequest(message: "accessToken or refreshToken or callbackURL is missing")))
            return
        }

        processLogin(with: promise).observe { result in
            switch result {
            case .success(let model):
                completion(.success(model))
            case .failure(let error):
                completion(.failure(.runtime(error: error)))
            }
        }
    }

    /// For internal use only
    private func authorize(withEmail email: String, password: String, completion: @escaping (Result<UserModel, ServiceError>) -> Void) {
        BMXCoreKit.shared.log(message: "Authorize user using email/password")

        processLogin(with: APIClient.getToken(userName: email, password: password)).observe { result in
            switch result {
            case .success(let model):
                completion(.success(model))
            case .failure(let error):
                completion(.failure(.runtime(error: error)))
            }
        }
    }

    public func logoutUser() {
        BMXCoreKit.shared.log(message: "Logout user")
        
        authProvider.invalidateTokens()
        BMXCoreKit.shared.log(message: "Tokens are removed from keychain")
        BMXUser.shared.logoutUser()
        BMXCoreKit.shared.log(message: "User is removed from cache")
    }
    
    public func registerWebhook(withTenantId tenantId: String,
                                urlString: String,
                                completion: @escaping (Result<String, ServiceError>) -> Void) {
        
        APIClient.getWebhooks(byTenantId: tenantId)
            .chained { integrations -> Future<TenantIntegrationModel> in
                for integration in integrations.data {
                    if integration.attributes.config.url == urlString {
                        let promise = Promise<TenantIntegrationModel>()
                        promise.resolve(with: integration)
                        return promise
                    }
                }                
                return APIClient.registerWebhook(withTenantId: tenantId, urlString: urlString)
            }.observe { result in
                switch result {
                case .success(let integration):
                    completion(.success(integration.id))
                case .failure(let error):
                    if let error = error as? ServiceError {
                        completion(.failure(error))
                    } else {
                        completion(.failure(.runtime(error: error)))
                    }
                }
            }
    }
    
    public func unregisterWebhook(withTenantId tenantId: String,
                                  webhookId: String,
                                  completion: @escaping (Result<Bool, ServiceError>) -> Void) {
        APIClient.unregisterWebhook(withTenantId: tenantId, webhookId: webhookId) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                completion(.failure(.runtime(error: error)))
            }
        }
    }
    
    public func reloadUserData(completion: @escaping (Result<UserModel, Error>) -> Void) {
        getUser().observe { result in
            completion(result)
        }
    }
    
    public func refreshAccessToken(completion: @escaping (Result<BMXAuthProvider, Error>) -> Void) {
        APIClient.refreshTokens { result in
            completion(result)
        }
    }

    // MARK: - Private
    
    private var oauth: OAuth2Swift?

    private func authorize(with callbackURL: URL, viewController: UIViewController, promptLogin: Bool) -> Future<TokensModel> {
        let promise = Promise<TokensModel>()
        guard let consumerKey = authProvider.clientID, let consumerSecret = authProvider.secret else {
            promise.reject(with: ServiceError.unableToCreateRequest(message: "clientID or secret is missing"))
            return promise
        }

        oauth = OAuth2Swift(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            authorizeUrl: environment.backendEnvironment.oauthAuthorize,
            accessTokenUrl: environment.backendEnvironment.oauthToken,
            responseType: "code"
        )

        oauth?.allowMissingStateCheck = true
        
        let parameters: [String: String] = promptLogin ? ["prompt": "login"] : [:]
        let authorizeURLHandler = SafariURLHandler(viewController: viewController, oauthSwift: oauth!)
        authorizeURLHandler.delegate = authorizationWebViewDelegate
        oauth?.authorizeURLHandler = authorizeURLHandler
        
        oauth?.authorize(withCallbackURL: callbackURL, scope: "openid+profile", state:"", parameters: parameters) { result in
            switch result {
            case .success(let (credential, _, _)):
                promise.resolve(with: TokensModel(access_token: credential.oauthToken, refresh_token: credential.oauthRefreshToken))
            case .failure(let error):
                promise.reject(with: error)
            }
        }

        return promise
    }

    private func processLogin(with authFuture: Future<TokensModel>) -> Future<UserModel> {
        let promise = Promise<UserModel>()

        authFuture
        /// get user region
        .chained { creds -> Future<RegionType> in
            BMXCoreKit.shared.log(format: "Set access token %{private}@ to keychain ", message: creds.access_token, type: .info)
            BMXCoreKit.shared.log(format: "Set refresh token %{private}@ to keychain ", message: creds.refresh_token, type: .info)
            self.authProvider.setUserTokens(accessToken: creds.access_token, refreshToken: creds.refresh_token)
            return APIClient.getUserRegion()
        }
        /// get user info
        .chained { region -> Future<UserModel> in
            BMXCoreKit.shared.environment.save(region: region)
            BMXCoreKit.shared.log(message: "Set user region")
            return self.getUser()
        }
        /// handle final result
        .observe { result in
            switch result {
            case .success(let user):
                promise.resolve(with: user)
            case .failure(let error):
                promise.reject(with: error)
                BMXCoreKit.shared.log(message: "Auth error: \(error)")
            }
        }

        return promise
    }

    private func getUser() -> Future<UserModel> {
        let promise = Promise<UserModel>()

        APIClient.getMe().observe { result in
            switch result {
            case .success(let user):
                do {
                    try BMXUser.shared.cache(user: user)

                    BMXCoreKit.shared.log(message: "User successfully logged in")
                    promise.resolve(with: user)
                } catch {
                    BMXCoreKit.shared.log(message: "Get user data error: \(error)")
                    promise.reject(with: error)
                }
            case .failure(let error):
                BMXCoreKit.shared.log(message: "Get me error: \(error)")
                promise.reject(with: error)
            }
        }

        return promise
    }
}
