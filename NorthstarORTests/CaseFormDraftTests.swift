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
}
