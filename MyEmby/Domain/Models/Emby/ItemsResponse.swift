//
//  ItemsResponse.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// 媒体项列表响应（用于分页查询）
struct ItemsResponse: Codable, Equatable {
    /// 媒体项列表
    let items: [EmbyItem]

    /// 总记录数
    let totalRecordCount: Int?

    /// 起始索引
    let startIndex: Int?

    enum CodingKeys: String, CodingKey {
        case items = "Items"
        case totalRecordCount = "TotalRecordCount"
        case startIndex = "StartIndex"
    }
}

/// 媒体库视图响应（专门用于 /Views 端点）
struct ViewsResponse: Codable, Equatable {
    /// 媒体库视图列表
    let items: [EmbyItem]

    /// 总记录数
    let totalRecordCount: Int?

    enum CodingKeys: String, CodingKey {
        case items = "Items"
        case totalRecordCount = "TotalRecordCount"
    }
}
