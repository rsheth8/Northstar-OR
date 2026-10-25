import XCTest
@testable import NorthstarOR

@MainActor
final class RecordingLifecycleTests: XCTestCase {
    func testExplicitEndReopenHistoryPersistenceAndStalePreview() throws {
        let store = InMemoryWorkspaceStore()
        let model = AppModel(store: store)
        try model.loadSampleWorkspace()
        let session = try model.startOrResume(caseID: XCTUnwrap(model.cases.first?.id))
        let stale = try XCTUnwrap(session.makeCommand(.recordConfirmation))
        let target = session.currentStep?.id
        _ = try model.record(XCTUnwrap(session.makeCommand(.endRecording)))
        XCTAssertTrue(session.isEnded)
        XCTAssertEqual(session.currentStep?.id, target)
        XCTAssertTrue(session.recordingState?.itemStatuses.values.allSatisfy { $0 == .unrecorded } == true)
        XCTAssertThrowsError(try model.record(stale))
        let relaunched = AppModel(store: store)
        XCTAssertTrue(try XCTUnwrap(relaunched.activeSession).isEnded)
        _ = try model.record(XCTUnwrap(session.makeCommand(.reopenRecording)))
        XCTAssertFalse(session.isEnded)
        XCTAssertThrowsError(try model.record(stale))
        XCTAssertEqual(session.events.count, 2)
        XCTAssertFalse(try XCTUnwrap(AppModel(store: store).activeSession).isEnded)
    }
    func testPendingAcknowledgmentBlocksEndWithoutChangingUnresolvedItem() throws {
        let model = AppModel(); try model.loadSampleWorkspace()
        let session = try model.startOrResume(caseID: XCTUnwrap(model.cases.first?.id))
        let required = try XCTUnwrap(session.procedure.steps.first(where: \.isRequired))
        _ = try model.record(XCTUnwrap(session.makeCommand(.selectItem, targetItemID: required.id)))
        _ = try model.record(XCTUnwrap(session.makeCommand(.deferItem)))
        let count = session.events.count
        XCTAssertThrowsError(try model.record(XCTUnwrap(session.makeCommand(.endRecording))))
        XCTAssertFalse(session.isEnded)
        XCTAssertEqual(session.events.count, count)
        XCTAssertNotNil(session.pendingAlert)
    }
}
