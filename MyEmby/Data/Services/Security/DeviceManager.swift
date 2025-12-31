//
//  DeviceManager.swift
//  MyEmby
//
//  Created by lihaozhen on 2025/12/31.
//

import UIKit

actor DeviceManager {
    static let shared = DeviceManager()
    private let deviceIdKey = "com.myemby.device_id"

    func getOrCreateDeviceId() async -> String {
        // 使用单例访问 Keychain
        if let savedId = try? await KeychainManager.shared.getString(for: deviceIdKey) {
            return savedId
        }

        let newId = await MainActor.run {
            UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        }

        // 存储新生成的 ID
        try? await KeychainManager.shared.save(newId, for: deviceIdKey)
        return newId
    }
}
