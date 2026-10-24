import XCTest
@testable import NorthstarOR

final class FictionalContentTests: XCTestCase {
    private let asOf = Date(timeIntervalSince1970: 1_800_000_000)

    func testFactoryReadsClockAndEachIDOnceAndKeepsReferencesCoherent() {
        var clockReads = 0
        var idReads: [SampleData.Record: Int] = [:]
        let seed = SampleData.make(clock: {
            clockReads += 1
            return self.asOf
        }, makeID: { record in
            idReads[record, default: 0] += 1
            return "independent-\(record.rawValue)-\(idReads[record]!)"
        })
        XCTAssertEqual(clockReads, 1)
        XCTAssertEqual(idReads.count, SampleData.Record.allCases.count)
        XCTAssertTrue(idReads.values.allSatisfy { $0 == 1 })
        XCTAssertEqual(seed.asOf, asOf)
        let sites = Set(seed.hospitals.map(\.id))
        XCTAssertTrue(seed.procedures.allSatisfy { sites.contains($0.hospitalID) })
        XCTAssertEqual(Set(seed.forecasts.keys), sites)
        XCTAssertTrue(seed.reps.allSatisfy { Set($0.driveMinutes.keys) == sites })
        XCTAssertEqual(seed.procedures.map(\.scheduledAt), [8.0, 26, 30].map { asOf.addingTimeInterval($0 * 3600) })
        let northShore = seed.hospitals.first { $0.town == "Grand Marais" }!
        XCTAssertEqual(seed.roadClosureAt(hospitalID: northShore.id), asOf.addingTimeInterval(1.5 * 3600))
        XCTAssertNil(seed.roadClosureAt(hospitalID: "missing-site"))
        let lakes = seed.hospitals.first { $0.town == "Bemidji" }!
        XCTAssertNil(seed.roadClosureAt(hospitalID: lakes.id))
    }

    func testFixedInputsReproduceOrdinaryRecordsWithoutProgressState() {
        let a = SampleData.make(clock: { self.asOf }, makeID: { "custom-\($0.rawValue)" })
        let b = SampleData.make(clock: { self.asOf }, makeID: { "custom-\($0.rawValue)" })
        XCTAssertEqual(a.hospitals, b.hospitals)
        XCTAssertEqual(a.reps, b.reps)
        XCTAssertEqual(a.forecasts, b.forecasts)
        XCTAssertEqual(a.procedures, b.procedures)
        for procedure in a.procedures.filter(FictionalCoordinationTemplate.supports) {
            let session = CoPilotSession(procedure: procedure, now: asOf)
            XCTAssertTrue(session.log.isEmpty)
            XCTAssertNil(session.pendingAlert)
            XCTAssertFalse(session.allConfirmationsRecorded)
        }
    }

    func testEmptySeedIsValidAndContainsNoAutomaticSampleRecords() {
        let empty = SampleData.Seed.empty(asOf: asOf)
        XCTAssertEqual(empty.asOf, asOf)
        XCTAssertTrue(empty.hospitals.isEmpty)
        XCTAssertTrue(empty.reps.isEmpty)
        XCTAssertTrue(empty.forecasts.isEmpty)
        XCTAssertTrue(empty.procedures.isEmpty)
        XCTAssertNil(empty.roadClosureAt(hospitalID: "any-site"))
    }

    func testTemplateWorksForIndependentCaseSiteAndContactIdentities() {
        let contact = DeviceRep(id: "contact-new", name: "Fictional Taylor", homeBase: "Example Town",
                                skills: [FictionalCoordinationTemplate.deviceFamily], driveMinutes: [:],
                                isAvailable: true, canSupportRemotely: true)
        let a = newProcedure(id: "created-case-a", hospitalID: "created-site-a")
        let b = newProcedure(id: "created-case-b", hospitalID: "created-site-b")
        XCTAssertTrue(contact.skills.contains(a.deviceFamily))
        let sessionA = CoPilotSession(procedure: a, now: asOf)
        let sessionB = CoPilotSession(procedure: b, now: asOf)
        XCTAssertTrue(sessionA.isRecordingSupported)
        XCTAssertTrue(sessionB.isRecordingSupported)
        sessionA.completeCurrentStep(at: asOf)
        sessionA.receiveRemoteMessage("Fictional technical documentation reply", from: contact.name, at: asOf)
        XCTAssertEqual(sessionA.status(of: a.steps[0]), .completed)
        XCTAssertEqual(sessionB.status(of: b.steps[0]), .current)
        XCTAssertTrue(sessionB.log.isEmpty)
        XCTAssertEqual(sessionA.procedure.id, "created-case-a")
        XCTAssertEqual(sessionB.procedure.id, "created-case-b")
    }

    func testUnsupportedICDSampleHasNoReusedItemsAndCannotRecord() {
        let seed = SampleData.make(clock: { self.asOf })
        let icd = seed.procedures.first { $0.deviceFamily == "icd" }!
        XCTAssertTrue(icd.steps.isEmpty)
        assertCannotRecord(icd)
        // A stale or constructed ICD record must also fail if it carries implant items.
        var incompatible = newProcedure()
        incompatible.deviceFamily = "icd"
        XCTAssertFalse(incompatible.steps.isEmpty)
        assertCannotRecord(incompatible)
    }

    func testEmptyAndAlteredContentCannotClaimCompletionOrRecord() {
        var empty = newProcedure()
        empty.steps = []
        assertCannotRecord(empty)
        var altered = newProcedure()
        altered.steps[0].detail = "Unreviewed replacement content"
        assertCannotRecord(altered)
    }

    func testOnlyEveryRecordedConfirmationAllowsCompleteRecordingSummary() {
        let procedure = newProcedure()
        let session = CoPilotSession(procedure: procedure, now: asOf)
        XCTAssertFalse(session.isFinished)
        XCTAssertFalse(session.allConfirmationsRecorded)
        for _ in procedure.steps { session.completeCurrentStep(at: asOf) }
        XCTAssertTrue(session.isFinished)
        XCTAssertTrue(session.allConfirmationsRecorded)
        XCTAssertEqual(session.log.filter { $0.kind == .stepCompleted }.count, procedure.steps.count)
        XCTAssertEqual(ContextPackage(session: session, hospital: nil).currentStep, session.recordingSummary)
    }

    func testAcknowledgingDeferredItemDoesNotMakeRecordingComplete() {
        let procedure = newProcedure()
        let session = CoPilotSession(procedure: procedure, now: asOf)
        session.skipCurrentStep(at: asOf)
        session.acknowledgeAlert(at: asOf)
        for _ in procedure.steps.dropFirst() { session.completeCurrentStep(at: asOf) }
        XCTAssertTrue(session.isFinished)
        XCTAssertFalse(session.allConfirmationsRecorded)
        XCTAssertEqual(session.status(of: procedure.steps[0]), .skipped)
        XCTAssertTrue(session.recordingSummary.contains("1 unresolved item"))
        let package = ContextPackage(session: session, hospital: nil)
        XCTAssertEqual(package.currentStep, session.recordingSummary)
        XCTAssertEqual(package.deviations.count, 1)
    }

    private func newProcedure(id: String = "independent-case", hospitalID: String = "independent-site") -> Procedure {
        FictionalCoordinationTemplate.makeProcedure(id: id, name: "Independently created fictional case", hospitalID: hospitalID,
                                                   scheduledAt: asOf.addingTimeInterval(3600), durationMinutes: 45)
    }

    private func assertCannotRecord(_ procedure: Procedure, file: StaticString = #filePath, line: UInt = #line) {
        let session = CoPilotSession(procedure: procedure, now: asOf)
        session.completeCurrentStep(at: asOf)
        session.skipCurrentStep(at: asOf)
        session.acknowledgeAlert(at: asOf)
        XCTAssertFalse(session.isRecordingSupported, file: file, line: line)
        XCTAssertNil(session.currentStep, file: file, line: line)
        XCTAssertFalse(session.isFinished, file: file, line: line)
        XCTAssertFalse(session.allConfirmationsRecorded, file: file, line: line)
        XCTAssertTrue(session.statuses.isEmpty, file: file, line: line)
        XCTAssertTrue(session.log.isEmpty, file: file, line: line)
        XCTAssertNil(session.pendingAlert, file: file, line: line)
        XCTAssertTrue(session.recordingSummary.contains("unavailable"), file: file, line: line)
        XCTAssertEqual(ContextPackage(session: session, hospital: nil).currentStep, session.recordingSummary, file: file, line: line)
    }
}
