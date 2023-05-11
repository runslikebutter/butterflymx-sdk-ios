//
//  TenantIntegrationModel.swift
//  BMXCore
//
//  Created by Yingtao on 6/1/21.
//  Copyright © 2021 ButterflyMX. All rights reserved.
//

struct TenantAllIntegrationsDataModel: Codable {
    var data: [TenantIntegrationModel]
}

struct TenantIntegrationDataModel: Codable {
    var data: TenantIntegrationModel
}

struct TenantIntegrationModel: Codable {
    var id: String
    var type: String
    var attributes: TenantIntegrationAttributes
}

struct TenantIntegrationAttributes: Codable {
    var config: TenantIntegrationAttributesConfig
}

struct TenantIntegrationAttributesConfig: Codable {
    var method: String
    var url: String
}
