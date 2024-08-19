//
//  BMXCallProtocol.swift
//  BMXCall
//
//  Created by Yingtao on 8/31/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

import Foundation
import BMXCore
import PushKit
import UIKit

public enum CallCancelReason {
    case answeredByOthers, canceledByCaller
}

public protocol CallStatusDelegate: AnyObject {
    
    func callConnected()
    
    func callAccepted(from call: Call, usingCallKit: Bool)

    // Before users answer the call
    func callCanceled(callId: String, reason: CallCancelReason, usingCallKit: Bool)
    
    // After users answer the call
    func callEnded(callId: String, usingCallKit: Bool)
}

extension CallStatusDelegate {
    func callCanceled(callId: String, reason: CallCancelReason, usingCallKit: Bool) {}
}

public class BMXCallKit {
    public static let shared = BMXCallKit()
    
    public var activeCall: Call? {
        return processor?.currentCall
    }
    
    var processor: IncomingCallProcessor?
    private var callId: String?
    
    public var callType: CallType = .callkit
    
    private init() {}
    
    public weak var incomingCallPresenter: IncomingCallUIInputs? {
        didSet {
            if let incomingCallPresenter = incomingCallPresenter {
                TwilioIncomingCallProcessor.shared.uiInput = incomingCallPresenter
            }
        }
    }
    
    public weak var callStatusDelegate: CallStatusDelegate? {
        didSet {
            if let callStatusDelegate = callStatusDelegate {
                TwilioIncomingCallProcessor.shared.callStatusDelegate = callStatusDelegate
            }
        }
    }
    
    public func processCall(guid: String,
                            callType: CallType = .callkit,
                            completion: @escaping (Result<Call, BMXCore.ServiceError>) -> Void) {
        
        callId = guid
        self.callType = callType
        
        getCall(guid: guid) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let call):
                guard let callProvider = call.callProvider else {
                    completion(.failure(.unableToProcessResponse(message: "No call provider")))
                    return
                }
                
                guard let callProcessor = self.getCallProcessor(by: callProvider) else {
                    completion(.failure(.unableToProcessResponse(message: "Call provider \(callProvider) is not supported")))
                    return
                }
                
                self.processor = callProcessor
                self.incomingCallPresenter?.delegate = self.processor
                
                guard call.attributes?.status == Call.Status.initializing.rawValue else {
                    self.processor?.processCall(call: call, callType: callType)
                    completion(.success(call))
                    return
                }
                
                if call.callProvider == .twilio {
                    self.handleWebRtcCall(callId: guid, completion: completion) {providerToken in
                        call.attributes?.providerToken = providerToken
                        processCall()
                    }
                } else {
                    processCall()
                }                
                
                func processCall() {
                    self.processor?.processCall(call: call, callType: callType)
                    completion(.success(call))
                }
                
            case .failure(let error):
                completion(.failure(.unableToProcessResponse(message: error.localizedDescription)))
            }
        }
    }
    
    // MARK: - Private
    
    private func getCall(guid: String, completion: @escaping (Result<Call, Error>) -> Void) {
        BMXCore.APIClient.getCallStatus(guid: guid) { result in
            switch result {
            case .success(let data):
                do {
                    let call = try CallStatus.getCall(data)
                    if let call = call {
                        completion(.success(call))
                    } else {
                        throw NSError(domain: "call or callStatus is empty", code: 0, userInfo: nil)
                    }
                } catch {
                    BMXCoreKit.shared.log(message: "Parsing JSON data error: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                BMXCoreKit.shared.log(message: "Get call status error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
        
    private func getCallProcessor(by type: Call.CallProvider) -> IncomingCallProcessor? {
        switch type {
        case .twilio:
            return TwilioIncomingCallProcessor.shared
        default:
            return nil
        }
    }
    
    private func retrieveProviderTokenByCallId(_ callId: String, deviceId: String, completion: @escaping (Result<ProviderTokens, Error>) -> Void) {
        let params: [String: Any] = [
            "data": [
                "type": "token",
                "attributes": [
                    "device_uuid": deviceId
                ]
            ]
        ]

        APIClient.sendRequest(
            path: "me/calls/\(callId)/token",
            params: params,
            method: .post) { res in
                switch res {
                case .success(let data):
                    do {
                        let providerTokens = try JSONDecoder().decode(ProviderTokens.self, from: data)
                        completion(.success(providerTokens))
                    } catch {
                        BMXCoreKit.shared.log(message: "Parsing JSON data error: \(error)")
                        completion(.failure(error))
                    }
                case .failure(let error):
                    BMXCoreKit.shared.log(message: "Get provider token error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
        }
    }
    
    private func handleWebRtcCall(callId: String,
                                  completion: @escaping (Result<Call, BMXCore.ServiceError>) -> Void,
                                  handleCallWhenProviderTokenIsReady: @escaping (String) -> Void) {
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
            completion(.failure(.unableToCreateRequest(message: "Failed to create unique device id.")))
            return
        }
        
        retrieveProviderTokenByCallId(callId, deviceId: deviceId) { result in
            switch result {
            case .success(let providerTokens):
                guard let token = providerTokens.tokens["twilio"] else {
                    completion(.failure(.unableToProcessResponse(message: "Failed to retrieve provider token.")))
                    return
                }
                
                handleCallWhenProviderTokenIsReady(token)
            case .failure(let error):
                completion(.failure(.unableToProcessResponse(message: error.localizedDescription)))
            }
        }
    }


    public func connectSoundDevice() {
        processor?.prepareSoundDeviceIfNeeded()
    }
    
    public func disconnectSoundDevice() {
        processor?.deactivateSoundDeviceIfNeeded()
    }
    
    public func muteMic() {
        if processor?.micEnabled == true {
            processor?.toggleMicrophone()
        }
    }
    
    public func unmuteMic() {
        if processor?.micEnabled == false {
            processor?.toggleMicrophone()
        }
    }
    
    public func turnOnSpeaker() {
        if processor?.speakerEnabled == false {
            processor?.toggleSpeaker()
        }
    }
    
    public func turnOffSpeaker() {
        if processor?.speakerEnabled == true {
            processor?.toggleSpeaker()
        }
    }
    
    public func showOutgoingVideo() {
        if processor?.cameraEnabled == false {
            processor?.toggleFrontCamera()
        }
    }
    
    public func hideOutgoingVideo() {
        if processor?.cameraEnabled == true {
            processor?.toggleFrontCamera()
        }
    }
    
    public func previewCall(autoAccept: Bool) {
        BMXCoreKit.shared.log(message: "Preview call with guid \(String(describing: callId)), autoAccept: \(autoAccept)")
        processor?.handleCallPreview()
        
        if autoAccept {
            processor?.answerCall()
        }
    }
    
    public func answerCall() {
        processor?.answerCall()
    }
    
    public func openDoor(completion: ((Bool) -> Void)? = nil) {
        processor?.pressOpenDoor(completion: completion)
    }
    
    public func endCall() {
        if let callId = callId {
            processor?.endCall(guid: callId)
        }        
    }    
}
