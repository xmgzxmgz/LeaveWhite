import CryptoKit
import Foundation

public struct CryptoBox: Sendable {
    private let keyManager: VaultKeyManager

    public init(keyManager: VaultKeyManager = VaultKeyManager()) {
        self.keyManager = keyManager
    }

    public func encrypt(_ plaintext: Data, mode: VaultMode, aad: Data? = nil) async throws -> Data {
        let key = try await keyManager.getOrCreateKey(for: mode)
        do {
            let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: aad ?? Data())
            guard let combined = sealed.combined else {
                throw SecurityError.cryptoFailure
            }
            return combined
        } catch {
            throw SecurityError.cryptoFailure
        }
    }

    public func decrypt(_ ciphertext: Data, mode: VaultMode, aad: Data? = nil) async throws -> Data {
        let key = try await keyManager.getOrCreateKey(for: mode)
        do {
            let sealed = try AES.GCM.SealedBox(combined: ciphertext)
            return try AES.GCM.open(sealed, using: key, authenticating: aad ?? Data())
        } catch {
            throw SecurityError.invalidCiphertext
        }
    }
}

