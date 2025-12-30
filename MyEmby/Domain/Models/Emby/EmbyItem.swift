//
//  EmbyItem.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// Emby 媒体项模型（核心模型）
///
/// 用于表示 Emby 服务器中的所有媒体项（电影、剧集、季、单集、文件夹等）
struct EmbyItem: Codable, Identifiable, Equatable {
    // MARK: - 基础信息

    /// 唯一标识符
    let id: String

    /// 媒体项名称
    let name: String

    /// 原始名称（可能包含语言标签）
    let originalTitle: String?

    /// 媒体类型
    let type: String?

    /// 媒体分类（Movie, Series, Episode, Season, Folder 等）
    let collectionType: String?

    /// 父级 ID（所属文件夹或剧集）
    let parentId: String?

    /// 父级媒体的显示名称（用于剧集显示所属剧集名称）
    let seriesName: String?

    /// 季索引（0 表示特殊剧集）
    let seasonId: String?

    /// 季编号
    let seasonNumber: Int?

    /// 剧集编号
    let indexNumber: Int?

    /// 剧集总数（用于剧集系列）
    let episodeCount: Int?

    // MARK: - 时间信息

    /// 首映日期
    let premiereDate: Date?

    /// 结束日期（用于系列）
    let endDate: Date?

    /// 生产年份
    let productionYear: Int?

    /// 官方评分
    let communityRating: Double?

    /// 用户评分（当前用户）
    let userData: UserData?

    // MARK: - 内容信息

    /// 剧情简介
    let overview: String?

    /// 标签列表
    let tags: [String]?

    /// 类型列表（如 "Action", "Drama"）
    let genres: [String]?

    /// 工作室/制作公司
    let studios: [NamePair]?

    /// 导演列表
    let people: [NamePair]?

    /// 运行时长（秒）
    let runTimeTicks: Int64?

    /// 播放时长（秒，计算属性）
    var runTime: TimeInterval? {
        guard let ticks = runTimeTicks else { return nil }
        return TimeInterval(ticks) / 10_000_000
    }

    // MARK: - 图片信息

    /// 主图标签（用于缓存控制）
    let imageTags: ImageTags?

    /// 背景图标签
    let backdropImageTags: [String]?

    /// 缩略图标签
    let poster: ItemImageInfo?

    /// Logo 图标路径
    let logoImagePath: String?

    // MARK: - 播放信息

    /// 媒体源列表（包含不同质量的视频流）
    let mediaSources: [MediaSource]?

    /// 是否可以播放
    var canPlay: Bool {
        mediaSources != nil && !mediaSources!.isEmpty
    }

    /// 是否支持直播（仅用于直播频道）
    let isLive: Bool?

    /// 是否已播放
    var isPlayed: Bool {
        userData?.played == true
    }

    /// 是否收藏
    var isFavorite: Bool {
        userData?.isFavorite == true
    }

    /// 播放进度（0-100）
    var playedPercentage: Double {
        userData?.playedPercentage ?? 0
    }

    // MARK: - 路径信息

    /// 服务器路径
    let path: String?

    /// 首选元数据语言
    let preferredMetadataLanguage: String?

    /// 首选元数据国家代码
    let preferredMetadataCountryCode: String?

    // MARK: - 编码键

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case originalTitle = "OriginalTitle"
        case type = "Type"
        case collectionType = "CollectionType"
        case parentId = "ParentId"
        case seriesName = "SeriesName"
        case seasonId = "SeasonId"
        case seasonNumber = "SeasonNumber"
        case indexNumber = "IndexNumber"
        case episodeCount = "EpisodeCount"
        case premiereDate = "PremiereDate"
        case endDate = "EndDate"
        case productionYear = "ProductionYear"
        case communityRating = "CommunityRating"
        case userData = "UserData"
        case overview = "Overview"
        case tags = "Tags"
        case genres = "Genres"
        case studios = "Studios"
        case people = "People"
        case runTimeTicks = "RunTimeTicks"
        case imageTags = "ImageTags"
        case backdropImageTags = "BackdropImageTags"
        case poster = "Poster"
        case logoImagePath = "LogoImagePath"
        case mediaSources = "MediaSources"
        case isLive = "IsLive"
        case path = "Path"
        case preferredMetadataLanguage = "PreferredMetadataLanguage"
        case preferredMetadataCountryCode = "PreferredMetadataCountryCode"
    }
}

// MARK: - 辅助模型

/// 用户数据（播放状态、收藏等）
struct UserData: Codable, Equatable {
    /// 播放进度百分比
    let playedPercentage: Double?

    /// 是否已播放
    let played: Bool?

    /// 是否收藏
    let isFavorite: Bool?

    /// 上次播放时间（刻度）
    let lastPlayedDate: Date?

    /// 播放位置（刻度）
    let playbackPositionTicks: Int64?

    enum CodingKeys: String, CodingKey {
        case playedPercentage = "PlayedPercentage"
        case played = "Played"
        case isFavorite = "IsFavorite"
        case lastPlayedDate = "LastPlayedDate"
        case playbackPositionTicks = "PlaybackPositionTicks"
    }
}

/// 媒体源（包含视频流、音频流、字幕流信息）
struct MediaSource: Codable, Equatable {
    /// 唯一标识符
    let id: String?

    /// 容器格式（如 "mkv", "mp4"）
    let container: String?

    /// 文件大小（字节）
    let size: Int64?

    /// 媒体流列表（视频、音频、字幕）
    let mediaStreams: [MediaStream]?

    /// 是否支持直接播放
    let supportsDirectPlay: Bool?

    /// 是否支持转码
    let supportsTranscoding: Bool?

    /// 直播流 ID（用于直播）
    let liveStreamId: String?

    /// 音频流（方便访问）
    var audioStreams: [MediaStream] {
        mediaStreams?.filter { $0.type == "Audio" } ?? []
    }

    /// 字幕流（方便访问）
    var subtitleStreams: [MediaStream] {
        mediaStreams?.filter { $0.type == "Subtitle" } ?? []
    }

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case container = "Container"
        case size = "Size"
        case mediaStreams = "MediaStreams"
        case supportsDirectPlay = "SupportsDirectPlay"
        case supportsTranscoding = "SupportsTranscoding"
        case liveStreamId = "LiveStreamId"
    }
}

/// 媒体流（视频流、音频流、字幕流）
struct MediaStream: Codable, Equatable {
    /// 流索引（用于切换）
    let index: Int?

    /// 流类型（Video, Audio, Subtitle）
    let type: String?

    /// 编解码器（如 "h264", "aac", "srt"）
    let codec: String?

    /// 语言代码
    let language: String?

    /// 显示标题
    let displayTitle: String?

    /// 是否是默认流
    let isDefault: Bool?

    /// 是否是外部流（外部字幕文件）
    let isExternal: Bool?

    /// 字幕格式（srt, ass, vtt 等）
    let codecTag: String?

    /// 视频宽度
    let width: Int?

    /// 视频高度
    let height: Int?

    /// 音频/视频比特率
    let bitRate: Int?

    /// 频道数（音频）
    let channels: Int?

    /// 采样率（音频）
    let sampleRate: Int?

    /// 流标题
    let title: String?

    enum CodingKeys: String, CodingKey {
        case index = "Index"
        case type = "Type"
        case codec = "Codec"
        case language = "Language"
        case displayTitle = "DisplayTitle"
        case isDefault = "IsDefault"
        case isExternal = "IsExternal"
        case codecTag = "CodecTag"
        case width = "Width"
        case height = "Height"
        case bitRate = "BitRate"
        case channels = "Channels"
        case sampleRate = "SampleRate"
        case title = "Title"
    }
}

/// 名称-ID 对（用于工作室、演员等）
struct NamePair: Codable, Equatable {
    /// 名称
    let name: String?

    /// 唯一标识符
    let id: String?

    /// 主图标签
    let primaryImageTag: String?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case id = "Id"
        case primaryImageTag = "PrimaryImageTag"
    }
}

/// 图片标签集合
struct ImageTags: Codable, Equatable {
    /// 主图标签（Primary）
    let primary: String?

    /// 艺术图标签
    let art: String?

    /// 背景图标签
    let backdrop: String?

    /// 标志图标签
    let banner: String?

    /// 缩略图标签
    let thumb: String?

    /// Logo 标签
    let logo: String?

    enum CodingKeys: String, CodingKey {
        case primary = "Primary"
        case art = "Art"
        case backdrop = "Backdrop"
        case banner = "Banner"
        case thumb = "Thumb"
        case logo = "Logo"
    }
}

/// 项目图片信息
struct ItemImageInfo: Codable, Equatable {
    /// 图片标签（用于缓存控制）
    let blurhash: String?

    /// 图片标签
    let tag: String?

    /// 图片类型
    let imageType: String?

    enum CodingKeys: String, CodingKey {
        case blurhash = "Blurhash"
        case tag = "Tag"
        case imageType = "ImageType"
    }
}
