//
//  APIClient.swift
//  ButterflyMXSDK
//
//  Created by Zhe Cui on 10/10/18.
//  Copyright © 2018 ButterflyMX. All rights reserved.
//

import Foundation
import Alamofire
#if COCOAPODS
import Japx
#else
import Japx
import JapxAlamofire
#endif


public class APIClient {
    static let sessionManager = Session()

    private static var decoder: JapxDecoder = {
        let decoder = JapxDecoder()
        decoder.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    class func getToken(userName: String, password: String) -> Future<TokensModel> {
        let promise = Promise<TokensModel>()

        let urlString = BMXCoreKit.shared.environment.backendEnvironment.accountURL + "/oauth/token"
        guard let clientID = BMXCoreKit.shared.authProvider.clientID, let secret = BMXCoreKit.shared.authProvider.secret else {
            promise.reject(with: ServiceError.unableToCreateRequest(message: "clientID or secret is empty"))
            return promise
        }
        let params = ["grant_type": "password",
                      "username": userName,
                      "password": password,
                      "client_id": clientID,
                      "client_secret": secret]

        APIClient.sessionManager.request(urlString, method: .post, parameters: params)
            .validate()
            .responseDecodable(of: TokensModel.self) { response in
                switch response.result {
                case .success(let tokens):
                    promise.resolve(with: tokens)
                case .failure(let error):
                    promise.reject(with: error)
                }
            }

        return promise
    }

    class func getMe() -> Future<UserModel> {
        let promise = Promise<UserModel>()
        let urlString = BMXCoreKit.shared.environment.backendEnvironment.baseURL + "/v3" + "/me?include=tenants,tenants.building,tenants.panels,tenants.devices,tenants.unit"
        
        APIClient.sessionManager.request(urlString, method: .get, interceptor: OAuth2Handler())
            .validate()
            .responseCodableJSONAPI(keyPath: "data", decoder: decoder) { (response: DataResponse<UserModel, AFError>) in
                switch response.result {
                case .success(let model):
                    promise.resolve(with: model)
                case .failure(let error):
                    promise.reject(with: error)
                }
        }

        return promise
    }
    
    //, completion: @escaping (Result<CallStatus, ServiceError>) -> Void)
    public class func getCallStatus(guid: String, completion: @escaping (Result<Data, AFError>) -> Void) {
        let urlString = "\(BMXCoreKit.shared.environment.backendEnvironment.baseURL)/v3/me/calls/\(guid)/status"

        APIClient.sessionManager.request(urlString, method: .get, interceptor: OAuth2Handler())
            .validate()
            .responseData { response in
                completion(response.result)
        }
    }

    class func doorReleaseRequest(_ panelID: String, unitID: String, method: String, successHandler: @escaping ((Data) -> Void), errorHandler: @escaping ((Error) -> Void)) {
        let urlString = BMXCoreKit.shared.environment.backendEnvironment.baseURL + "/v3/me" + "/open_door"

        let params = [
            "data": [
                "type": "door_release_requests",
                "attributes": [
                    "release_method" : method
                ],
                "relationships": [
                    "panel" : [
                        "data" : [ "id" : panelID ]
                    ],
                    "unit" : [
                        "data" : [ "id" : unitID ]
                    ]
                ]
            ]
        ]

        APIClient.sessionManager.request(urlString, method: .post, parameters: params, interceptor: OAuth2Handler())
            .validate()
            .responseData { response in
                switch response.result {
                case .success:
                    if let data = response.data {
                        successHandler(data)
                    }
                case .failure(let error):
                    errorHandler(error)
                }
        }

    }
    
    class func doorReleaseRequest(_ device: DeviceModel, unitID: String, method: String, successHandler: @escaping ((Data) -> Void), errorHandler: @escaping ((Error) -> Void)) {
        let urlString = BMXCoreKit.shared.environment.backendEnvironment.baseURL + "/v3/me" + "/open_door"

        let params = [
            "data": [
                "type": "door_release_requests",
                "attributes": [
                    "release_method" : method
                ],
                "relationships": [
                    "device" : [
                        "data" : [ "id" : device.id, "type": device.type]
                    ],
                    "unit" : [
                        "data" : [ "id" : unitID ]
                    ]
                ]
            ]
        ]

        APIClient.sessionManager.request(urlString, method: .post, parameters: params, interceptor: OAuth2Handler())
            .validate()
            .responseData { response in
                switch response.result {
                case .success:
                    if let data = response.data {
                        successHandler(data)
                    }
                case .failure(let error):
                    errorHandler(error)
                }
        }

    }


    class func getUserRegion() -> Future<RegionType> {
        let promise = Promise<RegionType>()
        let urlString = BMXCoreKit.shared.environment.backendEnvironment.accountURL + "/api/mobile" + "/regions"

        APIClient.sessionManager.request(urlString, method: .get, interceptor: OAuth2Handler())
            .validate()
            .responseData { response in
                switch response.result {
                case .success:
                    if let data = response.data, let regions = try? JSONDecoder().decode(Regions.self, from: data), let firstRegion = regions.regions.first {
                        promise.resolve(with: firstRegion)
                    } else {
                        promise.resolve(with: .na)
                    }
                case .failure(let error):
                    promise.reject(with: error)
                }
        }

        return promise
    }
    
    class func getWebhooks(byTenantId tenantId: String) -> Future<TenantAllIntegrationsDataModel> {
        let promise = Promise<TenantAllIntegrationsDataModel>()
        let urlString = BMXCoreKit.shared.environment.backendEnvironment.baseURL + "/v3/tenants/\(tenantId)/integrations"
        
        APIClient.sessionManager.request(urlString, method: .get, interceptor: OAuth2Handler())
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let model = try JSONDecoder().decode(TenantAllIntegrationsDataModel.self, from: data)
                        promise.resolve(with: model)
                    } catch {
                        promise.reject(with: error)
                    }
                case .failure(let error):
                    promise.reject(with: error)
                }
            }
        
        return promise
    }
    
    class func registerWebhook(withTenantId tenantId: String, urlString: String) -> Future<TenantIntegrationModel> {

        let promise = Promise<TenantIntegrationModel>()
        
        let params: [String : Any]? = [
            "data": [
                "type": "integrations",
                "attributes": [
                    "integrator": "webhook",
                    "configuration": [
                        "url": urlString,
                        "method": "post"
                    ],
                    "bindings": [
                        [
                        "actions": ["create", "status_update"],
                        "resource_type": "call"
                        ]
                    ]
                ]
            ]
        ]
        
        let apiUrlString = BMXCoreKit.shared.environment.backendEnvironment.baseURL + "/v3/tenants/\(tenantId)/integrations"
        APIClient.sessionManager.request(apiUrlString, method: .post,
                                         parameters: params,
                                         encoding: JSONEncoding.default,
                                         interceptor: OAuth2Handler())
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let model = try JSONDecoder().decode(TenantIntegrationDataModel.self, from: data)
                        promise.resolve(with: model.data)
                    } catch {
                        promise.reject(with: error)
                    }
                case .failure(let error):
                    promise.reject(with: error)
                }
            }
        return promise
    }
    
    class func unregisterWebhook(withTenantId tenantId: String, webhookId: String, completion: @escaping (Result<Data, AFError>) -> Void) {
        let urlString = BMXCoreKit.shared.environment.backendEnvironment.baseURL + "/v3/tenants/\(tenantId)/integrations/\(webhookId)"
        APIClient.sessionManager.request(urlString, method: .delete, interceptor: OAuth2Handler())
            .validate()
            .responseData { response in
                completion(response.result)
            }
    }
    
    class func refreshTokens(completion: @escaping (Result<BMXAuthProvider, Error>) -> Void) {
        let urlString = BMXCoreKit.shared.environment.backendEnvironment.accountURL + "/oauth/token"
        guard let refreshToken = BMXCoreKit.shared.authProvider.refreshToken, let clientID = BMXCoreKit.shared.authProvider.clientID,
        let secret = BMXCoreKit.shared.authProvider.secret else {
            completion(.failure(ServiceError.unableToCreateRequest(message: "refreshToken, clientID or secret is missing")))
            return
        }

        let parameters: [String: Any] = [
            "refresh_token": refreshToken,
            "client_id": clientID,
            "grant_type": "refresh_token",
            "client_secret": secret
        ]

        BMXCoreKit.shared.log(message: "Requesting new Access Token")
        AuthSessionManager.shared.sessionManager.request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseDecodable(of: TokensModel.self) { response in
                switch response.result {
                case .success(let tokens):
                    BMXCoreKit.shared.log(format: "Access Token Response Value: %{private}@", message: tokens.access_token, type: .info)
                    BMXCoreKit.shared.log(format: "Refrest Token Response Value: %{private}@", message: tokens.refresh_token, type: .info)
                    BMXCoreKit.shared.authProvider.setUserTokens(accessToken: tokens.access_token, refreshToken: tokens.refresh_token)
                    BMXCoreKit.shared.log(message: "Tokens are updated in the keychain")
                    completion(.success(BMXCoreKit.shared.authProvider))
                case .failure(let error):
                    BMXCoreKit.shared.log(message: "Access Token Response Error: \(error)")
                    completion(.failure(error))
                }
        }
    }
    
    public class func sendRequest(path: String, params: Parameters, method: HTTPMethod, completion: @escaping ((Result<Data, AFError>) -> Void)) {
        let urlString = BMXCoreKit.shared.environment.backendEnvironment.baseURL + "/v3/" + path

        BMXCoreKit.shared.log(format: "%@", message: "urlString: \(urlString), params: \(params)", type: .debug)

        APIClient.sessionManager.request(urlString, method: method, parameters: params, interceptor: OAuth2Handler())
            .validate()
            .responseData { response in
                completion(response.result)
        }
    }
}

