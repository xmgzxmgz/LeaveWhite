import SwiftUI
import SwiftData
import LeaveWhiteCore
import os

struct DashboardView: View {
    @Bindable var security: SecurityManager

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var breath = false
    @State private var feedbackTrigger = false

    var body: some View {
        let profile = profiles.first
        let evaluation = profile.map { p in
            DeadManSwitchEngine.evaluate(
                lastSeenAt: p.lastSeenAt,
                now: .now,
                silentPeriodDays: p.silentPeriodDays,
                warningWindowDays: p.warningWindowDays
            )
        }

        VStack(spacing: 18) {
            header(status: evaluation?.status)
                .padding(.top, 10)

            Spacer(minLength: 0)

            GlassCard {
                VStack(spacing: 18) {
                    Text("dashboard.guardian", bundle: .module)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary.opacity(0.8))

                    GuardianRing(
                        progress: progressRatio(profile: profile, evaluation: evaluation),
                        label: ringLabel(evaluation: evaluation)
                    )
                    .frame(width: 260, height: 260)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    Task { await checkIn() }
                } label: {
                    Text("dashboard.warning", bundle: .module)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.gold)
                        )
                }
                .buttonStyle(.plain)
                .platformSensoryImpact(trigger: feedbackTrigger)

                Button {
                    security.lock()
                } label: {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 46, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.secondaryBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(Theme.background)
        .task {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breath = true
            }
        }
    }

    private func header(status: DeadManStatus?) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.gold.opacity(breath ? 0.30 : 0.10))
                    .frame(width: 18, height: 18)

                Circle()
                    .fill(Theme.gold)
                    .frame(width: 8, height: 8)
            }

            Text(statusText(for: status), bundle: .module)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            Spacer(minLength: 0)

            LanguageMenu()
        }
        .padding(.horizontal, 18)
    }

    private func statusText(for status: DeadManStatus?) -> LocalizedStringKey {
        switch status {
        case .warning:
            return "dashboard.warning"
        case .triggered:
            return "dashboard.triggered"
        default:
            return "dashboard.safe"
        }
    }

    private func progressRatio(profile: UserProfile?, evaluation: DeadManEvaluation?) -> Double {
        guard let profile, let evaluation else { return 0 }
        let total = max(1, profile.silentPeriodDays)
        let used = min(total, evaluation.daysSinceLastSeen)
        return Double(used) / Double(total)
    }

    private func ringLabel(evaluation: DeadManEvaluation?) -> String {
        guard let evaluation else {
            return String(localized: "common.placeholder", bundle: .module)
        }
        if evaluation.status == .triggered {
            return "0"
        }
        return "\(evaluation.daysUntilTrigger)"
    }

    private func checkIn() async {
        guard let profile = profiles.first else { return }
        profile.lastCheckInAt = .now
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

        modelContext.insert(CheckInLog(kind: "manual_checkin", wasSuccessful: true, detail: nil))
        do {
            try modelContext.save()
            feedbackTrigger.toggle()
        } catch {
            LWLog.app.error("Failed to save check-in: \(error, privacy: .public)")
        }
    }
}

private struct GuardianRing: View {
    var progress: Double
    var label: String

    @State private var rotation = Angle.degrees(0)

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 20)

            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    AngularGradient(
                        colors: [Theme.gold.opacity(0.15), Theme.gold, Theme.gold.opacity(0.25)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.gold.opacity(0.35), radius: 12, x: 0, y: 0)

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ParticlesRing(time: t)
                    .blendMode(.plusLighter)
                    .opacity(0.85)
            }
            .mask(
                Circle()
                    .stroke(lineWidth: 26)
            )
            .rotationEffect(rotation)

            VStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                Text("dashboard.days", bundle: .module)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Theme.textPrimary.opacity(0.55))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                rotation = .degrees(360)
            }
        }
    }
}

private struct ParticlesRing: View {
    var time: TimeInterval

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2

            let particleCount = 18
            for i in 0..<particleCount {
                let phase = Double(i) / Double(particleCount)
                let angle = 2 * Double.pi * (phase + (time.truncatingRemainder(dividingBy: 3) / 3))
                let r = radius - 10
                let x = center.x + CGFloat(cos(angle)) * r
                let y = center.y + CGFloat(sin(angle)) * r

                let alpha = 0.15 + 0.85 * abs(sin(time + phase * 4))
                let particleSize = CGFloat(2 + 2 * abs(sin(time * 1.7 + phase * 6)))
                let rect = CGRect(
                    x: x - particleSize / 2,
                    y: y - particleSize / 2,
                    width: particleSize,
                    height: particleSize
                )

                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Theme.gold.opacity(alpha))
                )
            }
        }
    }
}
