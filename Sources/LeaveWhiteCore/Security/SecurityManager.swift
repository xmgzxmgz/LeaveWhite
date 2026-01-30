import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
public final class SecurityManager {
    public private(set) var isUnlocked: Bool
    public private(set) var lastAuthAt: Date?
    public var activeVaultMode: VaultMode

    private let cryptoBox: CryptoBox

    public init(
        isUnlocked: Bool = false,
        lastAuthAt: Date? = nil,
        activeVaultMode: VaultMode = .real,
        cryptoBox: CryptoBox = CryptoBox()
    ) {
        self.isUnlocked = isUnlocked
        self.lastAuthAt = lastAuthAt
        self.activeVaultMode = activeVaultMode
        self.cryptoBox = cryptoBox
    }

    public func lock() {
        isUnlocked = false
        lastAuthAt = nil
    }

    public func activateRealMode() {
        activeVaultMode = .real
    }

    public func activateDecoyMode() {
        activeVaultMode = .decoy
    }

    public func requestBiometricAuth(localizedReason: String) async throws {
        let context = LAContext()
        context.interactionNotAllowed = false

        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        guard canEvaluate else {
            throw SecurityError.biometricUnavailable
        }

        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: localizedReason
        )

        guard success else {
            throw SecurityError.biometricFailed
        }

        isUnlocked = true
        lastAuthAt = .now
    }

    public func encrypt(_ data: Data) async throws -> Data {
        guard isUnlocked else {
            throw SecurityError.biometricFailed
        }
        return try await cryptoBox.encrypt(data, mode: activeVaultMode)
    }

    public func decrypt(_ data: Data) async throws -> Data {
        guard isUnlocked else {
            throw SecurityError.biometricFailed
        }
        return try await cryptoBox.decrypt(data, mode: activeVaultMode)
    }
}
