import XCTest
@testable import NorthstarOR

final class CaseFormDraftTests: XCTestCase {
    private let time = Date(timeIntervalSince1970: 1_800_000_000)

    private func workspace() -> WorkspaceConfiguration {
        let site = Hospital(id: "site-a", name: "Fictional facility", town: "Example town", workspaceID: "ws",
                            timeZoneIdentifier: "America/Chicago")
        return WorkspaceConfiguration(id: "ws", name: "Fictional workspace", sites: [site], contacts: [],
            localParticipant: LocalParticipant(id: "p", workspaceID: "ws", displayName: "Fictional coordinator", statedRole: .coordinator))
    }

    private func filled(id: String = "case-1", reference: String = "NS-104", title: String = "Fictional case") -> CaseFormDraft {
        var draft = CaseFormDraft.new(in: workspace(), now: time, id: id)
        draft.input.reference = reference
        draft.input.title = title
        return draft
    }

    func testNewDraftDefaultsToSupportedTemplateAndFirstSite() {
        let draft = CaseFormDraft.new(in: workspace(), now: time)
        XCTAssertEqual(draft.input.siteID, "site-a")
        XCTAssertEqual(draft.input.templateReference, FictionalCoordinationTemplate.reference)
        XCTAssertEqual(draft.input.deviceFamily, FictionalCoordinationTemplate.deviceFamily)
        XCTAssertTrue(draft.input.id.hasPrefix("case-"))
    }

    func testValidDraftHasNoIssue() {
        XCTAssertNil(filled().validate(in: workspace(), existingCases: [], editing: nil))
    }

    func testMissingTitleAndReference() {
        XCTAssertEqual(filled(title: "  ").validate(in: workspace(), existingCases: [], editing: nil)?.field, .title)
        XCTAssertEqual(filled(reference: "").validate(in: workspace(), existingCases: [], editing: nil)?.field, .reference)
    }

    func testDuplicateReferenceAndTitleAreFieldErrors() throws {
        let ws = workspace()
        let first = try filled().input.makeProcedure(in: ws, existingCases: [], templates: CaseFormDraft.templates)
        let sameRef = filled(id: "case-2", reference: " ns-104 ", title: "Other case")
        XCTAssertEqual(sameRef.validate(in: ws, existingCases: [first], editing: nil),
                       CaseFormDraft.Issue(field: .reference, message: "Another case already uses this reference."))
        let sameTitle = filled(id: "case-3", reference: "NS-105")
        XCTAssertEqual(sameTitle.validate(in: ws, existingCases: [first], editing: nil)?.field, .title)
    }

    func testUnknownSiteAndDuration() {
        var draft = filled()
        draft.input.siteID = "missing"
        XCTAssertEqual(draft.validate(in: workspace(), existingCases: [], editing: nil)?.field, .site)
        draft = filled()
        draft.input.durationMinutes = 0
        XCTAssertEqual(draft.validate(in: workspace(), existingCases: [], editing: nil)?.field, .duration)
    }

    func testEditingKeepsIdAndAllowsUnchangedValues() throws {
        let ws = workspace()
        let saved = try filled().input.makeProcedure(in: ws, existingCases: [], templates: CaseFormDraft.templates)
        var draft = CaseFormDraft.editing(saved, in: ws)
        XCTAssertEqual(draft.input.id, saved.id)
        XCTAssertNil(draft.validate(in: ws, existingCases: [saved], editing: saved))
        draft.input.title = "Renamed fictional case"
        XCTAssertNil(draft.validate(in: ws, existingCases: [saved], editing: saved))
        XCTAssertEqual(draft.input.id, saved.id)
    }

    func testNonContractErrorsAreGeneralAndKeepInput() {
        struct Boom: Error {}
        let issue = CaseFormDraft.issue(for: Boom())
        XCTAssertNil(issue.field)
        XCTAssertFalse(issue.message.isEmpty)
    }

    func testDurationLabel() {
        XCTAssertEqual(CaseFormDraft.durationLabel(45), "45 min")
        XCTAssertEqual(CaseFormDraft.durationLabel(120), "2 h")
        XCTAssertEqual(CaseFormDraft.durationLabel(90), "1 h 30 min")
    }

    func testNewDraftTimeIsRoundedToMinute() {
        let draft = CaseFormDraft.new(in: workspace(), now: Date(timeIntervalSinceReferenceDate: 600 + 37.5))
        XCTAssertEqual(draft.input.scheduledAt.timeIntervalSinceReferenceDate, 600)
    }

    func testNonContractLocalizedErrorShowsItsDescription() {
        struct Failure: LocalizedError { var errorDescription: String? { "Storage is full." } }
        XCTAssertEqual(CaseFormDraft.issue(for: Failure()).message, "Storage is full.")
    }

    func testLegacyCaseWithoutTemplateCanBeEdited() {
        let ws = workspace()
        let legacy = Procedure(id: "old", name: "Legacy fictional case", deviceFamily: "pacemaker", hospitalID: "site-a",
                               scheduledAt: time, durationMinutes: 60, steps: FictionalCoordinationTemplate.steps,
                               workspaceID: "ws", reference: "OLD-1", templateReference: nil)
        let draft = CaseFormDraft.editing(legacy, in: ws)
        XCTAssertEqual(draft.input.templateReference, FictionalCoordinationTemplate.reference)
        XCTAssertNil(draft.validate(in: ws, existingCases: [legacy], editing: legacy))
        var other = legacy
        other.deviceFamily = "icd"
        let bad = CaseFormDraft.editing(other, in: ws)
        XCTAssertEqual(bad.validate(in: ws, existingCases: [other], editing: other)?.field, .template)
    }

    private func twoSiteWorkspace() -> WorkspaceConfiguration {
        var ws = workspace()
        ws.sites.append(Hospital(id: "site-b", name: "Other facility", town: "Elsewhere", workspaceID: "ws",
                                 timeZoneIdentifier: "Asia/Kolkata"))
        return ws
    }

    private func date(_ zone: String, _ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: zone)!
        return cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    func testChangeSiteKeepsWallClockTime() {
        let ws = twoSiteWorkspace()
        var draft = filled()
        draft.input.scheduledAt = date("America/Chicago", 2026, 6, 10, 9, 30)
        draft.changeSite(from: "site-a", to: "site-b", in: ws)
        XCTAssertEqual(draft.input.scheduledAt, date("Asia/Kolkata", 2026, 6, 10, 9, 30))
    }

    func testChangeSiteIntoDSTGapMovesToNextValidTime() {
        let ws = twoSiteWorkspace()
        var draft = filled()
        // 02:30 on 2026-03-08 does not exist in Chicago (clocks jump 02:00 to 03:00).
        draft.input.scheduledAt = date("Asia/Kolkata", 2026, 3, 8, 2, 30)
        draft.changeSite(from: "site-b", to: "site-a", in: ws)
        XCTAssertEqual(draft.input.scheduledAt, date("America/Chicago", 2026, 3, 8, 3, 0))
    }
}
