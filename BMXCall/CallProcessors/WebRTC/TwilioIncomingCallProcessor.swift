//
//  TwilioIncomingCallProcessor.swift
//  BMXCall
//
//  Created by Yingtao on 9/13/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

import Foundation
import TwilioVideo
import BMXCore

extension TwilioIncomingCallProcessor: IncomingCallUIDataSource {
    var speakerEnabled: Bool {
        return AudioSessionManager.shared.isSpeakerEnabled
    }
    
    var micEnabled: Bool {
        return localAudioTrack?.isEnabled ?? false
    }
    
    var cameraEnabled: Bool {
        return localVideoTrack?.isEnabled ?? false
    }
    
    var openDoorEnabled: Bool {
        return false
    }
    
    var currentPanelName: String? {
        if let panelName = currentCall?.attributes?.panelName {
            return panelName
        }
        return currentCall?.panelName ?? "Front door"
    }
    
    var currentPanelId: Int? {
        return currentCall?.panelId
    }
    
    var incomingVideoView: UIView? {
        return nil
    }
    
    var outgoingVideoView: UIView? {
        return nil
    }
}

extension TwilioIncomingCallProcessor: IncomingCallUIDelegate {
    func pressCallAccept() {
        enableLocalAudio()
        sendCallAccepted()
    }
    
    func pressCallDecline() {
        set(event: .userDeclinesCall)
    }
    
    func pressCallHungup() {
        set(event: .userHangsupCall)
    }
    
    func toggleFrontCamera() {
        guard let guid = currentGuid, let panelId = currentPanelId else {
            BMXCoreKit.shared.log(message: "GUID or panel id is missing")
            return
        }
        
        if localVideoTrack?.isEnabled == true {
            stopLocalVideo()
        } else {
            startLocalVideo()
        }
        
        CallNotifications.sendToggleCamera(guid: guid, panelId: panelId, video: cameraEnabled, audio: true)
        
        uiInput?.updateCameraControlStatus()
    }
    
    func toggleSpeaker() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {return }
            
            self.audioDevice.block = {
                AudioSessionManager.shared.enableSpeaker(!self.speakerEnabled, changeMode: true)
                DispatchQueue.main.async {
                    self.uiInput?.updateSpeakerControlStatus()
                }
            }
            self.audioDevice.block()
        }
       
    }
    
    func pressOpenDoor(completion: ((Bool) -> Void)? = nil) {
        _ = openDoorUsingNumberPad(completion: completion)
    }
    
    func proximityChange(value: Bool) {
        
    }
}

extension TwilioIncomingCallProcessor: LocalParticipantDelegate {
    func localParticipantDidPublishVideoTrack(participant: LocalParticipant, videoTrackPublication: LocalVideoTrackPublication) {
        print("localParticipantDidPublishVideoTrack")
    }
}

class TwilioIncomingCallProcessor: NSObject, IncomingCallProcessor {
    
    // Video SDK components    
    private var room: Room?
    private var camera: CameraSource?
    private var localVideoTrack: LocalVideoTrack?
    private var localAudioTrack: LocalAudioTrack?
    private var localParticipant: LocalParticipant? {
        return room?.localParticipant
    }
    private var remoteParticipant: RemoteParticipant?
    private var remoteView: VideoView?
    private var previewView: VideoView!
    
    private var audioDevice = TwilioVideo.DefaultAudioDevice()
    
    weak var uiInput: IncomingCallUIInputs?
    weak var callStatusDelegate: CallStatusDelegate?
    
    private var callType: CallType!
    
    private var currentGuid: String? {
        return currentCall?.guid
    }
    
    static let shared = TwilioIncomingCallProcessor()

    private var callStateMachine = SimpleStateMachine<CallState, CallOrUserEvent>(initialState: .idle)
    
    fileprivate var currentCallStatus: CallState = .idle
    fileprivate var currentEvent: CallOrUserEvent? = nil
    
    private override init() {
        super.init()
        
        /*
         * The important thing to remember when providing a AudioDevice is that the device must be set
         * before performing any other actions with the SDK (such as creating Tracks, or connecting to a Room).
         * In this case we've already initialized our own `DefaultAudioDevice` instance which we will now set.
         */
       
        TwilioVideoSDK.audioDevice = self.audioDevice
        
        // Setup state machine rules
        setupStateMachine()
    }
        
    private(set) var currentCall: Call?
            
    func processCall(call: Call, callType: CallType) {
        self.currentCall = call
        self.callType = callType
        
        set(event: .callDialing)
        process(call: call)
    }
    
    /// Sets the new call status to the current call and updates call state machine based on that status, call this when new call push notification with a new status is received.
    /// If there is no a current call or guid is different, then nothing will happen.
    /// - Parameter status: new raw status
    func processCall(guid: String, status: String) {
        if let currentCall = currentCall, currentGuid == guid {
            currentCall.attributes?.status = status
            process(call: currentCall)
        }
    }
    
    func handleCallPreview() {
        uiInput?.setupWaitingForAnsweringCallUI()
    }

    func answerCall() {
        set(event: .userAcceptsCall)
    }
    
    func openDoorUsingNumberPad(completion: ((Bool) -> Void)? = nil) -> Bool {
        BMXCoreKit.shared.log(message: "Open door")
        
        guard let guid = currentGuid, let panelId = currentPanelId else {
            BMXCoreKit.shared.log(message: "Can't open door, state: \(currentCallStatus), GUID or panel id is missing")
            return false
        }
        
        CallNotifications.sendOpenDoor(guid: guid, panelId: panelId, completion: completion)
        return true
    }
    
    func toggleMicrophone(_ isMuted: Bool? = nil) -> Bool {
        BMXCoreKit.shared.log(message: "Toggle microphone")
        
        guard let localAudioTrack = localAudioTrack, currentCallStatus == .ongoing else {
            return false
        }
        
        if let isMuted = isMuted {
            localAudioTrack.isEnabled = isMuted
        }
        
        localAudioTrack.isEnabled.toggle()
        uiInput?.updateMicrophoneControlStatus()
        return true
    }
    
    func prepareSoundDeviceIfNeeded() {
        audioDevice.isEnabled = true
    }
    
    func deactivateSoundDeviceIfNeeded() {
        audioDevice.isEnabled = false
    }

    func endCall(guid: String) {
        guard let currentGuid = currentGuid, guid.compare(currentGuid, options: .caseInsensitive) == .orderedSame else {
            BMXCoreKit.shared.log(message: "End call failed, because received guid != currentGuid")
            return
        }
               
        if currentCallStatus == .ongoing {
            set(event: .userHangsupCall)
        } else if currentCallStatus != .idle {
            set(event: .userDeclinesCall)
        }
    }
    
    // MARK: - Private
    
    private func enableLocalAudio() {
        localAudioTrack?.isEnabled = true
        
        DispatchQueue.main.async {
            self.uiInput?.updateSpeakerControlStatus()
            self.uiInput?.updateMicrophoneControlStatus()
        }
    }
    
    private func set(event: CallOrUserEvent) {
        if currentEvent != event {
            currentEvent = event
            notifyCallStateMachine(event: currentEvent!)
        }
    }
    
    private func notifyAboutAnsweredCallAndConnect() {
        BMXCoreKit.shared.log(message: "Answer")
        
        guard let accessToken = currentCall?.providerToken,
              let roomName = currentCall?.guid, let panel = currentPanelId else {
            BMXCoreKit.shared.log(message: "Cannot answer, can't get twilioProviderToken or roomName or currentPanelId")
            return
        }

        CallNotifications.sendIsActive(guid: roomName, panelId: panel)

        if let currentCall = currentCall {
            DispatchQueue.main.async {
                self.callStatusDelegate?.callAccepted(from: currentCall, usingCallKit: self.callType == .callkit)
            }
        }
        
        connect(with: accessToken, roomName: roomName)
    }
    
    fileprivate func declineCall() {
        BMXCoreKit.shared.log(message: "Decline call")
        guard let guid = currentGuid, let panelId = currentPanelId else {
            BMXCoreKit.shared.log(message: "GUID or panel id is missing")
            return
        }
        
        CallNotifications.sendCallEnded(guid: guid, panelId: panelId)
    }
        
    private func setupRemoteVideoView() {
        guard let uiInput = uiInput else {
            return
        }
        
        let size = uiInput.getInputVideoViewSize()
        
        self.remoteView = VideoView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height), delegate: self)
        
        if let remoteView = remoteView {
            uiInput.displayIncomingVideo(from: remoteView)
        }
    }
    
    private func setupLocalVideoView() {
        guard let uiInput = uiInput else {
            return
        }
        
        let size = uiInput.getOutputVideoViewSize()
        
        self.previewView = VideoView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height), delegate: self)
        
        if let previewView = previewView {
            uiInput.displayOutgoingVideo(from: previewView)
        }
    }
    
    private func renderRemoteParticipant(participant : RemoteParticipant) -> Bool {
        // This renders the first subscribed RemoteVideoTrack from the RemoteParticipant.
        let videoPublications = participant.remoteVideoTracks
        for publication in videoPublications {
            if let subscribedVideoTrack = publication.remoteTrack,
                publication.isTrackSubscribed {
                setupRemoteVideoView()
                guard let remoteView = remoteView else { return false }
                subscribedVideoTrack.addRenderer(remoteView)
                self.remoteParticipant = participant
                return true
            }
        }
        return false
    }

    private func renderRemoteParticipants(participants : Array<RemoteParticipant>) {
        for participant in participants {
            // Find the first renderable track.
            if participant.remoteVideoTracks.count > 0,
                renderRemoteParticipant(participant: participant) {
                break
            }
        }
    }

    private func prepareLocalMedia() {
        // We will share local audio and video when we connect to the Room.

        // Create an audio track.
        if (localAudioTrack == nil) {
            localAudioTrack = LocalAudioTrack(options: nil, enabled: false, name: "Microphone")

            if (localAudioTrack == nil) {
                BMXCoreKit.shared.log(message: "Failed to create audio track")
            }
        }
        
        prepareLocalVideoTrack()
    }
    
    private func cleanupRemoteParticipant() {
        if self.remoteParticipant != nil {
           
            self.remoteView = nil
            self.remoteParticipant = nil
        }
    }
    
    private let connectOptionsFactory = ConnectOptionsFactory()
    
    private func connect(with accessToken: String, roomName: String) {
        prepareLocalMedia()
        
        guard let localAudioTrack = self.localAudioTrack, let localVideoTrack = localVideoTrack else {
            BMXCoreKit.shared.log(message: "Cannot connect, local media track are not prepeared")
            return
        }

        // Preparing the connect options with the access token that we fetched (or hardcoded).
        let connectOptions = connectOptionsFactory.makeConnectOptions(
            accessToken: accessToken,
            roomName: roomName,
            audioTracks: [localAudioTrack],
            videoTracks: [localVideoTrack]
        )

        room = TwilioVideoSDK.connect(options: connectOptions, delegate: self)
        BMXCoreKit.shared.log(message: "Attempting to connect to room \(roomName))")
    }
    
    private func disconnect() {
        guard let room = room else { return }
        BMXCoreKit.shared.log(message: "Disconnect room \(room.name))")
        room.disconnect()
    }
    
    private func prepareLocalVideoTrack() {
        camera = CameraSource(delegate: self)
        localVideoTrack = LocalVideoTrack(source: camera!, enabled: false, name: "Camera")
    }
    
    private func startLocalVideo() {
        guard let frontCamera = CameraSource.captureDevice(position: .front) else {
            BMXCoreKit.shared.log(message: "Cannot start local video track, front camera is nil")
            return
        }

        BMXCoreKit.shared.log(message: "Enable local video track")
        localVideoTrack?.isEnabled = true
        //localParticipant?.publishVideoTrack(localVideoTrack!)
        BMXCoreKit.shared.log(message: "Start video capture from frontCamera")
        camera?.startCapture(device: frontCamera) { (captureDevice, videoFormat, error) in
            if let error = error {
                BMXCoreKit.shared.log(message: "Capture failed with error.\ncode = \((error as NSError).code) error = \(error.localizedDescription)")
            } else {
                BMXCoreKit.shared.log(message: "Capture started")
            }
        }
    }
    
    private func stopLocalVideo() {
        BMXCoreKit.shared.log(message: "Disable local video track")
        localVideoTrack?.isEnabled = false
        //localParticipant?.unpublishVideoTrack(localVideoTrack!)
        BMXCoreKit.shared.log(message: "Stop video capturing")
        camera?.stopCapture()
    }
    
    private func prepareAudioSessionForCall(overrideSpeaker: Bool? = nil) {
        // If the app is in active state then enable speaker
        // otherwise use earpiece
        let appState = UIApplication.shared.applicationState
        let overrideSpeaker = overrideSpeaker ?? (appState == .active)
        audioDevice.block = {
            AudioSessionManager.shared.prepareSessionForVoipCall(overrideSpeaker: overrideSpeaker, useChatMode: true)
        }
        audioDevice.block()
    }
}

// MARK:- CameraSourceDelegate
extension TwilioIncomingCallProcessor : CameraSourceDelegate {
    func cameraSourceDidFail(source: CameraSource, error: Error) {
        BMXCoreKit.shared.log(message: "Camera source failed with error: \(error.localizedDescription)")
    }
}


// MARK:- VideoViewDelegate
extension TwilioIncomingCallProcessor : VideoViewDelegate {
    func videoViewDimensionsDidChange(view: VideoView, dimensions: CMVideoDimensions) {
        self.remoteView?.setNeedsLayout()
    }
}

// MARK:- RoomDelegate
extension TwilioIncomingCallProcessor: RoomDelegate {
    func roomDidConnect(room: Room) {
        BMXCoreKit.shared.log(message: "Connected to room \(room.name) as \(room.localParticipant?.identity ?? "")")
        
        room.localParticipant?.delegate = self
        
        // This example only renders 1 RemoteVideoTrack at a time. Listen for all events to decide which track to render.
        for remoteParticipant in room.remoteParticipants {
            remoteParticipant.delegate = self
        }
        
        set(event: .callConnected)
    }

    func roomDidDisconnect(room: Room, error: Error?) {
        BMXCoreKit.shared.log(message: "Disconnected from room \(room.name), error = \(String(describing: error))")

        set(event: .callDisconnected)
    }
    
    func roomDidFailToConnect(room: Room, error: Error) {
        BMXCoreKit.shared.log(message: "Failed to connect to room with error = \(String(describing: error))")
        
        set(event: .callDisconnected)
        self.room = nil
    }

    func participantDidConnect(room: Room, participant: RemoteParticipant) {
        // Listen for events from all Participants to decide which RemoteVideoTrack to render.
        participant.delegate = self

        BMXCoreKit.shared.log(message: "Participant \(participant.identity) connected with \(participant.remoteAudioTracks.count) audio and \(participant.remoteVideoTracks.count) video tracks")
    }
    
    func roomIsReconnecting(room: Room, error: Error) {
        BMXCoreKit.shared.log(message: "Reconnecting to room \(room.name), error = \(String(describing: error))")
    }

    func roomDidReconnect(room: Room) {
        BMXCoreKit.shared.log(message: "Reconnected to room \(room.name)")
    }

    func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
        BMXCoreKit.shared.log(message: "Room \(room.name), Participant \(participant.identity) disconnected")
        set(event: .participantDidDisconnect)
    }

}

// MARK:- RemoteParticipantDelegate
extension TwilioIncomingCallProcessor : RemoteParticipantDelegate {

    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        // The LocalParticipant is subscribed to the RemoteParticipant's video Track. Frames will begin to arrive now.

        BMXCoreKit.shared.log(message: "Subscribed to \(publication.trackName) video track for Participant \(participant.identity)")

        if (self.remoteParticipant == nil) {
            _ = renderRemoteParticipant(participant: participant)
        }
    }
    
    func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.
        
        BMXCoreKit.shared.log(message: "Unsubscribed from \(publication.trackName) video track for Participant \(participant.identity)")

        if self.remoteParticipant == participant {
            cleanupRemoteParticipant()

            // Find another Participant video to render, if possible.
            if var remainingParticipants = room?.remoteParticipants,
                let index = remainingParticipants.firstIndex(of: participant) {
                remainingParticipants.remove(at: index)
                renderRemoteParticipants(participants: remainingParticipants)
            }
        }
    }

}

// MARK: - State Machine

extension TwilioIncomingCallProcessor {
    
    private func setupStateMachine() {
        // Current call state, call or user event, next call state
        callStateMachine[.idle] = [
            .callDialing : .receivedPushNotification,
            .callRejected : .idle,
            .callCanceledByCaller : .idle,
            .openedDoor : .idle
        ]
        
        callStateMachine[.receivedPushNotification] = [
            .userAcceptsCall : .accepted,
            .userDeclinesCall : .idle,
            .callCanceledByCaller : .idle,
            .callAnsweredByOthers : .idle,
            .openedDoor : .idle,
            .callRejected : .idle
        ]
        
        callStateMachine[.accepted] = [
            .callConnected : .ongoing,
            .callCanceledByCaller : .idle,
            .callAnsweredByOthers : .idle
        ]
        
        callStateMachine[.ongoing] = [
            .callDisconnected : .idle,
            .userHangsupCall : .idle,
            .userDeclinesCall : .idle,
            .callCanceledByCaller : .idle,
            .callAnsweredByOthers : .idle,
            .participantDidDisconnect : .idle
        ]
    }
    
    private func process(call: Call) {
        guard let callStatus = call.statusEnum else {
            BMXCoreKit.shared.log(message: "Unknown call state, fatal error")
            fatalError()
        }
        
        let prevEvent = currentEvent
        
        switch callStatus {
        case .initializing:
            BMXCoreKit.shared.log(message: "initializing, event = dialing")
            currentEvent = .callDialing
        case .connecting_sip:
            BMXCoreKit.shared.log(message: "connecting_sip")
            // Other device was tapped to accept call ahead,
            // user device will only receive connecting event
            if currentCallStatus == .receivedPushNotification {
                if currentEvent != .callAnsweredByOthers {
                    currentEvent = .callAnsweredByOthers
                }
            }
        case .canceled:
            BMXCoreKit.shared.log(message: "canceled, event = canceledByCaller")
            currentEvent = .callCanceledByCaller
        case .voip_rollover:
            BMXCoreKit.shared.log(message: "voip_rollover, ignore")
        case .rejected:
            BMXCoreKit.shared.log(message: "rejected")
            currentEvent = .callRejected
        case .timeout_online_signal:
            BMXCoreKit.shared.log(message: "timeout_online_signal, event = canceledByCaller")
            currentEvent = .callCanceledByCaller
        case .opened_door:
            BMXCoreKit.shared.log(message: "opened_door")
            currentEvent = .openedDoor
        }
        
        if let currentEvent = currentEvent, currentEvent != prevEvent {
            notifyCallStateMachine(event: currentEvent)
        }
    }
    
    private func sendCallAccepted() {
        guard let guid = currentGuid, let panelId = currentPanelId else {
            BMXCoreKit.shared.log(message: "GUID or panelId is missing")
            return
        }
        
        CallNotifications.sendCallAccepted(guid: guid, panelId: panelId, video: false, audio: true)
    }
    
    private func callConnected() {
        DispatchQueue.main.async {
            self.callStatusDelegate?.callConnected()
            self.setupLocalVideoView()
            if let previewView = self.previewView {
                self.localVideoTrack?.addRenderer(previewView)
            }
        }
        
        if callType == .callkit {
            enableLocalAudio()
        }
        
        sendCallAccepted()
    }
    
    private func cleanUpRoomState() {
        cleanupRemoteParticipant()
        self.room = nil
        stopLocalVideo()
    }
    
    private func notifyCallStateMachine(event: CallOrUserEvent) {
        BMXCoreKit.shared.log(message: "Current call state: \(callStateMachine.currentState)")
        BMXCoreKit.shared.log(message: "Incoming call event: \(String(describing: event))")
        
        guard let nextCallState = callStateMachine.transition(event), let callId = currentGuid else {
            BMXCoreKit.shared.log(message: "Not possible to get next call state")
            return
        }
        currentCallStatus = nextCallState
        
        BMXCoreKit.shared.log(message: "Call transitions to state: \(nextCallState)")
        
        switch nextCallState {
        case .receivedPushNotification:
            BMXCoreKit.shared.log(message: "turning to receivedPushNotification state")
            
            // For callkit call prepare audio session before reporting a new call status
            if callType == .callkit {
                prepareAudioSessionForCall()
            }
        case .accepted:
            BMXCoreKit.shared.log(message: "turning to accept state")
            notifyAboutAnsweredCallAndConnect()
            
            // For usual call prepare audio session after accepting
            if callType == .notification {
                prepareAudioSessionForCall(overrideSpeaker: true)
            }
        case .ongoing:
            BMXCoreKit.shared.log(message: "turning to ongoing state")
            callConnected()
        case .idle:
            BMXCoreKit.shared.log(message: "turning to idle state")
            let usingCallKit = callType == .callkit
            
            switch event {
            case .callDisconnected:
                BMXCoreKit.shared.log(message: "call disconnected")
                cleanUpRoomState()
                delegateCallEnded(callId: callId, usingCallKit: usingCallKit)
            case .userDeclinesCall:
                BMXCoreKit.shared.log(message: "user declines the call")
                declineCall()
                cleanUpRoomState()
                delegateCallEnded(callId: callId, usingCallKit: usingCallKit)
            case .userHangsupCall:
                BMXCoreKit.shared.log(message: "user hung up the call")
                disconnect()
                cleanUpRoomState()
                delegateCallEnded(callId: callId, usingCallKit: usingCallKit)
            case .callAnsweredByOthers:
                BMXCoreKit.shared.log(message: "call answer by others")
                delegateCallCanceled(callId: callId, reason: .answeredByOthers, usingCallKit: usingCallKit)
            case .callCanceledByCaller:
                BMXCoreKit.shared.log(message: "call canceled by caller")
                delegateCallCanceled(callId: callId, reason: .canceledByCaller, usingCallKit: usingCallKit)
            case .callRejected:
                BMXCoreKit.shared.log(message: "call rejected")
                delegateCallEnded(callId: callId, usingCallKit: usingCallKit)
            case .participantDidDisconnect:
                BMXCoreKit.shared.log(message: "participant did disconnect")
                disconnect()
                cleanUpRoomState()
                delegateCallEnded(callId: callId, usingCallKit: usingCallKit)
            default:
                BMXCoreKit.shared.log(message: "Default event: \(event)")
                delegateCallEnded(callId: callId, usingCallKit: usingCallKit)
            }
        }
    }
}

