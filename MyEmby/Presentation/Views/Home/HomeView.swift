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
    @State private var viewModel: HomeViewModel

    /// 显示的分类列表（缓存，避免重复计算）
    @State private var displayedCategories: [EmbyItem] = []

    // MARK: - 初始化

    /// 创建首页视图
    /// - Parameter viewModel: 视图模型
    init(viewModel: HomeViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - 视图主体

    var body: some View {
        ZStack {
            // 背景色
//            Color.black.ignoresSafeArea()

            // 主内容
            contentView
        }
        .navigationTitle("首页")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // 只在首次加载时获取数据
            Task {
                await viewModel.loadDataIfNeeded()
                updateDisplayedCategories()
            }
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

        // 不提供 onItemClick，让 MediaRowView 使用 NavigationLink
        return MediaRowView(
            title: category.name,
            items: items,
            viewModel: viewModel,
            showSeeAllButton: true,
            onSeeAll: {
                // TODO: 实现分类详情页导航
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
}

// MARK: - 初始化和加载

extension HomeView {
    /// 更新显示的分类列表（缓存，避免重复计算）
    private func updateDisplayedCategories() {
        displayedCategories = viewModel.displayedCategories
    }
}

// MARK: - 预览

#Preview {
    HomeView(viewModel: HomeViewModel())
        .preferredColorScheme(.dark)
}

#Preview("模拟数据") {
    HomeView(viewModel: HomeViewModel.preview)
        .preferredColorScheme(.dark)
}
