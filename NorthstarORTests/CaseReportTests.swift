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
    func testGeneralMessagesAreFrozenAndIsolatedToWorkspaceCaseAndSession() throws {
        let time = Date(timeIntervalSince1970: 1_000)
        let procedure = Procedure(id: "selected", name: "Selected case", deviceFamily: "Fictional", hospitalID: "site", scheduledAt: time, durationMinutes: 10, steps: [ProcedureStep(id: "one", title: "Statement", detail: "", isRequired: true, normallyCoveredByRep: false)], workspaceID: "workspace")
        let state = SessionRecordingState(identity: SessionIdentity(workspaceID: "workspace", caseID: "selected", sessionID: "session"), templateReference: CoordinationTemplateReference(id: "template", version: 1), startedAt: time, version: 0, itemStatuses: ["one": .unrecorded], selectedItemID: "one", pendingAcknowledgment: nil)
        let actor = LocalParticipant(id: "actor", workspaceID: "workspace", displayName: "Fictional coordinator", statedRole: .coordinator)
        var messages = [try SessionNote.make(id: "matching", workspaceID: "workspace", caseID: "selected", sessionID: "session", text: "Recorded general message", actor: actor, sentAt: time)]
        messages += [try SessionNote.make(id: "other-case", workspaceID: "workspace", caseID: "other", sessionID: "session", text: "Wrong case content", actor: actor, sentAt: time)]
        messages += [try SessionNote.make(id: "other-session", workspaceID: "workspace", caseID: "selected", sessionID: "other", text: "Wrong session content", actor: actor, sentAt: time)]
        let foreignActor = LocalParticipant(id: "foreign", workspaceID: "other", displayName: "Foreign coordinator", statedRole: .coordinator)
        messages += [try SessionNote.make(id: "other-workspace", workspaceID: "other", caseID: "selected", sessionID: "session", text: "Wrong workspace content", actor: foreignActor, sentAt: time)]
        let report = CaseReport(procedure: procedure, site: nil, state: state, events: [], questions: [], notes: messages, forecast: nil, capturedAt: time)
        messages.removeAll()
        XCTAssertEqual(report.notes.map(\.id), ["matching"])
        XCTAssertTrue(report.text.contains("Fictional coordinator · General message: Recorded general message"))
        XCTAssertTrue(report.text.contains(report.date(time)))
        XCTAssertFalse(report.text.contains("Wrong case content"))
        XCTAssertFalse(report.text.contains("Wrong session content"))
        XCTAssertFalse(report.text.contains("Wrong workspace content"))
    }
}
