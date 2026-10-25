import XCTest
@testable import NorthstarOR

final class VoiceCommandTests: XCTestCase {
    func testOnlyExactBoundedPhrases() {
        XCTAssertEqual(VoiceCommand.parse(" Record  Confirmation "), .complete)
        XCTAssertEqual(VoiceCommand.parse("defer this item."), .skip)
        XCTAssertEqual(VoiceCommand.parse("Record confirmation."), .complete)
        XCTAssertEqual(VoiceCommand.parse("Open Planner!"), .openPlanner)
        XCTAssertEqual(VoiceCommand.parse("Open Co-pilot"), .openCoPilot)
        XCTAssertEqual(VoiceCommand.parse("Show unresolved items"), .showUnresolved)
        XCTAssertEqual(VoiceCommand.parse("Stop listening"), .stopListening)
        XCTAssertEqual(VoiceCommand.parse("acknowledge deferral"), .confirm)
        for phrase in ["do not record confirmation", "record confirmation please", "done", "next", "skip", "confirm", "record", "record confirmation defer item", "send question"] {
            XCTAssertNil(VoiceCommand.parse(phrase), phrase)
        }
    }
    @MainActor func testPartialAndDuplicateFinalCannotCreateAnotherPreview() {
        let router = VoiceCommandRouter()
        let id = UUID()
        router.receive(id: id, transcript: "record confirmation", isFinal: false, captured: nil)
        XCTAssertNil(router.pending)
        router.receive(id: id, transcript: "record confirmation", isFinal: true, captured: nil)
        router.receive(id: id, transcript: "defer item", isFinal: true, captured: nil)
        XCTAssertEqual(router.heard, "record confirmation")
        router.invalidate()
        XCTAssertNil(router.heard)
        XCTAssertNil(router.take())
    }
    @MainActor func testCapturedPreviewIsSingleUseAndStaleCommandCannotMutate() throws {
        let session = CoPilotSession(procedure: FictionalCoordinationTemplate.makeProcedure(id: "voice-case", name: "Voice case", hospitalID: "voice-site", scheduledAt: .now, durationMinutes: 45, workspaceID: "voice-workspace"), sessionID: "voice-session")
        let captured = try XCTUnwrap(session.makeCommand(.recordConfirmation, source: .voice))
        let router = VoiceCommandRouter()
        let recognition = UUID()
        router.receive(id: recognition, transcript: "record confirmation", isFinal: true, captured: captured)
        XCTAssertTrue(session.events.isEmpty)
        let pending = try XCTUnwrap(router.take())
        XCTAssertEqual(pending.source, .voice)
        XCTAssertNil(router.take())
        try session.apply(XCTUnwrap(session.makeCommand(.deferItem)))
        let events = session.events
        XCTAssertThrowsError(try session.apply(pending))
        XCTAssertEqual(session.events, events)
        router.receive(id: recognition, transcript: "record confirmation", isFinal: true, captured: captured)
        XCTAssertNil(router.pending)
    }

    @MainActor func testCapturedCommandCannotCrossSessionOrChangedSelection() throws {
        func make(_ id: String) -> CoPilotSession {
            CoPilotSession(procedure: FictionalCoordinationTemplate.makeProcedure(id: id, name: "Fictional voice case", hospitalID: "site", scheduledAt: .now, durationMinutes: 45, workspaceID: "workspace"), sessionID: id)
        }
        let first = make("first"), second = make("second")
        let router = VoiceCommandRouter()
        router.receive(id: UUID(), transcript: "record confirmation", isFinal: true,
                       captured: first.makeCommand(.recordConfirmation, source: .voice))
        let pending = try XCTUnwrap(router.take())
        XCTAssertThrowsError(try second.apply(pending))
        XCTAssertTrue(second.events.isEmpty)
        try first.apply(XCTUnwrap(first.makeCommand(.selectItem, targetItemID: "device-check")))
        let before = first.events
        XCTAssertThrowsError(try first.apply(pending))
        XCTAssertEqual(first.events, before)
    }

    @MainActor func testPinnedWarningRejectsConfirmationPreviewAndCancelInvalidatesAcknowledgment() throws {
        let session = CoPilotSession(procedure: FictionalCoordinationTemplate.makeProcedure(id: "case", name: "Fictional", hospitalID: "site", scheduledAt: .now, durationMinutes: 45, workspaceID: "workspace"))
        try session.apply(XCTUnwrap(session.makeCommand(.deferItem)))
        let warning = try XCTUnwrap(session.recordingState?.pendingAcknowledgment)
        let captured = try XCTUnwrap(session.makeCommand(.acknowledgeWarning(acknowledgment: warning), source: .voice))
        let router = VoiceCommandRouter()
        router.receive(id: UUID(), transcript: "record confirmation", isFinal: true, captured: captured)
        XCTAssertNil(router.pending)
        router.receive(id: UUID(), transcript: "acknowledge deferral", isFinal: true, captured: captured)
        XCTAssertNotNil(router.pending)
        router.invalidate()
        XCTAssertNil(router.take())
        XCTAssertEqual(session.events.count, 1)
        XCTAssertNotNil(session.recordingState?.pendingAcknowledgment)
    }

}
