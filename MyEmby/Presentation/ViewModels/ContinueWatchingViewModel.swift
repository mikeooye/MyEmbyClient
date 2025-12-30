//
//  ContinueWatchingViewModel.swift
//  MyEmby
//
//  Created by Claude on 2025/12/30.
//

import Foundation
import Observation

/// 继续播放视图模型
@Observable
@MainActor
final class ContinueWatchingViewModel {

    // MARK: - 状态

    /// 加载状态
    var isLoading = false

    /// 错误信息
    var errorMessage: String?

    /// 继续播放的媒体列表（有播放进度的项目）
    var items: [EmbyItem] = []

    /// 图片 URL 映射
    var itemImageURLs: [String: URL] = [:]

    /// 是否已经加载过数据
    private(set) var hasLoadedOnce = false

    // MARK: - 依赖

    private let authRepository: AuthRepository

    // MARK: - 初始化

    init(authRepository: AuthRepository = .shared) {
        self.authRepository = authRepository
    }

    // MARK: - 公共方法

    /// 加载继续播放列表
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

            // 获取有播放进度的媒体项
            let response = try await mediaRepository.getItems(
                parentId: nil,
                includeItemTypes: ["Movie", "Episode"],
                sortBy: "DatePlayed",
                sortOrder: "Descending",
                limit: 50,
                recursive: true,
                filters: ["IsResumable"]
            )

            // 过滤出有播放进度的项目
            self.items = response.items.filter { $0.playedPercentage > 0 && $0.playedPercentage < 100 }

            // 加载图片
            await loadImageURLs(items: self.items, mediaRepository: mediaRepository)

            isLoading = false

        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    /// 仅在首次加载时获取数据（用于 TabView 保持状态）
    func loadDataIfNeeded() async {
        if !hasLoadedOnce {
            hasLoadedOnce = true
            await loadData()
        }
    }

    /// 刷新数据
    func refresh() async {
        await loadData()
    }

    /// 获取图片 URL
    func getImageURL(for itemId: String) -> URL? {
        itemImageURLs[itemId]
    }

    // MARK: - 私有方法

    /// 加载图片 URL
    private func loadImageURLs(items: [EmbyItem], mediaRepository: MediaRepository) async {
        await withTaskGroup(of: (String, URL).self) { group in
            for item in items {
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

            for await (itemId, url) in group {
                if url.scheme != "about" {
                    itemImageURLs[itemId] = url
                }
            }
        }
    }
}

// MARK: - 便捷扩展

extension ContinueWatchingViewModel {
    /// 是否有内容
    var hasContent: Bool {
        !items.isEmpty
    }

    /// 内容数量
    var itemCount: Int {
        items.count
    }
}
