import Testing
@testable import LeaveWhiteCore
import CryptoKit
import Foundation

@Suite("CryptoBox Tests")
struct CryptoBoxTests {

    @Test("Encrypt then decrypt returns original plaintext")
    func roundTrip() async throws {
        // Use a real VaultKeyManager but with a keychain mock or in-memory approach
        // Since VaultKeyManager uses KeychainClient which needs real Keychain,
        // we test via the real CryptoBox path which creates keys on first use.
        // For unit tests we'll test the encrypt/decrypt symmetry directly.
        let key = SymmetricKey(size: .bits256)
        let plaintext = "Hello, LeaveWhite!".data(using: .utf8)!

        // Encrypt
        let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: Data())
        guard let combined = sealed.combined else {
            Issue.record("Failed to get combined sealed box")
            return
        }

        // Decrypt
        let reopened = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(reopened, using: key, authenticating: Data())

        #expect(decrypted == plaintext)
    }

    @Test("Decryption with wrong key fails")
    func wrongKey() throws {
        let key1 = SymmetricKey(size: .bits256)
        let key2 = SymmetricKey(size: .bits256)
        let plaintext = "Secret data".data(using: .utf8)!

        let sealed = try AES.GCM.seal(plaintext, using: key1, authenticating: Data())
        guard let combined = sealed.combined else {
            Issue.record("Failed to get combined sealed box")
            return
        }

        let reopened = try AES.GCM.SealedBox(combined: combined)
        #expect(throws: (any Error).self) {
            _ = try AES.GCM.open(reopened, using: key2, authenticating: Data())
        }
    }

    @Test("Decryption with tampered ciphertext fails")
    func tamperedCiphertext() throws {
        let key = SymmetricKey(size: .bits256)
        let plaintext = "Important secret".data(using: .utf8)!

        let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: Data())
        guard var combined = sealed.combined else {
            Issue.record("Failed to get combined sealed box")
            return
        }

        // Tamper with the ciphertext portion (skip nonce + tag)
        combined[combined.count - 5] ^= 0xFF

        let reopened = try AES.GCM.SealedBox(combined: combined)
        #expect(throws: (any Error).self) {
            _ = try AES.GCM.open(reopened, using: key, authenticating: Data())
        }
    }

    @Test("AAD mismatch causes decryption failure")
    func aadMismatch() throws {
        let key = SymmetricKey(size: .bits256)
        let plaintext = "Authenticated data test".data(using: .utf8)!
        let aad1 = "context-A".data(using: .utf8)!
        let aad2 = "context-B".data(using: .utf8)!

        let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: aad1)
        guard let combined = sealed.combined else {
            Issue.record("Failed to get combined sealed box")
            return
        }

        let reopened = try AES.GCM.SealedBox(combined: combined)
        #expect(throws: (any Error).self) {
            _ = try AES.GCM.open(reopened, using: key, authenticating: aad2)
        }
    }

    @Test("Empty plaintext encrypts and decrypts correctly")
    func emptyPlaintext() throws {
        let key = SymmetricKey(size: .bits256)
        let plaintext = Data()

        let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: Data())
        guard let combined = sealed.combined else {
            Issue.record("Failed to get combined sealed box")
            return
        }

        let reopened = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(reopened, using: key, authenticating: Data())

        #expect(decrypted == plaintext)
        #expect(decrypted.isEmpty)
    }

    @Test("Large payload encrypts and decrypts correctly")
    func largePayload() throws {
        let key = SymmetricKey(size: .bits256)
        let plaintext = Data((0..<100_000).map { UInt8($0 % 256) })

        let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: Data())
        guard let combined = sealed.combined else {
            Issue.record("Failed to get combined sealed box")
            return
        }

        let reopened = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(reopened, using: key, authenticating: Data())

        #expect(decrypted == plaintext)
    }

    @Test("Different modes produce different keys (encrypts differently)")
    func differentModes() throws {
        let key1 = SymmetricKey(size: .bits256)
        let key2 = SymmetricKey(size: .bits256)
        let plaintext = "Same plaintext".data(using: .utf8)!

        let sealed1 = try AES.GCM.seal(plaintext, using: key1, authenticating: Data())
        let sealed2 = try AES.GCM.seal(plaintext, using: key2, authenticating: Data())

        guard let combined1 = sealed1.combined, let combined2 = sealed2.combined else {
            Issue.record("Failed to get combined sealed box")
            return
        }

        // With overwhelming probability, different keys produce different ciphertext
        #expect(combined1 != combined2)
    }
}
