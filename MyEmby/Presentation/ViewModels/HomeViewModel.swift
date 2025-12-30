//
//  HomeViewModel.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation

/// 首页视图模型（使用 iOS 17+ Observation 框架）
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - 状态

    /// 加载状态
    var isLoading = false

    /// 错误信息
    var errorMessage: String?

    /// 媒体库视图（分类列表）
    var libraryViews: [EmbyItem] = []

    /// 每个分类的最新媒体项（分类ID -> 媒体项列表）
    var latestItemsByCategory: [String: [EmbyItem]] = [:]

    /// 媒体项缓存（ID -> 媒体项，避免重复查找）
    var itemsCache: [String: EmbyItem] = [:]

    /// 刷新任务 ID（用于 Pull-to-Refresh）
    var refreshTask: Task<Void, Never>?

    // MARK: - 依赖

    private let authRepository: AuthRepository

    // MARK: - 初始化

    init(authRepository: AuthRepository = .shared) {
        self.authRepository = authRepository
    }

    // MARK: - 公共方法

    /// 加载首页数据
    func loadData() async {
        // 取消之前的刷新任务
        refreshTask?.cancel()

        // 创建新的刷新任务
        refreshTask = Task { @MainActor in
            await fetchHomeData()
        }

        await refreshTask?.value
    }

    /// 刷新数据
    func refresh() async {
        await loadData()
    }

    /// 获取媒体项的图片 URL
    /// - Parameter itemId: 媒体项 ID
    /// - Returns: 图片 URL（使用 Primary 图片）
    func getImageURL(for itemId: String) async throws -> URL {
      let key = itemId
      debugPrint("itemsCache: \(itemsCache)")
        // 从缓存中获取媒体项
        guard let item = itemsCache[key] else {
            throw NetworkError.notFound
        }

        // 立即捕获图片标签，避免异步访问问题
        let imageTag = item.imageTags?.primary ?? item.poster?.tag

        // 动态获取正确配置的 API 服务
        let apiService = try await authRepository.getAPIService()
        let mediaRepository = MediaRepository.create(apiService: apiService, authRepository: authRepository)

        return try await mediaRepository.getImageURL(
            itemId: itemId,
            imageType: .primary,
            maxWidth: 300,
            maxHeight: 450,
            tag: imageTag
        )
    }

    // MARK: - 私有方法

    /// 获取首页数据
    private func fetchHomeData() async {
        // 重置状态
        isLoading = true
        errorMessage = nil

        do {
            // 获取正确配置的 API 服务
            let apiService = try await authRepository.getAPIService()
            let mediaRepository = MediaRepository.create(apiService: apiService, authRepository: authRepository)

            // 1. 获取媒体库视图（分类列表）
            let views = try await mediaRepository.getUserViews()

            // 检查任务是否被取消
            guard !Task.isCancelled else { return }

            // 过滤掉没有媒体项的分类
            let validViews = views.filter { view in
                view.collectionType != nil && view.id.isEmpty == false
            }

            libraryViews = validViews

            // 2. 并行获取每个分类的最新媒体项
            await withTaskGroup(of: (String, [EmbyItem]).self) { group in
                for view in validViews {
                    // 限制并发数量，避免过多请求
                    group.addTask {
                        await self.fetchLatestItems(for: view, mediaRepository: mediaRepository)
                    }
                }

                // 收集结果
                for await (categoryId, items) in group {
                    latestItemsByCategory[categoryId] = items
                    // 更新媒体项缓存
                    for item in items {
                        itemsCache[item.id] = item
                    }
                }
            }

            // 检查任务是否被取消
            guard !Task.isCancelled else { return }

            isLoading = false

        } catch let error as NetworkError {
            isLoading = false

            // 如果是认证错误，清除过期的认证信息
            if case .unauthorized = error {
                print("认证失败，清除过期信息")
                Task {
                    try? await authRepository.logout()
                }
                errorMessage = "登录已过期，请重新登录"
            } else {
                errorMessage = error.alertMessage
                print("获取首页数据失败: \(error)")
            }

        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("获取首页数据失败: \(error)")
        }
    }

    /// 获取指定分类的最新媒体项
    /// - Parameters:
    ///   - category: 分类项
    ///   - mediaRepository: 媒体仓库
    /// - Returns: (分类ID, 媒体项列表) 元组
    private func fetchLatestItems(for category: EmbyItem, mediaRepository: MediaRepository) async -> (String, [EmbyItem]) {
        do {
            // 根据分类类型获取不同类型的媒体
            let includeItemTypes: [String]?

            switch category.collectionType {
            case "movies":
                includeItemTypes = ["Movie"]
            case "tvshows":
                includeItemTypes = ["Series", "Episode"]
            case "music":
                includeItemTypes = ["MusicAlbum", "MusicArtist"]
            default:
                includeItemTypes = nil
            }

            // 获取最新 10 个媒体项
            let items = try await mediaRepository.getLatestItems(
                parentId: category.id,
                limit: 10,
                includeItemTypes: includeItemTypes
            )

            return (category.id, items)

        } catch {
            print("获取分类 \(category.name) 的最新内容失败: \(error)")
            return (category.id, [])
        }
    }
}

// MARK: - 便捷扩展

extension HomeViewModel {
    /// 获取某个分类的最新媒体项
    /// - Parameter categoryId: 分类 ID
    /// - Returns: 媒体项列表
    func latestItems(for categoryId: String) -> [EmbyItem] {
        latestItemsByCategory[categoryId] ?? []
    }

    /// 获取所有显示的分类（排除空的）
    var displayedCategories: [EmbyItem] {
        libraryViews.filter { view in
            let items = latestItemsByCategory[view.id] ?? []
            return !items.isEmpty
        }
    }

    /// 分类总数
    var categoryCount: Int {
        libraryViews.count
    }

    /// 是否有数据
    var hasData: Bool {
        !libraryViews.isEmpty && !latestItemsByCategory.isEmpty
    }

    /// 是否显示空状态
    var shouldShowEmptyState: Bool {
        !isLoading && !hasData && errorMessage == nil
    }
}

// MARK: - 预览辅助

#if DEBUG
extension HomeViewModel {
    /// 创建预览用的 ViewModel（带模拟数据）
    static var preview: HomeViewModel {
        let viewModel = HomeViewModel()

        // 模拟分类
        viewModel.libraryViews = [
            EmbyItem(
                id: "movies",
                name: "电影",
                originalTitle: "Movies",
                type: "Folder",
                collectionType: "movies",
                parentId: nil,
                seriesName: nil,
                seasonId: nil,
                seasonNumber: nil,
                indexNumber: nil,
                episodeCount: nil,
                premiereDate: nil,
                endDate: nil,
                productionYear: nil,
                communityRating: nil,
                userData: nil,
                overview: nil,
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
            EmbyItem(
                id: "tvshows",
                name: "电视剧",
                originalTitle: "TV Shows",
                type: "Folder",
                collectionType: "tvshows",
                parentId: nil,
                seriesName: nil,
                seasonId: nil,
                seasonNumber: nil,
                indexNumber: nil,
                episodeCount: nil,
                premiereDate: nil,
                endDate: nil,
                productionYear: nil,
                communityRating: nil,
                userData: nil,
                overview: nil,
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
            )
        ]

        // 模拟媒体项
        let mockItems = (1...5).map { index in
            EmbyItem(
                id: "item\(index)",
                name: "示例媒体 \(index)",
                originalTitle: "Sample Media \(index)",
                type: index % 2 == 0 ? "Movie" : "Series",
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
                communityRating: 8.0,
                userData: nil,
                overview: nil,
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
            )
        }

        viewModel.latestItemsByCategory = [
            "movies": mockItems,
            "tvshows": mockItems
        ]

        return viewModel
    }
}
#endif
