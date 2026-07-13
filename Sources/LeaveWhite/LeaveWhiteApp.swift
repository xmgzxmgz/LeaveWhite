import SwiftUI
import SwiftData
import LeaveWhiteCore
import os

@main
struct LeaveWhiteApp: App {
    private let container: ModelContainer

    init() {
        do {
            // 优先尝试使用当前目录（CLI调试用），如果不可写则回退到 Documents
            // 在 macOS CLI 环境下，Documents 目录可能需要 TCC 权限，导致只读错误
            let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let localStoreURL = currentDir.appendingPathComponent("LeaveWhite.store")

            // 简单的写入测试来验证当前目录权限
            if FileManager.default.isWritableFile(atPath: currentDir.path) {
                 self.container = try ModelContainerFactory.make(url: localStoreURL)
            } else {
                let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                if let docDir = urls.first {
                    let storeURL = docDir.appendingPathComponent("LeaveWhite.store")
                    self.container = try ModelContainerFactory.make(url: storeURL)
                } else {
                    self.container = try ModelContainerFactory.make()
                }
            }
        } catch {
            LWLog.app.error("Persistent store unavailable, falling back to in-memory: \(error, privacy: .public)")
            do {
                self.container = try ModelContainerFactory.make(isInMemory: true)
            } catch {
                LWLog.app.critical("All storage options exhausted: \(error, privacy: .public)")
                do {
                    let schema = Schema([UserProfile.self])
                    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    self.container = try ModelContainer(for: schema, configurations: [config])
                } catch {
                    LWLog.app.critical("Cannot create any ModelContainer: \(error, privacy: .public)")
                    fatalError("LeaveWhite cannot start: \(error.localizedDescription)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, Locale(identifier: "zh-Hans"))
                .frame(minWidth: 375, maxWidth: 430, minHeight: 667, maxHeight: 932)
        }
        .modelContainer(container)
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}
