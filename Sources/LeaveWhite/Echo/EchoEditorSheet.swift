import SwiftUI
import LeaveWhiteCore

struct EchoDraft {
    var subject: String
    var content: String
    var releaseAt: Date

    init(subject: String = "", content: String = "", releaseAt: Date = .now) {
        self.subject = subject
        self.content = content
        self.releaseAt = releaseAt
    }
}

struct EchoEditorSheet: View {
    @Bindable var security: SecurityManager
    var onSave: (EchoDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draft = EchoDraft(releaseAt: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now)
    @State private var isPreviewing = false
    @State private var daysAhead: Double = 7
    @State private var feedback = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "echo.editor.subject", bundle: .module))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary.opacity(0.75))

                            TextField(String(localized: "echo.editor.subject", bundle: .module), text: $draft.subject)
                                .platformTextInputAutocapitalizationNever()
                                .platformAutocorrectionDisabled()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Theme.secondaryBackground)
                                )
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(String(localized: "echo.editor.content", bundle: .module))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary.opacity(0.75))

                                Spacer(minLength: 0)

                                Button {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        isPreviewing.toggle()
                                    }
                                } label: {
                                    Text(isPreviewing ? String(localized: "echo.editor.edit", bundle: .module) : String(localized: "echo.editor.preview", bundle: .module))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Theme.gold)
                                }
                                .buttonStyle(.plain)
                            }

                            if isPreviewing {
                                MarkdownPreview(text: draft.content)
                                    .frame(minHeight: 220)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Theme.secondaryBackground)
                                    )
                            } else {
                                TextEditor(text: $draft.content)
                                    .frame(minHeight: 220)
                                    .scrollContentBackground(.hidden)
                                    .foregroundStyle(Theme.textPrimary)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Theme.secondaryBackground)
                                    )
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "echo.editor.release", bundle: .module))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary.opacity(0.75))

                            HStack {
                                Text(String(localized: "echo.editor.daysAhead", bundle: .module))
                                    .foregroundStyle(Theme.textPrimary.opacity(0.75))

                                Spacer(minLength: 0)

                                Text("\(Int(daysAhead))")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.gold)
                            }

                            Slider(value: $daysAhead, in: 0...3650, step: 1)
                                .tint(Theme.gold)
                                .onChange(of: daysAhead) { _, newValue in
                                    feedback.toggle()
                                    draft.releaseAt = Calendar.current.date(byAdding: .day, value: Int(newValue), to: .now) ?? draft.releaseAt
                                }

                            Text(formattedReleaseDate)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Theme.textPrimary.opacity(0.65))
                        }
                    }
                }
                .padding(18)
            }
            .background(Theme.background)
            .navigationTitle(String(localized: "echo.editor.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: toolbarPlacementLeading) {
                    Button(String(localized: "echo.cancel", bundle: .module)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: toolbarPlacementTrailing) {
                    Button(String(localized: "echo.save", bundle: .module)) {
                        onSave(draft)
                    }
                    .disabled(!security.isUnlocked || draft.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .tint(Theme.gold)
        .platformSensoryImpact(trigger: feedback)
    }

    private static let releaseDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f
    }()

    private var formattedReleaseDate: String {
        Self.releaseDateFormatter.string(from: draft.releaseAt)
    }
}

private struct MarkdownPreview: View {
    var text: String

    var body: some View {
        let markdown = (try? AttributedString(markdown: text)) ?? AttributedString(text)
        ScrollView {
            Text(markdown)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

