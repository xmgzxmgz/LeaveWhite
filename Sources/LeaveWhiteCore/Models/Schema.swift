import Foundation
import SwiftData

@Model
public final class UserProfile {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var lastSeenAt: Date
    public var silentPeriodDays: Int
    public var warningWindowDays: Int
    public var notificationIntensity: String
    public var lastCheckInAt: Date?
    public var nextTriggerAt: Date
    public var statusRaw: String

    public var recoveryEmail: String?
    public var localeIdentifier: String
    public var preferredVaultModeRaw: String

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastSeenAt: Date = .now,
        silentPeriodDays: Int = 180,
        warningWindowDays: Int = 7,
        notificationIntensity: String = NotificationIntensity.high.rawValue,
        lastCheckInAt: Date? = nil,
        nextTriggerAt: Date = .now,
        statusRaw: String = DeadManStatus.safe.rawValue,
        recoveryEmail: String? = nil,
        localeIdentifier: String = Locale.current.identifier,
        preferredVaultModeRaw: String = VaultMode.real.rawValue
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSeenAt = lastSeenAt
        self.silentPeriodDays = silentPeriodDays
        self.warningWindowDays = warningWindowDays
        self.notificationIntensity = notificationIntensity
        self.lastCheckInAt = lastCheckInAt
        self.nextTriggerAt = nextTriggerAt
        self.statusRaw = statusRaw
        self.recoveryEmail = recoveryEmail
        self.localeIdentifier = localeIdentifier
        self.preferredVaultModeRaw = preferredVaultModeRaw
    }
}

@Model
public final class Beneficiary {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var displayName: String
    public var roleRaw: String
    public var email: String?
    public var phone: String?
    public var noteEncrypted: Data?

    @Relationship(inverse: \VaultEntry.beneficiary)
    public var entries: [VaultEntry]

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        displayName: String,
        roleRaw: String = BeneficiaryRole.other.rawValue,
        email: String? = nil,
        phone: String? = nil,
        noteEncrypted: Data? = nil,
        entries: [VaultEntry] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.displayName = displayName
        self.roleRaw = roleRaw
        self.email = email
        self.phone = phone
        self.noteEncrypted = noteEncrypted
        self.entries = entries
    }
}

@Model
public final class VaultEntry {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var kindRaw: String
    public var title: String
    public var subtitle: String?
    public var tags: String
    public var isSensitive: Bool
    public var vaultModeRaw: String

    public var triggerPolicyRaw: String
    public var releaseAt: Date?
    public var destroyOnTrigger: Bool

    public var encryptedPayload: Data
    public var payloadDigest: Data?
    public var payloadVersion: Int

    public var searchIndexHint: String
    public var classificationRaw: String?
    public var classificationConfidence: Double?

    @Relationship public var beneficiary: Beneficiary?

    @Relationship(inverse: \VaultFileChunk.entry)
    public var fileChunks: [VaultFileChunk]

    @Relationship(inverse: \LegacyContact.entry)
    public var legacyContacts: [LegacyContact]

    @Relationship(inverse: \BlockchainProof.entry)
    public var proofs: [BlockchainProof]

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        kindRaw: String,
        title: String,
        subtitle: String? = nil,
        tags: String = "",
        isSensitive: Bool = true,
        vaultModeRaw: String = VaultMode.real.rawValue,
        triggerPolicyRaw: String = TriggerPolicy.deliver.rawValue,
        releaseAt: Date? = nil,
        destroyOnTrigger: Bool = false,
        encryptedPayload: Data,
        payloadDigest: Data? = nil,
        payloadVersion: Int = 1,
        searchIndexHint: String = "",
        classificationRaw: String? = nil,
        classificationConfidence: Double? = nil,
        beneficiary: Beneficiary? = nil,
        fileChunks: [VaultFileChunk] = [],
        legacyContacts: [LegacyContact] = [],
        proofs: [BlockchainProof] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.kindRaw = kindRaw
        self.title = title
        self.subtitle = subtitle
        self.tags = tags
        self.isSensitive = isSensitive
        self.vaultModeRaw = vaultModeRaw
        self.triggerPolicyRaw = triggerPolicyRaw
        self.releaseAt = releaseAt
        self.destroyOnTrigger = destroyOnTrigger
        self.encryptedPayload = encryptedPayload
        self.payloadDigest = payloadDigest
        self.payloadVersion = payloadVersion
        self.searchIndexHint = searchIndexHint
        self.classificationRaw = classificationRaw
        self.classificationConfidence = classificationConfidence
        self.beneficiary = beneficiary
        self.fileChunks = fileChunks
        self.legacyContacts = legacyContacts
        self.proofs = proofs
    }
}

@Model
public final class VaultFileChunk {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var chunkIndex: Int
    public var totalChunks: Int
    public var encryptedChunk: Data
    public var checksum: Data?
    public var storageHint: String

    @Relationship public var entry: VaultEntry?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        chunkIndex: Int,
        totalChunks: Int,
        encryptedChunk: Data,
        checksum: Data? = nil,
        storageHint: String = "",
        entry: VaultEntry? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.chunkIndex = chunkIndex
        self.totalChunks = totalChunks
        self.encryptedChunk = encryptedChunk
        self.checksum = checksum
        self.storageHint = storageHint
        self.entry = entry
    }
}

@Model
public final class LegacyContact {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var platform: String
    public var legacyContactName: String
    public var legacyContactHandle: String
    public var instructionsEncrypted: Data?

    @Relationship public var entry: VaultEntry?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        platform: String,
        legacyContactName: String,
        legacyContactHandle: String,
        instructionsEncrypted: Data? = nil,
        entry: VaultEntry? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.platform = platform
        self.legacyContactName = legacyContactName
        self.legacyContactHandle = legacyContactHandle
        self.instructionsEncrypted = instructionsEncrypted
        self.entry = entry
    }
}

@Model
public final class BlockchainProof {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var networkRaw: String
    public var txHash: String
    public var hashAlgorithm: String
    public var digest: Data

    @Relationship public var entry: VaultEntry?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        networkRaw: String,
        txHash: String,
        hashAlgorithm: String,
        digest: Data,
        entry: VaultEntry? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.networkRaw = networkRaw
        self.txHash = txHash
        self.hashAlgorithm = hashAlgorithm
        self.digest = digest
        self.entry = entry
    }
}

@Model
public final class EchoMessage {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var title: String
    public var contentEncrypted: Data
    public var releaseAt: Date
    public var isSent: Bool
    public var sentAt: Date?
    public var attachmentEncrypted: Data?

    @Relationship public var beneficiary: Beneficiary?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        title: String,
        contentEncrypted: Data,
        releaseAt: Date,
        isSent: Bool = false,
        sentAt: Date? = nil,
        attachmentEncrypted: Data? = nil,
        beneficiary: Beneficiary? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.contentEncrypted = contentEncrypted
        self.releaseAt = releaseAt
        self.isSent = isSent
        self.sentAt = sentAt
        self.attachmentEncrypted = attachmentEncrypted
        self.beneficiary = beneficiary
    }
}

@Model
public final class CheckInLog {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var kind: String
    public var wasSuccessful: Bool
    public var detail: String?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        kind: String,
        wasSuccessful: Bool,
        detail: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.wasSuccessful = wasSuccessful
        self.detail = detail
    }
}

@Model
public final class EmergencyContact {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var displayName: String
    public var email: String
    public var phone: String?

    @Relationship(inverse: \EmergencyConfirmation.contact)
    public var confirmations: [EmergencyConfirmation]

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        displayName: String,
        email: String,
        phone: String? = nil,
        confirmations: [EmergencyConfirmation] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.displayName = displayName
        self.email = email
        self.phone = phone
        self.confirmations = confirmations
    }
}

@Model
public final class EmergencyConfirmation {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var statusRaw: String
    public var token: String
    public var requestedAt: Date
    public var confirmedAt: Date?
    public var expiresAt: Date

    @Relationship public var contact: EmergencyContact?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        statusRaw: String = EmergencyConfirmationStatus.requested.rawValue,
        token: String,
        requestedAt: Date = .now,
        confirmedAt: Date? = nil,
        expiresAt: Date,
        contact: EmergencyContact? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.statusRaw = statusRaw
        self.token = token
        self.requestedAt = requestedAt
        self.confirmedAt = confirmedAt
        self.expiresAt = expiresAt
        self.contact = contact
    }
}

@Model
public final class HealthSignalRule {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var kindRaw: String
    public var isEnabled: Bool
    public var lastValue: Double?
    public var lastSampleAt: Date?
    public var threshold: Double?
    public var noteEncrypted: Data?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        kindRaw: String,
        isEnabled: Bool = false,
        lastValue: Double? = nil,
        lastSampleAt: Date? = nil,
        threshold: Double? = nil,
        noteEncrypted: Data? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.kindRaw = kindRaw
        self.isEnabled = isEnabled
        self.lastValue = lastValue
        self.lastSampleAt = lastSampleAt
        self.threshold = threshold
        self.noteEncrypted = noteEncrypted
    }
}

@Model
public final class PersonalityModel {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var modelFilePath: String
    public var personalitySummaryEncrypted: Data?
    public var lastTrainedAt: Date?
    public var trainingCorpusDigest: Data?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        modelFilePath: String = "",
        personalitySummaryEncrypted: Data? = nil,
        lastTrainedAt: Date? = nil,
        trainingCorpusDigest: Data? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.modelFilePath = modelFilePath
        self.personalitySummaryEncrypted = personalitySummaryEncrypted
        self.lastTrainedAt = lastTrainedAt
        self.trainingCorpusDigest = trainingCorpusDigest
    }
}

@Model
public final class OnboardingStory {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date

    public var currentChapter: Int
    public var completedStepIdentifiers: String
    public var isFinished: Bool

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        currentChapter: Int = 0,
        completedStepIdentifiers: String = "",
        isFinished: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.currentChapter = currentChapter
        self.completedStepIdentifiers = completedStepIdentifiers
        self.isFinished = isFinished
    }
}

@Model
public final class AutoClassificationLog {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    public var inputDigest: Data
    public var predictedTypeRaw: String
    public var confidence: Double
    public var modelIdentifier: String

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        inputDigest: Data,
        predictedTypeRaw: String,
        confidence: Double,
        modelIdentifier: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.inputDigest = inputDigest
        self.predictedTypeRaw = predictedTypeRaw
        self.confidence = confidence
        self.modelIdentifier = modelIdentifier
    }
}

