import Foundation
import Security

public struct KeychainClient: Sendable {
    public init() {}

    public func readData(service: String, account: String) throws -> Data {
        var query: [String: Any] = [
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
            throw SecurityError.keyNotFound
        case errSecItemNotFound:
            throw SecurityError.keyNotFound
        default:
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
            throw SecurityError.keychainFailure(status: Int(updateStatus))
        }

        var add: [String: Any] = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = accessible

        let addStatus = SecItemAdd(add as CFDictionary, nil)
        if addStatus != errSecSuccess {
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
        throw SecurityError.keychainFailure(status: Int(status))
    }
}

