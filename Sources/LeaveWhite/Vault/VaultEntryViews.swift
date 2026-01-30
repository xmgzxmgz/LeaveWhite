import SwiftUI
import LeaveWhiteCore

struct VaultEntryDraft {
    var kind: AssetKind
    var title: String
    var tags: String
    var hint: String
    var plaintext: String
    var beneficiary: Beneficiary?
    var releaseAt: Date?
    var destroyOnTrigger: Bool

    init(
        kind: AssetKind = .note,
        title: String = "",
        tags: String = "",
        hint: String = "",
        plaintext: String = "",
        beneficiary: Beneficiary? = nil,
        releaseAt: Date? = nil,
        destroyOnTrigger: Bool = false
    ) {
        self.kind = kind
        self.title = title
        self.tags = tags
        self.hint = hint
        self.plaintext = plaintext
        self.beneficiary = beneficiary
        self.releaseAt = releaseAt
        self.destroyOnTrigger = destroyOnTrigger
    }
}

struct VaultEntryEditorSheet: View {
    @Bindable var security: SecurityManager
    var beneficiaries: [Beneficiary]
    var onSave: (VaultEntryDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draft = VaultEntryDraft()
    @State private var saveFeedback = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            fieldHeader(String(localized: "vault.field.kind", bundle: .module))
                            Picker("", selection: $draft.kind) {
                                ForEach(AssetKind.allCases, id: \.rawValue) { kind in
                                    Text(localizedKind(kind)).tag(kind)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            fieldHeader(String(localized: "vault.field.title", bundle: .module))
                            TextField(String(localized: "vault.field.title", bundle: .module), text: $draft.title)
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
                            fieldHeader(String(localized: "vault.field.tags", bundle: .module))
                            TextField(String(localized: "vault.field.tags", bundle: .module), text: $draft.tags)
                                .platformTextInputAutocapitalizationNever()
                                .platformAutocorrectionDisabled()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Theme.secondaryBackground)
                                )

                            fieldHeader(String(localized: "vault.field.hint", bundle: .module))
                            TextField(String(localized: "vault.field.hint", bundle: .module), text: $draft.hint)
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
                            fieldHeader(String(localized: "vault.field.beneficiary", bundle: .module))

                            Picker("", selection: beneficiarySelectionBinding) {
                                Text(String(localized: "common.placeholder", bundle: .module)).tag(UUID?.none)
                                ForEach(beneficiaries) { b in
                                    Text(b.displayName).tag(Optional.some(b.id))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            fieldHeader(String(localized: "vault.field.trigger", bundle: .module))

                            Toggle(isOn: $draft.destroyOnTrigger) {
                                Text(String(localized: "vault.trigger.destroy", bundle: .module))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            .toggleStyle(.switch)

                            if draft.kind == .timeLetter {
                                DatePicker(
                                    String(localized: "vault.kind.timeLetter", bundle: .module),
                                    selection: Binding(
                                        get: { draft.releaseAt ?? Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now },
                                        set: { draft.releaseAt = $0 }
                                    ),
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            fieldHeader(String(localized: "vault.field.content", bundle: .module))

                            if draft.kind == .password || draft.kind == .cryptoSeed {
                                SecureFieldPlus(text: $draft.plaintext, placeholderKey: "vault.field.content")
                            } else {
                                TextEditor(text: $draft.plaintext)
                                    .frame(minHeight: 180)
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
                }
                .padding(18)
            }
            .background(Theme.background)
            .navigationTitle(String(localized: "vault.new", bundle: .module))
            .toolbar {
                ToolbarItem(placement: toolbarPlacementLeading) {
                    Button(String(localized: "vault.cancel", bundle: .module)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: toolbarPlacementTrailing) {
                    Button(String(localized: "vault.save", bundle: .module)) {
                        saveFeedback.toggle()
                        onSave(draft)
                    }
                    .disabled(!security.isUnlocked || draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .tint(Theme.gold)
        .platformSensoryImpact(trigger: saveFeedback)
    }

    private var beneficiarySelectionBinding: Binding<UUID?> {
        Binding(
            get: { draft.beneficiary?.id },
            set: { id in
                guard let id else {
                    draft.beneficiary = nil
                    return
                }
                draft.beneficiary = beneficiaries.first(where: { $0.id == id })
            }
        )
    }

    private func localizedKind(_ kind: AssetKind) -> String {
        switch kind {
        case .account:
            return String(localized: "vault.kind.account", bundle: .module)
        case .password:
            return String(localized: "vault.kind.password", bundle: .module)
        case .note:
            return String(localized: "vault.kind.note", bundle: .module)
        case .file:
            return String(localized: "vault.kind.file", bundle: .module)
        case .cryptoSeed:
            return String(localized: "vault.kind.cryptoSeed", bundle: .module)
        case .socialLegacy:
            return String(localized: "vault.kind.socialLegacy", bundle: .module)
        case .timeLetter:
            return String(localized: "vault.kind.timeLetter", bundle: .module)
        case .legalWill:
            return String(localized: "vault.kind.legalWill", bundle: .module)
        case .aiMemory:
            return String(localized: "vault.kind.aiMemory", bundle: .module)
        case .healthDirective:
            return String(localized: "vault.kind.healthDirective", bundle: .module)
        }
    }

    private func fieldHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.textPrimary.opacity(0.75))
    }

    private var toolbarPlacementTrailing: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .automatic
        #endif
    }

    private var toolbarPlacementLeading: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarLeading
        #else
        return .automatic
        #endif
    }
}

struct VaultEntryCard: View {
    var entry: VaultEntry
    var isSelected: Bool
    var namespace: Namespace.ID

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(entry.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .matchedGeometryEffect(id: "title-\(entry.id)", in: namespace)

                        Spacer(minLength: 0)

                        if entry.destroyOnTrigger {
                            badge(String(localized: "vault.trigger.destroy", bundle: .module))
                        }
                    }

                    if !entry.searchIndexHint.isEmpty {
                        Text(entry.searchIndexHint)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Theme.textPrimary.opacity(0.65))
                            .lineLimit(2)
                            .matchedGeometryEffect(id: "hint-\(entry.id)", in: namespace)
                    }

                    if !entry.tags.isEmpty {
                        Text(entry.tags)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Theme.textPrimary.opacity(0.50))
                            .lineLimit(1)
                    }
                }

                Image(systemName: iconName(for: entry.kindRaw))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                    .matchedGeometryEffect(id: "icon-\(entry.id)", in: namespace)
            }
        }
        .opacity(isSelected ? 0 : 1)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }

    private func iconName(for kindRaw: String) -> String {
        switch kindRaw {
        case AssetKind.cryptoSeed.rawValue:
            return "bitcoinsign.circle"
        case AssetKind.password.rawValue:
            return "key.fill"
        case AssetKind.socialLegacy.rawValue:
            return "person.2.fill"
        case AssetKind.timeLetter.rawValue:
            return "clock.fill"
        case AssetKind.legalWill.rawValue:
            return "doc.text.fill"
        default:
            return "lock.fill"
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.gold)
            )
    }
}

struct VaultEntryDetailOverlay: View {
    var entry: VaultEntry
    var plaintext: String?
    var isDecrypting: Bool
    var namespace: Namespace.ID
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Theme.background.opacity(0.92)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary.opacity(0.8))
                        .onTapGesture { onClose() }

                    Spacer(minLength: 0)

                    Image(systemName: "lock.open")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Text(entry.title)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundStyle(Theme.textPrimary)
                                .matchedGeometryEffect(id: "title-\(entry.id)", in: namespace)

                            Spacer(minLength: 0)

                            Image(systemName: "lock.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.gold)
                                .matchedGeometryEffect(id: "icon-\(entry.id)", in: namespace)
                        }

                        if !entry.searchIndexHint.isEmpty {
                            Text(entry.searchIndexHint)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Theme.textPrimary.opacity(0.65))
                                .matchedGeometryEffect(id: "hint-\(entry.id)", in: namespace)
                        }

                        Divider().overlay(Color.white.opacity(0.10))

                        if isDecrypting {
                            Text(String(localized: "vault.detail.decrypting", bundle: .module))
                                .foregroundStyle(Theme.textPrimary.opacity(0.70))
                        } else {
                            ScrollView {
                                Text(plaintext ?? String(localized: "common.placeholder", bundle: .module))
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundStyle(Theme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .frame(minHeight: 220)
                        }
                    }
                }
                .padding(.horizontal, 18)

                Spacer(minLength: 0)
            }
        }
    }
}
