//
//  MPVMetalViewController.swift
//  MyEmby
//
//  基于 MPVKit (Libmpv) 实现的 mpv 视频播放控制器
//

import Foundation
import UIKit
import MetalKit
import LibMPV

/// MPV 金属渲染视图控制器
final class MPVMetalViewController: UIViewController {

    // MARK: - 属性

    /// Metal 渲染层
    var metalLayer = CAMetalLayer()

    /// mpv 实例指针
    var mpv: OpaquePointer!

    /// 播放委托
    weak var playDelegate: MPVPlayerDelegate?

    /// 异步队列
    private lazy var queue = DispatchQueue(label: "mpv", qos: .userInitiated)

    /// 当前播放 URL
    var playUrl: URL?

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMetalLayer()
        setupMpv()

        if let url = playUrl {
            loadFile(url)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        metalLayer.frame = view.frame

        // 重新设置 wid (视图大小改变时可能需要)
        if mpv != nil {
            mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &metalLayer)
            print("mpv: viewDidLayoutSubviews, wid updated")
        }
    }

    // MARK: - 初始化

    /// 设置 Metal 渲染层
    private func setupMetalLayer() {
        metalLayer.frame = view.bounds
        metalLayer.contentsScale = UIScreen.main.nativeScale
        metalLayer.framebufferOnly = true
        metalLayer.backgroundColor = UIColor.black.cgColor

        view.layer.addSublayer(metalLayer)
    }

    /// 设置 mpv
    private func setupMpv() {
        // 创建 mpv 实例
        mpv = mpv_create()
        if mpv == nil {
            print("mpv: failed creating context")
            return
        }
        print("mpv: context created")

        // 设置日志级别
#if DEBUG
        mpv_request_log_messages(mpv, "debug")
#else
        mpv_request_log_messages(mpv, "no")
#endif
        print("mpv: log messages configured")

        // 配置 mpv 选项
        configureMpvOptions()
        print("mpv: options configured")

        // 初始化 mpv
        let initResult = mpv_initialize(mpv)
        print("mpv: initialize result: \(initResult)")

        // 观察属性
        setupPropertyObservers()
        print("mpv: property observers set")

        // 设置唤醒回调 (使用全局上下文)
        let callbackCtx = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        mpv_set_wakeup_callback(mpv, { ctx in
            guard let ctx = ctx else { return }
            let controller = Unmanaged<MPVMetalViewController>.fromOpaque(ctx).takeUnretainedValue()
            DispatchQueue.main.async {
                controller.readEvents()
            }
        }, callbackCtx)
        print("mpv: wakeup callback set")

        // 设置通知
        setupNotifications()
        print("mpv: setup complete")
    }

    /// 配置 mpv 选项
    private func configureMpvOptions() {
        // 设置渲染层 - gpu-next 不稳定，备用 gpu
        mpv_set_option_string(mpv, "vo", "gpu")
        mpv_set_option_string(mpv, "gpu-api", "metal")

        // 设置硬件解码
        mpv_set_option_string(mpv, "hwdec", "videotoolbox")

        // 设置字幕选项
        mpv_set_option_string(mpv, "subs-match-os-language", "yes")
        mpv_set_option_string(mpv, "subs-fallback", "yes")

        // 禁用视频旋转
        mpv_set_option_string(mpv, "video-rotate", "no")

        // 设置 HTTP 请求头 (解决 403 Forbidden 问题)
        mpv_set_option_string(mpv, "user-agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1")
        mpv_set_option_string(mpv, "referrer", "https://emby.hutaoindex.com/")

        // 设置窗口 ID (直接使用 metalLayer 的指针)
        mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &metalLayer)
    }

    /// 设置属性观察
    private func setupPropertyObservers() {
        mpv_observe_property(mpv, 0, "time-pos", MPV_FORMAT_DOUBLE)
        mpv_observe_property(mpv, 0, "duration", MPV_FORMAT_DOUBLE)
        mpv_observe_property(mpv, 0, "pause", MPV_FORMAT_FLAG)
        mpv_observe_property(mpv, 0, "paused-for-cache", MPV_FORMAT_FLAG)
    }

    /// 设置通知
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    // MARK: - 后台/前台处理

    @objc private func enterBackground() {
        // 进入后台时暂停并隐藏视频
        pause()
        var vidDisable: Int64 = 1
        mpv_set_property(mpv, "vid", MPV_FORMAT_INT64, &vidDisable)
    }

    @objc private func enterForeground() {
        // 进入前台时恢复视频
        var vidEnable: Int64 = 0
        mpv_set_property(mpv, "vid", MPV_FORMAT_INT64, &vidEnable)
        play()
    }

    // MARK: - 播放控制

    /// 加载文件
    /// - Parameter url: 文件 URL
    func loadFile(_ url: URL) {
        guard mpv != nil else {
            print("mpv: loadFile failed - mpv is nil")
            return
        }
        print("mpv: loading file: \(url.absoluteString)")
        let args = [url.absoluteString, "replace"]
        command("loadfile", args: args)
    }

    /// 切换播放/暂停
    func togglePause() {
        if isPaused() {
            play()
        } else {
            pause()
        }
    }

    /// 播放
    func play() {
        setFlag("pause", false)
    }

    /// 暂停
    func pause() {
        setFlag("pause", true)
    }

    /// 是否已暂停
    func isPaused() -> Bool {
        return getFlag("pause")
    }

    /// 跳转到指定时间
    /// - Parameters:
    ///   - time: 目标时间（秒）
    ///   - type: 跳转类型
    func seek(to time: Double, type: SeekType = .relative) {
        let typeStr: String
        switch type {
        case .relative:
            typeStr = "relative"
        case .absolute:
            typeStr = "absolute"
        case .absolutePercent:
            typeStr = "absolute-percent"
        case .relativePercent:
            typeStr = "relative-percent"
        }
        let args = [String(time), typeStr]
        command("seek", args: args)
    }

    /// 跳转类型
    enum SeekType {
        case relative
        case absolute
        case absolutePercent
        case relativePercent
    }

    // MARK: - 属性获取

    /// 获取双精度属性
    /// - Parameter name: 属性名
    /// - Returns: 属性值
    func getDouble(_ name: String) -> Double {
        guard mpv != nil else { return 0.0 }
        var data = Double()
        mpv_get_property(mpv, name, MPV_FORMAT_DOUBLE, &data)
        return data
    }

    /// 获取布尔属性
    /// - Parameter name: 属性名
    /// - Returns: 属性值
    func getFlag(_ name: String) -> Bool {
        guard mpv != nil else { return false }
        var data = Int64()
        mpv_get_property(mpv, name, MPV_FORMAT_FLAG, &data)
        return data > 0
    }

    /// 设置布尔属性
    /// - Parameters:
    ///   - name: 属性名
    ///   - flag: 值
    private func setFlag(_ name: String, _ flag: Bool) {
        guard mpv != nil else { return }
        var data: Int = flag ? 1 : 0
        mpv_set_property(mpv, name, MPV_FORMAT_FLAG, &data)
    }

    // MARK: - 命令执行

    /// 执行 mpv 命令
    /// - Parameters:
    ///   - command: 命令名
    ///   - args: 命令参数
    func command(_ command: String, args: [String?] = []) {
        guard mpv != nil else { return }

        var cargs = makeCArgs(command, args).map { $0.flatMap { UnsafePointer<CChar>(strdup($0)) } }
        defer {
            for ptr in cargs where ptr != nil {
                free(UnsafeMutablePointer(mutating: ptr!))
            }
        }

        let returnValue = mpv_command(mpv, &cargs)
        if returnValue < 0 {
            print("mpv command error: \(String(cString: mpv_error_string(returnValue)))")
        }
    }

    /// 构建 C 风格参数
    private func makeCArgs(_ command: String, _ args: [String?]) -> [String?] {
        if !args.isEmpty, args.last == nil {
            fatalError("Command does not need a nil suffix")
        }

        var strArgs = args
        strArgs.insert(command, at: 0)
        strArgs.append(nil)

        return strArgs
    }

    /// 检查 mpv 错误
    private func checkError(_ status: CInt) {
        if status < 0 {
            print("mpv API error: \(String(cString: mpv_error_string(status)))")
        }
    }

    // MARK: - 事件处理

    /// 读取事件
    private func readEvents() {
        queue.async { [weak self] in
            guard let self = self else { return }

            while self.mpv != nil {
                let event = mpv_wait_event(self.mpv, 0)
                if event?.pointee.event_id == MPV_EVENT_NONE {
                    break
                }

                self.handleEvent(event)
            }
        }
    }

    /// 处理事件
    private func handleEvent(_ event: UnsafePointer<mpv_event>?) {
        guard let event = event else { return }

        switch event.pointee.event_id {
        case MPV_EVENT_PROPERTY_CHANGE:
            handlePropertyChange(event.pointee.data)

        case MPV_EVENT_SHUTDOWN:
            print("mpv shutdown")
            mpv_terminate_destroy(mpv)
            mpv = nil

        case MPV_EVENT_LOG_MESSAGE:
            #if DEBUG
            if let msg = UnsafeMutablePointer<mpv_event_log_message>(OpaquePointer(event.pointee.data)) {
                let prefix = String(cString: msg.pointee.prefix)
                let level = String(cString: msg.pointee.level)
                let text = String(cString: msg.pointee.text)
                print("[\(prefix)] \(level): \(text)")
            }
            #endif

        default:
            if let eventName = mpv_event_name(event.pointee.event_id) {
                print("mpv event: \(String(cString: eventName))")
            }
        }
    }

    /// 处理属性变化
    private func handlePropertyChange(_ data: UnsafeMutableRawPointer?) {
        guard let data = data else { return }

        let property = UnsafePointer<mpv_event_property>(OpaquePointer(data)).pointee
        let propertyName = String(cString: property.name)
        print("mpv property change: \(propertyName)")

        switch propertyName {
        case "time-pos":
            if let value = UnsafePointer<Double>(OpaquePointer(property.data))?.pointee {
                print("mpv time-pos: \(value)")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.playDelegate?.propertyChange(mpv: self.mpv, propertyName: propertyName, data: value)
                }
            }

        case "duration":
            if let value = UnsafePointer<Double>(OpaquePointer(property.data))?.pointee {
                print("mpv duration: \(value)")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.playDelegate?.propertyChange(mpv: self.mpv, propertyName: propertyName, data: value)
                }
            }

        case "pause":
            if let value = UnsafePointer<Bool>(OpaquePointer(property.data))?.pointee {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.playDelegate?.propertyChange(mpv: self.mpv, propertyName: propertyName, data: value)
                }
            }

        case "paused-for-cache":
            if let value = UnsafePointer<Bool>(OpaquePointer(property.data))?.pointee {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.playDelegate?.propertyChange(mpv: self.mpv, propertyName: propertyName, data: value)
                }
            }

        default:
            break
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - MPVPlayerDelegate

/// MPV 播放委托协议
public protocol MPVPlayerDelegate: AnyObject {
    func propertyChange(mpv: OpaquePointer, propertyName: String, data: Any?)
}
