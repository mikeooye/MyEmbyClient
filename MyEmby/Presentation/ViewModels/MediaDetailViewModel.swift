//
//  MediaDetailViewModel.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation

/// 媒体详情页视图模型
@Observable
@MainActor
final class MediaDetailViewModel {

    // MARK: - 状态

    /// 加载状态
    var isLoading = false

    /// 错误信息
    var errorMessage: String?

    /// 媒体项详情
    var item: EmbyItem?

    /// 背景图片 URL
    var backdropImageURL: URL?

    /// 海报图片 URL
    var posterImageURL: URL?

    /// 演员列表
    var cast: [NamePair] = []

    /// 演员 ID 到头像 URL 的映射
    var castImageURLs: [String: URL] = [:]

    /// 相关推荐
    var relatedItems: [EmbyItem] = []

    /// 相关推荐图片 URL 映射
    var relatedItemImageURLs: [String: URL] = [:]

    /// 季列表（用于剧集）
    var seasons: [EmbyItem] = []

    /// 当前选中的季
    var selectedSeason: EmbyItem?

    /// 当前选中的季索引
    var selectedSeasonIndex: Int = 0

    /// 当前季的剧集列表
    var episodes: [EmbyItem] = []

    /// 剧集图片 URL 映射
    var episodeImageURLs: [String: URL] = [:]

    /// 剧集排序方向（true = 升序，false = 降序）
    var isEpisodesAscending = true

    // MARK: - 依赖

    private let authRepository: AuthRepository
    private let itemId: String

    // MARK: - 初始化

    init(itemId: String, authRepository: AuthRepository = .shared) {
        self.itemId = itemId
        self.authRepository = authRepository
    }

    // MARK: - 公共方法

    /// 加载详情数据
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // 获取 API 服务
            let apiService = try await authRepository.getAPIService()
            let mediaRepository = MediaRepository.create(
                apiService: apiService,
                authRepository: authRepository
            )

            // 1. 获取媒体项详情
            let detailItem = try await mediaRepository.getItem(itemId: itemId)
            self.item = detailItem

            // 2. 加载背景图 URL
            if let backdropTag = detailItem.backdropImageTags?.first {
                self.backdropImageURL = try await mediaRepository.getImageURL(
                    itemId: itemId,
                    imageType: .backdrop,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    tag: backdropTag
                )
            }

            // 3. 加载海报 URL
            if let posterTag = detailItem.imageTags?.primary ?? detailItem.poster?.tag {
                self.posterImageURL = try await mediaRepository.getImageURL(
                    itemId: itemId,
                    imageType: .primary,
                    maxWidth: 600,
                    maxHeight: 900,
                    tag: posterTag
                )
            }

            // 4. 获取演员列表并加载头像
            if let people = detailItem.people {
                let filteredCast = people.filter { person in
                    // 过滤演员和导演
                    person.id != nil && person.name != nil
                }
                self.cast = filteredCast

                // 加载演员头像
                await loadCastImages(cast: filteredCast, mediaRepository: mediaRepository)
            }

            // 5. 根据类型加载相关内容
            if detailItem.type == "Series" {
                // 加载季列表
                await loadSeasons(mediaRepository: mediaRepository)
            } else if detailItem.type == "Season" {
                // 加载剧集列表
                await loadEpisodes(for: itemId, mediaRepository: mediaRepository)
            }

            // 6. 加载相关推荐
            await loadRelatedItems(
                mediaRepository: mediaRepository,
                itemType: detailItem.type
            )

            isLoading = false

        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    /// 切换收藏状态
    func toggleFavorite() async {
        guard let item = item else { return }

        // TODO: 实现收藏功能（需要在 EmbyAPIService 中添加 addFavoriteItem 和 removeFavoriteItem 方法）
        errorMessage = "收藏功能待实现"
    }

    /// 标记为已播放/未播放
    func togglePlayed() async {
        // TODO: 实现 markAsPlayed API（需要在 EmbyAPIService 中添加）
    }

    /// 获取演员头像 URL
    /// - Parameter personId: 演员 ID
    /// - Returns: 头像 URL（如果存在）
    func getCastImageURL(for personId: String) -> URL? {
        castImageURLs[personId]
    }

    /// 加载指定季的剧集
    func loadEpisodes(for seasonId: String, mediaRepository: MediaRepository) async {
        do {
            let sortOrder = isEpisodesAscending ? "Ascending" : "Descending"
            let response = try await mediaRepository.getItems(
                parentId: seasonId,
                includeItemTypes: ["Episode"],
                sortBy: "IndexNumber",  // 使用 indexNumber 排序
                sortOrder: sortOrder
            )
            self.episodes = response.items

            // 加载剧集图片
            await loadEpisodeImages(episodes: response.items, mediaRepository: mediaRepository)

        } catch {
            // 加载失败，静默处理
        }
    }

    /// 加载剧集图片
    private func loadEpisodeImages(episodes: [EmbyItem], mediaRepository: MediaRepository) async {
        await withTaskGroup(of: (String, URL).self) { group in
            for episode in episodes {
                // 尝试获取剧集的主图
                guard let imageTag = episode.imageTags?.primary else {
                    continue
                }

                group.addTask {
                    do {
                        let url = try await mediaRepository.getImageURL(
                            itemId: episode.id,
                            imageType: .primary,
                            maxWidth: 300,
                            maxHeight: 170,
                            tag: imageTag
                        )
                        return (episode.id, url)
                    } catch {
                        return (episode.id, URL(string: "about:blank")!)
                    }
                }
            }

            // 收集结果
            for await (episodeId, url) in group {
                if url.scheme != "about" {
                    episodeImageURLs[episodeId] = url
                }
            }
        }
    }

    /// 获取剧集图片 URL
    func getEpisodeImageURL(for episodeId: String) -> URL? {
        episodeImageURLs[episodeId]
    }

    /// 切换剧集排序方向
    func toggleEpisodeSortOrder() async {
        isEpisodesAscending.toggle()

        // 重新加载剧集
        if let season = selectedSeason {
            let apiService = try? await authRepository.getAPIService()
            if let apiService = apiService {
                let mediaRepository = MediaRepository.create(
                    apiService: apiService,
                    authRepository: authRepository
                )
                await loadEpisodes(for: season.id, mediaRepository: mediaRepository)
            }
        }
    }

    // MARK: - 私有方法

    /// 加载演员头像
    private func loadCastImages(cast: [NamePair], mediaRepository: MediaRepository) async {
        // 并行加载演员头像
        await withTaskGroup(of: (String, URL).self) { group in
            for person in cast {
                guard let personId = person.id,
                      let imageTag = person.primaryImageTag else {
                    continue
                }

                group.addTask {
                    do {
                        // Emby API 人员图片端点格式：
                        // /Users/{userId}/Items/{itemId}/Images/Primary/{personId}
                        // 这里使用 itemId 作为媒体项 ID，personId 作为人员 ID
                        let sessionInfo = try await self.authRepository.getSessionInfo()
                        let serverURL = try await self.authRepository.getServerConfig().serverURL

                        // 构建 URL
                        let urlString = "\(serverURL)/Users/\(sessionInfo.userId)/Items/\(self.itemId)/Images/Primary/\(personId)?tag=\(imageTag)&maxWidth=200&maxHeight=200"

                        if let url = URL(string: urlString) {
                            return (personId, url)
                        }
                    } catch {
                        // 加载失败，静默处理
                    }
                    return (personId, URL(string: "about:blank")!)
                }
            }

            // 收集结果
            for await (personId, url) in group {
                if url.scheme != "about" {
                    castImageURLs[personId] = url
                }
            }
        }
    }

    /// 加载季列表
    private func loadSeasons(mediaRepository: MediaRepository) async {
        do {
            let response = try await mediaRepository.getItems(
                parentId: itemId,
                includeItemTypes: ["Season"],
                sortBy: "SortName",
                sortOrder: "Ascending"
            )
            self.seasons = response.items

            // 默认选中第一季
            if let firstSeason = response.items.first {
                self.selectedSeason = firstSeason
                await loadEpisodes(for: firstSeason.id, mediaRepository: mediaRepository)
            }

        } catch {
            // 加载失败，静默处理
        }
    }

    /// 加载相关推荐
    private func loadRelatedItems(
        mediaRepository: MediaRepository,
        itemType: String?
    ) async {
        do {
            // 使用相同的类型和父级获取相关媒体
            var includeItemTypes: [String]?
            var parentId: String?

            if let item = self.item {
                if itemType == "Movie" {
                    includeItemTypes = ["Movie"]
                    parentId = item.parentId
                } else if itemType == "Series" {
                    includeItemTypes = ["Series"]
                    parentId = item.parentId
                }
            }

            let response = try await mediaRepository.getItems(
                parentId: parentId,
                includeItemTypes: includeItemTypes,
                sortBy: "Random",
                sortOrder: "Ascending",
                limit: 10
            )

            // 排除当前项
            self.relatedItems = response.items.filter { $0.id != itemId }

            // 加载相关推荐的图片
            await loadRelatedItemImages(items: self.relatedItems, mediaRepository: mediaRepository)

        } catch {
            // 加载失败，静默处理
        }
    }

    /// 加载相关推荐图片
    private func loadRelatedItemImages(items: [EmbyItem], mediaRepository: MediaRepository) async {
        await withTaskGroup(of: (String, URL).self) { group in
            for item in items {
                // 只加载有图片标签的项目
                guard let imageTag = item.imageTags?.primary else {
                    continue
                }

                group.addTask {
                    do {
                        let url = try await mediaRepository.getImageURL(
                            itemId: item.id,
                            imageType: .primary,
                            maxWidth: 300,
                            maxHeight: 450,
                            tag: imageTag
                        )
                        return (item.id, url)
                    } catch {
                        return (item.id, URL(string: "about:blank")!)
                    }
                }
            }

            // 收集结果
            for await (itemId, url) in group {
                if url.scheme != "about" {
                    relatedItemImageURLs[itemId] = url
                }
            }
        }
    }

    /// 获取相关推荐图片 URL
    func getRelatedItemImageURL(for itemId: String) -> URL? {
        relatedItemImageURLs[itemId]
    }
}

// MARK: - 便捷扩展

extension MediaDetailViewModel {
    /// 格式化时长
    func formatRuntime() -> String? {
        guard let runtime = item?.runTime else { return nil }
        let hours = Int(runtime) / 3600
        let minutes = (Int(runtime) % 3600) / 60

        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }

    /// 格式化评分
    func formatRating() -> String? {
        guard let rating = item?.communityRating else { return nil }
        return String(format: "%.1f", rating)
    }

    /// 是否可以播放
    var canPlay: Bool {
        item?.canPlay ?? false
    }

    /// 是否是剧集类型
    var isSeries: Bool {
        item?.type == "Series"
    }

    /// 是否有演员信息
    var hasCast: Bool {
        !cast.isEmpty
    }

    /// 是否有相关推荐
    var hasRelatedItems: Bool {
        !relatedItems.isEmpty
    }
}
