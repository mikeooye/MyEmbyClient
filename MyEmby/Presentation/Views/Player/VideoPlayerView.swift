//
//  VideoPlayerView.swift
//  MyEmby
//
//  基于 MPVKit 的视频播放器视图
//

import SwiftUI
import Combine
import LibMPV

/// MPV 金属播放器视图 (SwiftUI 包装)
struct MPVMetalPlayerView: UIViewControllerRepresentable {
    /// 播放器引用观察器
    @ObservedObject var playerObserver: PlayerObserver

    /// 播放器时间变化回调
    var onTimeChange: ((Double) -> Void)?

    /// 播放器时长变化回调
    var onDurationChange: ((Double) -> Void)?

    /// 播放器播放状态变化回调
    var onPlayingChange: ((Bool) -> Void)?

    func makeUIViewController(context: Context) -> MPVMetalViewController {
        let mpvVC = MPVMetalViewController()
        mpvVC.playDelegate = context.coordinator

        // 保存播放器引用
        Task { @MainActor in
            playerObserver.player = mpvVC
        }

        return mpvVC
    }

    func updateUIViewController(_ uiViewController: MPVMetalViewController, context: Context) {
        // 无需更新
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onTimeChange: onTimeChange,
            onDurationChange: onDurationChange,
            onPlayingChange: onPlayingChange
        )
    }

    /// 播放器协调器
    final class Coordinator: NSObject, MPVPlayerDelegate {
        var onTimeChange: ((Double) -> Void)?
        var onDurationChange: ((Double) -> Void)?
        var onPlayingChange: ((Bool) -> Void)?

        init(
            onTimeChange: ((Double) -> Void)?,
            onDurationChange: ((Double) -> Void)?,
            onPlayingChange: ((Bool) -> Void)?
        ) {
            self.onTimeChange = onTimeChange
            self.onDurationChange = onDurationChange
            self.onPlayingChange = onPlayingChange
        }

        nonisolated func propertyChange(mpv: OpaquePointer, propertyName: String, data: Any?) {
            switch propertyName {
            case "time-pos":
                if let time = data as? Double {
                    Task { @MainActor in
                        onTimeChange?(time)
                    }
                }
            case "duration":
                if let duration = data as? Double {
                    Task { @MainActor in
                        onDurationChange?(duration)
                    }
                }
            case "pause":
                if let paused = data as? Bool {
                    Task { @MainActor in
                        onPlayingChange?(!paused)
                    }
                }
            default:
                break
            }
        }
    }
}

/// 播放器观察器 (用于保存播放器引用)
final class PlayerObserver: ObservableObject {
     weak var player: MPVMetalViewController?
}

// MARK: - 视频播放器视图

/// 视频播放器视图
struct VideoPlayerView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - 属性

    /// 媒体项 ID
    let itemId: String

    /// 播放器观察器
    @StateObject private var playerObserver = PlayerObserver()

    /// 是否显示控制栏
    @State private var showControls = true

    /// 控制栏自动隐藏定时器
    @State private var controlsHideTimer: Timer?

    /// 播放状态
    @State private var isPlaying = false

    /// 当前播放时间
    @State private var currentTime: TimeInterval = 0

    /// 总时长
    @State private var totalDuration: TimeInterval = 0

    /// 是否加载中
    @State private var isLoading = true

    /// 错误信息
    @State private var errorMessage: String?

    // MARK: - 初始化

    init(itemId: String) {
        self.itemId = itemId
    }

    // MARK: - 视图主体

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // MPV 播放器
            MPVMetalPlayerView(
                playerObserver: playerObserver,
                onTimeChange: { time in
                    currentTime = time
                },
                onDurationChange: { duration in
                    totalDuration = duration
                    if duration > 0 {
                        isLoading = false
                    }
                },
                onPlayingChange: { playing in
                    isPlaying = playing
                }
            )
            .task {
                await loadMedia()
            }
            .ignoresSafeArea()

            // 控制层
            if showControls {
                controlsOverlay
                    .transition(.opacity)
            }

            // 关闭按钮
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .onTapGesture(count: 2) {
            withAnimation {
                showControls.toggle()
            }
        }
    }

    // MARK: - 设置

    /// 加载媒体项
    private func loadMedia() async {
        // 等待播放器准备就绪
        while playerObserver.player == nil {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }

        guard let controller = playerObserver.player else { return }

        do {
            let authRepository = AuthRepository.shared
            let apiService = try await authRepository.getAPIService()

            // 获取播放 URL
            let playbackURL = try await apiService.getPlaybackURL(for: itemId)
            debugPrint("playback URL: \(playbackURL)")

            controller.loadFile(playbackURL)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
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
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景轨道
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)

                    // 进度
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 4)

                    // 进度圆点
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: geometry.size.width * progress - 8)
                }
            }
            .frame(height: 16)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let progress = max(0, min(1, value.location.x / UIScreen.main.bounds.width))
                    let time = progress * totalDuration
                    playerObserver.player?.seek(to: time)
                    resetControlsHideTimer()
                }
        )
    }

    /// 进度（0.0 - 1.0）
    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return currentTime / totalDuration
    }

    /// 时间显示区域
    private var timeSection: some View {
        HStack {
            // 当前时间
            Text(formatTime(currentTime))
                .font(.system(size: 14))
                .foregroundColor(.white)

            Spacer()

            // 总时长
            Text(formatTime(totalDuration))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    /// 控制按钮区域
    private var controlsSection: some View {
        HStack(spacing: 32) {
            // 快退按钮
            Button(action: {
                let newTime = max(0, currentTime - 10)
                playerObserver.player?.seek(to: newTime)
                resetControlsHideTimer()
            }) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            // 播放/暂停按钮
            Button(action: {
                playerObserver.player?.togglePause()
                resetControlsHideTimer()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                    .frame(width: 66, height: 66)
            }

            // 快进按钮
            Button(action: {
                let newTime = min(totalDuration, currentTime + 10)
                playerObserver.player?.seek(to: newTime)
                resetControlsHideTimer()
            }) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - 私有方法

    /// 格式化时间显示
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "0:00" }

        let secs = Int(seconds)
        let mins = secs / 60
        let hours = mins / 60
        let remainingMins = mins % 60
        let remainingSecs = secs % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, remainingMins, remainingSecs)
        } else {
            return String(format: "%d:%02d", mins, remainingSecs)
        }
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
    VideoPlayerView(itemId: "test-id")
}
