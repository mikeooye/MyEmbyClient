//
//  MediaDetailView.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// 媒体详情页视图
struct MediaDetailView: View {
    // MARK: - 属性

    /// 媒体项 ID
    let itemId: String

    /// 视图模型
    @State private var viewModel: MediaDetailViewModel

    /// 认证仓库
    private let authRepository = AuthRepository.shared

    /// 英雄区域高度
    private let heroHeight: CGFloat = 450

    // MARK: - 初始化

    init(itemId: String) {
        self.itemId = itemId
        self._viewModel = State(initialValue: MediaDetailViewModel(itemId: itemId))
    }

    // MARK: - 视图主体

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 英雄区域
                heroSection

                // 信息区域
                infoSection

                // 演员列表（如果有）
                if viewModel.hasCast {
                    castSection
                }

                // 剧集列表（如果是电视剧）
                if viewModel.isSeries && !viewModel.episodes.isEmpty {
                    episodesSection
                }

                // 相关推荐（如果有）
                if viewModel.hasRelatedItems {
                    relatedSection
                }

                // 底部间距
                Spacer()
                    .frame(height: 40)
            }
            .background(Color.white)
        }
        .overlay(
            // 返回按钮
            backButton,
            alignment: .topLeading
        )
        .ignoresSafeArea()
        .task {
            await viewModel.loadData()
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - 子视图

    /// 英雄区域（背景图 + 海报 + 播放按钮）
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // 背景图（模糊）
            if let backdropURL = viewModel.backdropImageURL {
                RemoteImageView(
                    url: backdropURL,
                    targetSize: CGSize(width: 1920, height: 1080)
                )
                .frame(height: heroHeight)
                .clipped()
                .blur(radius: 5)
            } else {
                Color.gray.opacity(0.3)
                    .frame(height: heroHeight)
            }

            // 渐变遮罩
            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: heroHeight)

            // 海报 + 播放按钮
            VStack(spacing: 16) {
                Spacer()

                // 海报
                if let posterURL = viewModel.posterImageURL {
                    RemoteImageView(
                        url: posterURL,
                        targetSize: CGSize(width: 300, height: 450)
                    )
                    .frame(width: 180, height: 270)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                } else {
                    // 默认海报占位符
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 180, height: 270)
                    .cornerRadius(12)
                }

                // 播放按钮
                Button(action: {
                    // TODO: 跳转到播放器
                    print("播放媒体")
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 64, height: 64)

                        Image(systemName: "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .offset(x: 2) // 视觉修正
                    }
                    .shadow(radius: 8)
                }
                .disabled(!viewModel.canPlay)
                .opacity(viewModel.canPlay ? 1.0 : 0.5)

                // 操作按钮（收藏、标记等）
                actionButtons
            }
            .padding(.bottom, 32)
        }
        .frame(height: heroHeight)
    }

    /// 操作按钮行
    private var actionButtons: some View {
        HStack(spacing: 40) {
            // 收藏按钮
            Button(action: {
                Task {
                    await viewModel.toggleFavorite()
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: viewModel.item?.isFavorite == true ?
                         "heart.fill" : "heart")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.item?.isFavorite == true ?
                                         .red : .primary)

                    Text("收藏")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }

            // 标记已看按钮
            Button(action: {
                Task {
                    await viewModel.togglePlayed()
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: viewModel.item?.isPlayed == true ?
                         "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.primary)

                    Text("标记")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }

            // 分享按钮
            Button(action: {
                // TODO: 实现分享功能
                print("分享")
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 28))
                        .foregroundColor(.primary)

                    Text("分享")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
    }

    /// 信息区域
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题 + 年份
            HStack(alignment: .top, spacing: 12) {
                Text(viewModel.item?.name ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                if let year = viewModel.item?.productionYear {
                    Text("(\(year))")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }

                Spacer()
            }

            // 元信息行（评分、时长）
            HStack(spacing: 16) {
                // 评分
                if let rating = viewModel.formatRating() {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        Text(rating)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }

                // 时长
                if let runtime = viewModel.formatRuntime() {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(runtime)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }

                Spacer()
            }

            // 类型标签
            if let genres = viewModel.item?.genres, !genres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(genres.prefix(5), id: \.self) { genre in
                            Text(genre)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(16)
                        }
                    }
                }
            }

            // 剧情简介
            if let overview = viewModel.item?.overview, !overview.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("剧情简介")
                        .font(.headline)
                        .foregroundColor(.black)

                    Text(overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    /// 演员列表
    private var castSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("演员")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.cast, id: \.id) { person in
                        CastCardView(person: person)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }

    /// 剧集列表
    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("剧集")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 20)

            // 季选择器（如果有多个季）
            if viewModel.seasons.count > 1 {
                Picker("季", selection: $viewModel.selectedSeasonIndex) {
                    ForEach(0..<viewModel.seasons.count, id: \.self) { index in
                        Text(viewModel.seasons[index].name)
                            .tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .onChange(of: viewModel.selectedSeasonIndex) { _, newIndex in
                    // 切换季时加载对应的剧集
                    let season = viewModel.seasons[newIndex]
                    Task {
                        let apiService = try? await authRepository.getAPIService()
                        if let apiService = apiService {
                            let mediaRepository = MediaRepository.create(
                                apiService: apiService,
                                authRepository: authRepository
                            )
                            await viewModel.loadEpisodes(
                                for: season.id,
                                mediaRepository: mediaRepository
                            )
                        }
                    }
                }
            }

            // 剧集列表
            VStack(spacing: 0) {
                ForEach(viewModel.episodes, id: \.id) { episode in
                    EpisodeRowView(episode: episode)
                        .onTapGesture {
                            // TODO: 跳转到播放器
                            print("播放剧集: \(episode.name)")
                        }

                    if episode.id != viewModel.episodes.last?.id {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }

    /// 相关推荐
    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("相关推荐")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(viewModel.relatedItems, id: \.id) { item in
                        NavigationLink(value: AppRoute.mediaDetail(itemId: item.id)) {
                            MediaCardView(
                                item: item,
                                imageURL: nil, // TODO: 传递图片 URL
                                width: 120,
                                height: 180,
                                showTitle: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }

    /// 返回按钮
    private var backButton: some View {
        Button(action: {
            NavigationManager.shared.goBack()
        }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .shadow(radius: 2)
                    .frame(width: 44, height: 44)

                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            .padding(.leading, 16)
            .padding(.top, 8)
        }
    }
}

// MARK: - 演员卡片

struct CastCardView: View {
    let person: NamePair

    var body: some View {
        VStack(spacing: 8) {
            // 头像
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            }

            // 姓名
            Text(person.name ?? "未知")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 80)
        }
    }
}

// MARK: - 剧集行

struct EpisodeRowView: View {
    let episode: EmbyItem

    var body: some View {
        HStack(spacing: 12) {
            // 剧集编号
            Text("\(episode.indexNumber ?? 0)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 40)

            // 剧集信息
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if let overview = episode.overview {
                    Text(overview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // 播放进度
                if episode.playedPercentage > 0 {
                    ProgressView(value: episode.playedPercentage, total: 100)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                }
            }

            Spacer()

            // 时长
            if let runtime = episode.runTime {
                Text("\(Int(runtime / 60))m")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 播放图标
            Image(systemName: "play.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - 预览

#Preview {
    MediaDetailView(itemId: "preview-id")
        .preferredColorScheme(.dark)
}
