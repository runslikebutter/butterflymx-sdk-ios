//
//  BuildingModel.swift
//  BMXCore
//
//  Created by Sviatoslav Belmeha on 4/4/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation
import Japx

public struct BuildingModel: JapxCodable {
    public let id: String
    public let type: String

    public let openDoorButtonEnabled: Bool
}
