//
//  SettingsViewModel.swift
//  MyEmby
//
//  Created by Claude on 2025/12/30.
//

import Foundation
import Observation

/// 设置视图模型
@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - 状态

    /// 用户信息
    var userInfo: EmbyUser?

    /// 服务器配置
    var serverConfig: ServerConfig?

    /// 是否正在登出
    var isLoggingOut = false

    // MARK: - 依赖

    private let authRepository: AuthRepository

    // MARK: - 初始化

    init(authRepository: AuthRepository = .shared) {
        self.authRepository = authRepository
    }

    // MARK: - 公共方法

    /// 加载用户和服务器信息
    func loadUserInfo() async {
        do {
            // 获取会话信息
            let sessionInfo = try await authRepository.getSessionInfo()

            // 获取用户信息
            let apiService = try await authRepository.getAPIService()
            userInfo = try await apiService.getUserInfo(userId: sessionInfo.userId)

            // 获取服务器配置
            serverConfig = try await authRepository.getServerConfig()

        } catch {
            // 加载失败，静默处理
        }
    }

    /// 登出
    func logout() async {
        isLoggingOut = true

        do {
            try await authRepository.logout()
        } catch {
            // 登出失败，静默处理
        }

        isLoggingOut = false
    }
}

// MARK: - 便捷扩展

extension SettingsViewModel {
    /// 用户显示名称
    var userDisplayName: String? {
        userInfo?.name
    }

    /// 服务器地址
    var serverAddress: String? {
        serverConfig?.serverURL
    }
}
