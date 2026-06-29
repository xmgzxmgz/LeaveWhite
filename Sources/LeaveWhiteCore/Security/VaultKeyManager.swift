import CryptoKit
import Foundation
import os

public actor VaultKeyManager {
    public struct KeyDescriptor: Sendable {
        public var service: String
        public var account: String
        public init(service: String, account: String) {
            self.service = service
            self.account = account
        }
    }

    private let keychain: KeychainClient
    private let realKey: KeyDescriptor
    private let decoyKey: KeyDescriptor

    public init(
        keychain: KeychainClient = KeychainClient(),
        realKey: KeyDescriptor = .init(service: "com.leavewhite.vault", account: "vaultkey.real"),
        decoyKey: KeyDescriptor = .init(service: "com.leavewhite.vault", account: "vaultkey.decoy")
    ) {
        self.keychain = keychain
        self.realKey = realKey
        self.decoyKey = decoyKey
    }

    public func getOrCreateKey(for mode: VaultMode) throws -> SymmetricKey {
        let descriptor = descriptor(for: mode)
        do {
            let data = try keychain.readData(service: descriptor.service, account: descriptor.account)
            return SymmetricKey(data: data)
        } catch {
            if let securityError = error as? SecurityError, securityError == .keyNotFound {
                let key = SymmetricKey(size: .bits256)
                let raw = key.withUnsafeBytes { Data($0) }
                try keychain.upsertData(raw, service: descriptor.service, account: descriptor.account)
                return key
            }
            LWLog.security.error("VaultKeyManager.getOrCreateKey failed: \(error, privacy: .public)")
            throw error
        }
    }

    public func rotateKey(for mode: VaultMode) throws {
        let descriptor = descriptor(for: mode)
        let key = SymmetricKey(size: .bits256)
        let raw = key.withUnsafeBytes { Data($0) }
        try keychain.upsertData(raw, service: descriptor.service, account: descriptor.account)
    }

    private func descriptor(for mode: VaultMode) -> KeyDescriptor {
        switch mode {
        case .real:
            return realKey
        case .decoy:
            return decoyKey
        }
    }
}

