//
//  NetworkLogger.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// 网络请求调试工具
enum NetworkLogger {
    /// 打印请求详情
    static func logRequest(_ request: URLRequest) {
        print("==========================================")
        print("📤 HTTP Request")
        print("==========================================")
        print("URL: \(request.url?.absoluteString ?? "nil")")
        print("Method: \(request.httpMethod ?? "nil")")

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("Headers:")
            for (key, value) in headers {
                print("  \(key): \(value)")
            }
        }

        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }

        if let queryItems = URLComponents(string: request.url?.absoluteString ?? "")?.queryItems {
            print("Query Parameters:")
            for item in queryItems {
                print("  \(item.name): \(item.value ?? "nil")")
            }
        }

        print("==========================================\n")
    }

    /// 打印响应详情
    static func logResponse(_ response: URLResponse, data: Data) {
        print("==========================================")
        print("📥 HTTP Response")
        print("==========================================")

        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers:")
            if let headers = httpResponse.allHeaderFields as? [String: String] {
                for (key, value) in headers {
                    print("  \(key): \(value)")
                }
            }
        }

        if let responseString = String(data: data, encoding: .utf8) {
            // 增加输出长度限制到 5000 字符
            let output = responseString.count > 5000
                ? responseString.prefix(5000) + "... (truncated)"
                : responseString
            print("Body:\n\(output)")
        }

        print("==========================================\n")
    }

    /// 打印错误
    static func logError(_ error: Error) {
        print("==========================================")
        print("❌ Network Error")
        print("==========================================")
        print("Error: \(error.localizedDescription)")

        // 如果是 DecodingError，显示详细信息
        if let decodingError = error as? DecodingError {
            logDecodingError(decodingError)
        } else if let networkError = error as? NetworkError {
            print("Network Error Type: \(networkError)")
            print("Alert Title: \(networkError.alertTitle)")
            print("Alert Message: \(networkError.alertMessage)")
        }

        print("==========================================\n")
    }

    /// 打印 JSON 解码错误的详细信息
    private static func logDecodingError(_ error: DecodingError) {
        print("📋 JSON Decoding Error Details:")

        switch error {
        case .typeMismatch(let type, let context):
            print("  ❌ Type Mismatch:")
            print("     Expected Type: \(type)")
            print("     Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("     Description: \(context.debugDescription)")

            if let underlyingError = context.underlyingError {
                print("     Underlying Error: \(underlyingError)")
            }

        case .valueNotFound(let type, let context):
            print("  ❌ Value Not Found:")
            print("     Expected Type: \(type)")
            print("     Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("     Description: \(context.debugDescription)")

        case .keyNotFound(let key, let context):
            print("  ❌ Key Not Found:")
            print("     Missing Key: \(key.stringValue)")
            print("     Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("     Description: \(context.debugDescription)")

        case .dataCorrupted(let context):
            print("  ❌ Data Corrupted:")
            print("     Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("     Description: \(context.debugDescription)")

            if let underlyingError = context.underlyingError {
                print("     Underlying Error: \(underlyingError)")
            }

        @unknown default:
            print("  ❌ Unknown Decoding Error:")
            print("     Description: \(error.localizedDescription)")
        }
    }
}
