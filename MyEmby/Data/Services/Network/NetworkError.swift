//
//  NetworkError.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// 网络错误类型
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noInternetConnection
    case requestFailed(Error)
    case invalidResponse
    case httpError(statusCode: Int)
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case decodingError(Error)
    case encodingError(Error)
    case invalidData
    case tokenExpired
    case unknown(Error)

    /// 错误描述
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL 地址"
        case .noInternetConnection:
            return "网络连接不可用，请检查网络设置"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "服务器响应无效"
        case .httpError(let statusCode):
            return "HTTP 错误: 状态码 \(statusCode)"
        case .unauthorized:
            return "认证失败，请重新登录"
        case .forbidden:
            return "没有访问权限"
        case .notFound:
            return "请求的资源不存在"
        case .serverError:
            return "服务器错误，请稍后重试"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .encodingError(let error):
            return "数据编码失败: \(error.localizedDescription)"
        case .invalidData:
            return "无效的数据格式"
        case .tokenExpired:
            return "登录已过期，请重新登录"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }

    /// 用户友好的错误信息
    var localizedDescription: String {
        errorDescription ?? "发生未知错误"
    }

    /// 是否可以重试
    var isRetryable: Bool {
        switch self {
        case .noInternetConnection, .serverError, .requestFailed:
            return true
        default:
            return false
        }
    }

    /// 是否需要重新登录
    var requiresReauthentication: Bool {
        switch self {
        case .unauthorized, .tokenExpired:
            return true
        default:
            return false
        }
    }

    /// 从 URLResponse 创建 NetworkError
    static func from(response: URLResponse) -> NetworkError? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return .invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return nil
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 408, 502...504:
            return .serverError
        case 500...599:
            return .serverError
        default:
            return .httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - 自定义错误展示

extension NetworkError {
    /// 获取用于 Alert 的错误信息
    var alertMessage: String {
        switch self {
        case .noInternetConnection:
            return "请检查您的网络连接后重试"
        case .unauthorized, .tokenExpired:
            return "请重新登录以继续使用"
        case .serverError:
            return "服务器暂时无法响应，请稍后重试"
        case .notFound:
            return "请求的内容不存在"
        default:
            return errorDescription ?? "发生错误，请稍后重试"
        }
    }

    /// 获取用于 Alert 的标题
    var alertTitle: String {
        switch self {
        case .noInternetConnection:
            return "网络连接失败"
        case .unauthorized, .tokenExpired:
            return "需要重新登录"
        case .serverError:
            return "服务器错误"
        case .notFound:
            return "未找到内容"
        default:
            return "操作失败"
        }
    }
}
