import XCTest
@testable import NorthstarOR

/// The sample's hourly evidence must agree with its summary forecasts, so the matcher,
/// weather views and reports tell one story. All values are fictional.
@MainActor
final class FictionalPlanningScenariosTests: XCTestCase {
    private let asOf = Date(timeIntervalSince1970: 1_800_000_000)

    private func sample() throws -> AppModel {
        let model = AppModel(store: InMemoryWorkspaceStore(), clock: { self.asOf })
        try model.loadSampleWorkspace()
        return model
    }

    func testEverySiteHasValidHourlyEvidenceMatchingItsSummaryForecast() throws {
        let model = try sample()
        let seed = SampleData.make(clock: { self.asOf })
        XCTAssertEqual(model.planningEvidenceRecords.count, seed.hospitals.count)
        for site in seed.hospitals {
            let evidence = try XCTUnwrap(model.planningEvidence(for: site.id))
            let summary = try XCTUnwrap(seed.forecasts[site.id])
            XCTAssertNoThrow(try evidence.validate())
            XCTAssertEqual(evidence.revision, 0)
            XCTAssertEqual(evidence.samples.count, FictionalPlanningScenarios.lastHour - FictionalPlanningScenarios.firstHour + 1)
            XCTAssertEqual(evidence.forecast.snowfallInches, summary.snowfallInches, accuracy: 0.001)
            XCTAssertEqual(evidence.closureAt, seed.roadClosureAt(hospitalID: site.id))
            XCTAssertEqual(evidence.summary, summary.summary)
            XCTAssertFalse(evidence.isStale(at: asOf))
            XCTAssertTrue(evidence.isStale(at: asOf.addingTimeInterval(7 * 3600)), "Sample evidence ages like any issued forecast")
            XCTAssertTrue(evidence.samples.allSatisfy { $0.temperatureFahrenheit != nil && $0.windMPH != nil })
        }
    }

    func testBlizzardScenarioDrivesTheSameCoverageResultAsTheSummary() throws {
        let model = try sample()
        let northShore = try XCTUnwrap(model.cases.first { $0.id == SampleData.Record.northShoreCase.rawValue })
        let rec = model.recommendation(for: northShore)
        XCTAssertEqual(rec.risk, .high)
        XCTAssertEqual(rec.roadClosureMinutes, 90)
        let remote = rec.options.compactMap { option -> String? in
            if case .remoteRep(let rep) = option { return rep.id } else { return nil }
        }
        XCTAssertEqual(remote, ["rep-ana", "rep-marcus"])
        let lakes = try XCTUnwrap(model.cases.first { $0.id == SampleData.Record.lakesCase.rawValue })
        XCTAssertEqual(model.recommendation(for: lakes).risk, .low)
        XCTAssertTrue(model.recommendation(for: lakes).reasons.contains("Forecast records no road closure."))
    }

    func testEvidenceSurvivesRelaunchAndTheFirstEditBecomesRevisionOne() throws {
        let store = InMemoryWorkspaceStore()
        let model = AppModel(store: store, clock: { self.asOf })
        try model.loadSampleWorkspace()
        let site = SampleData.Record.northShoreSite.rawValue
        let relaunched = AppModel(store: store, clock: { self.asOf })
        XCTAssertEqual(relaunched.planningEvidence(for: site), model.planningEvidence(for: site))
        var edited = try XCTUnwrap(model.planningEvidence(for: site))
        edited.summary = "Fictional edited scenario"
        let saved = try model.savePlanningEvidence(edited, expectedRevision: 0)
        XCTAssertEqual(saved.revision, 1)
        XCTAssertEqual(AppModel(store: store, clock: { self.asOf }).planningEvidence(for: site)?.summary, "Fictional edited scenario")
    }

    func testBlizzardPeaksDuringTheNorthShoreCaseWindow() {
        let evidence = FictionalPlanningScenarios.make(siteID: "site", scenario: FictionalPlanningScenarios.northShoreBlizzard, asOf: asOf)
        let peak = evidence.orderedSamples.max { $0.snowfallInches < $1.snowfallInches }
        XCTAssertEqual(peak?.snowfallInches, 1.8)
        XCTAssertGreaterThanOrEqual(evidence.orderedSamples.compactMap(\.windMPH).max() ?? 0, 35, "Blizzard wind in the scenario")
        XCTAssertTrue(evidence.orderedSamples.allSatisfy { $0.snowfallInches >= 0 })
    }
}
