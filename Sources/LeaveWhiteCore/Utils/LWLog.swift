import Foundation
import os

/// Centralised logger for the LeaveWhite app.
/// Uses `os_log` on Apple platforms for structured, privacy-aware logging.
public enum LWLog {
    private static let subsystem = "com.leavewhite"

    /// General app lifecycle and UI events.
    public static let app = Logger(subsystem: subsystem, category: "app")

    /// Security-sensitive events (keychain, crypto, biometric).
    public static let security = Logger(subsystem: subsystem, category: "security")

    /// Vault operations (encrypt, decrypt, save).
    public static let vault = Logger(subsystem: subsystem, category: "vault")

    /// Echo / DeadManSwitch engine events.
    public static let engine = Logger(subsystem: subsystem, category: "engine")
}
