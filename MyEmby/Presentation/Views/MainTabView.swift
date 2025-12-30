//
//  MainTabView.swift
//  MyEmby
//
//  Created by Claude on 2025/12/30.
//

import SwiftUI

/// 主标签栏视图
///
/// 包含 4 个标签页：
/// - 首页
/// - 继续播放
/// - 收藏
/// - 设置
struct MainTabView: View {
    // MARK: - 属性

    /// 当前选中的标签索引
    @State private var selectedTab = 0

    // MARK: - ViewModels（使用 @State 保持状态）

    /// 首页视图模型
    @State private var homeViewModel = HomeViewModel()

    /// 继续播放视图模型
    @State private var continueWatchingViewModel = ContinueWatchingViewModel()

    /// 收藏视图模型
    @State private var favoritesViewModel = FavoritesViewModel()

    // MARK: - 视图主体

    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页
            NavigationStack(path: $homePath) {
                HomeView(viewModel: homeViewModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        homeDestinationView(for: route)
                    }
            }
            .tabItem {
                Label("首页", systemImage: selectedTab == 0 ? "house.fill" : "house")
            }
            .tag(0)

            // 继续播放
            NavigationStack(path: $continueWatchingPath) {
                ContinueWatchingContent(viewModel: continueWatchingViewModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        continueWatchingDestinationView(for: route)
                    }
            }
            .tabItem {
                Label("继续播放", systemImage: selectedTab == 1 ? "play.circle.fill" : "play.circle")
            }
            .tag(1)

            // 收藏
            NavigationStack(path: $favoritesPath) {
                FavoritesContent(viewModel: favoritesViewModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        favoritesDestinationView(for: route)
                    }
            }
            .tabItem {
                Label("收藏", systemImage: selectedTab == 2 ? "heart.fill" : "heart")
            }
            .tag(2)

            // 设置
            NavigationStack {
                SettingsContent()
            }
            .tabItem {
                Label("设置", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
            }
            .tag(3)
        }
        .tint(.blue)
    }

    // MARK: - 导航路径

    @State private var homePath = NavigationPath()
    @State private var continueWatchingPath = NavigationPath()
    @State private var favoritesPath = NavigationPath()

    // MARK: - 导航处理

    @ViewBuilder
    private func homeDestinationView(for route: AppRoute) -> some View {
        switch route {
        case .mediaDetail(let itemId):
            MediaDetailView(itemId: itemId)
        case .category(let categoryId, let categoryName):
            Text("分类详情页: \(categoryName)")
                .navigationTitle(categoryName)
        case .player(let itemId):
            Text("播放器: \(itemId)")
        case .settings:
            Text("设置")
        }
    }

    @ViewBuilder
    private func continueWatchingDestinationView(for route: AppRoute) -> some View {
        switch route {
        case .mediaDetail(let itemId):
            MediaDetailView(itemId: itemId)
        case .category(let categoryId, let categoryName):
            Text("分类详情页: \(categoryName)")
                .navigationTitle(categoryName)
        case .player(let itemId):
            Text("播放器: \(itemId)")
        case .settings:
            Text("设置")
        }
    }

    @ViewBuilder
    private func favoritesDestinationView(for route: AppRoute) -> some View {
        switch route {
        case .mediaDetail(let itemId):
            MediaDetailView(itemId: itemId)
        case .category(let categoryId, let categoryName):
            Text("分类详情页: \(categoryName)")
                .navigationTitle(categoryName)
        case .player(let itemId):
            Text("播放器: \(itemId)")
        case .settings:
            Text("设置")
        }
    }
}

// MARK: - 继续播放内容（不含 NavigationStack）

struct ContinueWatchingContent: View {
    @State private var viewModel: ContinueWatchingViewModel

    /// 创建继续播放视图
    /// - Parameter viewModel: 视图模型
    init(viewModel: ContinueWatchingViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            } else if viewModel.hasContent {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(viewModel.items) { item in
                            NavigationLink(value: AppRoute.mediaDetail(itemId: item.id)) {
                                MediaCardView(
                                    item: item,
                                    imageURL: viewModel.getImageURL(for: item.id),
                                    width: (UIScreen.main.bounds.width - 60) / 2,
                                    height: ((UIScreen.main.bounds.width - 60) / 2) * 1.5,
                                    showTitle: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
                .background(Color.white)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("没有继续播放的内容")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("开始观看视频后，它们会出现在这里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
        }
        .navigationTitle("继续播放")
        .onAppear {
            // 只在首次加载时获取数据
            Task {
                await viewModel.loadDataIfNeeded()
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - 收藏内容（不含 NavigationStack）

struct FavoritesContent: View {
    @State private var viewModel: FavoritesViewModel

    /// 创建收藏视图
    /// - Parameter viewModel: 视图模型
    init(viewModel: FavoritesViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            } else if viewModel.hasContent {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(viewModel.items) { item in
                            NavigationLink(value: AppRoute.mediaDetail(itemId: item.id)) {
                                MediaCardView(
                                    item: item,
                                    imageURL: viewModel.getImageURL(for: item.id),
                                    width: (UIScreen.main.bounds.width - 60) / 2,
                                    height: ((UIScreen.main.bounds.width - 60) / 2) * 1.5,
                                    showTitle: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
                .background(Color.white)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("还没有收藏")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("点击媒体详情页的收藏按钮，将喜欢的内容添加到这里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
        }
        .navigationTitle("收藏")
        .onAppear {
            // 只在首次加载时获取数据
            Task {
                await viewModel.loadDataIfNeeded()
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - 设置内容（不含 NavigationStack）

struct SettingsContent: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            // 用户信息区
            if let userName = viewModel.userDisplayName {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName)
                                .font(.headline)
                                .foregroundColor(.primary)

                            if let serverAddress = viewModel.serverAddress {
                                Text(serverAddress)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }

            // 通用设置
            Section("通用") {
                HStack {
                    Label("主题", systemImage: "paintbrush")
                    Spacer()
                    Text("跟随系统")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Label("语言", systemImage: "globe")
                    Spacer()
                    Text("简体中文")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // 关于
            Section("关于") {
                HStack {
                    Label("版本", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // 登出
            Section {
                Button(action: {
                    Task {
                        await viewModel.logout()
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isLoggingOut {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("退出登录")
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isLoggingOut)
            }
        }
        .navigationTitle("设置")
        .task {
            await viewModel.loadUserInfo()
        }
        .alert("退出登录", isPresented: .constant(false)) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                Task {
                    await viewModel.logout()
                }
            }
        } message: {
            Text("确定要退出登录吗？")
        }
    }
}

// MARK: - 预览

#Preview {
    MainTabView()
}
