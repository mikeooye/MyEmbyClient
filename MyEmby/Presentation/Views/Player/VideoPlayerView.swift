//
//  VideoPlayerView.swift
//  MyEmby
//
//  Created by Claude on 2025/12/30.
//

import SwiftUI
import AVKit

/// 视频播放器视图
struct VideoPlayerView: View {
    @Environment(\.dismiss) var dismiss // 获取系统关闭动作
    
    // MARK: - 属性

    /// 视图模型
    @State private var viewModel: PlayerViewModel

    /// 媒体项 ID
    let itemId: String

    /// 是否显示控制栏
    @State private var showControls = true

    /// 控制栏自动隐藏定时器
    @State private var controlsHideTimer: Timer?

    // MARK: - 初始化

    /// 创建播放器视图
    /// - Parameters:
    ///   - itemId: 媒体项 ID
    ///   - viewModel: 播放器视图模型
    @MainActor
    init(itemId: String, viewModel: PlayerViewModel) {
        self.itemId = itemId
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - 视图主体

    var body: some View {
        ZStack {
            if let player = viewModel.player {
                // 视频播放器
                VideoPlayer(player: player)
                    .onAppear {
                        // 加载媒体项
                        Task {
                            await loadItem()
                        }
                    }
            } else if viewModel.isLoading {
                // 加载状态
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                // 错误状态
                errorView(message: errorMessage)
            } else {
                // 初始状态
                loadingView
            }

            // 控制层
            if showControls {
                controlsOverlay
                    .transition(.opacity)
            }
            Button("关闭") {
                dismiss() // 点击后关闭全屏
            }
            .foregroundColor(.white)
        }
        .onAppear( perform: {
            Task {
                await loadItem()
            }
        })
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onTapGesture(count: 2) {
            // 双击切换控制栏显示
            withAnimation {
                showControls.toggle()
            }
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    // MARK: - 子视图

    /// 控制层
    private var controlsOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            // 控制面板
            VStack(spacing: 16) {
                // 进度条
                progressSection

                // 时间显示
                timeSection

                // 控制按钮
                controlsSection
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .background(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            resetControlsHideTimer()
        }
    }

    /// 进度条区域
    private var progressSection: some View {
        VStack(spacing: 8) {
            // 进度条
            ProgressView(value: viewModel.playbackProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(x: 1, y: 2, anchor: .center)

            // 缓冲进度
            ProgressView(value: viewModel.bufferingProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .white.opacity(0.3)))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .offset(y: -8)
        }
    }

    /// 时间显示区域
    private var timeSection: some View {
        HStack {
            // 当前时间
            Text(viewModel.formatTime(viewModel.currentTime))
                .font(.system(size: 14))
                .foregroundColor(.white)

            Spacer()

            // 总时长
            Text(viewModel.formatTime(viewModel.totalDuration))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    /// 控制按钮区域
    private var controlsSection: some View {
        HStack(spacing: 32) {
            // 快退按钮
            Button(action: {
                viewModel.backward()
                resetControlsHideTimer()
            }) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            // 播放/暂停按钮
            Button(action: {
                viewModel.togglePlayPause()
                resetControlsHideTimer()
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                    .frame(width: 66, height: 66)
            }

            // 快进按钮
            Button(action: {
                viewModel.forward()
                resetControlsHideTimer()
            }) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
    }

    /// 加载视图
    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("加载中...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
    }

    /// 错误视图
    private func errorView(message: String) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)

                Text("播放失败")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("重试") {
                    Task {
                        await loadItem()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - 私有方法

    /// 加载媒体项
    private func loadItem() async {
        // 需要先获取媒体项信息
        // 这里简化处理，假设 itemId 已经足够
        // 实际需要从 API 获取完整的 EmbyItem

        // TODO: 从 API 获取媒体项
        // 临时创建一个模拟的媒体项用于测试
        let mockItem = EmbyItem(
            id: itemId,
            name: "测试视频",
            originalTitle: nil,
            type: "Video",
            collectionType: nil,
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

        await viewModel.loadItem(mockItem)
    }

    /// 重置控制栏隐藏定时器
    private func resetControlsHideTimer() {
        controlsHideTimer?.invalidate()
        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            withAnimation {
                showControls = false
            }
        }
    }
}

// MARK: - 预览

#Preview {
    VideoPlayerView(itemId: "test-id", viewModel: PlayerViewModel())
}
