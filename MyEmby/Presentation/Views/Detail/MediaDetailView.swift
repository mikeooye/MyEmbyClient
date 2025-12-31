//
//  MediaDetailView.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SDWebImageSwiftUI

/// 媒体详情页视图
struct MediaDetailView: View {
    // MARK: - 属性
    
    /// 媒体项 ID
    let itemId: String
    
    /// 视图模型
    @State private var viewModel: MediaDetailViewModel
    @State private var isPlaying = false
    
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
            VStack(alignment: .leading, spacing: 24) {
                // 封面图片区域
                posterSection
                
                // 标题区域
                titleSection
                
                // 元信息区域（评分、年份、分类）
                metadataSection
                
                // 播放按钮
                playButtonSection
                
                // 剧情简介
                if let overview = viewModel.item?.overview, !overview.isEmpty {
                    overviewSection
                }
                
                // 演职人员
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
            }
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .ignoresSafeArea(.all, edges: .top)
        .navigationTitle(viewModel.item?.name ?? "详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    // 收藏按钮
                    Button(action: {
                        Task {
                            await viewModel.toggleFavorite()
                        }
                    }) {
                        Image(systemName: viewModel.item?.isFavorite == true ?
                              "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.item?.isFavorite == true ? .red : .gray)
                    }
                    
                    // 标记已看按钮
                    Button(action: {
                        Task {
                            await viewModel.togglePlayed()
                        }
                    }) {
                        Image(systemName: viewModel.item?.isPlayed == true ?
                              "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 20))
                        .foregroundColor((viewModel.item?.isPlayed ?? false) ? .blue : .gray)
                    }
                }
            }
        }
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
    
    /// 封面图片区域
    private var posterSection: some View {
        WebImage(url: viewModel.posterImageURL) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                }
                .frame(maxWidth: .infinity)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
    }
    
    /// 标题区域
    private var titleSection: some View {
        Text(viewModel.item?.name ?? "")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.black)
            .padding(.horizontal, 20)
    }
    
    /// 元信息区域（评分、年份、分类）
    private var metadataSection: some View {
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
            
            // 年份
            if let year = viewModel.item?.productionYear {
                Text(year, format: .number.grouping(.never))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 分类标签
            if let genres = viewModel.item?.genres, !genres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(genres.prefix(3), id: \.self) { genre in
                            Text(genre)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    /// 播放按钮区域
    private var playButtonSection: some View {
        Button {
            isPlaying = true
        }
        label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text("立即播放")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canPlay)
        .opacity(viewModel.canPlay ? 1.0 : 0.5)
        .padding(.horizontal, 20)
        .fullScreenCover(isPresented: $isPlaying) {
            VideoPlayerView(itemId: itemId, viewModel: PlayerViewModel())
        }
    }
    
    /// 剧情简介区域
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("剧情简介")
                .font(.headline)
                .foregroundColor(.black)
            
            Text(viewModel.item?.overview ?? "")
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(.horizontal, 20)
    }
    
    /// 演员列表
    private var castSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("演职人员")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.cast, id: \.id) { person in
                        if let personId = person.id {
                            CastCardView(
                                person: person,
                                imageURL: viewModel.getCastImageURL(for: personId)
                            )
                        } else {
                            CastCardView(person: person, imageURL: nil)
                        }
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
            // 标题栏（包含标题和排序按钮）
            HStack {
                Text("剧集")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                // 排序切换按钮
                Button(action: {
                    Task {
                        await viewModel.toggleEpisodeSortOrder()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isEpisodesAscending ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        Text(viewModel.isEpisodesAscending ? "正序" : "倒序")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
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
            
            // 横向剧集列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.episodes, id: \.id) { episode in
                        EpisodeCardView(
                            episode: episode,
                            imageURL: viewModel.getEpisodeImageURL(for: episode.id)
                        )
                        .containerShape(Rectangle())
                        .onTapGesture {
                            // TODO: 跳转到播放器
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
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
                                imageURL: viewModel.getRelatedItemImageURL(for: item.id),
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
}

// MARK: - 演员卡片

struct CastCardView: View {
    let person: NamePair
    let imageURL: URL?
    
    var body: some View {
        VStack(spacing: 8) {
            // 头像
            if let imageURL = imageURL {
                // 使用真实头像
                WebImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        fallbackAvatar
                    @unknown default:
                        fallbackAvatar
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .shadow(radius: 2)
            } else {
                // 占位符
                fallbackAvatar
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
    
    /// 占位符头像
    private var fallbackAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
            
            Image(systemName: "person.fill")
                .font(.system(size: 32))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - 剧集卡片

struct EpisodeCardView: View {
    let episode: EmbyItem
    let imageURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 剧集图片或占位符
            WebImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.2)
                        Text("E\(episode.indexNumber ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.2)
                        Text("E\(episode.indexNumber ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 134, height: 75)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(8)
            .clipped()
            .overlay(
                // 播放进度条
                VStack {
                    Spacer()
                    if episode.playedPercentage > 0 {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(height: 3)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * (episode.playedPercentage / 100), height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                }
            )
            .overlay(
                // 已看标记
                VStack {
                    HStack {
                        Spacer()
                        if episode.isPlayed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                                .padding(4)
                        }
                    }
                    Spacer()
                }
            )
            
            // 剧集编号
            Text("第 \(episode.indexNumber ?? 0) 集")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // 剧集名称
            Text(episode.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .frame(width: 134)
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - 预览

#Preview {
    MediaDetailView(itemId: "preview-id")
        .preferredColorScheme(.dark)
}
