//
//  MediaRowView.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// 媒体行视图（横向滚动的媒体列表）
struct MediaRowView: View {
    // MARK: - 属性

    /// 行标题
    let title: String

    /// 媒体项列表
    let items: [EmbyItem]

    /// 首页视图模型（用于获取图片 URL）
    let viewModel: HomeViewModel

    /// 是否显示"查看全部"按钮
    var showSeeAllButton: Bool = true

    /// 查看全部回调
    var onSeeAll: (() -> Void)?

    /// 点击媒体项回调
    var onItemClick: ((EmbyItem) -> Void)?

    /// 加载状态
    @State private var isLoading = false

    // MARK: - 初始化

    /// 创建媒体行视图
    /// - Parameters:
    ///   - title: 行标题
    ///   - items: 媒体项列表
    ///   - viewModel: 首页视图模型
    ///   - showSeeAllButton: 是否显示"查看全部"按钮
    ///   - onSeeAll: 查看全部回调
    ///   - onItemClick: 点击媒体项回调（可选，如果不提供则使用 NavigationLink）
    init(
        title: String,
        items: [EmbyItem],
        viewModel: HomeViewModel,
        showSeeAllButton: Bool = true,
        onSeeAll: (() -> Void)? = nil,
        onItemClick: ((EmbyItem) -> Void)? = nil
    ) {
        self.title = title
        self.items = items
        self.viewModel = viewModel
        self.showSeeAllButton = showSeeAllButton
        self.onSeeAll = onSeeAll
        self.onItemClick = onItemClick
    }

    // MARK: - 视图主体

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            headerSection

            // 媒体项列表（横向滚动）
            mediaItemsSection
        }
        .padding(.horizontal)
    }

    // MARK: - 子视图

    /// 标题栏
    private var headerSection: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)

            Spacer()

            if showSeeAllButton {
                Button(action: {
                    onSeeAll?()
                }) {
                    Text("查看全部")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    /// 媒体项列表
    private var mediaItemsSection: some View {
        Group {
            if items.isEmpty {
                // 空状态
                emptyStateView
            } else {
                // 横向滚动列表
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(items) { item in
                            AsyncMediaCard(
                                item: item,
                                viewModel: viewModel,
                                onItemClick: onItemClick
                            )
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "film")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))

            Text("暂无内容")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 异步媒体卡片

/// 异步加载图片的媒体卡片
private struct AsyncMediaCard: View {
    /// 媒体项
    @State var item: EmbyItem

    /// 首页视图模型（用于获取图片 URL）
    @State var viewModel: HomeViewModel

    /// 点击回调（可选，如果不提供则使用 NavigationLink）
    let onItemClick: ((EmbyItem) -> Void)?

    /// 图片 URL
    @State private var imageURL: URL?

    var body: some View {
        Group {
            if let onItemClick = onItemClick {
                // 使用点击回调方式
                MediaCardView(
                    item: item,
                    imageURL: imageURL,
                    onTap: {
                        onItemClick(item)
                    }
                )
            } else {
                // 使用 NavigationLink 方式
                NavigationLink(value: AppRoute.mediaDetail(itemId: item.id)) {
                    MediaCardView(
                        item: item,
                        imageURL: imageURL,
                        onTap: nil  // 不使用 onTap，让 NavigationLink 处理
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .task(id: item.id) {
            // 加载图片
            do {
                imageURL = try await viewModel.getImageURL(for: item.id)
            } catch {
                // 加载失败，静默处理
            }
        }
    }
}

// MARK: - 预览

#Preview {
    VStack(spacing: 20) {
        // 示例 1: 电影列表
        MediaRowView(
            title: "最新电影",
            items: [
                EmbyItem(
                    id: "1",
                    name: "奥本海默",
                    originalTitle: "Oppenheimer",
                    type: "Movie",
                    collectionType: nil,
                    parentId: nil,
                    seriesName: nil,
                    seasonId: nil,
                    seasonNumber: nil,
                    indexNumber: nil,
                    episodeCount: nil,
                    premiereDate: Date(),
                    endDate: nil,
                    productionYear: 2023,
                    communityRating: 8.9,
                    userData: nil,
                    overview: nil,
                    tags: nil,
                    genres: ["Drama", "History"],
                    studios: nil,
                    people: nil,
                    runTimeTicks: nil,
                    imageTags: nil,
                    backdropImageTags: nil,
                    poster: nil,
                    logoImagePath: nil,
                    mediaSources: nil,
                    isLive: false,
                    path: nil,
                    preferredMetadataLanguage: nil,
                    preferredMetadataCountryCode: nil
                ),
                EmbyItem(
                    id: "2",
                    name: "芭比",
                    originalTitle: "Barbie",
                    type: "Movie",
                    collectionType: nil,
                    parentId: nil,
                    seriesName: nil,
                    seasonId: nil,
                    seasonNumber: nil,
                    indexNumber: nil,
                    episodeCount: nil,
                    premiereDate: Date(),
                    endDate: nil,
                    productionYear: 2023,
                    communityRating: 7.8,
                    userData: nil,
                    overview: nil,
                    tags: nil,
                    genres: ["Comedy", "Fantasy"],
                    studios: nil,
                    people: nil,
                    runTimeTicks: nil,
                    imageTags: nil,
                    backdropImageTags: nil,
                    poster: nil,
                    logoImagePath: nil,
                    mediaSources: nil,
                    isLive: false,
                    path: nil,
                    preferredMetadataLanguage: nil,
                    preferredMetadataCountryCode: nil
                ),
                EmbyItem(
                    id: "3",
                    name: "星际特工",
                    originalTitle: "Valerian",
                    type: "Movie",
                    collectionType: nil,
                    parentId: nil,
                    seriesName: nil,
                    seasonId: nil,
                    seasonNumber: nil,
                    indexNumber: nil,
                    episodeCount: nil,
                    premiereDate: Date(),
                    endDate: nil,
                    productionYear: 2017,
                    communityRating: 6.8,
                    userData: nil,
                    overview: nil,
                    tags: nil,
                    genres: ["Action", "Adventure"],
                    studios: nil,
                    people: nil,
                    runTimeTicks: nil,
                    imageTags: nil,
                    backdropImageTags: nil,
                    poster: nil,
                    logoImagePath: nil,
                    mediaSources: nil,
                    isLive: false,
                    path: nil,
                    preferredMetadataLanguage: nil,
                    preferredMetadataCountryCode: nil
                )
            ],
            viewModel: HomeViewModel.preview,
            onItemClick: { _ in }
        )

        // 示例 2: 电视剧列表
        MediaRowView(
            title: "最新剧集",
            items: [
                EmbyItem(
                    id: "4",
                    name: "最后生还者",
                    originalTitle: "The Last of Us",
                    type: "Episode",
                    collectionType: nil,
                    parentId: "series1",
                    seriesName: "The Last of Us",
                    seasonId: "s1",
                    seasonNumber: 1,
                    indexNumber: 1,
                    episodeCount: nil,
                    premiereDate: Date(),
                    endDate: nil,
                    productionYear: 2023,
                    communityRating: 9.0,
                    userData: nil,
                    overview: nil,
                    tags: nil,
                    genres: ["Drama"],
                    studios: nil,
                    people: nil,
                    runTimeTicks: nil,
                    imageTags: nil,
                    backdropImageTags: nil,
                    poster: nil,
                    logoImagePath: nil,
                    mediaSources: nil,
                    isLive: false,
                    path: nil,
                    preferredMetadataLanguage: nil,
                    preferredMetadataCountryCode: nil
                )
            ],
            viewModel: HomeViewModel.preview,
            onItemClick: { _ in }
        )

        // 示例 3: 空列表
        MediaRowView(
            title: "即将推出",
            items: [],
            viewModel: HomeViewModel.preview,
            onItemClick: { _ in }
        )
    }
    .background(Color.gray.opacity(0.1))
}
