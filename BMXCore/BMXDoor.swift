//
//  BMXDoor.swift
//  ButterflyMXSDK
//
//  Created by Sviatoslav Belmeha on 1/24/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation

public class BMXDoor {

    public static let shared = BMXDoor()

    public enum OpenDoorMethod: String {
        case frontDoorView = "front_door_view"
        case bluetooth = "bluetooth"
    }

    private init() {}

    public func openDoor(panel: PanelModel, tenant: TenantModel, method: OpenDoorMethod = .frontDoorView, completion: @escaping (Result<Void, ServiceError>) -> Void) {
        guard tenant.isOpenDoorEnabled == true, let unitId = tenant.unit?.id else {
            completion(.failure(.unableToCreateRequest(message: "No door locks available")))
            return
        }

        BMXCoreKit.shared.log(message: "Open door with panelID=\(panel.id), unitID=\(unitId), method=\(method.rawValue)")

        APIClient.doorReleaseRequest(panel.id, unitID: unitId, method: method.rawValue, successHandler: { data in
            completion(.success(()))
        }) { error in
            completion(.failure(.runtime(error: error)))
        }
    }
    
    public func openDoor(device: DeviceModel, tenant: TenantModel, method: OpenDoorMethod = .frontDoorView, completion: @escaping (Result<Void, ServiceError>) -> Void) {
        guard tenant.isOpenDoorEnabled == true, let unitId = tenant.unit?.id else {
            completion(.failure(.unableToCreateRequest(message: "No door locks available")))
            return
        }

        BMXCoreKit.shared.log(message: "Open door with device=\(device.id), unitID=\(unitId), method=\(method.rawValue)")

        APIClient.doorReleaseRequest(device, unitID: unitId, method: method.rawValue, successHandler: { data in
            completion(.success(()))
        }) { error in
            completion(.failure(.runtime(error: error)))
        }
    }

}
