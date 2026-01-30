import SwiftUI

/// 通用的语言切换菜单按钮
struct LanguageMenu: View {
    @Environment(LanguageManager.self) private var languageManager
    
    var body: some View {
        Menu {
            Picker("Language", selection: Bindable(languageManager).language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
        } label: {
            Image(systemName: "globe")
                .font(.system(size: 18))
                .foregroundStyle(Theme.textPrimary.opacity(0.8))
                .padding(10)
                .background(
                    Circle()
                        .fill(Theme.secondaryBackground)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .menuOrder(.fixed)
    }
}
