//
//  CallStatesAndEvents.swift
//  BMXCall
//
//  Created by Yingtao on 9/13/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

import Foundation

enum CallState {
    case receivedPushNotification
    case accepted
    case ongoing
    case idle
}

enum CallOrUserEvent {
    case callDialing
    
    case userAcceptsCall
    case callConnected
    case callDisconnected
    case callRejected
    case userHangsupCall
    case userDeclinesCall
    
    case callAnsweredByOthers
    case callCanceledByCaller
    case participantDidDisconnect
    case openedDoor
}
