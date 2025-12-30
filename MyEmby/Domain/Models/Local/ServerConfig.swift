//
//  ServerConfig.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// Emby 服务器配置模型
struct ServerConfig: Codable, Equatable {
    let serverURL: String
    let port: Int
    let useHTTPS: Bool
    let username: String

    /// 构建完整 Base URL
    var baseURL: String {
        let scheme = useHTTPS ? "https" : "http"
        return "\(scheme)://\(serverURL):\(port)"
    }

    /// 初始化方法
    init(serverURL: String, port: Int, useHTTPS: Bool, username: String) {
        self.serverURL = serverURL
        self.port = port
        self.useHTTPS = useHTTPS
        self.username = username
    }

    /// Codable 编码键
    enum CodingKeys: String, CodingKey {
        case serverURL = "server_url"
        case port
        case useHTTPS = "use_https"
        case username
    }
}
