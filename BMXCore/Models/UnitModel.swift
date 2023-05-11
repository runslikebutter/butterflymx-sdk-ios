//
//  UnitModel.swift
//  BMXCore
//
//  Created by Sviatoslav Belmeha on 4/3/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation
import Japx

public struct UnitModel: JapxCodable {
    public var type: String
    public let id: String
    
    public let unitType: String?
    public let label: String?
}
