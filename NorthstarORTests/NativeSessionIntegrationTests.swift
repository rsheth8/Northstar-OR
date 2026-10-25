import XCTest
@testable import NorthstarOR

@MainActor
final class NativeSessionIntegrationTests: XCTestCase {
    private func pair(clock: @escaping () -> Date = Date.init) throws -> (AppModel, AppModel, SessionPair, SessionPair, InMemoryWorkspaceStore) {
        let roomLink = SessionPair(), repLink = SessionPair()
        roomLink.other = repLink; repLink.other = roomLink
        let store = InMemoryWorkspaceStore()
        let room = AppModel(sync: LocalSyncService(nearby: roomLink), clock: clock)
        let rep = AppModel(sync: LocalSyncService(nearby: repLink), store: store, clock: clock, post: .rep)
        try room.loadSampleWorkspace(); try rep.loadSampleWorkspace()
        _ = try room.startOrResume(caseID: SampleData.Record.northShoreCase.rawValue)
        roomLink.connect(); repLink.connect()
        // Both callbacks exist before the room publishes the authoritative join brief.
        try roomLink.publish(XCTUnwrap(roomLink.lastSnapshot))
        return (room, rep, roomLink, repLink, store)
    }

    func testConnectedRoomWithoutRecordingExplainsTheMissingCase() throws {
        let link = SessionPair()
        let room = AppModel(sync: LocalSyncService(nearby: link))
        try room.loadSampleWorkspace()
        link.connect()
        room.requestCall()
        XCTAssertEqual(room.nearbyError, "Start or resume a case in Planner before requesting a call.")
        XCTAssertNil(room.callInvitation)
        XCTAssertEqual(room.linkState, .connected(peerName: "Fictional peer"))
    }

    func testConnectedRepWithoutCurrentRoomRecordingExplainsTheMissingContext() throws {
        let link = SessionPair()
        let rep = AppModel(sync: LocalSyncService(nearby: link), post: .rep)
        try rep.loadSampleWorkspace()
        link.connect()
        rep.requestCall()
        XCTAssertEqual(rep.nearbyError, "The room device must start or resume a case before you can request a call.")
        XCTAssertNil(rep.callInvitation)
    }

    func testLateJoinWithoutQuestionLiveUpdatesMessagesAndRelaunch() throws {
        let (room, rep, _, _, store) = try pair()
        XCTAssertTrue(rep.remoteSessionCurrent)
        XCTAssertTrue(rep.questions.isEmpty)
        let session = try XCTUnwrap(room.activeSession)
        _ = try room.record(XCTUnwrap(session.makeCommand(.deferItem)))
        XCTAssertEqual(rep.remoteSession?.context.recordingRevision, session.recordingState?.version)
        let note = try rep.sendSessionNote(text: "Fictional rep joined")
        XCTAssertEqual(room.sessionNotes.map(\.id), [note.id])
        XCTAssertEqual(rep.sessionNotes[0].delivery, .receivedByPeer)
        let restored = AppModel(store: store, post: .rep)
        XCTAssertEqual(restored.remoteSession?.origin, rep.remoteSession?.origin)
        XCTAssertEqual(restored.sessionNotes.map(\.id), [note.id])
        XCTAssertFalse(restored.remoteSessionCurrent)
        XCTAssertEqual(room.activeSession?.pendingAlert?.id, session.currentStep?.id)
    }

    func testFailedMessageSurvivesSnapshotAndRetryKeepsIdentity() throws {
        let (room, rep, roomLink, repLink, _) = try pair()
        repLink.failSends = true
        XCTAssertThrowsError(try rep.sendSessionNote(text: "Keep this update"))
        let kept = try XCTUnwrap(rep.sessionNotes.last)
        try roomLink.publish(XCTUnwrap(roomLink.lastSnapshot))
        XCTAssertEqual(rep.sessionNotes.map(\.id), [kept.id])
        repLink.failSends = false
        let retried = try rep.sendSessionNote(text: "Keep this update")
        XCTAssertEqual(retried.id, kept.id)
        XCTAssertEqual(room.sessionNotes.map(\.id), [kept.id])
        XCTAssertEqual(rep.sessionNotes.count, 1)
        XCTAssertEqual(rep.sessionNotes[0].delivery, .receivedByPeer)
    }

    func testRecordedSupportContextPublishesAndSurvivesRelaunch() throws {
        let link = SessionPair()
        let store = InMemoryWorkspaceStore()
        let room = AppModel(sync: LocalSyncService(nearby: link), store: store)
        try room.loadSampleWorkspace()
        let session = try room.startOrResume(caseID: SampleData.Record.northShoreCase.rawValue)
        link.connect()
        room.sync.send(.reducedSupportChanged(procedureID: session.procedure.id, on: true))
        XCTAssertEqual(link.lastSnapshot?.context.reducedSupport, true)
        XCTAssertEqual(AppModel(store: store).activeSession?.reducedSupport, true)
    }

    func testSaveRecoveryFinalizesRepSnapshotWithoutNewRoomEvent() throws {
        let (room, rep, roomLink, _, store) = try pair()
        store.failWrites = true
        try roomLink.publish(XCTUnwrap(roomLink.lastSnapshot))
        XCTAssertFalse(rep.remoteSessionCurrent)
        XCTAssertNotNil(rep.saveError)
        store.failWrites = false
        try rep.retrySave()
        XCTAssertTrue(rep.remoteSessionCurrent)
        XCTAssertNil(rep.saveError)
        let note = try rep.sendSessionNote(text: "Recovered")
        XCTAssertEqual(room.sessionNotes.last?.id, note.id)
    }

    func testExpiredAndCanceledInvitationCannotStartMedia() throws {
        var time = Date()
        let (room, rep, roomLink, repLink, _) = try pair(clock: { time })
        room.requestCall()
        let invitation = try XCTUnwrap(room.callInvitation)
        XCTAssertEqual(rep.callInvitation?.id, invitation.id)
        time = time.addingTimeInterval(31)
        rep.acceptInvitation()
        XCTAssertEqual(rep.callInvitation?.state, .expired)
        XCTAssertNil(room.nearbyCall); XCTAssertNil(rep.nearbyCall)
        var stale = invitation; stale.state = .accepted
        roomLink.onInvitation?(stale)
        XCTAssertNil(room.nearbyCall)
        time = time.addingTimeInterval(1)
        rep.requestCall()
        XCTAssertEqual(room.callInvitation?.from, .rep)
        rep.cancelInvitation()
        XCTAssertEqual(room.callInvitation?.state, .canceled)
        room.acceptInvitation()
        XCTAssertNil(room.nearbyCall)
        XCTAssertTrue(roomLink.signals.isEmpty); XCTAssertTrue(repLink.signals.isEmpty)
    }
}

@MainActor
private final class SessionPair: NearbyTransport {
    weak var other: SessionPair?
    var failSends = false
    var supportsSession: Bool { true }
    var linkState: NearbyLinkState = .looking
    var onEnvelope: ((SupportEnvelope) -> Void)?
    var onLinkState: ((NearbyLinkState) -> Void)?
    var onSnapshot: ((SharedSessionSnapshot) -> Void)?
    var onInvitation: ((CallInvitation) -> Void)?
    var onCallSignal: ((NativeCallSignal) -> Void)?
    var lastSnapshot: SharedSessionSnapshot?
    var signals: [NativeCallSignal] = []
    func start() { connect() }
    func connect() { linkState = .connected(peerName: "Fictional peer"); onLinkState?(linkState) }
    func stop() { linkState = .idle; onLinkState?(linkState) }
    func send(_ envelope: SupportEnvelope) throws {
        if failSends { throw NearbyTransportError.notConnected }
        other?.onEnvelope?(envelope)
    }
    func publish(_ snapshot: SharedSessionSnapshot) throws { lastSnapshot = snapshot; other?.onSnapshot?(snapshot) }
    func sendInvitation(_ invitation: CallInvitation) throws { other?.onInvitation?(invitation) }
    func sendCallSignal(_ signal: NativeCallSignal) throws { signals.append(signal); other?.onCallSignal?(signal) }
}
