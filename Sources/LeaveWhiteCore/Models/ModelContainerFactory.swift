import Foundation
import SwiftData

public enum ModelContainerFactory {
    public static func make(isInMemory: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            Beneficiary.self,
            VaultEntry.self,
            VaultFileChunk.self,
            LegacyContact.self,
            BlockchainProof.self,
            EchoMessage.self,
            CheckInLog.self,
            EmergencyContact.self,
            EmergencyConfirmation.self,
            HealthSignalRule.self,
            PersonalityModel.self,
            OnboardingStory.self,
            AutoClassificationLog.self
        ])

        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(schema: schema, url: url)
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: isInMemory
            )
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

