//
//  AuthViewModel.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation

/// 认证视图模型（使用 iOS 17+ Observation 框架）
@Observable
final class AuthViewModel {

    // MARK: - 状态

    /// 登录表单
    var loginForm = LoginForm()

    /// 加载状态
    var isLoading = false

    /// 错误信息
    var errorMessage: String?

    /// 登录是否成功
    var isAuthenticated = false

    // MARK: - 依赖

    private let authRepository: AuthRepository

    // MARK: - 初始化

    init(authRepository: AuthRepository = .shared) {
        self.authRepository = authRepository

        // Task 中异步检查登录状态
        Task {
            isAuthenticated = await authRepository.isLoggedIn()
        }
    }

    // MARK: - 公共方法

    /// 登录
    func login() async {
        // 重置错误信息
        errorMessage = nil

        // 验证表单
        guard validateForm() else {
            return
        }

        // 设置加载状态
        isLoading = true

        do {
            // 执行登录
            _ = try await authRepository.login(
                serverURL: loginForm.serverURL,
                port: loginForm.port,
                useHTTPS: loginForm.useHTTPS,
                username: loginForm.username,
                password: loginForm.password
            )

            // 更新状态
            isAuthenticated = true
            isLoading = false

        } catch let error as NetworkError {
            // 处理网络错误
            isLoading = false
            errorMessage = error.alertMessage

        } catch {
            // 处理其他错误
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    /// 登出
    func logout() async {
        do {
            try await authRepository.logout()
            isAuthenticated = false

            // 重置表单
            loginForm = LoginForm()
        } catch {
            // 登出失败，静默处理
        }
    }

    /// 检查登录状态
    func checkAuthStatus() async -> Bool {
        isAuthenticated = await authRepository.isLoggedIn()
        return isAuthenticated
    }

    // MARK: - 私有方法

    /// 验证表单
    /// - Returns: 是否有效
    private func validateForm() -> Bool {
        // 验证服务器地址
        guard !loginForm.serverURL.isEmpty else {
            errorMessage = "请输入服务器地址"
            return false
        }

        // 验证端口号
        guard loginForm.port > 0 && loginForm.port <= 65535 else {
            errorMessage = "端口号必须在 1-65535 之间"
            return false
        }

        // 验证用户名
        guard !loginForm.username.isEmpty else {
            errorMessage = "请输入用户名"
            return false
        }

        // 验证密码
        guard !loginForm.password.isEmpty else {
            errorMessage = "请输入密码"
            return false
        }

        return true
    }
}

// MARK: - 登录表单模型

/// 登录表单数据模型
struct LoginForm {
    var serverURL: String = "emby.hutaoindex.com"
    var port: Int = 443
    var useHTTPS: Bool = true
    var username: String = ""
    var password: String = ""

    /// 验证表单是否有效
    var isValid: Bool {
        !serverURL.isEmpty &&
        port > 0 && port <= 65535 &&
        !username.isEmpty &&
        !password.isEmpty
    }
}

// MARK: - 预览辅助

#if DEBUG
extension AuthViewModel {
    /// 创建预览用的 ViewModel（带模拟数据）
    static var preview: AuthViewModel {
        let viewModel = AuthViewModel(authRepository: .shared)
        viewModel.loginForm = LoginForm(
            serverURL: "192.168.1.100",
            port: 8096,
            useHTTPS: false,
            username: "admin",
            password: ""
        )
        return viewModel
    }
}
#endif
