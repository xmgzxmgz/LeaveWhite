import SwiftUI
import SwiftData
import LeaveWhiteCore
import os

struct VaultView: View {
    @Bindable var security: SecurityManager
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \VaultEntry.updatedAt, order: .reverse) private var allEntries: [VaultEntry]
    @Query(sort: \Beneficiary.displayName, order: .forward) private var beneficiaries: [Beneficiary]

    @State private var queryText = ""
    @State private var selectedKindRaw: String? = nil
    @State private var isPresentingEditor = false
    @State private var selectedEntry: VaultEntry? = nil
    @State private var detailPlaintext: String? = nil
    @State private var isDecrypting = false

    @Namespace private var animation

    var body: some View {
        let visibleEntries = filteredEntries

        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        searchBar
                            .padding(.horizontal, 18)
                            .padding(.top, 14)

                        filtersRow
                            .padding(.horizontal, 18)

                        LazyVStack(spacing: 12) {
                            ForEach(visibleEntries) { entry in
                                VaultEntryCard(
                                    entry: entry,
                                    isSelected: selectedEntry?.id == entry.id,
                                    namespace: animation
                                )
                                .onTapGesture {
                                    selectedEntry = entry
                                    detailPlaintext = nil
                                    Task { await decryptSelectedEntry() }
                                }
                            }

                            if visibleEntries.isEmpty {
                                GlassCard {
                                    VStack(spacing: 10) {
                                        Image(systemName: "lock.rectangle.stack")
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundStyle(Theme.gold)

                                        Text(String(localized: "vault.title", bundle: .module))
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundStyle(Theme.textPrimary)

                                        Text(String(localized: "common.placeholder", bundle: .module))
                                            .foregroundStyle(Theme.textPrimary.opacity(0.55))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 30)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 24)
                    }
                }

                if let selectedEntry {
                    VaultEntryDetailOverlay(
                        entry: selectedEntry,
                        plaintext: detailPlaintext,
                        isDecrypting: isDecrypting,
                        namespace: animation,
                        onClose: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.92)) {
                                self.selectedEntry = nil
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            .navigationTitle(String(localized: "vault.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: toolbarPlacementTrailing) {
                    Button {
                        isPresentingEditor = true
                    } label: { Image(systemName: "plus") }
                }

                ToolbarItem(placement: toolbarPlacementLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            toggleVaultMode()
                        }
                    } label: {
                        Text(vaultModeLabel)
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
            }
        }
        .tint(Theme.gold)
        .sheet(isPresented: $isPresentingEditor) {
            VaultEntryEditorSheet(
                security: security,
                beneficiaries: beneficiaries,
                onSave: { draft in
                    Task { await saveDraft(draft) }
                }
            )
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #endif
        }
    }

    private var searchBar: some View {
        TextField("", text: $queryText, prompt: Text("vault.search.placeholder", bundle: .module))
            .platformTextInputAutocapitalizationNever()
            .platformAutocorrectionDisabled()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.secondaryBackground)
            )
    }

    private var filtersRow: some View {
        HStack(spacing: 10) {
            Menu {
                Button {
                    selectedKindRaw = nil
                } label: {
                    Text("common.placeholder", bundle: .module)
                }

                ForEach(AssetKind.allCases, id: \.rawValue) { kind in
                    Button {
                        selectedKindRaw = kind.rawValue
                    } label: {
                        Text(localizedKind(kind), bundle: .module)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    let labelKey: LocalizedStringKey = selectedKindRaw.flatMap { AssetKind(rawValue: $0) }.map(localizedKind) ?? "vault.field.kind"
                    Text(labelKey, bundle: .module)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.secondaryBackground)
                )
            }

            Spacer(minLength: 0)

            Text(security.activeVaultMode == .real ? "vault.mode.real" : "vault.mode.decoy", bundle: .module)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textPrimary.opacity(0.75))
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
        }
    }

    private var filteredEntries: [VaultEntry] {
        let mode = security.activeVaultMode.rawValue
        let q = queryText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return allEntries
            .filter { $0.vaultModeRaw == mode }
            .filter { entry in
                if let selectedKindRaw {
                    return entry.kindRaw == selectedKindRaw
                }
                return true
            }
            .filter { entry in
                if q.isEmpty { return true }
                let haystack = [
                    entry.title,
                    entry.subtitle ?? "",
                    entry.tags,
                    entry.searchIndexHint
                ].joined(separator: " ").lowercased()
                return haystack.contains(q)
            }
    }

    private func localizedKind(_ kind: AssetKind) -> LocalizedStringKey {
        switch kind {
        case .account:
            return "vault.kind.account"
        case .password:
            return "vault.kind.password"
        case .note:
            return "vault.kind.note"
        case .file:
            return "vault.kind.file"
        case .cryptoSeed:
            return "vault.kind.cryptoSeed"
        case .socialLegacy:
            return "vault.kind.socialLegacy"
        case .timeLetter:
            return "vault.kind.timeLetter"
        case .legalWill:
            return "vault.kind.legalWill"
        case .aiMemory:
            return "vault.kind.aiMemory"
        case .healthDirective:
            return "vault.kind.healthDirective"
        }
    }

    private var vaultModeLabel: String {
        String(localized: "vault.mode.toggle", bundle: .module)
    }

    private func toggleVaultMode() {
        if security.activeVaultMode == .real {
            security.activateDecoyMode()
        } else {
            security.activateRealMode()
        }
    }

    private func decryptSelectedEntry() async {
        guard let selectedEntry else { return }
        guard security.isUnlocked else {
            detailPlaintext = String(localized: "vault.detail.locked", bundle: .module)
            return
        }

        isDecrypting = true
        do {
            let plaintext = try await security.decrypt(selectedEntry.encryptedPayload)
            detailPlaintext = String(data: plaintext, encoding: .utf8) ?? String(localized: "common.placeholder", bundle: .module)
        } catch {
            LWLog.vault.error("Decryption failed: \(error, privacy: .public)")
            detailPlaintext = String(localized: "error.unknown", bundle: .module)
        }
        isDecrypting = false
    }

    private func saveDraft(_ draft: VaultEntryDraft) async {
        guard security.isUnlocked else { return }
        do {
            let classification = HeuristicClassifier.classify(text: draft.plaintext)
            let encrypted = try await security.encrypt(Data(draft.plaintext.utf8))

            let entry = VaultEntry(
                kindRaw: draft.kind.rawValue,
                title: draft.title,
                subtitle: nil,
                tags: draft.tags,
                isSensitive: true,
                vaultModeRaw: security.activeVaultMode.rawValue,
                triggerPolicyRaw: draft.destroyOnTrigger ? TriggerPolicy.destroy.rawValue : TriggerPolicy.deliver.rawValue,
                releaseAt: draft.releaseAt,
                destroyOnTrigger: draft.destroyOnTrigger,
                encryptedPayload: encrypted,
                payloadDigest: nil,
                payloadVersion: 1,
                searchIndexHint: draft.hint,
                classificationRaw: classification.type.rawValue,
                classificationConfidence: classification.confidence,
                beneficiary: draft.beneficiary,
                fileChunks: [],
                legacyContacts: [],
                proofs: []
            )

            modelContext.insert(entry)
            try modelContext.save()
            isPresentingEditor = false
        } catch {
            LWLog.vault.error("Failed to save vault entry: \(error, privacy: .public)")
        }
    }
}
