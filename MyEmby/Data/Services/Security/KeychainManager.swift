//
//  KeychainManager.swift
//  MyEmby
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Security

/// Keychain 错误类型
enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedStatus(OSStatus)
    case encodingError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "未找到指定的 Keychain 项"
        case .duplicateItem:
            return "Keychain 中已存在该项"
        case .invalidData:
            return "无效的数据格式"
        case .unexpectedStatus(let status):
            return "意外的 Keychain 状态码: \(status)"
        case .encodingError(let error):
            return "数据编码失败: \(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解码失败: \(error.localizedDescription)"
        }
    }
}

/// Keychain 管理器（原生实现，不依赖第三方库）
///
/// 功能：
/// - 存储和检索敏感数据（Token、密码等）
/// - 支持泛型，可存储任何 Codable 类型
/// - 线程安全
/// - 自动处理错误
actor KeychainManager {
    
    static let shared = KeychainManager()

    // MARK: - 配置

    /// Keychain 服务标识符（通常是 Bundle ID）
    private let service: String

    /// Keychain 访问组（用于 App 共享数据，可选）
    private let accessGroup: String?

    // MARK: - 初始化

    private init(service: String? = nil, accessGroup: String? = nil) {
        // 默认使用 Bundle ID 作为服务标识符
        self.service = service ?? Bundle.main.bundleIdentifier ?? "com.myemby.app"
        self.accessGroup = accessGroup
    }

    // MARK: - 公共方法

    /// 保存数据到 Keychain
    /// - Parameters:
    ///   - value: 要保存的值（必须符合 Codable 协议）
    ///   - key: 存储键
    func save<T: Codable>(_ value: T, for key: String) throws {
        let data = try JSONEncoder().encode(value)

        // 构建查询字典
      let query = baseQuery(for: key)

        // 先尝试更新现有项
        let updateStatus = SecItemUpdate(query as CFDictionary, [
            kSecValueData: data
        ] as CFDictionary)

        // 如果项不存在，则添加新项
        if updateStatus == errSecItemNotFound {
            var addItem = query
          addItem[kSecValueData as String] = data

            let addStatus = SecItemAdd(addItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    /// 从 Keychain 读取数据
    /// - Parameters:
    ///   - key: 存储键
    ///   - type: 目标类型
    /// - Returns: 解码后的值
    func get<T: Codable>(for key: String, as type: T.Type) throws -> T {
        var query = baseQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.unexpectedStatus(status)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw KeychainError.decodingError(error)
        }
    }

    /// 删除 Keychain 中的数据
    /// - Parameter key: 存储键
    func delete(for key: String) throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// 检查 Keychain 中是否存在某个键
    /// - Parameter key: 存储键
    /// - Returns: 是否存在
    func exists(for key: String) -> Bool {
        var query = baseQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// 清空所有 Keychain 数据（慎用！）
    func clearAll() throws {
        let query = baseQuery(for: "")
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - 私有方法

    /// 构建基础查询字典
    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        // 如果设置了访问组，添加到查询中
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        // 设置数据保护级别（设备解锁后才能访问）
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        return query
    }
}

// MARK: - 便捷扩展

extension KeychainManager {
    /// 便捷方法：存储字符串
    func save(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query = baseQuery(for: key)
        let updateStatus = SecItemUpdate(query as CFDictionary, [
            kSecValueData: data
        ] as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var addItem = query
            addItem[kSecValueData as String] = data
            let addStatus = SecItemAdd(addItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    /// 便捷方法：读取字符串
    func getString(for key: String) throws -> String {
        var query = baseQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedStatus(status)
        }

        return string
    }
}
