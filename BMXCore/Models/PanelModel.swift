//
//  PanelModel.swift
//  BMXCore
//
//  Created by Sviatoslav Belmeha on 4/3/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation
import Japx

@available(*, deprecated, message: "use DeviceModel instead")
public struct PanelModel: JapxCodable {
    public let type: String
    public let id: String

    public let name: String?
}

public struct DeviceModel: JapxCodable {
    public let type: String
    public let id: String

    public let name: String?
}
