//
//  ImageCache.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import UIKit

/// 图片缓存服务（基于 NSCache）
actor ImageCache {
    /// 共享单例
    static let shared = ImageCache()

    /// 内存缓存
    private let cache = NSCache<NSString, UIImage>()

    /// 缓存键生成器
    private func cacheKey(for url: URL) -> NSString {
        url.absoluteString as NSString
    }

    /// 初始化
    private init() {
        // 设置缓存限制（根据设备内存调整）
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        cache.countLimit = 100 // 最多 100 张图片
    }

    /// 获取图片
    /// - Parameter url: 图片 URL
    /// - Returns: 缓存的图片（如果存在）
    func getImage(for url: URL) -> UIImage? {
        cache.object(forKey: cacheKey(for: url))
    }

    /// 保存图片
    /// - Parameters:
    ///   - image: 要缓存的图片
    ///   - url: 图片 URL
    func setImage(_ image: UIImage, for url: URL) {
        // 估算图片大小（用于缓存成本计算）
        let cost = Int(image.size.width * image.size.height * 4) // RGBA = 4 字节/像素
        cache.setObject(image, forKey: cacheKey(for: url), cost: cost)
    }

    /// 清除所有缓存
    func removeAll() {
        cache.removeAllObjects()
    }

    /// 移除指定图片
    /// - Parameter url: 图片 URL
    func removeImage(for url: URL) {
        cache.removeObject(forKey: cacheKey(for: url))
    }
}

/// 图片加载器（负责下载图片）
actor ImageLoader {
    /// 共享单例
    static let shared = ImageLoader()

    /// URLSession 单例
    private let session: URLSession

    /// 初始化
    private init(session: URLSession = .shared) {
        // 配置 URLSession（使用默认缓存策略）
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50 MB 内存缓存
            diskCapacity: 200 * 1024 * 1024,   // 200 MB 磁盘缓存
            diskPath: "emby_image_cache"
        )
        // 添加超时配置
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    /// 加载图片
    /// - Parameter url: 图片 URL
    /// - Returns: 加载的图片
    func loadImage(from url: URL) async throws -> UIImage {
        // 发起网络请求
        let (data, _) = try await session.data(from: url)

        // 解码图片
        guard let image = UIImage(data: data) else {
            throw NetworkError.decodingError(NSError(
                domain: "ImageLoader",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无法解码图片数据"]
            ))
        }

        return image
    }
}
