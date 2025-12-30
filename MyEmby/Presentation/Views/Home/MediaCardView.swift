//
//  MediaCardView.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// 媒体卡片视图（显示单个媒体项的封面和信息）
struct MediaCardView: View {
    // MARK: - 属性

    /// 媒体项
    let item: EmbyItem

    /// 图片 URL（可选，如果为 nil 则使用 item.id 生成）
    let imageURL: URL?

    /// 卡片宽度
    let width: CGFloat

    /// 卡片高度
    let height: CGFloat

    /// 是否显示标题
    var showTitle: Bool = true

    /// 点击回调
    var onTap: (() -> Void)?

    // MARK: - 初始化

    /// 创建媒体卡片
    /// - Parameters:
    ///   - item: 媒体项
    ///   - imageURL: 图片 URL（可选）
    ///   - width: 卡片宽度
    ///   - height: 卡片高度
    ///   - showTitle: 是否显示标题
    ///   - onTap: 点击回调
    init(
        item: EmbyItem,
        imageURL: URL? = nil,
        width: CGFloat = 120,
        height: CGFloat = 180,
        showTitle: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.item = item
        self.imageURL = imageURL
        self.width = width
        self.height = height
        self.showTitle = showTitle
        self.onTap = onTap
    }

    // MARK: - 视图主体

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面图片
            imageSection

            // 标题
            if showTitle {
                titleSection
            }
        }
        .frame(width: width)
        .onTapGesture {
            onTap?()
        }
    }

    // MARK: - 子视图

    /// 图片部分
    private var imageSection: some View {
        RemoteImageView(
            url: imageURL,
            targetSize: CGSize(width: width, height: height),
            placeholder: {
                ZStack {
                    Color.yellow.opacity(0.3)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            },
            errorView: {
                ZStack {
                    Color.yellow.opacity(0.3)
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
            }
        )
        .frame(width: width, height: height)
        .cornerRadius(8)
        .shadow(radius: 4)
        .overlay(
            // 播放进度条（如果有）
            playbackProgressOverlay,
            alignment: .bottom
        )
        .overlay(
            // 收藏标记（如果已收藏）
            favoriteBadge,
            alignment: .topTrailing
        )
    }

    /// 标题部分
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(.primary)

            // 显示年份或集数
            if let year = item.productionYear {
                Text("\(year)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else if let episodeNumber = item.indexNumber {
                if let seasonNumber = item.seasonNumber {
                    Text("S\(seasonNumber) E\(episodeNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Episode \(episodeNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: width, alignment: .leading)
    }

    /// 播放进度覆盖层
    private var playbackProgressOverlay: some View {
        Group {
            if item.playedPercentage > 0 {
                GeometryReader { geometry in
                    ZStack {
                        // 背景条
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .frame(height: 4)

                        // 进度条
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * (item.playedPercentage / 100), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
    }

    /// 收藏徽章
    private var favoriteBadge: some View {
        Group {
            if item.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.8))
                    )
                    .padding(4)
            }
        }
    }
}

// MARK: - 预览

#Preview {
    ScrollView {
        HStack(spacing: 16) {
            // 模拟电影卡片
            MediaCardView(
                item: EmbyItem(
                    id: "1",
                    name: "肖申克的救赎",
                    originalTitle: "The Shawshank Redemption",
                    type: "Movie",
                    collectionType: "movies",
                    parentId: nil,
                    seriesName: nil,
                    seasonId: nil,
                    seasonNumber: nil,
                    indexNumber: nil,
                    episodeCount: nil,
                    premiereDate: Date(),
                    endDate: nil,
                    productionYear: 1994,
                    communityRating: 9.3,
                    userData: UserData(playedPercentage: 75, played: false, isFavorite: true, lastPlayedDate: nil, playbackPositionTicks: nil),
                    overview: "两个被囚禁的人多年结下了友谊...",
                    tags: ["剧情", "犯罪"],
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
                ),
                imageURL: URL(string: "https://picsum.photos/300/450?random=1"),
                width: 120,
                height: 180
            )

            // 模拟剧集卡片
            MediaCardView(
                item: EmbyItem(
                    id: "2",
                    name: "权力的游戏",
                    originalTitle: "Game of Thrones",
                    type: "Series",
                    collectionType: "tvshows",
                    parentId: nil,
                    seriesName: nil,
                    seasonId: nil,
                    seasonNumber: nil,
                    indexNumber: nil,
                    episodeCount: 73,
                    premiereDate: Date(),
                    endDate: Date(),
                    productionYear: 2011,
                    communityRating: 9.2,
                    userData: UserData(playedPercentage: 0, played: false, isFavorite: false, lastPlayedDate: nil, playbackPositionTicks: nil),
                    overview: "七大王国的权力斗争...",
                    tags: ["奇幻", "冒险"],
                    genres: ["Fantasy", "Adventure"],
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
                imageURL: URL(string: "https://picsum.photos/300/450?random=2"),
                width: 120,
                height: 180
            )

            // 模拟单集卡片
            MediaCardView(
                item: EmbyItem(
                    id: "3",
                    name: "凛冬将至",
                    originalTitle: "Winter Is Coming",
                    type: "Episode",
                    collectionType: nil,
                    parentId: "2",
                    seriesName: "权力的游戏",
                    seasonId: "s1",
                    seasonNumber: 1,
                    indexNumber: 1,
                    episodeCount: nil,
                    premiereDate: Date(),
                    endDate: nil,
                    productionYear: 2011,
                    communityRating: 8.5,
                    userData: UserData(playedPercentage: 100, played: true, isFavorite: false, lastPlayedDate: nil, playbackPositionTicks: nil),
                    overview: "第一集...",
                    tags: nil,
                    genres: nil,
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
                imageURL: URL(string: "https://picsum.photos/300/450?random=3"),
                width: 120,
                height: 180
            )
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
