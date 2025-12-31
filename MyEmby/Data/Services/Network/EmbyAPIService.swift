//
//  EmbyAPIService.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import UIKit

/// Emby API 服务（核心网络层）
///
/// 职责：
/// - 处理所有与 Emby 服务器的网络通信
/// - 管理认证和 Token
/// - 错误处理和重试逻辑
final class EmbyAPIService {

    // MARK: - 属性

    private let baseURL: String
    private let tokenManager: TokenManager
    private let session: URLSession

    /// 依赖注入
    init(
        baseURL: String,
        tokenManager: TokenManager,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.tokenManager = tokenManager
        self.session = session
    }

    // MARK: - 认证相关

    /// 通过用户名和密码认证
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    /// - Returns: 认证响应
    func authenticate(username: String, password: String) async throws -> EmbyAuthResponse {
        let endpoint = APIEndpoint.authenticateByName

        // 构建请求体
        let requestBody = [
            "Username": username,
            "Pw": password
        ]

        // 登录接口不需要认证
        var request = try await createRequest(for: endpoint, requiresAuth: false)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        return try await performRequest(request)
    }

    // MARK: - 用户相关

    /// 获取用户信息
    /// - Parameter userId: 用户 ID
    /// - Returns: 用户信息
    func getUserInfo(userId: String) async throws -> EmbyUser {
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "info", value: "true"))

        let request = try await createRequest(
            for: APIEndpoint.getUserInfo(userId: userId),
            queryItems: queryItems,
            requiresAuth: true
        )

        return try await performRequest(request)
    }

    /// 获取用户的媒体库视图（分类列表）
    /// - Parameter userId: 用户 ID
    /// - Returns: 媒体库视图响应（包含分类列表）
    func getUserViews(userId: String) async throws -> ViewsResponse {
        let request = try await createRequest(
            for: APIEndpoint.getUserViews(userId: userId),
            requiresAuth: true
        )

        return try await performRequest(request)
    }

    // MARK: - 媒体项相关

    /// 获取媒体项列表（支持筛选和排序）
    /// - Parameters:
    ///   - userId: 用户 ID
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
        userId: String,
        parentId: String? = nil,
        includeItemTypes: [String]? = nil,
        sortBy: String? = nil,
        sortOrder: String? = nil,
        limit: Int? = nil,
        startIndex: Int? = nil,
        recursive: Bool = true,
        filters: [String]? = nil
    ) async throws -> ItemsResponse {
        var queryItems: [URLQueryItem] = []

        // 添加查询参数
        if let parentId = parentId {
            queryItems.append(URLQueryItem(name: "ParentId", value: parentId))
        }

        if let types = includeItemTypes {
            queryItems.append(URLQueryItem(name: "IncludeItemTypes", value: types.joined(separator: ",")))
        }

        if let sort = sortBy {
            queryItems.append(URLQueryItem(name: "SortBy", value: sort))
        }

        if let order = sortOrder {
            queryItems.append(URLQueryItem(name: "SortOrder", value: order))
        }

        if let limit = limit {
            queryItems.append(URLQueryItem(name: "Limit", value: "\(limit)"))
        }

        if let start = startIndex {
            queryItems.append(URLQueryItem(name: "StartIndex", value: "\(start)"))
        }

        queryItems.append(URLQueryItem(name: "Recursive", value: recursive ? "true" : "false"))

        if let filters = filters {
            queryItems.append(URLQueryItem(name: "Filters", value: filters.joined(separator: ",")))
        }

        let request = try await createRequest(
            for: APIEndpoint.getItems(userId: userId),
            queryItems: queryItems,
            requiresAuth: true
        )

        return try await performRequest(request)
    }

    /// 获取单个媒体项详情
    /// - Parameters:
    ///   - userId: 用户 ID
    ///   - itemId: 媒体项 ID
    /// - Returns: 媒体项详情
    func getItem(userId: String, itemId: String) async throws -> EmbyItem {
        let request = try await createRequest(
            for: APIEndpoint.getItem(userId: userId, itemId: itemId),
            requiresAuth: true
        )

        return try await performRequest(request)
    }
    
    /// 获取媒体播放信息
    ///   - Parameters:
    ///     - userId: 用户ID
    ///     - itemId： 媒体项ID
    func getItemsByIdPlaybackInfo(userId: String, itemId: String) async throws -> PlaybackInfo {
        let request = try await createRequest(
            for: APIEndpoint.getPlaybackInfo(itemId: itemId),
            queryItems: [
                URLQueryItem(name: "UserId", value: userId)
            ],
            requiresAuth: true
        )
        return try await performRequest(request)
    }

    /// 获取最新添加的媒体项
    /// - Parameters:
    ///   - userId: 用户 ID
    ///   - parentId: 父级 ID（可选，限制在特定分类下）
    ///   - limit: 返回数量限制
    ///   - includeItemTypes: 包含的媒体类型
    /// - Returns: 最新媒体项列表
    func getLatestItems(
        userId: String,
        parentId: String? = nil,
        limit: Int = 10,
        includeItemTypes: [String]? = nil
    ) async throws -> [EmbyItem] {
        var queryItems: [URLQueryItem] = []

        queryItems.append(URLQueryItem(name: "Limit", value: "\(limit)"))

        if let parentId = parentId {
            queryItems.append(URLQueryItem(name: "ParentId", value: parentId))
        }

        if let types = includeItemTypes {
            queryItems.append(URLQueryItem(name: "IncludeItemTypes", value: types.joined(separator: ",")))
        }

        let request = try await createRequest(
            for: APIEndpoint.getLatestItems(userId: userId),
            queryItems: queryItems,
            requiresAuth: true
        )

        return try await performRequest(request)
    }
    
    // MARK: - 视频相关
    
    /// 获取播放地址
    func getPlaybackURL(for itemId: String) async throws -> URL {
        // 构建播放 URL
        // Emby 播放端点格式: /Videos/{itemId}/stream?Static=true&api_key={apiKey}
        // MKV 无法播放，需要转换
        var components = URLComponents(string: "\(baseURL)/Videos/\(itemId)/stream")!
        let apiKey = await getAPIKey()
        components.queryItems = [
            URLQueryItem(name: "Static", value: "true"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        return url
    }

    // MARK: - 图片相关

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
        var queryItems: [URLQueryItem] = []

        // 添加尺寸参数
        if let width = maxWidth {
            queryItems.append(URLQueryItem(name: "maxWidth", value: "\(width)"))
        }

        if let height = maxHeight {
            queryItems.append(URLQueryItem(name: "maxHeight", value: "\(height)"))
        }

        // 添加图片标签（用于缓存控制）
        if let tag = tag {
            queryItems.append(URLQueryItem(name: "tag", value: tag))
        }

        return try APIEndpoint.getImage(
            itemId: itemId,
            imageType: imageType,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        ).url(baseURL: baseURL, queryItems: queryItems)
    }

    // MARK: - 通用请求方法

    /// 执行网络请求
    /// - Parameter request: URL 请求
    /// - Returns: 解码后的响应对象
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        // 打印请求信息
        NetworkLogger.logRequest(request)

        // 发起请求
        let (data, response) = try await session.data(for: request)

        // 打印响应信息
        NetworkLogger.logResponse(response, data: data)

        // 检查 HTTP 状态码
        if let error = NetworkError.from(response: response) {
            NetworkLogger.logError(error)
            throw error
        }

        // 解码响应
        do {
            let decoder = JSONDecoder()
            // 处理日期格式（Emby 使用多种日期格式）
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()

                // 尝试 1: 解析 ISO8601 格式的字符串日期（如 "2025-12-12T05:13:30.8479860Z"）
                if let dateString = try? container.decode(String.self) {
                    // 使用 ISO8601DateFormatter
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [
                        .withInternetDateTime,
                        .withFractionalSeconds
                    ]

                    if let date = isoFormatter.date(from: dateString) {
                        return date
                    }

                    // 尝试不带分数秒的格式
                    isoFormatter.formatOptions = [.withInternetDateTime]
                    if let date = isoFormatter.date(from: dateString) {
                        return date
                    }

                    // 尝试字符串形式的 Unix 时间戳（数字字符串）
                    if let timestamp = Double(dateString) {
                        return Date(timeIntervalSince1970: timestamp / 1000) // 毫秒转秒
                    }
                }

                // 尝试 2: 解析 Double 类型的 Unix 时间戳
                if let timestamp = try? container.decode(Double.self) {
                    return Date(timeIntervalSince1970: timestamp)
                }

                // 所有尝试都失败
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "无法解析日期，支持的格式：ISO8601、Unix 时间戳（Double/String）"
                )
            }

            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            NetworkLogger.logError(error)
            throw NetworkError.decodingError(error)
        } catch {
            NetworkLogger.logError(error)
            throw NetworkError.decodingError(error)
        }
    }

    /// 执行不返回数据的网络请求（DELETE 等）
    /// - Parameter request: URL 请求
    func performVoidRequest(_ request: URLRequest) async throws {
        let (_, response) = try await session.data(for: request)

        if let error = NetworkError.from(response: response) {
            throw error
        }
    }

    // MARK: - 请求构建

    /// 创建 URL 请求
    /// - Parameters:
    ///   - endpoint: API 端点
    ///   - queryItems: 查询参数
    ///   - requiresAuth: 是否需要认证
    /// - Returns: URL 请求
    private func createRequest(
        for endpoint: APIEndpoint,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> URLRequest {
        // 构建 URL
        let url = try endpoint.url(baseURL: baseURL, queryItems: queryItems)

        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // 添加认证头
        if requiresAuth {
            // 添加 api_key 参数到 URL
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var items = components?.queryItems ?? []

            // 获取 api_key
            if let apiKey = await getAPIKey() {
                items.append(URLQueryItem(name: "api_key", value: apiKey))
            }

            components?.queryItems = items
            if let newURL = components?.url {
                request.url = newURL
            }
        }

        // 添加通用请求头
        // 使用官方客户端标识，避免被服务器阻止
        request.setValue("Emby for iOS", forHTTPHeaderField: "X-Emby-Client")
        request.setValue("iPhone", forHTTPHeaderField: "X-Emby-Device-Name")
        request.setValue(UIDevice.current.identifierForVendor?.uuidString ?? "unknown", forHTTPHeaderField: "X-Emby-Device-Id")

        // 添加认证头（即使不需要 token 也要添加，因为 Emby 需要客户端信息）
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let authHeader = "MediaBrowser Client=\"Emby for iOS\", Device=\"iPhone\", DeviceId=\"\(deviceId)\", Version=\"1.0.0.0\""
        request.setValue(authHeader, forHTTPHeaderField: "X-Emby-Authorization")

        // 添加额外的认证信息
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }

    // MARK: - 辅助方法

    /// 获取查询参数（包含 api_key）
    private func getQueryItems() async -> [URLQueryItem] {
        do {
            let items = try await tokenManager.getAPIQueryItems()
            return items
        } catch {
            return []
        }
    }

    /// 获取 API Key
    private func getAPIKey() async -> String? {
        do {
            return try await tokenManager.getAccessToken()
        } catch {
            return nil
        }
    }
}

// MARK: - 便捷方法

extension EmbyAPIService {
    /// 使用服务器配置创建 API 服务实例
    static func create(config: ServerConfig, tokenManager: TokenManager) -> EmbyAPIService {
        EmbyAPIService(baseURL: config.baseURL, tokenManager: tokenManager)
    }
}
