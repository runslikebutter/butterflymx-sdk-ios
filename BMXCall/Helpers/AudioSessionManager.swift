//
//  AudioSessionManager.swift
//  BMXCall
//
//  Created by Yingtao on 9/7/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

import Foundation
import AVFoundation
import BMXCore

extension AVAudioSessionPortDescription {
    var isHeadphones: Bool {
        return portType == .headphones || portType == .bluetoothHFP || portType == .headsetMic
    }
}

extension AVAudioSession {

    var isHeadphonesConnected: Bool {
        return !currentRoute.outputs.filter { $0.isHeadphones }.isEmpty
    }

}


final class AudioSessionManager {

    static let shared = AudioSessionManager()

    var isHeadphonesConnected: Bool {
        return session.isHeadphonesConnected
    }
    
    var isSpeakerEnabled: Bool {
        let currentRoute = session.currentRoute
        return currentRoute.outputs.map({ $0.portType }).contains(.builtInSpeaker) || session.mode == .videoChat
    }

    // MARK: - Initialization

    private init(session: AVAudioSession = AVAudioSession.sharedInstance()) {
        self.session = session
        self.initialCategory = session.category
        self.initialMode = session.mode
    }

    /// Switches session's category to the default `AVAudioSessionCategory`
    /// and mode to the default `AVAudioSessionMode`.
    func restoreInitialSession() {
        switchToInitialCategory()
        switchToInitialMode()
    }

    @discardableResult
    func switchToMultiRouteCategory() -> Bool {
        return set(category: .multiRoute, for: session)
    }

    /// Switches session's category to the default `AVAudioSessionCategory`.
    /// When your video or audio is no longer playing, Apple recommends to reset category to the default value.
    ///
    /// - Returns: `true` if succeeded, otherwise - `false`.
    @discardableResult
    func switchToInitialCategory() -> Bool {
        return set(category: initialCategory, for: session)
    }

    /// Switches session's mode to the default `AVAudioSessionMode`.
    ///
    /// - Returns: `true` if succeeded, otherwise - `false`.
    @discardableResult
    func switchToInitialMode() -> Bool {
        return set(mode: initialMode, for: session)
    }
    
    func setSessionActive(_ active: Bool) {
        do {
            try session.setActive(active)
        } catch {
            BMXCoreKit.shared.log(message: "Error occured when setting session active: \(error)")
        }
    }
    
    /// Prepare audio session for a call. Should be called before reporting a new callkit call if it's a callkit call, and after answered if it's default call.
    /// In case with a sip call - default mode should be used.
    /// In case with a twilio call - the mode should be videoChat or voiceChat depending on overrideSpeaker value.
    /// - Parameters:
    ///   - overrideSpeaker: true if speaker should be used
    ///   - useChatMode: if true will use videoChat or voiceChat, otherwise will use default
    func prepareSessionForVoipCall(overrideSpeaker: Bool, useChatMode: Bool) {
        do {
            let mode: AVAudioSession.Mode = useChatMode ? (overrideSpeaker && !isHeadphonesConnected) ? .videoChat : .voiceChat : .default
            try session.setCategory(.playAndRecord, mode: mode, options: [.allowBluetooth, .allowBluetoothA2DP])
            if overrideSpeaker && !isHeadphonesConnected {
                try session.overrideOutputAudioPort(.speaker)
            } else {
                try session.overrideOutputAudioPort(.none)
            }
        } catch {
            BMXCoreKit.shared.log(message: "Override audio to Speaker error: \(error)")
        }
    }
    
    func enableSpeaker(_ enable: Bool, changeMode: Bool) {
        do {
            if changeMode {
                try session.setMode(enable ? .videoChat : .voiceChat)
            }
            try session.overrideOutputAudioPort(enable ? .speaker : .none)
            try session.setActive(true)
        } catch {
            BMXCoreKit.shared.log(message: "Override audio to Speaker error: \(error)")
        }
    }

    // MARK: - Private

    private let initialCategory: AVAudioSession.Category
    private let initialMode: AVAudioSession.Mode
    private let session: AVAudioSession

    private func set(category: AVAudioSession.Category, mode: AVAudioSession.Mode = .default, for session: AVAudioSession) -> Bool {
        do {
            try session.setCategory(category, mode: .default)
            return true
        } catch {
            BMXCoreKit.shared.log(message: "Set audio category error: \(error)")
            return false
        }
    }

    private func set(mode: AVAudioSession.Mode, for session: AVAudioSession) -> Bool {
        do {
            try session.setMode(mode)
            return true
        } catch {
            BMXCoreKit.shared.log(message: "Set audio mode error: \(error)")
            return false
        }
    }

}
