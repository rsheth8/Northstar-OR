import XCTest
@testable import NorthstarOR

@MainActor
final class CoveragePlanTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private func pair() throws -> (AppModel, AppModel, PlanLink, PlanLink, InMemoryWorkspaceStore) {
        let a = PlanLink(), b = PlanLink(); a.peer = b; b.peer = a
        let store = InMemoryWorkspaceStore()
        let room = AppModel(sync: LocalSyncService(nearby: a), store: store, clock: { self.now })
        let rep = AppModel(sync: LocalSyncService(nearby: b), clock: { self.now }, post: .rep)
        try room.loadSampleWorkspace(); try rep.loadSampleWorkspace()
        a.connect(); b.connect()
        return (room, rep, a, b, store)
    }
    private func remote(_ model: AppModel) throws -> (Procedure, DeviceRep) {
        for item in model.cases {
            for option in model.recommendation(for: item).options {
                if case .remoteRep(let rep) = option { return (item, rep) }
            }
        }
        throw CoveragePlanError.ineligible
    }
    func testExactRevisionResponseAndRescheduleSupersession() throws {
        let (room, rep, link, _, store) = try pair()
        let (item, contact) = try remote(room)
        let first = try room.requestCoverage(caseID: item.id, mode: .remote, recipientID: contact.id, expectedRevision: nil)
        XCTAssertEqual(first.delivery, .receivedByPeer)
        XCTAssertEqual(rep.incomingCoveragePlans.first?.recordID, first.recordID)
        try rep.respondToCoverage(planID: first.id, revision: first.revision, accepted: true)
        XCTAssertEqual(room.coveragePlan(for: item.id)?.response?.accepted, true)
        let accepted = try XCTUnwrap(room.coveragePlan(for: item.id)?.response)
        link.onEnvelope?(first.responseEnvelope(accepted))
        XCTAssertEqual(room.coveragePlans.count, 1)
        let next = try room.requestCoverage(caseID: item.id, mode: .reschedule, recipientID: nil, expectedRevision: first.revision)
        XCTAssertEqual(next.revision, 2)
        XCTAssertEqual(next.id, first.id)
        XCTAssertEqual(rep.incomingCoveragePlans.first?.mode, .reschedule)
        link.onEnvelope?(first.responseEnvelope(accepted))
        XCTAssertNil(room.coveragePlan(for: item.id)?.response)
        XCTAssertThrowsError(try rep.respondToCoverage(planID: first.id, revision: first.revision, accepted: true))
        XCTAssertThrowsError(try room.requestCoverage(caseID: item.id, mode: .remote, recipientID: contact.id, expectedRevision: first.revision))
        XCTAssertEqual(AppModel(store: store).coveragePlan(for: item.id)?.revision, 2)
    }
    func testWrongModeAndFailedSaveDoNotChangePlan() throws {
        let (room, _, link, _, store) = try pair()
        let (item, contact) = try remote(room)
        let plan = try room.requestCoverage(caseID: item.id, mode: .remote, recipientID: contact.id, expectedRevision: nil)
        let wrong = CoveragePlan.Response(planID: plan.id, revision: plan.revision, mode: .inPerson,
            actor: .init(id: "peer", workspaceID: "peer-workspace", displayName: "Fictional peer", statedRole: .technicalRep), accepted: true, at: now)
        link.onEnvelope?(plan.responseEnvelope(wrong))
        XCTAssertNil(room.coveragePlan(for: item.id)?.response)
        var malformed = wrong
        malformed.mode = .remote
        malformed.actor = .init(id: " ", workspaceID: "", displayName: " ", statedRole: .technicalRep)
        link.onEnvelope?(plan.responseEnvelope(malformed))
        XCTAssertNil(room.coveragePlan(for: item.id)?.response)
        store.failWrites = true
        XCTAssertThrowsError(try room.requestCoverage(caseID: item.id, mode: .reschedule, recipientID: nil, expectedRevision: plan.revision))
        XCTAssertEqual(room.coveragePlan(for: item.id)?.recordID, plan.recordID)
        XCTAssertEqual(AppModel(store: store).coveragePlans.count, 1)
    }
    func testTransportFailureRetainsRequestAndRetryIdentity() throws {
        let (room, rep, link, _, _) = try pair()
        let (item, contact) = try remote(room)
        link.fail = true
        XCTAssertThrowsError(try room.requestCoverage(caseID: item.id, mode: .remote, recipientID: contact.id, expectedRevision: nil))
        let retained = try XCTUnwrap(room.coveragePlan(for: item.id))
        XCTAssertEqual(retained.delivery, .failed)
        link.fail = false
        try room.retryCoverage(planID: retained.id, revision: retained.revision)
        XCTAssertEqual(room.coveragePlan(for: item.id)?.recordID, retained.recordID)
        XCTAssertEqual(rep.incomingCoveragePlans.count, 1)
        XCTAssertEqual(room.coveragePlan(for: item.id)?.delivery, .receivedByPeer)
    }
    func testUnavailableContactAndOldSnapshot() throws {
        let (room, _, _, _, _) = try pair()
        let (item, _) = try remote(room)
        XCTAssertThrowsError(try room.requestCoverage(caseID: item.id, mode: .remote, recipientID: "missing", expectedRevision: nil))
        XCTAssertTrue(room.coveragePlans.isEmpty)
        let old = try JSONDecoder().decode(WorkspaceSnapshot.self, from: Data(#"{"formatVersion":1}"#.utf8))
        XCTAssertTrue(old.coveragePlans.isEmpty)
    }
}

@MainActor
private final class PlanLink: NearbyTransport {
    weak var peer: PlanLink?
    var fail = false
    var supportsSession: Bool { true }
    var linkState: NearbyLinkState = .idle
    var onEnvelope: ((SupportEnvelope) -> Void)?
    var onLinkState: ((NearbyLinkState) -> Void)?
    var onDiscoveryChange: (() -> Void)?
    func connect() { linkState = .connected(peerName: "Fictional peer"); onLinkState?(linkState) }
    func start() { connect() }
    func stop() { linkState = .idle; onLinkState?(linkState) }
    func send(_ envelope: SupportEnvelope) throws {
        if fail { throw NearbyTransportError.notConnected }
        peer?.onEnvelope?(envelope)
    }
}
