//
//  AuthRepository.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// 认证通知名称
extension Notification.Name {
    /// 认证失效通知（当 Token 过期时发送）
    static let authenticationInvalidated = Notification.Name("authenticationInvalidated")
}

/// 认证仓库（聚合 API 服务和 Token 管理）
///
/// 职责：
/// - 处理登录和登出流程
/// - 管理服务器配置和会话信息
/// - 为 ViewModel 提供简洁的数据访问接口
final class AuthRepository {

    // MARK: - 属性

    private let apiService: EmbyAPIService
    private let tokenManager: TokenManager
    private let keychain: KeychainManager

    /// Keychain 存储键
    private enum Key {
        static let serverConfig = "emby.server_config"
    }

    // MARK: - 初始化

    init(
        apiService: EmbyAPIService,
        tokenManager: TokenManager,
        keychain: KeychainManager
    ) {
        self.apiService = apiService
        self.tokenManager = tokenManager
        self.keychain = keychain
    }

    /// 便捷初始化（使用新的 KeychainManager 实例）
    convenience init(
        apiService: EmbyAPIService,
        tokenManager: TokenManager
    ) {
        self.init(apiService: apiService, tokenManager: tokenManager, keychain: KeychainManager())
    }

    // MARK: - 公共方法

    /// 登录
    /// - Parameters:
    ///   - serverURL: 服务器地址
    ///   - port: 端口号
    ///   - useHTTPS: 是否使用 HTTPS
    ///   - username: 用户名
    ///   - password: 密码
    /// - Returns: 认证响应
    func login(
        serverURL: String,
        port: Int,
        useHTTPS: Bool,
        username: String,
        password: String
    ) async throws -> EmbyAuthResponse {
        // 创建服务器配置
        let config = ServerConfig(
            serverURL: serverURL,
            port: port,
            useHTTPS: useHTTPS,
            username: username
        )

        // 创建新的 TokenManager 用于登录（避免使用旧的 token）
        let newTokenManager = TokenManager.create()

        // 创建 API 服务实例（使用新配置）
        let apiService = EmbyAPIService.create(config: config, tokenManager: newTokenManager)

        // 执行认证
        let response = try await apiService.authenticate(
            username: username,
            password: password
        )

        // 保存服务器配置
        try await keychain.save(config, for: Key.serverConfig)

        // 保存会话信息（使用新的 TokenManager）
        try await newTokenManager.saveSessionInfo(response.sessionInfo)

        return response
    }

    /// 登出
    func logout() async throws {
        // 清除会话信息
        try await tokenManager.clearSession()

        // 清除服务器配置
        try await keychain.delete(for: Key.serverConfig)
    }

    /// 处理认证失效（当 Token 过期时调用）
    func handleAuthenticationInvalidated() async {
        do {
            // 清除过期的认证信息
            try await logout()

            // 发送通知，通知所有监听者
            NotificationCenter.default.post(
                name: .authenticationInvalidated,
                object: nil
            )
        } catch {
            // 清除失败，静默处理
        }
    }

    /// 检查是否已登录
    /// - Returns: 是否已登录
    func isLoggedIn() async -> Bool {
        return await tokenManager.isLoggedIn()
    }

    /// 获取当前会话信息
    /// - Returns: 会话信息
    func getSessionInfo() async throws -> SessionInfo {
        return try await tokenManager.getSessionInfo()
    }

    /// 获取保存的服务器配置
    /// - Returns: 服务器配置
    func getServerConfig() async throws -> ServerConfig {
        return try await keychain.get(for: Key.serverConfig, as: ServerConfig.self)
    }

    /// 获取 API 服务实例（使用保存的配置）
    /// - Returns: API 服务
    /// - Throws: 如果未登录或没有服务器配置
    func getAPIService() async throws -> EmbyAPIService {
        let config = try await getServerConfig()
        return EmbyAPIService(
            baseURL: config.baseURL,
            tokenManager: tokenManager
        )
    }

    /// 检查并恢复会话
    /// - Returns: 如果会话有效则返回 API 服务，否则返回 nil
    func restoreSession() async -> EmbyAPIService? {
        guard await isLoggedIn() else {
            return nil
        }

        do {
            return try await getAPIService()
        } catch {
            return nil
        }
    }
}

// MARK: - 依赖注入

extension AuthRepository {
    /// 使用服务器配置创建实例
    static func create(config: ServerConfig) -> AuthRepository {
        let tokenManager = TokenManager.create()
        let apiService = EmbyAPIService.create(config: config, tokenManager: tokenManager)
        return AuthRepository(apiService: apiService, tokenManager: tokenManager)
    }

    /// 共享实例（单例）
    ///
    /// 注意：首次使用时需要配置，否则 API 服务将使用空 baseURL
    static let shared: AuthRepository = {
        let tokenManager = TokenManager.create()
        let apiService = EmbyAPIService(baseURL: "", tokenManager: tokenManager)
        return AuthRepository(apiService: apiService, tokenManager: tokenManager)
    }()
}
