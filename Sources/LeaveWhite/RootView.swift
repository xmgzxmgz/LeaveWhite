import SwiftUI
import SwiftData
import LeaveWhiteCore
import os

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var security = SecurityManager()
    @State private var isAttemptingUnlock = false
    @State private var unlockFeedbackTrigger = false
    @State private var unlockErrorMessage: String?

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            MainTabView(security: security)
                .opacity(security.isUnlocked ? 1 : 0)
                .blur(radius: security.isUnlocked ? 0 : 30)
                .animation(.easeInOut(duration: 0.35), value: security.isUnlocked)

            if !security.isUnlocked {
                LockedOverlay(
                    isAttemptingUnlock: isAttemptingUnlock,
                    errorMessage: unlockErrorMessage,
                    onUnlock: {
                        Task { await unlock() }
                    },
                    feedbackTrigger: $unlockFeedbackTrigger
                )
                .transition(.opacity)
            }
        }
        .task { await bootstrapProfileAndAttemptUnlock() }
    }

    private func bootstrapProfileAndAttemptUnlock() async {
        if profiles.isEmpty {
            let profile = UserProfile()
            profile.nextTriggerAt = Calendar.current.date(byAdding: .day, value: profile.silentPeriodDays, to: profile.lastSeenAt) ?? .now
            modelContext.insert(profile)
            do {
                try modelContext.save()
            } catch {
                LWLog.app.error("Failed to save initial profile: \(error, privacy: .public)")
            }
        }

        await unlock()
        await updateLastSeenIfUnlocked()
    }

    private func unlock() async {
        guard !isAttemptingUnlock else { return }
        isAttemptingUnlock = true
        unlockErrorMessage = nil

        do {
            try await security.requestBiometricAuth(localizedReason: String(localized: "root.locked.subtitle", bundle: .module))
            unlockFeedbackTrigger.toggle()
        } catch {
            unlockErrorMessage = localizedErrorMessage(error)
        }

        isAttemptingUnlock = false
    }

    private func updateLastSeenIfUnlocked() async {
        guard security.isUnlocked else { return }

        guard let profile = profiles.first else { return }
        profile.lastSeenAt = .now
        profile.updatedAt = .now

        let evaluation = DeadManSwitchEngine.evaluate(
            lastSeenAt: profile.lastSeenAt,
            now: .now,
            silentPeriodDays: profile.silentPeriodDays,
            warningWindowDays: profile.warningWindowDays
        )

        profile.statusRaw = evaluation.status.rawValue
        profile.nextTriggerAt = Calendar.current.date(byAdding: .day, value: evaluation.daysUntilTrigger, to: .now) ?? profile.nextTriggerAt

        modelContext.insert(CheckInLog(kind: "app_open", wasSuccessful: true, detail: nil))
        do {
            try modelContext.save()
        } catch {
            LWLog.app.error("Failed to save lastSeen update: \(error, privacy: .public)")
        }
    }
}

private struct LockedOverlay: View {
    var isAttemptingUnlock: Bool
    var errorMessage: String?
    var onUnlock: () -> Void
    @Binding var feedbackTrigger: Bool

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                LanguageMenu()
            }
            .padding(.top, 10)
            .padding(.trailing, 20)

            Text("root.locked.title", bundle: .module)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 60)

            Text("root.locked.subtitle", bundle: .module)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Theme.textPrimary.opacity(0.75))

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Theme.textPrimary.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button(action: onUnlock) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 8, height: 8)
                        .opacity(isAttemptingUnlock ? 0.4 : 1)

                    Text("root.unlock.button", bundle: .module)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.gold)
                )
            }
            .disabled(isAttemptingUnlock)
            .platformSensoryImpact(trigger: feedbackTrigger)
            .padding(.top, 18)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Theme.background.opacity(0.90),
                    Theme.background.opacity(0.60),
                    Theme.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(0.65)
        )
    }
}
