import XCTest
@testable import NorthstarOR

final class VoiceCommandTests: XCTestCase {
    func testOnlyExactBoundedPhrases() {
        XCTAssertEqual(VoiceCommand.parse(" Record  Confirmation "), .complete)
        XCTAssertEqual(VoiceCommand.parse("defer item"), .skip)
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

}
