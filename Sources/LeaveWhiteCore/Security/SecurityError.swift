import Foundation

public enum SecurityError: Error, LocalizedError, Sendable, Equatable {
    case biometricUnavailable
    case biometricFailed
    case keyNotFound
    case keychainFailure(status: Int)
    case cryptoFailure
    case invalidCiphertext

    public var errorDescription: String? {
        switch self {
        case .biometricUnavailable:
            return "Biometric unavailable"
        case .biometricFailed:
            return "Biometric failed"
        case .keyNotFound:
            return "Key not found"
        case .keychainFailure(let status):
            return "Keychain failure: \(status)"
        case .cryptoFailure:
            return "Crypto failure"
        case .invalidCiphertext:
            return "Invalid ciphertext"
        }
    }
}
