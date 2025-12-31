//
//  PlayerViewModel.swift
//  MyEmby
//
//  Created by Claude on 2025/12/30.
//

import Foundation
import Observation
import AVFoundation
import Combine

/// 播放器视图模型
@Observable
@MainActor
final class PlayerViewModel {
    // MARK: - 状态
    
    /// 媒体项
    private(set) var item: EmbyItem?
    
    /// 是否正在加载
    var isLoading = false
    
    /// 错误信息
    var errorMessage: String?
    
    /// AVPlayer 实例
    var player: AVPlayer?
    
    /// 播放器项目（用于控制时间观察）
    private var playerItem: AVPlayerItem?
    
    /// 时间观察者
    private var timeObserver: AnyCancellable?
    
    /// 播放 URL
    private var playbackURL: URL?
    
    // MARK: - 播放状态
    
    /// 总时长（秒）
    private(set) var totalDuration: TimeInterval = 0
    
    /// 当前播放时间（秒）
    private(set) var currentTime: TimeInterval = 0
    
    /// 是否正在播放
    private(set) var isPlaying: Bool = false
    
    /// 播放进度（0.0 - 1.0）
    private(set) var playbackProgress: Double = 0
    
    /// 缓冲进度（0.0 - 1.0）
    private(set) var bufferingProgress: Double = 0
    
    // MARK: - 依赖
    
    private let authRepository: AuthRepository
    
    // MARK: - 初始化
    
    init(authRepository: AuthRepository? = nil) {
        self.authRepository = authRepository ?? .shared
    }
    
    func onDisappear() {
        cleanup()
    }
    
    // MARK: - 公共方法
    
    /// 设置媒体项并准备播放
    /// - Parameter item: 媒体项
    func loadItem(_ item: EmbyItem) async {
        self.item = item
        isLoading = true
        errorMessage = nil
        
        do {
            // 获取播放 URL
            let url = try await getPlaybackURL(for: item)
            debugPrint("play url: \(url)")
            self.playbackURL = url
            
            // 创建播放器
            setupPlayer(with: url)
            
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    /// 播放/暂停切换
    func togglePlayPause() {
        guard let player = player else { return }
        
        if player.rate == 0 {
            // 当前暂停，开始播放
            player.play()
            isPlaying = true
        } else {
            // 当前播放，暂停
            player.pause()
            isPlaying = false
        }
    }
    
    /// 播放
    func play() {
        player?.play()
        isPlaying = true
    }
    
    /// 暂停
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    /// 快进 10 秒
    func forward() {
        guard let player = player else { return }
        let newTime = min(currentTime + 10, totalDuration)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
    }
    
    /// 快退 10 秒
    func backward() {
        guard let player = player else { return }
        let newTime = max(currentTime - 10, 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
    }
    
    /// 跳转到指定时间
    /// - Parameter time: 目标时间（秒）
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }
    
    /// 设置播放速度
    /// - Parameter speed: 播放速度（0.5 = 慢放, 1.0 = 正常, 2.0 = 快放）
    func setPlaybackSpeed(_ speed: Float) {
        player?.rate = isPlaying ? speed : 0
    }
    
    // MARK: - 私有方法
    
    /// 获取播放 URL
    private func getPlaybackURL(for item: EmbyItem) async throws -> URL {
        // 获取 API 服务
        let apiService = try await authRepository.getAPIService()
        let sessionInfo = try await authRepository.getSessionInfo()
        let playbackInfo = try await apiService.getItemsByIdPlaybackInfo(userId: sessionInfo.userId, itemId: item.id)
        debugPrint("playbackinfo: \(playbackInfo)")
        return try await apiService.getPlaybackURL(for: item.id)
    }
    
    /// 设置播放器
    private func setupPlayer(with url: URL) {
        // 清理旧的播放器
        cleanup()
        
        // 创建新的播放器项目
        let playerItem = AVPlayerItem(url: url)
        self.playerItem = playerItem
        
        // 创建播放器
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        
        // 观察播放状态
        observePlayback()
    }
    
    /// 观察播放状态
    private func observePlayback() {
        guard let player = player, let playerItem = playerItem else { return }
        
        // 使用 AVPlayer 的 API 监听时间，并转换为 Publisher
        let timePublisher = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .map { _ in player.currentTime() }
        
        // 观察已缓存范围 (LoadedTimeRanges)
        let bufferPublisher = playerItem.publisher(for: \.loadedTimeRanges)
        
        // 观察时间变化
        timeObserver = timePublisher
            .combineLatest(bufferPublisher)
            .sink { [weak self] time, ranges in
                // time 是 CMTime 类型
                self?.updatePlaybackStatus()
            }
        
        // 观察播放结束
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    /// 更新播放状态
    private func updatePlaybackStatus() {
        guard let playerItem = playerItem else { return }
        
        // 更新总时长
        let duration = playerItem.duration.seconds
        if duration.isFinite {
            totalDuration = duration
        }
        
        // 更新当前时间
        currentTime = playerItem.currentTime().seconds
        
        // 更新播放进度
        if totalDuration > 0 {
            playbackProgress = currentTime / totalDuration
        }
        
        // 更新缓冲进度
        if let loadedTimeRanges = playerItem.loadedTimeRanges.first?.timeRangeValue {
            let bufferedDuration = loadedTimeRanges.start.seconds + loadedTimeRanges.duration.seconds
            bufferingProgress = min(bufferedDuration / totalDuration, 1.0)
        }
    }
    
    /// 播放结束回调
    @objc private func playerDidFinishPlaying() {
        isPlaying = false
        playbackProgress = 1.0
    }
    
    /// 清理资源
    private func cleanup() {
        player?.pause()
        player = nil
        playerItem = nil
        timeObserver?.cancel()
        timeObserver = nil
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 便捷扩展

extension PlayerViewModel {
    /// 格式化时间显示
    /// - Parameter seconds: 秒数
    /// - Returns: 格式化的时间字符串（如 "1:23:45" 或 "3:45"）
    func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let hours = mins / 60
        let remainingMins = mins % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, remainingMins, secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }
}
