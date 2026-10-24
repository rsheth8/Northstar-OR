import XCTest
@testable import NorthstarOR

final class CoverageMatcherTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func procedure(inHours h: Double, hospital: String = "grand-marais", family: String = "pacemaker") -> Procedure {
        Procedure(id: "p", name: "Test", deviceFamily: family, hospitalID: hospital,
                  scheduledAt: now.addingTimeInterval(h * 3600), durationMinutes: 90, steps: [])
    }

    func testBlizzardBeforeCaseIsHighRiskWithRemoteAndReschedule() {
        let forecast = StormForecast(summary: "Blizzard", roadClosureInHours: 1, snowfallInches: 14)
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: SampleData.reps, forecast: forecast, now: now)
        XCTAssertEqual(rec.risk, .high)
        XCTAssertTrue(rec.reducedSupport)
        XCTAssertTrue(rec.options.contains { if case .reschedule = $0 { return true } else { return false } })
    }

    func testClearWeatherPicksClosestQualifiedRep() {
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: SampleData.reps, forecast: nil, now: now)
        XCTAssertEqual(rec.risk, .low)
        guard case .inPersonRep(let rep, _)? = rec.options.first else { return XCTFail("expected in-person rep") }
        XCTAssertEqual(rep.id, "rep-ana")
    }

    func testNoCertifiedRepMeansReschedule() {
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8, family: "robotic-arm"), reps: SampleData.reps, forecast: nil, now: now)
        XCTAssertEqual(rec.risk, .high)
        guard case .reschedule? = rec.options.first else { return XCTFail("expected reschedule") }
    }
}
