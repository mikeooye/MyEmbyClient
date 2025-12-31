//
//  EmbyAuthResponse.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import UIKit

/// Emby 认证响应模型
struct EmbyAuthResponse: Codable, Equatable {
    let accessToken: String
    let serverId: String
    let user: EmbyUser

    /// Codable 编码键
    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case serverId = "ServerId"
        case user = "User"
    }

    /// 计算属性：会话信息
    func getSessionInfo() async -> SessionInfo {
        let deviceId = await DeviceManager.shared.getOrCreateDeviceId()
        return SessionInfo(
            accessToken: accessToken,
            serverId: serverId,
            userId: user.id,
            username: user.name,
            deviceId: deviceId
        )
    }
}

/// 会话信息（用于简化使用）
struct SessionInfo: Codable, Equatable, Sendable {
    let accessToken: String
    let serverId: String
    let userId: String
    let username: String
    let deviceId: String

    /// 认证头（Bearer Token）
    var authHeader: String {
        "MediaBrowser Client=\"MyEmby\", Device=\"iOS\", DeviceId=\"\(deviceId)\", Token=\"\(accessToken)\""
    }

    /// URL 查询参数
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "api_key", value: accessToken)
        ]
    }
}
