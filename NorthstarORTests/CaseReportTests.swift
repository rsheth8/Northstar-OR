import XCTest
@testable import NorthstarOR

final class CaseReportTests: XCTestCase {
    func testNoRecordingIsExplicitAndSnapshotRetainsOriginalValues() {
        var procedure = Procedure(id: "new-case", name: "Fictional coordination", deviceFamily: "Fictional", hospitalID: "new-site", scheduledAt: Date(timeIntervalSince1970: 0), durationMinutes: 60, steps: [ProcedureStep(id: "one", title: "Team statement", detail: "", isRequired: true, normallyCoveredByRep: false)])
        let report = CaseReport(procedure: procedure, site: nil, state: nil, events: [], questions: [], forecast: nil, capturedAt: Date(timeIntervalSince1970: 100))
        procedure.name = "Changed after snapshot"
        XCTAssertEqual(report.procedure.name, "Fictional coordination")
        XCTAssertEqual(report.items.first?.status, .unrecorded)
        XCTAssertTrue(report.text.contains("No recording"))
        XCTAssertTrue(report.text.contains("No forecast recorded"))
        XCTAssertTrue(report.text.contains("Unknown; UTC shown"))
        XCTAssertFalse(report.text.contains("Changed after snapshot"))
    }
    func testWrongCaseStateCannotPopulateItems() {
        let procedure = Procedure(id: "selected", name: "Selected case", deviceFamily: "Fictional", hospitalID: "site", scheduledAt: .now, durationMinutes: 10, steps: [ProcedureStep(id: "one", title: "Statement", detail: "", isRequired: true, normallyCoveredByRep: false)], workspaceID: "workspace")
        let state = SessionRecordingState(identity: SessionIdentity(workspaceID: "workspace", caseID: "other", sessionID: "other-session"), templateReference: CoordinationTemplateReference(id: "template", version: 1), startedAt: .now, version: 1, itemStatuses: ["one": .teamConfirmed], selectedItemID: "one", pendingAcknowledgment: nil)
        let report = CaseReport(procedure: procedure, site: nil, state: state, events: [], questions: [], forecast: nil, capturedAt: .now)
        XCTAssertNil(report.state)
        XCTAssertEqual(report.items.first?.status, .unrecorded)
    }
}
