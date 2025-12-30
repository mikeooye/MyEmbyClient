//
//  HomeView.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// 首页视图（显示各分类的最新媒体）
struct HomeView: View {
    // MARK: - 属性

    /// 视图模型
    @State private var viewModel = HomeViewModel()

    /// 显示的分类列表（缓存，避免重复计算）
    @State private var displayedCategories: [EmbyItem] = []

    /// 导航管理器
    @State private var navigationManager = NavigationManager.shared

    // MARK: - 视图主体

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            ZStack {
                // 背景色
//                Color.black.ignoresSafeArea()

                // 主内容
                contentView
            }
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .navigationTitle("首页")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    userAvatarButton
                }
            }
        }
        .onAppear {
            // 视图出现时加载数据
            onAppear()
        }
        .onChange(of: viewModel.libraryViews) { _, _ in
            // 当分类列表更新时，更新缓存的显示列表
            updateDisplayedCategories()
        }
        .onChange(of: viewModel.latestItemsByCategory) { _, _ in
            // 当媒体项更新时，更新缓存的显示列表
            updateDisplayedCategories()
        }
    }

    // MARK: - 子视图

    /// 主内容视图
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.libraryViews.isEmpty {
            // 首次加载状态
            loadingView
        } else if let errorMessage = viewModel.errorMessage, !viewModel.hasData {
            // 错误状态
            errorView(message: errorMessage)
        } else if viewModel.shouldShowEmptyState {
            // 空状态
            emptyStateView
        } else {
            // 主内容（滚动视图）
            ScrollView {
                LazyVStack(spacing: 24) {
                    // 遍历所有分类（使用缓存的列表，避免重复计算）
                    ForEach(displayedCategories) { category in
                        categorySection(for: category)
                    }
                }
                .padding(.vertical, 16)
            }
            .refreshable {
                // 下拉刷新
                await viewModel.refresh()
            }
        }
    }

    /// 分类部分
    private func categorySection(for category: EmbyItem) -> some View {
        let items = viewModel.latestItems(for: category.id)

        // ⚡️ 直接传递 viewModel，避免闭包传递问题
        return MediaRowView(
            title: category.name,
            items: items,
            viewModel: viewModel,
            showSeeAllButton: true,
            onSeeAll: {
                // 跳转到分类详情页
                NavigationManager.shared.push(.category(
                    categoryId: category.id,
                    categoryName: category.name
                ))
            },
            onItemClick: { item in
                // 跳转到媒体详情页
                NavigationManager.shared.push(.mediaDetail(itemId: item.id))
            }
        )
    }

    /// 加载视图
    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("加载中...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// 错误视图
    private func errorView(message: String) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)

                Text("加载失败")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    Task {
                        await viewModel.loadData()
                    }
                }) {
                    Text("重试")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    /// 空状态视图
    private var emptyStateView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "film.stack")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)

                Text("暂无内容")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("请联系管理员添加媒体库")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// 用户头像按钮
    private var userAvatarButton: some View {
        Button(action: {
            // TODO: 显示用户设置菜单
            print("显示用户菜单")
        }) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
        }
    }
}

// MARK: - 初始化和加载

extension HomeView {
    /// 视图出现时加载数据
    func onAppear() {
        Task {
            await viewModel.loadData()
            // 数据加载完成后，更新缓存的显示列表
            updateDisplayedCategories()
        }
    }

    /// 更新显示的分类列表（缓存，避免重复计算）
    private func updateDisplayedCategories() {
        displayedCategories = viewModel.displayedCategories
    }
}

// MARK: - 导航处理

extension HomeView {
    /// 根据路由返回目标视图
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .mediaDetail(let itemId):
            MediaDetailView(itemId: itemId)
        case .category(let categoryId, let categoryName):
            // TODO: 创建分类详情页
            Text("分类详情页: \(categoryName)")
                .navigationTitle(categoryName)
        case .player(let itemId):
            // TODO: 创建播放器页面
            Text("播放器: \(itemId)")
        case .settings:
            // TODO: 创建设置页面
            Text("设置")
        }
    }
}

// MARK: - 预览

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}

#Preview("模拟数据") {
    HomeView()
        .environment(\.colorScheme, .dark)
        .onAppear {
            // 使用预览数据
            let viewModel = HomeViewModel.preview
            // TODO: 注入预览数据到视图
            _ = viewModel
        }
}
