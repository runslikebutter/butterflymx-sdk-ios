//
//  Tenant.swift
//  BMXCore
//
//  Created by Sviatoslav Belmeha on 31.10.2019.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Japx

public struct TenantModel: JapxCodable {
    public var id: String
    public var type: String

    public let unit: UnitModel?
    public let panels: [PanelModel]?
    public let devices: [DeviceModel]?
    public let building: BuildingModel?

    public var isOpenDoorEnabled: Bool {
        return building?.openDoorButtonEnabled ?? false
    }
}
