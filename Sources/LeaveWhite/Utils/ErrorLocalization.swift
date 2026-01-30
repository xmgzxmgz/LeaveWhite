import Foundation
import LeaveWhiteCore

func localizedErrorMessage(_ error: Error) -> String {
    if let securityError = error as? SecurityError {
        switch securityError {
        case .biometricUnavailable:
            return String(localized: "error.biometricUnavailable", bundle: .module)
        case .biometricFailed:
            return String(localized: "error.biometricFailed", bundle: .module)
        case .keyNotFound, .keychainFailure, .cryptoFailure, .invalidCiphertext:
            return String(localized: "error.unknown", bundle: .module)
        }
    }
    return String(localized: "error.unknown", bundle: .module)
}

