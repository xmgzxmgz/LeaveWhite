import SwiftUI
import SwiftData
import LeaveWhiteCore
import os

struct EchoChronosView: View {
    @Bindable var security: SecurityManager

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EchoMessage.releaseAt, order: .forward) private var messages: [EchoMessage]

    @State private var isPresentingEditor = false
    @State private var selectedMessage: EchoMessage? = nil
    @State private var decryptedContent: String? = nil
    @State private var isDecrypting = false

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            EchoMessageCard(message: msg)
                                .onTapGesture {
                                    selectedMessage = msg
                                    decryptedContent = nil
                                    Task { await decryptSelectedMessage() }
                                }
                        }

                        if messages.isEmpty {
                            GlassCard {
                                VStack(spacing: 10) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundStyle(Theme.gold)

                                    Text(String(localized: "echo.new", bundle: .module))
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            }
                            .padding(.top, 18)
                        }
                    }
                    .padding(18)
                }

                if let selectedMessage {
                    EchoMessageDetailOverlay(
                        message: selectedMessage,
                        plaintext: decryptedContent,
                        isDecrypting: isDecrypting,
                        onClose: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.92)) {
                                self.selectedMessage = nil
                            }
                        }
                    )
                }
            }
            .navigationTitle(String(localized: "echo.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: toolbarPlacementTrailing) {
                    Button {
                        isPresentingEditor = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .tint(Theme.gold)
        .sheet(isPresented: $isPresentingEditor) {
            EchoEditorSheet(security: security) { draft in
                Task { await saveDraft(draft) }
            }
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #endif
        }
        .onReceive(timer) { _ in
            dispatchDueMessages()
        }
        .task {
            dispatchDueMessages()
        }
    }

    private func saveDraft(_ draft: EchoDraft) async {
        guard security.isUnlocked else { return }
        do {
            let encrypted = try await security.encrypt(Data(draft.content.utf8))
            let msg = EchoMessage(
                title: draft.subject,
                contentEncrypted: encrypted,
                releaseAt: draft.releaseAt,
                isSent: false,
                sentAt: nil,
                attachmentEncrypted: nil,
                beneficiary: nil
            )
            modelContext.insert(msg)
            try modelContext.save()
            isPresentingEditor = false
        } catch {
            LWLog.engine.error("Failed to save echo message: \(error, privacy: .public)")
        }
    }

    private func decryptSelectedMessage() async {
        guard let selectedMessage else { return }
        guard security.isUnlocked else {
            decryptedContent = String(localized: "vault.detail.locked", bundle: .module)
            return
        }
        isDecrypting = true
        do {
            let data = try await security.decrypt(selectedMessage.contentEncrypted)
            decryptedContent = String(data: data, encoding: .utf8) ?? String(localized: "common.placeholder", bundle: .module)
        } catch {
            LWLog.engine.error("Echo decryption failed: \(error, privacy: .public)")
            decryptedContent = String(localized: "error.unknown", bundle: .module)
        }
        isDecrypting = false
    }

    private func dispatchDueMessages() {
        let now = Date.now
        let due = messages.filter { !$0.isSent && $0.releaseAt <= now }
        guard !due.isEmpty else { return }

        for msg in due {
            msg.isSent = true
            msg.sentAt = now
            msg.updatedAt = now
        }

        do {
            try modelContext.save()
        } catch {
            LWLog.engine.error("Failed to save dispatched messages: \(error, privacy: .public)")
        }
    }
}

private struct EchoMessageCard: View {
    var message: EchoMessage

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Text(message.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)

                        Spacer(minLength: 0)

                        statusBadge
                    }

                    Text(dateText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Theme.textPrimary.opacity(0.65))
                }

                Image(systemName: message.isSent ? "paperplane.fill" : "clock")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
        }
    }

    private var statusBadge: some View {
        Text(message.isSent ? String(localized: "echo.sent", bundle: .module) : String(localized: "echo.pending", bundle: .module))
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.gold)
            )
            .opacity(message.isSent ? 0.55 : 1)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private var dateText: String {
        Self.dateFormatter.string(from: message.releaseAt)
    }
}

private struct EchoMessageDetailOverlay: View {
    var message: EchoMessage
    var plaintext: String?
    var isDecrypting: Bool
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

                    Image(systemName: message.isSent ? "paperplane.fill" : "clock")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(message.title)
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(Theme.textPrimary)

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
                            .frame(minHeight: 240)
                        }
                    }
                }
                .padding(.horizontal, 18)

                Spacer(minLength: 0)
            }
        }
    }
}
