import XCTest
@testable import NorthstarOR

final class CoverageMatcherTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func procedure(inHours h: Double, hospital: String = "grand-marais", family: String = "pacemaker",
                   durationMinutes: Int = 90) -> Procedure {
        Procedure(id: "p", name: "Test", deviceFamily: family, hospitalID: hospital,
                  scheduledAt: now.addingTimeInterval(h * 3600), durationMinutes: durationMinutes, steps: [])
    }

    func rep(_ id: String, _ name: String, drive: Int? = 60, skills: Set<String> = ["pacemaker"],
             available: Bool = true, remote: Bool = true) -> DeviceRep {
        DeviceRep(id: id, name: name, homeBase: "Fictional", skills: skills,
                  driveMinutes: drive.map { ["grand-marais": $0] } ?? [:],
                  isAvailable: available, canSupportRemotely: remote)
    }

    func closure(inMinutes m: Double) -> StormForecast {
        StormForecast(summary: "Simulated storm", roadClosureInHours: m / 60, snowfallInches: 10, asOf: now)
    }

    func assessment(_ rec: CoverageMatcher.Recommendation, _ id: String) -> CoverageMatcher.RepAssessment? {
        rec.assessments.first { $0.rep.id == id }
    }

    func isReschedule(_ option: CoverageMatcher.Option?) -> Bool {
        if case .reschedule? = option { return true } else { return false }
    }

    func remoteIDs(_ rec: CoverageMatcher.Recommendation) -> [String] {
        rec.options.compactMap { if case .remoteRep(let r) = $0 { return r.id } else { return nil } }
    }

    func inPersonIDs(_ rec: CoverageMatcher.Recommendation) -> [String] {
        rec.options.compactMap { if case .inPersonRep(let r, _) = $0 { return r.id } else { return nil } }
    }

    // MARK: - Starter behavior kept

    func testBlizzardBeforeCaseIsHighRiskWithRemoteAndReschedule() {
        let forecast = StormForecast(summary: "Blizzard", roadClosureInHours: 1, snowfallInches: 14)
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: SampleData.reps, forecast: forecast, now: now)
        XCTAssertEqual(rec.risk, .high)
        XCTAssertTrue(rec.reducedSupport)
        XCTAssertTrue(rec.options.contains { isReschedule($0) })
    }

    func testClearWeatherPicksClosestQualifiedRep() {
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: SampleData.reps, forecast: nil, now: now)
        XCTAssertEqual(rec.risk, .low)
        XCTAssertFalse(rec.reducedSupport)
        guard case .inPersonRep(let rep, _)? = rec.options.first else { return XCTFail("expected in-person rep") }
        XCTAssertEqual(rep.id, "rep-ana")
        XCTAssertFalse(rec.options.contains { isReschedule($0) }, "Reschedule is only a candidate without in-person coverage")
    }

    func testNoCertifiedRepMeansRescheduleOnly() {
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8, family: "robotic-arm"), reps: SampleData.reps, forecast: nil, now: now)
        XCTAssertEqual(rec.risk, .high)
        XCTAssertEqual(rec.options.count, 1)
        XCTAssertTrue(isReschedule(rec.options.first))
        XCTAssertTrue(rec.assessments.allSatisfy { $0.inPersonBlocker == .notQualified && !$0.canSupportRemotely })
    }

    // MARK: - Fictional Grand Marais sample

    func testGrandMaraisSampleOffersRemoteRepsAndRescheduleWithClosureReason() {
        let seed = SampleData.make(clock: { self.now })
        let gm = seed.procedures[0]
        let rec = CoverageMatcher().recommend(for: gm, reps: seed.reps, forecast: seed.forecasts[gm.hospitalID], now: now)

        XCTAssertEqual(rec.risk, .high)
        XCTAssertEqual(rec.roadClosureMinutes, 90)
        XCTAssertEqual(inPersonIDs(rec), [])
        XCTAssertEqual(remoteIDs(rec), ["rep-ana", "rep-marcus"])
        XCTAssertTrue(isReschedule(rec.options.last))
        XCTAssertEqual(assessment(rec, "rep-ana")?.inPersonBlocker,
                       .arrivesAfterRoadClosure(driveMinutes: 110, minutesUntilClosure: 90))
        XCTAssertEqual(assessment(rec, "rep-priya")?.inPersonBlocker, .notQualified)
    }

    // MARK: - Availability and qualification

    func testUnavailableRepIsNeverOfferedRemotely() {
        let reps = [rep("a", "Avery", available: false), rep("b", "Blake", drive: nil)]
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: reps, forecast: nil, now: now)
        XCTAssertEqual(remoteIDs(rec), ["b"])
        XCTAssertEqual(assessment(rec, "a")?.inPersonBlocker, .unavailable)
        XCTAssertEqual(assessment(rec, "a")?.canSupportRemotely, false)
    }

    func testMissingDriveTimeIsReportedNotGuessed() {
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: [rep("a", "Avery", drive: nil, remote: false)],
                                             forecast: nil, now: now)
        XCTAssertEqual(assessment(rec, "a")?.inPersonBlocker, .driveTimeUnknown)
        XCTAssertEqual(rec.risk, .high)
        XCTAssertEqual(rec.options.count, 1)
        XCTAssertTrue(isReschedule(rec.options.first))
        XCTAssertTrue(rec.reasons.contains { $0.contains("not recorded") })
        XCTAssertFalse(rec.reasons.contains { $0.localizedCaseInsensitiveContains("road") && $0.contains("Avery") },
                       "A missing drive time must not be blamed on roads")
    }

    // MARK: - Forecast

    func testAbsentForecastLeavesClosureUnknownWithoutInventingWeather() {
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: [rep("a", "Avery")], forecast: nil, now: now)
        XCTAssertNil(rec.roadClosureMinutes)
        XCTAssertEqual(rec.risk, .low)
        XCTAssertTrue(rec.reasons.contains("No forecast recorded; road closure unknown."))
    }

    func testLegacyForecastWithoutAsOfCountsFromNow() {
        let legacy = StormForecast(summary: "Legacy", roadClosureInHours: 1, snowfallInches: 3)
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: [rep("a", "Avery")], forecast: legacy, now: now)
        XCTAssertEqual(rec.roadClosureMinutes, 60)
    }

    func testClosureDuringCaseWindowIsElevatedWhenRepCanStillArrive() {
        // Arrives at 60 min, closure at 300, case 480–570.
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: [rep("a", "Avery")],
                                             forecast: closure(inMinutes: 300), now: now)
        XCTAssertEqual(inPersonIDs(rec), ["a"])
        XCTAssertEqual(rec.risk, .elevated)
    }

    // MARK: - Boundary policy

    func testArrivingExactlyAtSetupDeadlineIsOnTime() {
        // 60 min drive + 45 min setup == 105 min until start.
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 105.0 / 60), reps: [rep("a", "Avery")],
                                             forecast: nil, now: now)
        XCTAssertNil(assessment(rec, "a")?.inPersonBlocker)
    }

    func testOneMinutePastSetupDeadlineIsLate() {
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 104.0 / 60), reps: [rep("a", "Avery")],
                                             forecast: nil, now: now)
        XCTAssertEqual(assessment(rec, "a")?.inPersonBlocker,
                       .arrivesAfterSetupDeadline(driveMinutes: 60, minutesUntilSetupDeadline: 59))
    }

    func testArrivingExactlyAtRoadClosureIsTooLate() {
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: [rep("a", "Avery")],
                                             forecast: closure(inMinutes: 60), now: now)
        XCTAssertEqual(assessment(rec, "a")?.inPersonBlocker,
                       .arrivesAfterRoadClosure(driveMinutes: 60, minutesUntilClosure: 60))
    }

    func testClosureExactlyAtCaseEndIsOutsideTheWindow() {
        // Case ends at 480 + 90 = 570 min.
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: [rep("a", "Avery")],
                                             forecast: closure(inMinutes: 570), now: now)
        XCTAssertEqual(rec.risk, .low)
    }

    func testPastScheduleBlocksInPersonButKeepsRemote() {
        let rec = CoverageMatcher().recommend(for: procedure(inHours: -1), reps: [rep("a", "Avery")], forecast: nil, now: now)
        XCTAssertEqual(assessment(rec, "a")?.inPersonBlocker, .startHasPassed)
        XCTAssertEqual(remoteIDs(rec), ["a"])
        XCTAssertEqual(rec.risk, .high)
        XCTAssertTrue(isReschedule(rec.options.last))
    }

    // MARK: - Ranking

    func testTiedOptionsHaveStableOrder() {
        let reps = [rep("z", "Zoe"), rep("b2", "Blake"), rep("b1", "Blake"), rep("c", "Casey", drive: 30)]
        let first = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: reps, forecast: nil, now: now)
        let shuffled = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: reps.reversed(), forecast: nil, now: now)
        XCTAssertEqual(inPersonIDs(first), ["c", "b1", "b2", "z"])
        XCTAssertEqual(inPersonIDs(shuffled), inPersonIDs(first))
        XCTAssertEqual(first.assessments.map(\.rep.id), shuffled.assessments.map(\.rep.id))
    }

    func testRemoteSupportIsListedSeparatelyFromInPerson() {
        let reps = [rep("a", "Avery", drive: 30), rep("b", "Blake", drive: nil)]
        let rec = CoverageMatcher().recommend(for: procedure(inHours: 8), reps: reps, forecast: nil, now: now)
        XCTAssertEqual(inPersonIDs(rec), ["a"])
        XCTAssertEqual(remoteIDs(rec), ["a", "b"], "Remote support is a separate capability from attending in person")
        XCTAssertTrue(assessment(rec, "a")?.canSupportRemotely ?? false)
    }
}
