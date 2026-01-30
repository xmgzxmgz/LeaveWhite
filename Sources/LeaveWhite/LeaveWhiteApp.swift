import SwiftUI
import SwiftData
import LeaveWhiteCore

@main
struct LeaveWhiteApp: App {
    private let container: ModelContainer
    @State private var languageManager = LanguageManager()

    init() {
        do {
            // 优先尝试使用 Documents 目录，解决 CLI 运行时的权限问题
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            if let docDir = urls.first {
                let storeURL = docDir.appendingPathComponent("LeaveWhite.store")
                self.container = try ModelContainerFactory.make(url: storeURL)
            } else {
                self.container = try ModelContainerFactory.make()
            }
        } catch {
            do {
                self.container = try ModelContainerFactory.make(isInMemory: true)
            } catch {
                fatalError(String(describing: error))
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
            .frame(minWidth: 375, maxWidth: 430, minHeight: 667, maxHeight: 932) // 模拟 iOS 屏幕比例
        }
        .modelContainer(container)
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}
