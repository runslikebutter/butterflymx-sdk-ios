//
//  IncomingViewProtocols.swift
//  BMXCall
//
//  Created by Yingtao on 9/10/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

import UIKit

public protocol IncomingCallUIInputs: AnyObject {
    func setupWaitingForAnsweringCallUI()
    
    func getInputVideoViewSize() -> CGSize
    func getOutputVideoViewSize() -> CGSize
    func displayIncomingVideo(from view: UIView)
    func displayOutgoingVideo(from view: UIView)
            
    func updateSpeakerControlStatus()
    func updateMicrophoneControlStatus()
    func updateCameraControlStatus()
    
    var delegate: (IncomingCallUIDelegate & IncomingCallUIDataSource)? { get set }
}

public protocol IncomingCallUIDelegate: AnyObject {
    func pressCallAccept()
    func pressCallDecline()
    func pressCallHungup()
    func toggleFrontCamera()
    func toggleSpeaker()
    func toggleMicrophone()
    func pressOpenDoor(completion: ((Bool) -> Void)?)
    func proximityChange(value: Bool)
}

public protocol IncomingCallUIDataSource {
    var speakerEnabled: Bool { get }
    var micEnabled: Bool { get }
    var cameraEnabled: Bool { get }
    var openDoorEnabled: Bool { get }
    
    var currentCall: Call? { get }
    var currentPanelName: String? { get }
    var currentPanelId: Int? { get }
    
    var incomingVideoView: UIView? { get }
    var outgoingVideoView: UIView? { get }
}

