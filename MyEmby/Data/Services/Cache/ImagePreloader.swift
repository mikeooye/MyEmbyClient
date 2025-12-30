//
//  ImagePreloader.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import UIKit

/// 图片预加载服务（提前加载图片以提升性能）
actor ImagePreloader {
    /// 共享单例
    static let shared = ImagePreloader()

    /// 最大并发加载数
    private let maxConcurrentLoads = 5

    /// 当前活跃的加载任务
    private var activeTasks: Set<Task<Void, Never>> = []

    /// 待加载队列（URL 优先级）
    private var pendingURLs: [(url: URL, priority: Double)] = []

    /// 初始化
    private init() {}

    /// 预加载单张图片
    /// - Parameter url: 图片 URL
    func preloadImage(_ url: URL) {
        preloadImages([url])
    }

    /// 预加载多张图片
    /// - Parameters:
    ///   - urls: 图片 URL 数组
    ///   - priority: 优先级（默认 0.0，数值越大优先级越高）
    func preloadImages(_ urls: [URL], priority: Double = 0.0) {
        // 添加到待加载队列
        for url in urls {
            // 检查是否已经在缓存中
            Task {
                if let _ = await ImageCache.shared.getImage(for: url) {
                    return // 已缓存，跳过
                }

                // 添加到待加载队列
                pendingURLs.append((url, priority))
            }
        }

        // 触发加载
        Task {
            await processQueue()
        }
    }

    /// 预加载媒体项的图片
    /// - Parameters:
    ///   - items: 媒体项数组
    ///   - imageProvider: 图片 URL 提供闭包
    func preloadItems<T: Collection>(
        _ items: T,
        imageProvider: @escaping (T.Element) async throws -> URL?,
        priority: Double = 0.0
    ) async {
        for item in items {
            // 限制并发数
            while activeTasks.count >= maxConcurrentLoads {
                await waitForTaskCompletion()
            }

            // 创建预加载任务
            let task = Task {
                do {
                    if let url = try await imageProvider(item) {
                        // 直接调用内部方法，避免 await
                        Task {
                            await preloadImage(url)
                        }
                    }
                } catch {
                    // 静默失败，不影响主流程
                    print("预加载图片失败: \(error)")
                }
            }

            activeTasks.insert(task)
        }
    }

    /// 取消所有预加载任务
    func cancelAll() {
        for task in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
        pendingURLs.removeAll()
    }

    /// 处理待加载队列
    private func processQueue() async {
        // 按优先级排序
        pendingURLs.sort { $0.priority > $1.priority }

        // 处理队列中的 URL
        while !pendingURLs.isEmpty {
            // 限制并发数
            while activeTasks.count >= maxConcurrentLoads && !activeTasks.isEmpty {
                await waitForTaskCompletion()
            }

            guard let (url, _) = pendingURLs.first else {
                break
            }
            pendingURLs.removeFirst()

            // 检查是否已在缓存中
            if let _ = await ImageCache.shared.getImage(for: url) {
                continue
            }

            // 创建加载任务
            let task = Task<Void, Never> {
                do {
                    let image = try await ImageLoader.shared.loadImage(from: url)
                    await ImageCache.shared.setImage(image, for: url)
                } catch {
                    // 静默失败
                }
            }

            activeTasks.insert(task)
        }
    }

    /// 等待任意一个任务完成
    private func waitForTaskCompletion() async {
        guard !activeTasks.isEmpty else { return }

        // 等待第一个完成的任务
        var completedTask: Task<Void, Never>?
        repeat {
            for task in activeTasks {
                if task.isCancelled {
                    completedTask = task
                    break
                }
            }

            if completedTask == nil {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
            }
        } while completedTask == nil

        if let task = completedTask {
            activeTasks.remove(task)
        }
    }

    /// 获取预加载统计信息
    func getStats() -> (activeTasks: Int, pendingURLs: Int) {
        return (activeTasks.count, pendingURLs.count)
    }
}
