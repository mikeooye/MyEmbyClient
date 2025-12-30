//
//  EmbyUser.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// Emby 用户信息模型
struct EmbyUser: Codable, Identifiable, Equatable {
    /// 用户唯一标识符
    let id: String
    /// 用户名
    let name: String
    /// 服务器标识符
    let serverId: String?
    /// 用户名前缀（通常是首字母）
    let prefix: String?
    /// 账户创建时间
    let dateCreated: Date?
    /// 是否设置了密码
    let hasPassword: Bool
    /// 是否配置了密码
    let hasConfiguredPassword: Bool
    /// 是否配置了简易密码
    let hasConfiguredEasyPassword: Bool?
    /// 主图标签（用于图片缓存）
    let primaryImageTag: String?
    /// 最后登录时间
    let lastLoginDate: Date?
    /// 最后活动时间
    let lastActivityDate: Date?
    /// 用户配置
    let configuration: UserConfiguration?
    /// 用户策略（权限设置）
    let policy: UserPolicy?

    /// Codable 编码键（Emby API 使用 PascalCase）
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case serverId = "ServerId"
        case prefix = "Prefix"
        case dateCreated = "DateCreated"
        case hasPassword = "HasPassword"
        case hasConfiguredPassword = "HasConfiguredPassword"
        case hasConfiguredEasyPassword = "HasConfiguredEasyPassword"
        case primaryImageTag = "PrimaryImageTag"
        case lastLoginDate = "LastLoginDate"
        case lastActivityDate = "LastActivityDate"
        case configuration = "Configuration"
        case policy = "Policy"
    }
}

/// 用户配置
struct UserConfiguration: Codable, Equatable {
    /// 播放默认音频轨道
    let playDefaultAudioTrack: Bool?
    /// 显示缺失剧集
    let displayMissingEpisodes: Bool?
    /// 字幕模式
    let subtitleMode: String?
    /// 排序的媒体库视图
    let orderedViews: [String]?
    /// 最新项目中排除的项
    let latestItemsExcludes: [String]?
    /// 我的媒体中排除的项
    let myMediaExcludes: [String]?
    /// 在"最新"中隐藏已播放
    let hidePlayedInLatest: Bool?
    /// 在"更多类似"中隐藏已播放
    let hidePlayedInMoreLikeThis: Bool?
    /// 在"建议"中隐藏已播放
    let hidePlayedInSuggestions: Bool?
    /// 记住音频选择
    let rememberAudioSelections: Bool?
    /// 记住字幕选择
    let rememberSubtitleSelections: Bool?
    /// 自动播放下一集
    let enableNextEpisodeAutoPlay: Bool?
    /// 恢复倒退秒数
    let resumeRewindSeconds: Int?
    /// 片头跳过模式
    let introSkipMode: String?
    /// 启用本地密码
    let enableLocalPassword: Bool?
    /// 音频语言偏好
    let audioLanguagePreference: String?
    /// 字幕语言偏好
    let subtitleLanguagePreference: String?
    /// 分组文件夹
    let groupedFolders: [String]?
    /// 显示集合视图
    let displayCollectionsView: Bool?

    enum CodingKeys: String, CodingKey {
        case playDefaultAudioTrack = "PlayDefaultAudioTrack"
        case displayMissingEpisodes = "DisplayMissingEpisodes"
        case subtitleMode = "SubtitleMode"
        case orderedViews = "OrderedViews"
        case latestItemsExcludes = "LatestItemsExcludes"
        case myMediaExcludes = "MyMediaExcludes"
        case hidePlayedInLatest = "HidePlayedInLatest"
        case hidePlayedInMoreLikeThis = "HidePlayedInMoreLikeThis"
        case hidePlayedInSuggestions = "HidePlayedInSuggestions"
        case rememberAudioSelections = "RememberAudioSelections"
        case rememberSubtitleSelections = "RememberSubtitleSelections"
        case enableNextEpisodeAutoPlay = "EnableNextEpisodeAutoPlay"
        case resumeRewindSeconds = "ResumeRewindSeconds"
        case introSkipMode = "IntroSkipMode"
        case enableLocalPassword = "EnableLocalPassword"
        case audioLanguagePreference = "AudioLanguagePreference"
        case subtitleLanguagePreference = "SubtitleLanguagePreference"
        case groupedFolders = "GroupedFolders"
        case displayCollectionsView = "DisplayCollectionsView"
    }
}

/// 用户策略（权限设置）
struct UserPolicy: Codable, Equatable {
    /// 是否是管理员
    let isAdministrator: Bool?
    /// 是否隐藏
    let isHidden: Bool?
    /// 是否远程隐藏
    let isHiddenRemotely: Bool?
    /// 是否从未使用设备隐藏
    let isHiddenFromUnusedDevices: Bool?
    /// 是否禁用
    let isDisabled: Bool?
    /// 锁定日期
    let lockedOutDate: Int?
    /// 允许标签或评级
    let allowTagOrRating: Bool?
    /// 阻止的标签
    let blockedTags: [String]?
    /// 标签阻止模式是否包含
    let isTagBlockingModeInclusive: Bool?
    /// 包含的标签
    let includeTags: [String]?
    /// 启用用户偏好访问
    let enableUserPreferenceAccess: Bool?
    /// 访问时间表
    let accessSchedules: [String]?
    /// 阻止未评级项目
    let blockUnratedItems: [String]?
    /// 启用对其他用户的远程控制
    let enableRemoteControlOfOtherUsers: Bool?
    /// 启用共享设备控制
    let enableSharedDeviceControl: Bool?
    /// 启用远程访问
    let enableRemoteAccess: Bool?
    /// 启用直播电视管理
    let enableLiveTvManagement: Bool?
    /// 启用直播电视访问
    let enableLiveTvAccess: Bool?
    /// 启用媒体播放
    let enableMediaPlayback: Bool?
    /// 启用音频转码
    let enableAudioPlaybackTranscoding: Bool?
    /// 启用视频转码
    let enableVideoPlaybackTranscoding: Bool?
    /// 启用播放重封装
    let enablePlaybackRemuxing: Bool?
    /// 启用内容删除
    let enableContentDeletion: Bool?
    /// 受限功能
    let restrictedFeatures: [String]?
    /// 从文件夹启用内容删除
    let enableContentDeletionFromFolders: [String]?
    /// 启用内容下载
    let enableContentDownloading: Bool?
    /// 启用字幕下载
    let enableSubtitleDownloading: Bool?
    /// 启用字幕管理
    let enableSubtitleManagement: Bool?
    /// 启用同步转码
    let enableSyncTranscoding: Bool?
    /// 启用媒体转换
    let enableMediaConversion: Bool?
    /// 启用的频道
    let enabledChannels: [String]?
    /// 启用所有频道
    let enableAllChannels: Bool?
    /// 启用的文件夹
    let enabledFolders: [String]?
    /// 启用所有文件夹
    let enableAllFolders: Bool?
    /// 无效登录尝试次数
    let invalidLoginAttemptCount: Int?
    /// 启用公共共享
    let enablePublicSharing: Bool?
    /// 远程客户端比特率限制
    let remoteClientBitrateLimit: Int?
    /// 认证提供者 ID
    let authenticationProviderId: String?
    /// 排除的子文件夹
    let excludedSubFolders: [String]?
    /// 同时流限制
    let simultaneousStreamLimit: Int?
    /// 启用的设备
    let enabledDevices: [String]?
    /// 启用所有设备
    let enableAllDevices: Bool?
    /// 允许摄像头上传
    let allowCameraUpload: Bool?
    /// 允许共享个人项目
    let allowSharingPersonalItems: Bool?

    enum CodingKeys: String, CodingKey {
        case isAdministrator = "IsAdministrator"
        case isHidden = "IsHidden"
        case isHiddenRemotely = "IsHiddenRemotely"
        case isHiddenFromUnusedDevices = "IsHiddenFromUnusedDevices"
        case isDisabled = "IsDisabled"
        case lockedOutDate = "LockedOutDate"
        case allowTagOrRating = "AllowTagOrRating"
        case blockedTags = "BlockedTags"
        case isTagBlockingModeInclusive = "IsTagBlockingModeInclusive"
        case includeTags = "IncludeTags"
        case enableUserPreferenceAccess = "EnableUserPreferenceAccess"
        case accessSchedules = "AccessSchedules"
        case blockUnratedItems = "BlockUnratedItems"
        case enableRemoteControlOfOtherUsers = "EnableRemoteControlOfOtherUsers"
        case enableSharedDeviceControl = "EnableSharedDeviceControl"
        case enableRemoteAccess = "EnableRemoteAccess"
        case enableLiveTvManagement = "EnableLiveTvManagement"
        case enableLiveTvAccess = "EnableLiveTvAccess"
        case enableMediaPlayback = "EnableMediaPlayback"
        case enableAudioPlaybackTranscoding = "EnableAudioPlaybackTranscoding"
        case enableVideoPlaybackTranscoding = "EnableVideoPlaybackTranscoding"
        case enablePlaybackRemuxing = "EnablePlaybackRemuxing"
        case enableContentDeletion = "EnableContentDeletion"
        case restrictedFeatures = "RestrictedFeatures"
        case enableContentDeletionFromFolders = "EnableContentDeletionFromFolders"
        case enableContentDownloading = "EnableContentDownloading"
        case enableSubtitleDownloading = "EnableSubtitleDownloading"
        case enableSubtitleManagement = "EnableSubtitleManagement"
        case enableSyncTranscoding = "EnableSyncTranscoding"
        case enableMediaConversion = "EnableMediaConversion"
        case enabledChannels = "EnabledChannels"
        case enableAllChannels = "EnableAllChannels"
        case enabledFolders = "EnabledFolders"
        case enableAllFolders = "EnableAllFolders"
        case invalidLoginAttemptCount = "InvalidLoginAttemptCount"
        case enablePublicSharing = "EnablePublicSharing"
        case remoteClientBitrateLimit = "RemoteClientBitrateLimit"
        case authenticationProviderId = "AuthenticationProviderId"
        case excludedSubFolders = "ExcludedSubFolders"
        case simultaneousStreamLimit = "SimultaneousStreamLimit"
        case enabledDevices = "EnabledDevices"
        case enableAllDevices = "EnableAllDevices"
        case allowCameraUpload = "AllowCameraUpload"
        case allowSharingPersonalItems = "AllowSharingPersonalItems"
    }
}

