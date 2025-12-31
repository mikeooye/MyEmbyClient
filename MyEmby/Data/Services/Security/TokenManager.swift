//
//  TokenManager.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// Token 管理器
///
/// 职责：
/// - 管理 Emby 访问令牌
/// - 存储和检索会话信息
/// - 提供 Token 有效性检查
actor TokenManager {
    
    static let shared = TokenManager()
    // MARK: - 属性

    /// Keychain 存储键
    private enum Key {
        static let accessToken = "emby.access_token"
        static let serverId = "emby.server_id"
        static let userId = "emby.user_id"
        static let username = "emby.username"
        static let sessionInfo = "emby.session_info"
        static let deviceId = "emby.device_id"
    }

    // MARK: - 初始化

    // MARK: - 公共方法

    /// 保存会话信息
    /// - Parameter sessionInfo: 会话信息
    func saveSessionInfo(_ sessionInfo: SessionInfo) async throws {
        try await KeychainManager.shared.save(sessionInfo, for: Key.sessionInfo)
    }

    /// 获取会话信息
    /// - Returns: 会话信息，如果不存在则返回 nil
    func getSessionInfo() async throws -> SessionInfo {
        try await KeychainManager.shared.get(for: Key.sessionInfo, as: SessionInfo.self)
    }

    /// 检查是否已登录
    /// - Returns: 是否有有效的会话信息
    func isLoggedIn() async -> Bool {
        do {
            _ = try await getSessionInfo()
            return true
        } catch {
            return false
        }
    }

    /// 获取访问令牌
    /// - Returns: 访问令牌
    /// - Throws: 如果未登录则抛出错误
    func getAccessToken() async throws -> String {
        let sessionInfo = try await getSessionInfo()
        return sessionInfo.accessToken
    }

    /// 获取用户 ID
    /// - Returns: 用户 ID
    /// - Throws: 如果未登录则抛出错误
    func getUserId() async throws -> String {
        let sessionInfo = try await getSessionInfo()
        return sessionInfo.userId
    }

    /// 获取服务器 ID
    /// - Returns: 服务器 ID
    /// - Throws: 如果未登录则抛出错误
    func getServerId() async throws -> String {
        let sessionInfo = try await getSessionInfo()
        return sessionInfo.serverId
    }

    /// 清除所有会话信息（登出）
    func clearSession() async throws {
        try await KeychainManager.shared.delete(for: Key.sessionInfo)
    }

    // MARK: - 便捷方法

    /// 获取认证头（用于 HTTP 请求）
    /// - Returns: Emby 认证头字符串
    /// - Throws: 如果未登录则抛出错误
    func getAuthHeader() async throws -> String {
        let sessionInfo = try await getSessionInfo()
      return await sessionInfo.authHeader
    }

    /// 获取 API 查询参数
    /// - Returns: 包含 api_key 的查询参数数组
    /// - Throws: 如果未登录则抛出错误
    func getAPIQueryItems() async throws -> [URLQueryItem] {
        let sessionInfo = try await getSessionInfo()
      return await sessionInfo.queryItems
    }

    /// 验证会话是否有效（可选实现）
    /// - Returns: 会话是否有效
    func validateSession() async -> Bool {
        // TODO: 可以添加额外的验证逻辑
        // 例如：检查 Token 是否过期、验证服务器连接等
        return await isLoggedIn()
    }
}

// MARK: - 错误处理

extension TokenManager {
    enum TokenError: Error, LocalizedError {
        case notLoggedIn
        case invalidSession
        case tokenExpired

        var errorDescription: String? {
            switch self {
            case .notLoggedIn:
                return "用户未登录"
            case .invalidSession:
                return "无效的会话信息"
            case .tokenExpired:
                return "访问令牌已过期"
            }
        }
    }
}
