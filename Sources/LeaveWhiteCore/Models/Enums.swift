import Foundation

public enum AssetKind: String, Codable, CaseIterable, Sendable {
    case account
    case password
    case note
    case file
    case cryptoSeed
    case socialLegacy
    case timeLetter
    case legalWill
    case aiMemory
    case healthDirective
}

public enum BeneficiaryRole: String, Codable, CaseIterable, Sendable {
    case spouse
    case partner
    case family
    case friend
    case colleague
    case other
}

public enum TriggerPolicy: String, Codable, CaseIterable, Sendable {
    case deliver
    case destroy
}

public enum DeadManStatus: String, Codable, CaseIterable, Sendable {
    case safe
    case warning
    case pendingTrigger
    case triggered
}

public enum NotificationIntensity: String, Codable, CaseIterable, Sendable {
    case low
    case normal
    case high
}

public enum HealthSignalKind: String, Codable, CaseIterable, Sendable {
    case heartRate
    case stepCount
    case sleepAnalysis
    case heartRateVariability
    case respiratoryRate
    case bloodOxygen
}

public enum BlockchainNetwork: String, Codable, CaseIterable, Sendable {
    case ethereum
    case polygon
    case arbitrum
    case solana
    case other
}

public enum EmergencyConfirmationStatus: String, Codable, CaseIterable, Sendable {
    case requested
    case confirmed
    case expired
    case cancelled
}

public enum VaultMode: String, Codable, CaseIterable, Sendable {
    case real
    case decoy
}

public enum AutoClassifiedType: String, Codable, CaseIterable, Sendable {
    case account
    case password
    case reflection
    case crypto
    case file
    case other
}

