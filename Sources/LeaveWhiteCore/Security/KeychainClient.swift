import Foundation
import Security
import os

public struct KeychainClient: Sendable {
    private static let logger = LWLog.security

    public init() {}

    public func readData(service: String, account: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            if let data = item as? Data {
                return data
            }
            Self.logger.error("Keychain read succeeded but item is not Data for service=\(service, privacy: .public)")
            throw SecurityError.keyNotFound
        case errSecItemNotFound:
            Self.logger.debug("Keychain item not found for service=\(service, privacy: .public) account=\(account, privacy: .public)")
            throw SecurityError.keyNotFound
        default:
            Self.logger.error("Keychain read failed with status \(Int(status)) for service=\(service, privacy: .public)")
            throw SecurityError.keychainFailure(status: Int(status))
        }
    }

    public func upsertData(
        _ data: Data,
        service: String,
        account: String,
        accessible: CFString = kSecAttrAccessibleWhenUnlocked
    ) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let update: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus != errSecItemNotFound {
            Self.logger.error("Keychain update failed with status \(Int(updateStatus)) for service=\(service, privacy: .public)")
            throw SecurityError.keychainFailure(status: Int(updateStatus))
        }

        var add: [String: Any] = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = accessible

        let addStatus = SecItemAdd(add as CFDictionary, nil)
        if addStatus != errSecSuccess {
            Self.logger.error("Keychain insert failed with status \(Int(addStatus)) for service=\(service, privacy: .public)")
            throw SecurityError.keychainFailure(status: Int(addStatus))
        }
    }

    public func delete(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            return
        }
        Self.logger.error("Keychain delete failed with status \(Int(status)) for service=\(service, privacy: .public)")
        throw SecurityError.keychainFailure(status: Int(status))
    }
}

