import Testing
@testable import LeaveWhiteCore
import Foundation

@Suite("DeadManSwitchEngine Tests")
struct DeadManSwitchEngineTests {
    private let calendar = Calendar.current

    @Test("Status is safe when within silent period")
    func safeStatus() {
        let now = Date.now
        let lastSeen = calendar.date(byAdding: .day, value: -10, to: now)!
        let eval = DeadManSwitchEngine.evaluate(
            lastSeenAt: lastSeen, now: now,
            silentPeriodDays: 180, warningWindowDays: 7
        )
        #expect(eval.status == .safe)
        #expect(eval.daysSinceLastSeen == 10)
        #expect(eval.isInWarningWindow == false)
        #expect(eval.daysUntilTrigger == 170)
    }

    @Test("Status is warning within warning window")
    func warningStatus() {
        let now = Date.now
        let lastSeen = calendar.date(byAdding: .day, value: -177, to: now)!
        let eval = DeadManSwitchEngine.evaluate(
            lastSeenAt: lastSeen, now: now,
            silentPeriodDays: 180, warningWindowDays: 7
        )
        #expect(eval.status == .warning)
        #expect(eval.isInWarningWindow == true)
        #expect(eval.daysUntilTrigger == 3)
    }

    @Test("Status is triggered when silent period exceeded")
    func triggeredStatus() {
        let now = Date.now
        let lastSeen = calendar.date(byAdding: .day, value: -200, to: now)!
        let eval = DeadManSwitchEngine.evaluate(
            lastSeenAt: lastSeen, now: now,
            silentPeriodDays: 180, warningWindowDays: 7
        )
        #expect(eval.status == .triggered)
        #expect(eval.daysSinceLastSeen >= 200)
        #expect(eval.daysUntilTrigger == 0)
        #expect(eval.isInWarningWindow == false)
    }

    @Test("Boundary: exactly at silent period triggers")
    func exactBoundary() {
        let now = Date.now
        let lastSeen = calendar.date(byAdding: .day, value: -180, to: now)!
        let eval = DeadManSwitchEngine.evaluate(
            lastSeenAt: lastSeen, now: now,
            silentPeriodDays: 180, warningWindowDays: 7
        )
        #expect(eval.status == .triggered)
    }

    @Test("Zero days since last seen")
    func zeroDays() {
        let now = Date.now
        let eval = DeadManSwitchEngine.evaluate(
            lastSeenAt: now, now: now,
            silentPeriodDays: 180, warningWindowDays: 7
        )
        #expect(eval.status == .safe)
        #expect(eval.daysSinceLastSeen == 0)
        #expect(eval.daysUntilTrigger == 180)
    }

    @Test("Same-day check-in keeps safe status")
    func sameDayCheckIn() {
        let now = Date.now
        let eval = DeadManSwitchEngine.evaluate(
            lastSeenAt: now, now: now,
            silentPeriodDays: 90, warningWindowDays: 5
        )
        #expect(eval.status == .safe)
        #expect(eval.daysSinceLastSeen == 0)
        #expect(eval.daysUntilTrigger == 90)
    }
}
