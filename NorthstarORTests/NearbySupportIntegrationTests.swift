import XCTest
@testable import NorthstarOR

@MainActor
final class NearbySupportIntegrationTests: XCTestCase {
    func testLocalQuestionReplyAndRelaunchPreserveDeferral() throws {
        let store = InMemoryWorkspaceStore()
        let model = AppModel(store: store)
        try model.loadSampleWorkspace()
        let session = try model.startOrResume(caseID: SampleData.Record.northShoreCase.rawValue)
        _ = try model.record(XCTUnwrap(session.makeCommand(.deferItem)))
        let rep = try XCTUnwrap(model.reps.first { $0.statedRole == .technicalRep })
        let q = try model.sendSupportQuestion(text: "Where is the fictional reference?", recipient: rep)
        XCTAssertEqual(q.delivery, .onThisDevice)
        try model.acknowledgeQuestion(q.id)
        try model.sendSupportReply(q.id, text: "See the fictional training packet.")
        XCTAssertEqual(session.recordingState?.itemStatuses[session.currentStep!.id], .deferred)
        let restored = AppModel(store: store)
        XCTAssertEqual(restored.latestQuestion(for: session.identity.sessionID)?.replyText, "See the fictional training packet.")
        XCTAssertNotNil(restored.activeSession?.pendingAlert)
    }

    func testIndependentRepWorkspaceReceivesQuestionAndReplyWithExactReceipts() throws {
        let a = PairTransport(), b = PairTransport(); a.other = b; b.other = a
        let room = AppModel(sync: LocalSyncService(nearby: a))
        let store = InMemoryWorkspaceStore()
        let rep = AppModel(sync: LocalSyncService(nearby: b), store: store, post: .rep)
        try room.loadSampleWorkspace()
        let workspace = WorkspaceConfiguration(id: "independent", name: "Fictional rep workspace", sites: [Hospital(id: "rep-site", name: "Fictional rep site", town: "Example", workspaceID: "independent", timeZoneIdentifier: "America/Chicago")], contacts: [],
            localParticipant: .init(id: "rep", workspaceID: "independent", displayName: "Fictional Rep", statedRole: .technicalRep))
        try rep.createWorkspace(workspace)
        let session = try room.startOrResume(caseID: SampleData.Record.northShoreCase.rawValue)
        let contact = try XCTUnwrap(room.reps.first { $0.statedRole == .technicalRep })
        let q = try room.sendSupportQuestion(text: "Question A", recipient: contact)
        XCTAssertEqual(rep.latestQuestion(for: nil)?.text, "Question A")
        XCTAssertEqual(room.latestQuestion(for: nil)?.delivery, .receivedByPeer)
        try rep.acknowledgeQuestion(q.id)
        try rep.sendSupportReply(q.id, text: "Reply A")
        XCTAssertEqual(room.latestQuestion(for: session.identity.sessionID)?.replyText, "Reply A")
        XCTAssertEqual(rep.latestQuestion(for: nil)?.reply?.delivery, .receivedByPeer)
        XCTAssertEqual(AppModel(store: store).latestQuestion(for: nil)?.workspaceID, room.workspace?.id)
    }

    func testFailedSendRetryRetainsIdentityAndSnapshot() throws {
        let transport = PairTransport()
        let model = AppModel(sync: LocalSyncService(nearby: transport))
        try model.loadSampleWorkspace()
        _ = try model.startOrResume(caseID: SampleData.Record.northShoreCase.rawValue)
        let contact = try XCTUnwrap(model.reps.first { $0.statedRole == .technicalRep })
        XCTAssertThrowsError(try model.sendSupportQuestion(text: "Kept question", recipient: contact))
        let q = try XCTUnwrap(model.latestQuestion(for: nil))
        XCTAssertEqual(q.delivery, .failed)
        let receiver = PairTransport(); transport.other = receiver; receiver.other = transport
        let rep = AppModel(sync: LocalSyncService(nearby: receiver), post: .rep); try rep.loadSampleWorkspace()
        try model.retrySupportMessage(q.messageID)
        XCTAssertEqual(model.questions.count, 1)
        XCTAssertEqual(model.questions[0].snapshot, q.snapshot)
        XCTAssertEqual(model.questions[0].delivery, .receivedByPeer)
    }

    func testRepCannotRecordOrStartAndOldSnapshotStillLoads() throws {
        let model = AppModel()
        try model.loadSampleWorkspace()
        let session = try model.startOrResume(caseID: SampleData.Record.northShoreCase.rawValue)
        let command = try XCTUnwrap(session.makeCommand(.recordConfirmation))
        model.demoPost = .rep
        XCTAssertThrowsError(try model.record(command))
        XCTAssertThrowsError(try model.startOrResume(caseID: session.procedure.id))
        XCTAssertEqual(session.recordingState?.version, 0)
        let data = try JSONEncoder().encode(WorkspaceSnapshot(workspace: model.workspace))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "supportQuestions")
        let restored = AppModel(store: InMemoryWorkspaceStore(data: try JSONSerialization.data(withJSONObject: json)))
        XCTAssertEqual(restored.loadState, .ready)
        XCTAssertTrue(restored.questions.isEmpty)
    }

    func testSaveFailureKeepsQuestionAndDraftWithoutTransmittingUntilRetry() throws {
        let a = PairTransport(), b = PairTransport(); a.other = b; b.other = a
        let store = InMemoryWorkspaceStore()
        let room = AppModel(sync: LocalSyncService(nearby: a), store: store)
        let rep = AppModel(sync: LocalSyncService(nearby: b), post: .rep)
        try room.loadSampleWorkspace(); try rep.loadSampleWorkspace()
        _ = try room.startOrResume(caseID: SampleData.Record.northShoreCase.rawValue)
        let key = try room.supportDraftKey()
        try room.setDraft("Kept draft", for: key)
        store.failWrites = true
        XCTAssertThrowsError(try room.sendSupportQuestion(text: "Kept draft", recipient: XCTUnwrap(room.reps.first)))
        XCTAssertTrue(rep.questions.isEmpty)
        XCTAssertEqual(room.draft(for: key), "Kept draft")
        XCTAssertNotNil(room.saveError)
        let question = try XCTUnwrap(room.questions.last)
        store.failWrites = false
        try room.retrySupportMessage(question.messageID)
        XCTAssertEqual(rep.questions.count, 1)
        XCTAssertEqual(rep.questions[0].snapshot, question.snapshot)
    }

    func testSavedLocalQuestionCanBeSentLaterAndReceiptRequiresSavedInbox() throws {
        let room = AppModel()
        let store = InMemoryWorkspaceStore()
        let a = PairTransport(), b = PairTransport(); a.other = b; b.other = a
        let rep = AppModel(sync: LocalSyncService(nearby: b), store: store, post: .rep)
        try room.loadSampleWorkspace(); try rep.loadSampleWorkspace()
        _ = try room.startOrResume(caseID: SampleData.Record.northShoreCase.rawValue)
        let question = try room.sendSupportQuestion(text: "Saved for later", recipient: XCTUnwrap(room.reps.first))
        XCTAssertEqual(question.delivery, .onThisDevice)
        room.installNearbyTransport(a)
        store.failWrites = true
        try room.retrySupportMessage(question.messageID)
        XCTAssertEqual(room.questions[0].delivery, .waitingForPeer)
        XCTAssertNotNil(rep.saveError)
        store.failWrites = false
        try room.retrySupportMessage(question.messageID)
        XCTAssertEqual(room.questions[0].delivery, .receivedByPeer)
        XCTAssertEqual(rep.questions.count, 1)
        XCTAssertEqual(rep.questions[0].id, question.id)
        XCTAssertEqual(AppModel(store: store).questions[0].id, question.id)
    }

    func testAcknowledgmentContextAndInactiveCaseReplyKeepOriginalRecord() throws {
        let a = PairTransport(), b = PairTransport(); a.other = b; b.other = a
        let room = AppModel(sync: LocalSyncService(nearby: a))
        let rep = AppModel(sync: LocalSyncService(nearby: b), post: .rep)
        try room.loadSampleWorkspace(); try rep.loadSampleWorkspace()
        let first = try room.startOrResume(caseID: SampleData.Record.northShoreCase.rawValue)
        _ = try room.record(XCTUnwrap(first.makeCommand(.deferItem)))
        let question = try room.sendSupportQuestion(text: "Case A question", recipient: XCTUnwrap(room.reps.first))
        let pending = try XCTUnwrap(first.recordingState?.pendingAcknowledgment)
        _ = try room.record(XCTUnwrap(first.makeCommand(.acknowledgeWarning(acknowledgment: pending))))
        let live = try XCTUnwrap(rep.liveContext(for: question))
        XCTAssertEqual(SupportExchange.changedLineCount(snapshot: question.snapshot, live: live), 0)
        XCTAssertNotEqual(live.acknowledgmentIDs, question.snapshot.acknowledgmentIDs)
        let other = try XCTUnwrap(room.cases.first { $0.id != first.procedure.id && FictionalCoordinationTemplate.template.supports($0) })
        let second = try room.startOrResume(caseID: other.id)
        try rep.sendSupportReply(question.id, text: "Case A reply")
        XCTAssertEqual(room.latestQuestion(for: first.identity.sessionID)?.replyText, "Case A reply")
        XCTAssertNil(room.latestQuestion(for: second.identity.sessionID))
        XCTAssertTrue(room.activeSession === second)
        XCTAssertEqual(first.recordingState?.itemStatuses[pending.itemID], .deferred)
    }
}

@MainActor
private final class PairTransport: NearbyTransport {
    weak var other: PairTransport?
    var linkState: NearbyLinkState = .connected(peerName: "Fictional paired iPad")
    var onEnvelope: ((SupportEnvelope) -> Void)?
    var onLinkState: ((NearbyLinkState) -> Void)?
    func start() {}
    func stop() { linkState = .idle; onLinkState?(.idle) }
    func send(_ envelope: SupportEnvelope) throws {
        guard let other else { throw NearbyTransportError.notConnected }
        other.onEnvelope?(envelope)
    }
}
