//
//  BMXCallProtocol.swift
//  BMXCall
//
//  Created by Yingtao on 8/31/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

import Foundation

public enum CallType  {
    case notification
    case callkit
}

protocol IncomingCallProcessor: IncomingCallUIDelegate & IncomingCallUIDataSource {
    var callStatusDelegate: CallStatusDelegate? { get set }
    var uiInput: IncomingCallUIInputs? { get set }
    
    func handleCallPreview()
    func processCall(call: Call, callType: CallType)
    func prepareSoundDeviceIfNeeded()
    func deactivateSoundDeviceIfNeeded()
    func endCall(guid: String)
    func openDoorUsingNumberPad(completion: ((Bool) -> Void)?) -> Bool
    func toggleMicrophone(_ value: Bool?) -> Bool
    func answerCall()
    
    // The functions below have default implementations for calling callStatusDelegate's functions in main queue
    func delegateCallCanceled(callId: String, reason: CallCancelReason, usingCallKit: Bool)
    func delegateCallEnded(callId: String, usingCallKit: Bool)
}

extension IncomingCallProcessor {
    func toggleMicrophone() {
        _ = toggleMicrophone(nil)
    }
    
    func delegateCallCanceled(callId: String, reason: CallCancelReason, usingCallKit: Bool) {
        DispatchQueue.main.async {
            self.callStatusDelegate?.callCanceled(callId: callId, reason: reason, usingCallKit: usingCallKit)
        }
    }

    func delegateCallEnded(callId: String, usingCallKit: Bool) {
        DispatchQueue.main.async {
            self.callStatusDelegate?.callEnded(callId: callId, usingCallKit: usingCallKit)
        }
    }
}
