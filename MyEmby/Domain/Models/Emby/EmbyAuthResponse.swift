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
    var sessionInfo: SessionInfo {
        SessionInfo(
            accessToken: accessToken,
            serverId: serverId,
            userId: user.id,
            username: user.name
        )
    }
}

/// 会话信息（用于简化使用）
struct SessionInfo: Codable, Equatable {
    let accessToken: String
    let serverId: String
    let userId: String
    let username: String

    /// 认证头（Bearer Token）
    var authHeader: String {
        "MediaBrowser Client=\"MyEmby\", Device=\"iOS\", DeviceId=\"\(deviceId)\", Token=\"\(accessToken)\""
    }

    /// 生成设备 ID（基于设备唯一标识）
    private var deviceId: String {
        // TODO: 从 UserDefaults 或 Keychain 获取持久化设备 ID
        // 临时使用 UIDevice.current.identifierForVendor
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
        #else
        return "ios-device"
        #endif
    }

    /// URL 查询参数
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "api_key", value: accessToken)
        ]
    }
}
