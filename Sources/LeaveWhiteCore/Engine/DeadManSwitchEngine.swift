import Foundation

public struct DeadManEvaluation: Sendable {
    public var status: DeadManStatus
    public var daysSinceLastSeen: Int
    public var daysUntilTrigger: Int
    public var isInWarningWindow: Bool

    public init(status: DeadManStatus, daysSinceLastSeen: Int, daysUntilTrigger: Int, isInWarningWindow: Bool) {
        self.status = status
        self.daysSinceLastSeen = daysSinceLastSeen
        self.daysUntilTrigger = daysUntilTrigger
        self.isInWarningWindow = isInWarningWindow
    }
}

public enum DeadManSwitchEngine {
    public static func evaluate(
        lastSeenAt: Date,
        now: Date,
        silentPeriodDays: Int,
        warningWindowDays: Int
    ) -> DeadManEvaluation {
        let daysSince = max(0, Calendar.current.dateComponents([.day], from: lastSeenAt, to: now).day ?? 0)
        let daysUntil = max(0, silentPeriodDays - daysSince)

        if daysSince >= silentPeriodDays {
            return DeadManEvaluation(
                status: .triggered,
                daysSinceLastSeen: daysSince,
                daysUntilTrigger: 0,
                isInWarningWindow: false
            )
        }

        let inWarning = daysUntil <= max(0, warningWindowDays)
        if inWarning {
            return DeadManEvaluation(
                status: .warning,
                daysSinceLastSeen: daysSince,
                daysUntilTrigger: daysUntil,
                isInWarningWindow: true
            )
        }

        return DeadManEvaluation(
            status: .safe,
            daysSinceLastSeen: daysSince,
            daysUntilTrigger: daysUntil,
            isInWarningWindow: false
        )
    }
}

