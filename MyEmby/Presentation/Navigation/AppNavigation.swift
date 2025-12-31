//
//  AppNavigation.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import SwiftUI

/// 应用导航路由（用于页面跳转）
enum AppRoute: Codable, Hashable {
    /// 媒体详情页
    case mediaDetail(itemId: String)

    /// 播放器页面
    case player(itemId: String)

    /// 分类详情页
    case category(categoryId: String, categoryName: String)

    /// 设置页面
    case settings
}

/// 导航路径管理器
@Observable
@MainActor
final class NavigationManager {
    /// 单例
    static let shared = NavigationManager()

    /// 导航路径
    var path: NavigationPath = NavigationPath()

    /// 当前页面栈（用于调试）
    private var pageStack: [AppRoute] = []

    private init() {}

    /// 跳转到指定页面
    func push(_ route: AppRoute) {
        pageStack.append(route)
        path.append(route)
    }

    /// 返回上一页
    func goBack() {
        if !pageStack.isEmpty {
            pageStack.removeLast()
            path.removeLast()
        }
    }

    /// 返回到根页面
    func goToRoot() {
        pageStack.removeAll()
        path.removeLast(path.count)
    }

    /// 当前页面数量
    var currentPageCount: Int {
        pageStack.count
    }
}
