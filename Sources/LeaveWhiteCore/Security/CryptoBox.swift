import CryptoKit
import Foundation
import os

public struct CryptoBox: Sendable {
    private static let logger = LWLog.security

    private let keyManager: VaultKeyManager

    public init(keyManager: VaultKeyManager = VaultKeyManager()) {
        self.keyManager = keyManager
    }

    public func encrypt(_ plaintext: Data, mode: VaultMode, aad: Data? = nil) async throws -> Data {
        let key = try await keyManager.getOrCreateKey(for: mode)
        do {
            let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: aad ?? Data())
            guard let combined = sealed.combined else {
                Self.logger.error("AES.GCM.seal produced no combined output")
                throw SecurityError.cryptoFailure
            }
            return combined
        } catch let error as SecurityError {
            throw error
        } catch {
            Self.logger.error("Encryption failed: \(error, privacy: .public)")
            throw SecurityError.cryptoFailure
        }
    }

    public func decrypt(_ ciphertext: Data, mode: VaultMode, aad: Data? = nil) async throws -> Data {
        let key = try await keyManager.getOrCreateKey(for: mode)
        do {
            let sealed = try AES.GCM.SealedBox(combined: ciphertext)
            return try AES.GCM.open(sealed, using: key, authenticating: aad ?? Data())
        } catch let error as SecurityError {
            throw error
        } catch {
            Self.logger.error("Decryption failed: \(error, privacy: .public)")
            throw SecurityError.invalidCiphertext
        }
    }
}
