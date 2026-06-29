import SwiftUI
import SwiftData
import LeaveWhiteCore
import os

@main
struct LeaveWhiteApp: App {
    private let container: ModelContainer
    @State private var languageManager = LanguageManager()

    init() {
        do {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            if let docDir = urls.first {
                let storeURL = docDir.appendingPathComponent("LeaveWhite.store")
                self.container = try ModelContainerFactory.make(url: storeURL)
            } else {
                self.container = try ModelContainerFactory.make()
            }
        } catch {
            LWLog.app.error("Persistent store unavailable, falling back to in-memory: \(error, privacy: .public)")
            do {
                self.container = try ModelContainerFactory.make(isInMemory: true)
            } catch {
                LWLog.app.critical("All storage options exhausted: \(error, privacy: .public)")
                // Last resort: force in-memory with minimal config
                // ModelContainerFactory.make(isInMemory: true) should almost never fail,
                // but if it does, we create the simplest possible container to avoid crashing.
                do {
                    let schema = Schema([UserProfile.self])
                    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    self.container = try ModelContainer(for: schema, configurations: [config])
                } catch {
                    // Truly unrecoverable -- log and rethrow to crash report rather than silent fatalError
                    LWLog.app.critical("Cannot create any ModelContainer: \(error, privacy: .public)")
                    fatalError("LeaveWhite cannot start: \(error.localizedDescription)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let locale = languageManager.locale {
                    RootView()
                        .environment(\.locale, locale)
                } else {
                    RootView()
                }
            }
            .environment(languageManager)
            .id(languageManager.language)
            .frame(minWidth: 375, maxWidth: 430, minHeight: 667, maxHeight: 932)
        }
        .modelContainer(container)
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}
