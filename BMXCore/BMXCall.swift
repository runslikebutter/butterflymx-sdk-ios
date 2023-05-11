//
//  BMXCall.swift
//  ButterflyMXSDK
//
//  Created by Zhe Cui on 10/10/18.
//  Copyright © 2018 ButterflyMX. All rights reserved.
//

import PushKit
import AVFoundation

public enum CallCancelReason {
    case AnsweredByOthers, CanceledByCaller
}

public protocol BMXCallNotificationsDelegate: class {
    func callReceived(_ call: Call)
    func callCanceled(_ call: Call, reason: CallCancelReason)
}

public protocol BMXCallDelegate: class {
    func incomingVideoStarted(video: UIView)
    func outgoingVideoStarted(video: UIView) -> CGSize?
    func callAccepted(_ call: Call)
    func callStarted(_ call: Call)
    func callEnded(_ call: Call)
}

public extension BMXCallDelegate {
    func callAccepted(_ call: Call) {}
    func callStarted(_ call: Call) {}
    func callEnded(_ call: Call) {}
}

public class BMXCall: PjSIPManagerOnRegistrationDelegate, PjSIPManagerOnCallDelegate, PjSIPManagerCallComingDelegate, PjSIPManagerVideoDelegate, PjSIPManagerLoggingDelegate {
    public static let shared = BMXCall()
    public weak var delegate: BMXCallDelegate?
    public weak var notificationsDelegate: BMXCallNotificationsDelegate?
    
    private var calls: [Call] = []
    var activeGuid: String?
    public var activeCall: Call? {
        guard let guid = activeGuid,
            let index = locateCall(guid) else {
                return nil
        }
        
        return calls[index]
    }
    
    private var selfViewVideoView: UIView?
    
    public enum CallState {
        case receivedPushNotification
        case accepted
        case ongoing
        case idle
    }
    
    public enum CallOrUserEvent {
        case callDialing
        
        case userAcceptsCall
        case callConnected
        case callDisconnected
        case userHangsupCall
        
        case callAnsweredByOthers
        case callCanceledByCaller
    }
    
    var callStateMachine = SimpleStateMachine<CallState, CallOrUserEvent>(initialState: .idle)
    
    private init() {
        PjSIPManager.shared.onCallDelegate = self
        PjSIPManager.shared.callComingDelegate = self
        PjSIPManager.shared.onRegistrationDelegate = self
        PjSIPManager.shared.videoDelegate = self
        PjSIPManager.shared.loggingDelegate = self
        
        // Current call state, call or user event, next call state
        callStateMachine[.idle] = [
            .callDialing : .receivedPushNotification,
        ]
        
        callStateMachine[.receivedPushNotification] = [
            .userAcceptsCall : .accepted,
            .callCanceledByCaller : .idle,
            .callAnsweredByOthers : .idle
        ]
        
        callStateMachine[.accepted] = [
            .callConnected : .ongoing,
            .callCanceledByCaller : .idle,
            .callAnsweredByOthers : .idle
        ]
        
        callStateMachine[.ongoing] = [
            .callDisconnected : .idle,
            .userHangsupCall : .idle,
            .callCanceledByCaller : .idle,
            .callAnsweredByOthers : .idle
        ]
    }
    
    public func getCallInfo(payload: PKPushPayload, completion: @escaping (Result<Call>) -> Void) {
        BMXCore.shared.delegate?.logging("get call info")
        
        guard let callStatus = payload.dictionaryPayload["call_status"] as? String, let callGuid = payload.dictionaryPayload["guid"] as? String else {
            BMXCore.shared.delegate?.logging("Call status or call guid is not available")
            return
        }
        
        BMXCore.shared.delegate?.logging("Call status: \(callStatus)")
        
        APIClient.getCallStatus(guid: callGuid, successHandler: { (data) in
            do {
                guard let response = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                    BMXCore.shared.delegate?.logging("Data -> JSON error")
                    return
                }

                BMXCore.shared.delegate?.logging("JSONAPI Response [/mobile/v3/calls/\(callGuid)/status: \(response)")
                
                do {
                    if let call = try JSONDecoder().decode(IncludedContainer<AttributesContainer<Call>>.self, from: data).included.first?.attributes {
                        // It may take a split second to update call status on server from the true call status on panel
                        if call.status?.rawValue != callStatus {
                            call.status = Call.Status(rawValue: callStatus)
                        }
                        self.processCall(call)
                        
                        completion(.success(call))
                    }
                } catch {
                    BMXCore.shared.delegate?.logging("Get call error: \(error)")
                    completion(.error(error))
                }
            } catch {
                BMXCore.shared.delegate?.logging("Parsing JSON data error: \(error)")
                completion(.error(error))
            }
        }) { (error) in
            BMXCore.shared.delegate?.logging("Get call status error: \(error.localizedDescription)")
            completion(.error(error))
        }
    }
    
    public func previewCall(_ guid: String) {
        BMXCore.shared.delegate?.logging("Preview call with guid \(guid)")
        
        activeGuid = guid
        PjSIPManager.shared.pjsuaStart {
            PjSIPManager.shared.createAndRegisterANewAccount()
        }
    }
    
    public func answerCall() {
        unmuteMic()
        BMXCore.shared.delegate?.logging("Answer call")
        XMPPMessage.sendCallAccepted(video: false, audio: true)
    }

    public func hangupCall() {
        if PjSIPManager.shared.sipCallOn {
            BMXCore.shared.delegate?.logging("Sip on, hangup call")
            PjSIPManager.shared.hangupCall()

            guard let call = activeCall else {
                BMXCore.shared.delegate?.logging("No active call")
                return
            }

            if call.event != .userHangsupCall {
                BMXCore.shared.delegate?.logging("call event changed: \(String(describing: call.event)) -> userHangsupCall")
                call.event = .userHangsupCall
                notifyCallStateMachine(call)
            }
        }
    }

    public func declineCall() {
        BMXCore.shared.delegate?.logging("Decline call")
        XMPPMessage.sendCallEnded()

        guard let call = activeCall else {
            BMXCore.shared.delegate?.logging("No active call")
            return
        }

        if call.event != .userHangsupCall {
            BMXCore.shared.delegate?.logging("call event changed: \(String(describing: call.event)) -> userHangsupCall")
            call.event = .userHangsupCall
            notifyCallStateMachine(call)
        }
    }
    
    public func unmuteMic() {
        BMXCore.shared.delegate?.logging("Unmute Mic")
        PjSIPManager.shared.unmuteMic()
    }
    
    public func muteMic() {
        BMXCore.shared.delegate?.logging("Mute Mic")
        PjSIPManager.shared.muteMic()
    }
    
    public func turnOnSpeaker() {
        BMXCore.shared.delegate?.logging("Turn on Speaker")
        DispatchQueue.global(qos: .default).async {
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            } catch {
                BMXCore.shared.delegate?.logging("Divert audio to Speaker error: \(error)")
            }
        }
    }
    
    public func turnOffSpeaker() {
        BMXCore.shared.delegate?.logging("Turn off Speaker")
        DispatchQueue.global(qos: .default).async {
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            } catch {
                BMXCore.shared.delegate?.logging("Divert audio to No error: \(error)")
            }
        }
    }
    
    public func showOutgoingVideo() {
        BMXCore.shared.delegate?.logging("Show self view")
        selfViewVideoView?.isHidden = false
        XMPPMessage.sendToggleCamera(video: true, audio: true)
    }
    
    public func hideOutgoingVideo() {
        BMXCore.shared.delegate?.logging("Hide self view")
        selfViewVideoView?.isHidden = true
        XMPPMessage.sendToggleCamera(video: false, audio: true)
    }

    public func openDoor() {
        BMXCore.shared.delegate?.logging("Open door")
        XMPPMessage.sendOpenDoor()
    }
    
    // Process events from push notifications
    private func processCall(_ call: Call) {
        // Append new call to queue, or update existing call status
        var index: Int
        
        if let position = locateCall(call.guid ?? "") {
            calls[position].status = call.status
            index = position
        } else {
            calls.append(call)
            index = 0
        }
        
        let call = calls[index]
        var eventChanged = false

        guard let callStatus = call.status else {
            BMXCore.shared.delegate?.logging("Unknown call state, fatal error")
            fatalError()
        }
        
        // Process events: callDialing, callCanceledByCaller, and callAnsweredByOthers
        // according to current call status(accepted or not) and call event
        switch callStatus {
        case .initializing:
            BMXCore.shared.delegate?.logging("initializing, event = dialing")
            if call.event != .callDialing {
                BMXCore.shared.delegate?.logging("call event changed: \(String(describing: call.event)) -> callDialing")
                call.event = .callDialing
                eventChanged = true
            }
        case .connecting_sip:
            // Other device was tapped to accept call ahead,
            // user device will only receive connecting_sip event
            if call.state == .receivedPushNotification {
                BMXCore.shared.delegate?.logging("connecting_sip, event = callAnsweredByOthers")
                if call.event != .callAnsweredByOthers {
                    BMXCore.shared.delegate?.logging("call event changed: \(String(describing: call.event)) -> callAnsweredByOthers")
                    call.event = .callAnsweredByOthers
                    eventChanged = true
                }
            } else {
                BMXCore.shared.delegate?.logging("connecting_sip, ignore event")
            }
        case .canceled:
            BMXCore.shared.delegate?.logging("canceled, event = canceledByCaller")
            if call.event != .callCanceledByCaller {
                BMXCore.shared.delegate?.logging("call event changed: \(String(describing: call.event)) -> canceledByCaller")
                call.event = .callCanceledByCaller
                eventChanged = true
            }
        case .voip_rollover:
            BMXCore.shared.delegate?.logging("voip_rollover, ignore")
            break
        case .rejected:
            BMXCore.shared.delegate?.logging("rejected, ignore")
            break
        case .timeout_online_signal:
            BMXCore.shared.delegate?.logging("timeout_online_signal, event = canceledByCaller")
            if call.event != .callCanceledByCaller {
                BMXCore.shared.delegate?.logging("call state changed: \(String(describing: call.event)) -> canceledByCaller")
                call.event = .callCanceledByCaller
                eventChanged = true
            }
        }
        
        if eventChanged {
            notifyCallStateMachine(call)
        }
    }
    
    private func notifyCallStateMachine(_ call: Call) {
        BMXCore.shared.delegate?.logging("Current call state: \(callStateMachine.currentState)")
        BMXCore.shared.delegate?.logging("Incoming call event: \(String(describing: call.event))")
        
        if activeGuid != nil, call.guid != activeGuid! {
            BMXCore.shared.delegate?.logging("Not active call")
            return
        }
        
        if let event = call.event, let nextCallState = callStateMachine.transition(event) {
            BMXCore.shared.delegate?.logging("Call transitions to state: \(nextCallState)")
            call.state = nextCallState
            switch nextCallState {
            case .receivedPushNotification:
                BMXCore.shared.delegate?.logging("turning to receivedPushNotification state")
                notificationsDelegate?.callReceived(call)
            case .accepted:
                BMXCore.shared.delegate?.logging("turning to accept state")
                XMPPMessage.sendIsActive()
                delegate?.callAccepted(call)
            case .ongoing:
                BMXCore.shared.delegate?.logging("turning to ongoing state")
                delegate?.callStarted(call)
            case .idle:
                BMXCore.shared.delegate?.logging("turning to idle state")
                switch event {
                case .callCanceledByCaller:
                    BMXCore.shared.delegate?.logging("call canceled by caller")
                    notificationsDelegate?.callCanceled(call, reason: .CanceledByCaller)
                    delegate?.callEnded(call)
                case .callAnsweredByOthers:
                    BMXCore.shared.delegate?.logging("call answer by others")
                    notificationsDelegate?.callCanceled(call, reason: .AnsweredByOthers)
                    delegate?.callEnded(call)
                case .userHangsupCall:
                    BMXCore.shared.delegate?.logging("user hung up the call")
                    XMPPMessage.sendCallEnded()
                    delegate?.callEnded(call)
                case .callDisconnected:
                    BMXCore.shared.delegate?.logging("call disconnected")
                    delegate?.callEnded(call)
                default:
                    BMXCore.shared.delegate?.logging("Default event: \(event)")
                }
                
                guard let index = locateCall(call.guid ?? "") else {
                    BMXCore.shared.delegate?.logging("Error: couldn't locate the call")
                    return
                }
                BMXCore.shared.delegate?.logging("Remove call from calls at position \(index)")
                calls.remove(at: index)
                activeGuid = nil
                selfViewVideoView = nil
                
                if !calls.isEmpty {
                    let nextCall = calls.removeFirst()
                    activeGuid = nextCall.guid
                    notifyCallStateMachine(nextCall)
                }
            }
        }
    }
    
    // Search in calls the position of the incoming call, return index, otherwise return nil
    private func locateCall(_ guid: String) -> Int? {
        for (index, call) in calls.enumerated() {
            if call.guid == guid {
                BMXCore.shared.delegate?.logging("found call, index: \(index)")
                return index
            }
        }
        
        return nil
    }
    
    // Delegate
    func logging(_ data: String) {
        BMXCore.shared.delegate?.logging(data)
    }
    
    func registrationDone() {
        BMXCore.shared.delegate?.logging("Registration done")
        
        guard let call = activeCall else {
            BMXCore.shared.delegate?.logging("No active call")
            return
        }
        
        if call.event != .userAcceptsCall {
            BMXCore.shared.delegate?.logging("call event changed: \(String(describing: call.event)) -> userAcceptsCall")
            call.event = .userAcceptsCall
            notifyCallStateMachine(call)
        }
    }
    
    func callConnected(_ callID: Int, _ remoteUri: String) {
        BMXCore.shared.delegate?.logging("Call connected: \(callID), \(remoteUri)")
        
        guard let call = activeCall else {
            BMXCore.shared.delegate?.logging("No active call")
            return
        }
        
        if call.callID != callID {
            BMXCore.shared.delegate?.logging("Error: call ID not matching")
            return
        }
        
        if call.event != .callConnected {
            BMXCore.shared.delegate?.logging("call event changed: \(String(describing: call.event)) -> callConnected")
            call.event = .callConnected
            
            notifyCallStateMachine(call)
        }
    }
    
    func callDisconnected(_ callID: Int, _ remoteUri: String, _ reason: String) {
        BMXCore.shared.delegate?.logging("Call got disconnected: \(callID), \(remoteUri), \(reason)")
        
        guard let call = activeCall else {
            BMXCore.shared.delegate?.logging("No active call")
            return
        }
        
        if call.callID != callID {
            BMXCore.shared.delegate?.logging("Error: call ID not matching")
            return
        }
        
        if call.event != .callDisconnected {
            BMXCore.shared.delegate?.logging("call event changed: \(String(describing: call.event)) -> callDisconnected")
            call.event = .callDisconnected
            
            notifyCallStateMachine(call)
        }
    }
    
    // Only when two devices accepts a call at the same time, one device will get the call,
    // the other device will get call canceled event
    func callCanceled(_ callID: Int, _ state: PjSIPManager.CallTransactionState) {
        BMXCore.shared.delegate?.logging("Call got canceled")
        
        if state == .terminated {
            BMXCore.shared.delegate?.logging("Call got answered by others")
            guard let call = activeCall else {
                BMXCore.shared.delegate?.logging("No active call")
                return
            }
            
            if call.callID != callID {
                BMXCore.shared.delegate?.logging("Error: call ID not matching")
                return
            }
            
            if call.event != .callAnsweredByOthers {
                BMXCore.shared.delegate?.logging("call event changed: \(String(describing: call.event)) -> callAnsweredByOthers")
                call.event = .callAnsweredByOthers
                
                notifyCallStateMachine(call)
            }
        }
    }
    
    func callComingIn(_ callId: Int, _ remoteUri: String) {
        BMXCore.shared.delegate?.logging("Call coming in: \(callId), \(remoteUri)")
        
        guard let call = activeCall else {
            BMXCore.shared.delegate?.logging("No active call")
            return
        }
        
        guard remoteUri.contains(call.panelSip ?? "") else {
            BMXCore.shared.delegate?.logging("Warning: call from different panel")
            return
        }
        
        call.callID = callId
        
        if PjSIPManager.shared.sipCallOn {
            PjSIPManager.shared.answerCall(callID: callId, succeeded: {
                BMXCore.shared.delegate?.logging("Sent answer call succeeded")
            }, failed: {
                BMXCore.shared.delegate?.logging("Failed to send answer call.")
            })
        }
    }
    
    func displayIncomingVideoWindow(_ window: UIView) {
        BMXCore.shared.delegate?.logging("Incoming video started")
        delegate?.incomingVideoStarted(video: window)
    }
    
    func displayOutgoingVideoWindow(_ window: UIView) {
        BMXCore.shared.delegate?.logging("Outgoing video started")
        
        guard let size = delegate?.outgoingVideoStarted(video: window) else {
            BMXCore.shared.delegate?.logging("Error: couldn't get video size")
            return
        }

        selfViewVideoView = window
        let winID = PjSIPManager.shared.outgoingVideoWindowID
        PjSIPManager.shared.resizeVideoWindow(winID, size.width, size.height)
        PjSIPManager.shared.repositionVideoWindow(winID, 0, 0)
    }

}
