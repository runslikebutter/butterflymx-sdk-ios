//
//  CallStatus.swift
//  BMXCall
//
//  Created by Yingtao on 9/13/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

import Foundation

class CallStatus: Codable {
    class CallStatusDataAttributes: Codable {
        var status: String?
        var multiple_devices: Bool?
        var created_at: String?
    }
    
    class CallStatusData: Codable {
        var id: String?
        var type: String?
        var attributes: CallStatusDataAttributes?
    }
    
    class CallStatusIncluded: Codable {
        var attributes: CallStatusIncludedAttributes?
    }
    
    class CallStatusIncludedAttributes: Codable {
        var panel_name: String?
    }
    
    var data: CallStatusData?
    var included: [Call] = []
    
    var status: String {
        return data?.attributes?.status ?? ""
    }
    
    var multipleDevices: Bool {
        return data?.attributes?.multiple_devices ?? false
    }
    
    var panelName: String? {
        return included.first?.attributes?.panelName
    }
    
    var createdAt: String? {
        return data?.attributes?.created_at
    }
    
    static func getCallStatus(_ data: Data) throws -> CallStatus? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CallStatus.self, from: data)
    }
    
    static func getCall(_ data: Data) throws -> Call? {
        guard let callStatus = try getCallStatus(data) else {
            return nil
        }
        
        let call = callStatus.included.first
        call?.status = callStatus.status
        return call
    }
}

