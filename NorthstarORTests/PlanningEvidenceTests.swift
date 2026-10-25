import XCTest
@testable import NorthstarOR

final class PlanningEvidenceTests: XCTestCase {
    func testLegacyClosureWithoutBaselineStaysUnknownAcrossEvaluations() {
        let forecast = StormForecast(summary: "Fictional legacy forecast", roadClosureInHours: 1, snowfallInches: 3)
        let at = Date(timeIntervalSince1970: 1_800_000_000)
        let procedure = Procedure(id: "independent", name: "Fictional", deviceFamily: "pacemaker", hospitalID: "site", scheduledAt: at.addingTimeInterval(10000), durationMinutes: 60, steps: [])
        for now in [at, at.addingTimeInterval(3600)] {
            let result = CoverageMatcher().recommend(for: procedure, reps: [], forecast: forecast, now: now)
            XCTAssertNil(result.roadClosureMinutes, "Missing issue time cannot move a road closure forward on every evaluation")
            XCTAssertTrue(result.reasons.contains { $0.localizedCaseInsensitiveContains("unknown") })
        }
    }
    func testEvidenceRejectsDuplicateSamplesAndPreservesExplicitClosure() throws {
        let at = Date(timeIntervalSince1970: 1_800_000_000)
        var value = PlanningEvidence(siteID: "site", source: "Fictional source", scenario: "Manual", recordedAt: at,
            issuedAt: at, validFrom: at, validUntil: at.addingTimeInterval(7200), summary: "Fictional weather",
            closure: .at(at.addingTimeInterval(3600)), samples: [.init(timestamp: at, snowfallInches: 1)])
        try value.validate()
        XCTAssertEqual(value.forecast.roadClosureAt, value.closureAt)
        value.samples.append(value.samples[0])
        XCTAssertThrowsError(try value.validate())
        let legacy = PlanningEvidence.legacy(siteID: "site", forecast: .init(summary: "Unknown", roadClosureInHours: 1, snowfallInches: 3))
        XCTAssertEqual(legacy.forecast.snowfallInches, 3)
        XCTAssertNil(legacy.forecast.asOf)
        XCTAssertNil(legacy.recordedAt)
        XCTAssertNil(legacy.issuedAt)
        XCTAssertTrue(legacy.samples.isEmpty)
        XCTAssertNil(legacy.forecast.roadClosureAt)
        XCTAssertEqual(legacy.closure, .unknown)
    }

    @MainActor
    func testEvidenceRevisionPersistenceStaleEditAndFailedWrite() throws {
        let store = InMemoryWorkspaceStore()
        let model = AppModel(store: store)
        try model.loadSampleWorkspace()
        let site = try XCTUnwrap(model.hospitals.first)
        let original = model.planningEvidence(for: site.id)
        let at = Date(timeIntervalSince1970: 1_800_000_000)
        let proposed = PlanningEvidence(siteID: site.id, source: "Fictional editor", scenario: "Manual", recordedAt: at,
            issuedAt: at, validFrom: at, validUntil: at.addingTimeInterval(7200), summary: "Independently named scenario",
            closure: .at(at.addingTimeInterval(3600)), samples: [.init(timestamp: at, snowfallInches: 1)])
        let saved = try model.savePlanningEvidence(proposed, expectedRevision: original?.revision)
        XCTAssertEqual(saved.revision, 1)
        XCTAssertThrowsError(try model.savePlanningEvidence(proposed, expectedRevision: original?.revision))
        XCTAssertEqual(AppModel(store: store).planningEvidence(for: site.id), saved)
        store.failWrites = true
        XCTAssertThrowsError(try model.savePlanningEvidence(proposed, expectedRevision: saved.revision))
        XCTAssertEqual(model.planningEvidence(for: site.id), saved)
        XCTAssertEqual(AppModel(store: store).planningEvidence(for: site.id), saved)
    }

    func testOldSnapshotDecodesWithoutEvidenceAndInvalidSiteIsRejected() throws {
        let data = Data(#"{"formatVersion":1,"forecasts":{},"cases":[],"sessions":[],"drafts":[],"supportQuestions":[],"sessionNotes":[]}"#.utf8)
        let snapshot = try JSONDecoder().decode(WorkspaceSnapshot.self, from: data)
        XCTAssertTrue(snapshot.planningEvidenceRecords.isEmpty)
        try snapshot.validate()
        var invalid = snapshot
        invalid.planningEvidenceRecords = [PlanningEvidence(siteID: "missing", source: "Fictional", scenario: "Manual", summary: "Test")]
        XCTAssertThrowsError(try invalid.validate())
    }

}
