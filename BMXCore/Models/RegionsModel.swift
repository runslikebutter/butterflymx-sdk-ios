//
//  RegionsModel.swift
//  BMXCore
//
//  Created by Sviatoslav Belmeha on 8/16/19.
//  Copyright © 2019 ButterflyMX. All rights reserved.
//

import Foundation

public enum RegionType: String, Decodable {
    case eu, na
}

class Regions: Decodable {
    let regions: [RegionType]
}
