import SwiftUI

/// 支持的语言枚举
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case chinese = "zh-Hans"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }
}

/// 语言管理器，负责管理应用内的语言切换与持久化
@Observable
class LanguageManager {
    /// 当前选择的语言，默认跟随系统（如果没有设置过）
    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        }
    }
    
    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language"),
           let appLanguage = AppLanguage(rawValue: savedLanguage) {
            self.language = appLanguage
        } else {
            self.language = .system
        }
    }
    
    /// 获取当前的 Locale 对象
    /// 如果选择 .system，返回 nil 让 SwiftUI 使用系统默认
    var locale: Locale? {
        switch language {
        case .system:
            return nil
        case .english:
            return Locale(identifier: "en")
        case .chinese:
            return Locale(identifier: "zh-Hans")
        }
    }
}
