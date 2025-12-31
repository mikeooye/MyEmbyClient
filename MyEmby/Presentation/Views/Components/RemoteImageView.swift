//
//  RemoteImageView.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// 远程图片视图（支持缓存和加载状态）
struct RemoteImageView: View {
    // MARK: - 属性

    /// 图片 URL
    let url: URL?

    /// 目标尺寸（用于优化加载）
    let targetSize: CGSize?

    /// 占位符（加载时显示）
    let placeholder: (() -> any View)?

    /// 错误视图（加载失败时显示）
    let errorView: (() -> any View)?

    /// 图片缓存
    @State private var image: UIImage?

    /// 加载状态
    @State private var isLoading = false

    /// 错误状态
    @State private var hasError = false

    /// 图片淡入动画
    @State private var imageOpacity: Double = 0

    // MARK: - 初始化

    /// 创建远程图片视图
    /// - Parameters:
    ///   - url: 图片 URL
    ///   - targetSize: 目标尺寸（用于优化加载）
    ///   - placeholder: 占位符视图
    ///   - errorView: 错误视图
    init(
        url: URL?,
        targetSize: CGSize? = nil,
        placeholder: (() -> any View)? = nil,
        errorView: (() -> any View)? = nil
    ) {
        self.url = url
        self.targetSize = targetSize
        self.placeholder = placeholder
        self.errorView = errorView
    }

    // MARK: - 视图主体

    var body: some View {
        Group {
            if let image = image {
                // 显示图片
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(imageOpacity)
                    .onAppear {
                        // 淡入动画
                        withAnimation(.easeInOut(duration: 0.3)) {
                            imageOpacity = 1.0
                        }
                    }
            } else if hasError, let errorView = errorView {
                // 显示错误视图
                AnyView(errorView())
            } else {
                // 显示占位符
                if let placeholder = placeholder {
                    AnyView(placeholder())
                } else {
                    // 默认占位符
                    defaultPlaceholder
                }
            }
        }
        .task {
            await loadImage()
        }
    }

    /// 默认占位符
    private var defaultPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.2)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
    }

    // MARK: - 私有方法

    /// 加载图片
    private func loadImage() async {
        guard let url = url else {
            hasError = true
            return
        }

        isLoading = true
        hasError = false

        do {
            // 检查内存缓存
            if let cachedImage = await ImageCache.shared.getImage(for: url) {
                image = cachedImage
                isLoading = false
                return
            }

            // 下载图片（使用单例）
            let downloadedImage = try await ImageLoader.shared.loadImage(from: url)

            // 缓存图片
            await ImageCache.shared.setImage(downloadedImage, for: url)

            // 更新 UI
            image = downloadedImage
            isLoading = false
        } catch {
            isLoading = false
            hasError = true
        }
    }
}

// MARK: - 便捷初始化方法

extension RemoteImageView {
    /// 使用 URL 字符串创建视图
    /// - Parameters:
    ///   - urlString: URL 字符串
    ///   - targetSize: 目标尺寸
    ///   - placeholder: 占位符视图
    ///   - errorView: 错误视图
    /// - Returns: 远程图片视图（如果 URL 无效则返回 nil）
    init?(
        urlString: String?,
        targetSize: CGSize? = nil,
        placeholder: (() -> any View)? = nil,
        errorView: (() -> any View)? = nil
    ) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }

        self.init(url: url, targetSize: targetSize, placeholder: placeholder, errorView: errorView)
    }
}

// MARK: - 预览

#Preview {
    VStack(spacing: 20) {
        // 测试 1: 有 URL
        RemoteImageView(
            url: URL(string: "https://picsum.photos/300/450")
        )
        .frame(width: 150, height: 225)
        .cornerRadius(8)

        // 测试 2: 自定义占位符
        RemoteImageView(
            url: URL(string: "https://example.com/image.jpg")
        ) {
            ZStack {
                Color.blue.opacity(0.2)
                ProgressView()
            }
        } errorView: {
            ZStack {
                Color.red.opacity(0.2)
                Image(systemName: "exclamationmark.triangle")
            }
        }
        .frame(width: 150, height: 225)
        .cornerRadius(8)

        // 测试 3: 无 URL
        RemoteImageView(url: nil)
            .frame(width: 150, height: 225)
            .cornerRadius(8)
    }
    .padding()
}
