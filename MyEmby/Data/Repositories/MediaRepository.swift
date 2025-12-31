//
//  MediaRepository.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// 媒体仓库（聚合媒体相关的 API 服务）
///
/// 职责：
/// - 处理媒体项的获取和查询
/// - 管理图片 URL 构建
/// - 为 ViewModel 提供简洁的数据访问接口
final class MediaRepository {

    // MARK: - 属性

    private let apiService: EmbyAPIService
    private let authRepository: AuthRepository

    // MARK: - 初始化

    init(
        apiService: EmbyAPIService,
        authRepository: AuthRepository
    ) {
        self.apiService = apiService
        self.authRepository = authRepository
    }

    // MARK: - 公共方法

    /// 获取用户的媒体库视图（分类列表）
    /// - Returns: 媒体库视图列表（如 "电影"、"电视剧"、"音乐" 等）
    func getUserViews() async throws -> [EmbyItem] {
        // 获取用户 ID
        let sessionInfo = try await authRepository.getSessionInfo()
        let response = try await apiService.getUserViews(userId: sessionInfo.userId)
        return response.items
    }

    /// 获取最新添加的媒体项
    /// - Parameters:
    ///   - parentId: 父级 ID（可选，限制在特定分类下）
    ///   - limit: 返回数量限制
    ///   - includeItemTypes: 包含的媒体类型
    /// - Returns: 最新媒体项列表
    func getLatestItems(
        parentId: String? = nil,
        limit: Int = 10,
        includeItemTypes: [String]? = nil
    ) async throws -> [EmbyItem] {
        // 获取用户 ID
        let sessionInfo = try await authRepository.getSessionInfo()
        return try await apiService.getLatestItems(
            userId: sessionInfo.userId,
            parentId: parentId,
            limit: limit,
            includeItemTypes: includeItemTypes
        )
    }

    /// 获取媒体项列表（支持筛选和排序）
    /// - Parameters:
    ///   - parentId: 父级 ID（可选，用于获取特定文件夹下的内容）
    ///   - includeItemTypes: 包含的媒体类型（如 ["Movie", "Series"]）
    ///   - sortBy: 排序字段（如 "SortName", "DateCreated", "PremiereDate"）
    ///   - sortOrder: 排序顺序（"Ascending" 或 "Descending"）
    ///   - limit: 返回数量限制
    ///   - startIndex: 分页起始索引
    ///   - recursive: 是否递归查找子文件夹
    ///   - filters: 筛选器（如 ["IsPlayed", "IsFavorite"]）
    /// - Returns: 媒体项列表响应
    func getItems(
        parentId: String? = nil,
        includeItemTypes: [String]? = nil,
        sortBy: String? = nil,
        sortOrder: String? = nil,
        limit: Int? = nil,
        startIndex: Int? = nil,
        recursive: Bool = true,
        filters: [String]? = nil
    ) async throws -> ItemsResponse {
        // 获取用户 ID
        let sessionInfo = try await authRepository.getSessionInfo()
        return try await apiService.getItems(
            userId: sessionInfo.userId,
            parentId: parentId,
            includeItemTypes: includeItemTypes,
            sortBy: sortBy,
            sortOrder: sortOrder,
            limit: limit,
            startIndex: startIndex,
            recursive: recursive,
            filters: filters
        )
    }

    /// 获取单个媒体项详情
    /// - Parameter itemId: 媒体项 ID
    /// - Returns: 媒体项详情
    func getItem(itemId: String) async throws -> EmbyItem {
        // 获取用户 ID
        let sessionInfo = try await authRepository.getSessionInfo()
        return try await apiService.getItem(userId: sessionInfo.userId, itemId: itemId)
    }

    /// 获取图片 URL
    /// - Parameters:
    ///   - itemId: 媒体项 ID
    ///   - imageType: 图片类型（primary, backdrop, thumb 等）
    ///   - maxWidth: 最大宽度（可选，用于缩放）
    ///   - maxHeight: 最大高度（可选，用于缩放）
    ///   - tag: 图片标签（用于缓存控制，可选）
    /// - Returns: 图片 URL
    func getImageURL(
        itemId: String,
        imageType: APIEndpoint.ImageType,
        maxWidth: Int? = nil,
        maxHeight: Int? = nil,
        tag: String? = nil
    ) async throws -> URL {
        try await apiService.getImageURL(
            itemId: itemId,
            imageType: imageType,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            tag: tag
        )
    }

    /// 搜索媒体项
    /// - Parameters:
    ///   - searchTerm: 搜索关键词
    ///   - limit: 返回数量限制
    /// - Returns: 匹配的媒体项列表
    func searchItems(searchTerm: String, limit: Int = 20) async throws -> ItemsResponse {
        // 获取用户 ID
        let sessionInfo = try await authRepository.getSessionInfo()

        // TODO: 实现搜索逻辑（需要在 APIEndpoint 中添加搜索端点）
        // 目前使用 getItems 的简化版本
        return try await apiService.getItems(
            userId: sessionInfo.userId,
            parentId: nil,
            includeItemTypes: ["Movie", "Series", "Episode"],
            sortBy: "SortName",
            sortOrder: "Ascending",
            limit: limit,
            startIndex: nil,
            recursive: true,
            filters: nil
        )
    }
}

// MARK: - 依赖注入

extension MediaRepository {
    /// 使用现有的 API 服务和认证仓库创建实例
    static func create(
        apiService: EmbyAPIService,
        authRepository: AuthRepository
    ) -> MediaRepository {
        MediaRepository(apiService: apiService, authRepository: authRepository)
    }

    /// 共享实例（单例）
    ///
    /// 注意：首次使用时需要配置，否则 API 服务将使用空 baseURL
    static let shared: MediaRepository = {
        let apiService = EmbyAPIService(baseURL: "", tokenManager: TokenManager.shared)
        let authRepository = AuthRepository.shared
        return MediaRepository(apiService: apiService, authRepository: authRepository)
    }()
}
