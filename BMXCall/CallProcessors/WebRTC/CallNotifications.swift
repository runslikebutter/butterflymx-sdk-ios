//
//  XMPPMessage.swift
//  ButterflyMXSDK
//
//  Created by Zhe Cui on 10/10/18.
//  Copyright © 2018 ButterflyMX. All rights reserved.
//

import Foundation
import BMXCore

@objc
class CallNotifications: NSObject {
    
    class func sendCallAccepted(guid: String, panelId: Int, video: Bool, audio: Bool) {
        BMXCoreKit.shared.log(message: "Send call accepted")

        let params = [
            "data": [
                "type": "notifications",
                "id": "\(panelId)",
                "attributes": [
                    "panel_id": panelId,
                    "video": video,
                    "audio": audio,
                    "call_guid": guid
                ]
            ]
        ]

        APIClient.sendRequest(
            path: "notifications/call_accepted",
            params: params,
            method: .post) { res in
                switch res {
                case .success:
                    BMXCoreKit.shared.log(message: "Message delivered: \(guid)")
                case .failure(let error):
                    BMXCoreKit.shared.log(message: "Error \(error.localizedDescription) delivering message: \(guid)")
                }
        }
    }
    
    class func sendIsActive(guid: String, panelId: Int) {
        BMXCoreKit.shared.log(message: "Send IsActive")

        let params = [
            "data": [
                "type": "notifications",
                "id": "\(panelId)",
                "attributes": [
                    "panel_id" : panelId,
                    "call_guid" : guid
                ]
            ]
        ]

        APIClient.sendRequest(
            path: "notifications/is_active",
            params: params,
            method: .post) { res in
                switch res {
                case .success:
                    BMXCoreKit.shared.log(message: "Message delivered: \(guid)")
                case .failure(let error):
                    BMXCoreKit.shared.log(message: "Error \(error.localizedDescription) delivering message: \(guid)")
                }
            }
    }
    
    class func sendToggleCamera(guid: String, panelId: Int, video: Bool, audio: Bool) {
        BMXCoreKit.shared.log(message: "Send Toggle Camera")

        let params = [
            "data": [
                "type": "notifications",
                "id": "\(panelId)",
                "attributes": [
                    "panel_id": panelId,
                    "video": video,
                    "audio": audio,
                    "call_guid": guid
                ]
            ]
        ]

        APIClient.sendRequest(
            path: "notifications/toggle_camera",
            params: params,
            method: .post) { res in
                switch res {
                case .success:
                    BMXCoreKit.shared.log(message: "Message delivered: \(guid)")
                case .failure(let error):
                    BMXCoreKit.shared.log(message: "Error \(error.localizedDescription) delivering message: \(guid)")
                }
        }
    }

    class func sendOpenDoor(guid: String, panelId: Int, completion: ((Bool) -> Void)? = nil) {
        BMXCoreKit.shared.log(message: "Send open door")

        let params = [
            "data": [
                "type": "notifications",
                "id": "\(panelId)",
                "attributes": [
                    "panel_id": panelId,
                    "call_guid": guid
                ]
            ]
        ]

        APIClient.sendRequest(
            path: "notifications/open_door",
            params: params,
            method: .post) { res in
                switch res {
                case .success:
                    BMXCoreKit.shared.log(message: "Message delivered: \(guid)")
                    completion?(true)
                case .failure(let error):
                    BMXCoreKit.shared.log(message: "Error \(error.localizedDescription) delivering message: \(guid)")
                    completion?(false)
                }
        }
    }

    class func sendCallEnded(guid: String, panelId: Int, completion: (() -> Void)? = nil) {
        BMXCoreKit.shared.log(message: "Send CallEnded")

        let params = [
            "data": [
                "type": "notifications",
                "id": "\(panelId)",
                "attributes": [
                    "panel_id": panelId,
                    "call_guid": guid
                ]
            ]
        ]

        APIClient.sendRequest(
            path: "notifications/call_ended",
            params: params,
            method: .post) { res in
                switch res {
                case .success:
                    BMXCoreKit.shared.log(message: "Message delivered: \(guid)")
                case .failure(let error):
                    BMXCoreKit.shared.log(message: "Error \(error.localizedDescription) delivering message: \(guid)")
                }
                completion?()
        }
    }
    
}
