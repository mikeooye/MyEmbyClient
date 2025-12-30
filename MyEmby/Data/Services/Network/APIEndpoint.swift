//
//  APIEndpoint.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// Emby API 端点枚举
enum APIEndpoint {
    // MARK: - 认证相关
    case authenticateByName
    case login(userId: String)

    // MARK: - 用户相关
    case getUserInfo(userId: String)
    case getUserViews(userId: String)

    // MARK: - 媒体项相关
    case getItems(userId: String)
    case getItem(userId: String, itemId: String)
    case getLatestItems(userId: String)

    // MARK: - 搜索
    case searchItems(userId: String)

    // MARK: - 收藏
    case getFavoriteItems(userId: String)
    case addFavoriteItem(userId: String, itemId: String)
    case removeFavoriteItem(userId: String, itemId: String)

    // MARK: - 播放相关
    case getPlaybackInfo(userId: String, itemId: String)

    // MARK: - 图片
    case getImage(itemId: String, imageType: ImageType, maxWidth: Int?, maxHeight: Int?)

    /// 图片类型
    enum ImageType: String {
        case primary
        case backdrop
        case banner
        case thumb
        case logo
    }

    /// 构建 URL 路径
    var path: String {
        switch self {
        // 认证
        case .authenticateByName:
            return "/Users/authenticatebyname"
        case .login(let userId):
            return "/Users/\(userId)/Login"

        // 用户
        case .getUserInfo(let userId):
            return "/Users/\(userId)"
        case .getUserViews(let userId):
            return "/Users/\(userId)/Views"

        // 媒体项
        case .getItems(let userId):
            return "/Users/\(userId)/Items"
        case .getItem(let userId, let itemId):
            return "/Users/\(userId)/Items/\(itemId)"
        case .getLatestItems(let userId):
            return "/Users/\(userId)/Items/Latest"

        // 搜索
        case .searchItems(let userId):
            return "/Users/\(userId)/Items"

        // 收藏
        case .getFavoriteItems(let userId):
            return "/Users/\(userId)/Items"
        case .addFavoriteItem(let userId, let itemId):
            return "/Users/\(userId)/FavoriteItems/\(itemId)"
        case .removeFavoriteItem(let userId, let itemId):
            return "/Users/\(userId)/FavoriteItems/\(itemId)"

        // 播放
        case .getPlaybackInfo(let userId, let itemId):
            return "/Users/\(userId)/Items/\(itemId)/PlaybackInfo"

        // 图片
        case .getImage(let itemId, let imageType, _, _):
            return "/Items/\(itemId)/Images/\(imageType.rawValue)"
        }
    }

    /// HTTP 方法
    var method: HTTPMethod {
        switch self {
        case .authenticateByName, .login:
            return .post
        case .addFavoriteItem:
            return .post
        case .removeFavoriteItem:
            return .delete
        default:
            return .get
        }
    }

    /// HTTP 方法枚举
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
}

// MARK: - URL 构建

extension APIEndpoint {
    /// 构建完整的 URL
    /// - Parameters:
    ///   - baseURL: 服务器基础 URL
    ///   - queryItems: 查询参数
    /// - Returns: 完整的 URL
    func url(baseURL: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }

        // 添加查询参数
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        return url
    }
}
