//
//  AppRootBuilder.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// 应用根视图构建器
///
/// 职责：
/// - 检查登录状态
/// - 决定显示登录页面还是主页面
/// - 管理应用的路由逻辑
struct AppRootBuilder: View {

    @State private var authViewModel = AuthViewModel()
    @State private var hasCheckedInitialStatus = false

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // 显示主界面（TabBar）
                MainTabView()
            } else {
                // 登录页面（共享同一个 authViewModel）
                LoginView(viewModel: authViewModel)
                    .task {
                        // 只在首次显示时检查登录状态
                        if !hasCheckedInitialStatus {
                            hasCheckedInitialStatus = true
                            _ = await authViewModel.checkAuthStatus()
                        }
                    }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    AppRootBuilder()
}
