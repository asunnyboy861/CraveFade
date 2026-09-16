import XCTest
@testable import CraveFade

final class CraveFadeTests: XCTestCase {

    func makeProfile(goal: QuitGoal, baseline: Int = 100, taper: Double = 0.15, start: Date = .now) -> QuitProfile {
        let profile = QuitProfile()
        profile.goal = goal
        profile.baselinePuffs = baseline
        profile.taperPercent = taper
        profile.startDate = start
        return profile
    }

    func testDailyLimitQuitNow() {
        let profile = makeProfile(goal: .quitNow)
        XCTAssertEqual(TaperPlanEngine.dailyLimit(profile: profile, on: .now), 0)
    }

    func testDailyLimitObserve() {
        let profile = makeProfile(goal: .observe)
        XCTAssertEqual(TaperPlanEngine.dailyLimit(profile: profile, on: .now), .max)
    }

    func testDailyLimitTaperDeclines() {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -14, to: .now)!
        let profile = makeProfile(goal: .taper, baseline: 100, taper: 0.10, start: start)
        let nowLimit = TaperPlanEngine.dailyLimit(profile: profile, on: .now)
        XCTAssertLessThan(nowLimit, 100)
        let earlier = TaperPlanEngine.dailyLimit(profile: profile, on: cal.date(byAdding: .day, value: -7, to: .now)!)
        XCTAssertLessThanOrEqual(nowLimit, earlier)
    }

    func testTaperReachesZero() {
        let start = Calendar.current.date(byAdding: .day, value: -400, to: .now)!
        let profile = makeProfile(goal: .taper, baseline: 100, taper: 0.20, start: start)
        XCTAssertEqual(TaperPlanEngine.dailyLimit(profile: profile, on: .now), 0)
        XCTAssertNotNil(TaperPlanEngine.projectedQuitDate(profile: profile))
    }

    func testCostPerPuff() {
        let profile = makeProfile(goal: .observe)
        profile.costPerUnit = 12
        profile.puffsPerUnit = 600
        XCTAssertEqual(profile.costPerPuff, 0.02, accuracy: 0.0001)
    }

    func testCorrectionNetMath() {
        let profile = makeProfile(goal: .quitNow)
        profile.costPerUnit = 10
        profile.puffsPerUnit = 100
        XCTAssertEqual(profile.costPerPuff, 0.10, accuracy: 0.0001)
    }
}
