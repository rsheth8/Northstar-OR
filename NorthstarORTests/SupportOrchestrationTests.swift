import XCTest
@testable import NorthstarOR

/// F06/F07 support: requests, acceptance, questions with immutable snapshots, acknowledgment
/// and messages, all persisted on this device. All data is fictional.
@MainActor
final class SupportOrchestrationTests: XCTestCase {
    private final class Clock { var now = Date(timeIntervalSince1970: 1_800_000_000) }
    /// XCTest makes a new instance per test, so each test starts at the same time.
    private let clock = Clock()

    private func model(_ store: InMemoryWorkspaceStore, sync: SyncService = LocalSyncService()) -> AppModel {
        let clock = self.clock
        return AppModel(sync: sync, store: store, clock: { clock.now }, draftSaveDelay: .seconds(600))
    }

    private func tick(_ seconds: TimeInterval = 60) { clock.now = clock.now.addingTimeInterval(seconds) }

    private func configuration(contacts: [DeviceRep]? = nil) -> WorkspaceConfiguration {
        let site = Hospital(id: "site-a", name: "Fictional facility", town: "Example town", workspaceID: "workspace-a",
                            timeZoneIdentifier: "America/Chicago")
        let remote = DeviceRep(id: "contact-a", name: "Fictional rep A", homeBase: "Example town", skills: ["pacemaker"],
                               driveMinutes: [:], isAvailable: true, canSupportRemotely: true, workspaceID: "workspace-a",
                               statedRole: .technicalRep)
        let local = DeviceRep(id: "contact-b", name: "Fictional rep B", homeBase: "Example town", skills: ["pacemaker"],
                              driveMinutes: [:], isAvailable: true, canSupportRemotely: false,
                              workspaceID: "workspace-a", statedRole: .technicalRep)
        return WorkspaceConfiguration(id: "workspace-a", name: "Fictional workspace", sites: [site],
            contacts: contacts ?? [remote, local],
            localParticipant: LocalParticipant(id: "participant-a", workspaceID: "workspace-a",
                                               displayName: "Fictional coordinator", statedRole: .coordinator))
    }

    private func caseInput(_ id: String, hoursFromNow: Double) -> CaseInput {
        CaseInput(id: id, workspaceID: "workspace-a", reference: "REF-\(id)", title: "Fictional case \(id)",
                  siteID: "site-a", scheduledAt: clock.now.addingTimeInterval(hoursFromNow * 3600), durationMinutes: 60,
                  deviceFamily: "pacemaker", templateReference: FictionalCoordinationTemplate.reference)
    }

    private func configured(_ store: InMemoryWorkspaceStore, sync: SyncService = LocalSyncService()) throws -> AppModel {
        let model = model(store, sync: sync)
        try model.createWorkspace(configuration())
        try model.saveCase(caseInput("case-a", hoursFromNow: 1))
        try model.saveCase(caseInput("case-b", hoursFromNow: 2))
        return model
    }

    @discardableResult
    private func record(_ model: AppModel, _ action: SessionCommandAction, target: String? = nil) throws -> SessionEvent {
        let session = try XCTUnwrap(model.activeSession)
        let command = try XCTUnwrap(session.makeCommand(action, targetItemID: target, actor: model.workspace?.localParticipant,
                                                        at: clock.now))
        return try model.record(command)
    }

    /// Accepted remote request on case-a, recording started, item 1 confirmed, item 2 deferred.
    private func demoState(_ store: InMemoryWorkspaceStore, sync: SyncService = LocalSyncService()) throws
        -> (AppModel, SupportRequest) {
        let model = try configured(store, sync: sync)
        let request = try model.requestSupport(caseID: "case-a", contactID: "contact-a", arrangement: .remote,
                                               reason: "Fictional road closure keeps the rep off site.")
        tick()
        try model.respond(toRequest: request.id, accept: true)
        tick()
        try model.startOrResume(caseID: "case-a")
        tick()
        try record(model, .recordConfirmation)
        tick()
        try record(model, .deferItem)
        tick()
        return (model, try XCTUnwrap(model.supportRequest(request.id)))
    }

    // MARK: - Demo path

    func testDemoPathRequestAcceptAskAcknowledgeReplyAndRelaunch() throws {
        let store = InMemoryWorkspaceStore()
        let (model, request) = try demoState(store)
        XCTAssertEqual(request.status, .accepted)
        XCTAssertNotNil(model.activeSession?.pendingAlert, "deferral warning is pending")
        let versionBefore = model.activeSession?.events.count

        let question = try model.askQuestion(requestID: request.id, text: "  Which fictional settings sheet applies?  ")
        XCTAssertEqual(question.text, "Which fictional settings sheet applies?")
        XCTAssertEqual(question.askedByName, "Fictional coordinator")
        XCTAssertEqual(model.activeSession?.events.count, versionBefore, "asking does not change recording")
        XCTAssertNotNil(model.activeSession?.pendingAlert, "asking does not acknowledge the warning")

        let snapshot = question.snapshot
        XCTAssertEqual(snapshot.caseReference, "REF-case-a")
        XCTAssertEqual(snapshot.siteName, "Fictional facility")
        XCTAssertEqual(snapshot.templateLabel, "Fictional pacemaker coordination, version 1")
        XCTAssertEqual(snapshot.confirmed.map(\.id), ["timeout"])
        XCTAssertEqual(snapshot.mostRecentConfirmationTitle, "Team brief confirmation")
        XCTAssertEqual(snapshot.deferred.map(\.id), ["device-check"])
        XCTAssertEqual(snapshot.unresolved.count, FictionalCoordinationTemplate.steps.count - 1)
        XCTAssertEqual(snapshot.pendingAcknowledgmentItemTitle, "Fictional device details confirmation")
        XCTAssertEqual(snapshot.currentItemID, "device-check")
        XCTAssertEqual(snapshot.arrangement, .remote)
        XCTAssertEqual(snapshot.logisticalReason, "Fictional road closure keeps the rep off site.")
        XCTAssertEqual(snapshot.recordingVersion, versionBefore)
        XCTAssertEqual(snapshot.capturedAt, question.askedAt)

        tick()
        try model.acknowledgeQuestion(requestID: request.id, questionID: question.id)
        let acknowledgedAt = model.supportRequest(request.id)?.questions.first?.acknowledgedAt
        XCTAssertNotNil(acknowledgedAt)
        let writes = store.writeCount
        tick()
        try model.acknowledgeQuestion(requestID: request.id, questionID: question.id)
        XCTAssertEqual(model.supportRequest(request.id)?.questions.first?.acknowledgedAt, acknowledgedAt, "idempotent")
        XCTAssertEqual(store.writeCount, writes, "a repeated acknowledgment saves nothing")
        XCTAssertNotNil(model.activeSession?.pendingAlert, "question acknowledgment is not the warning acknowledgment")

        tick()
        let reply = try model.sendMessage(requestID: request.id, text: "Fictional sheet B covers this.", fromRep: true)
        XCTAssertEqual(reply.senderName, "Fictional rep A")
        XCTAssertEqual(reply.senderRole, .technicalRep)
        tick()
        let teamMessage = try model.sendMessage(requestID: request.id, text: "Thanks.", fromRep: false)
        XCTAssertEqual(teamMessage.senderName, "Fictional coordinator")
        XCTAssertFalse(teamMessage.isFromRep)

        let log = try XCTUnwrap(model.activeSession?.log.map(\.message))
        XCTAssertTrue(log.contains("Fictional rep A accepted the support request."))
        XCTAssertTrue(log.contains("Fictional rep A acknowledged the question."))
        XCTAssertEqual(model.activeSession?.log.last(where: { $0.kind == .remoteMessage })?.message,
                       "Fictional rep A: Fictional sheet B covers this.")

        let relaunched = self.model(store)
        XCTAssertEqual(relaunched.supportRequests, model.supportRequests)
        XCTAssertEqual(relaunched.currentRequest(for: "case-a")?.questions.first?.snapshot, snapshot)
        let restoredLog = try XCTUnwrap(relaunched.activeSession?.log)
        XCTAssertTrue(restoredLog.map(\.message).contains("Fictional rep A acknowledged the question."))
        XCTAssertEqual(restoredLog.last(where: { $0.kind == .remoteMessage })?.message,
                       "Fictional rep A: Fictional sheet B covers this.")
        XCTAssertEqual(restoredLog.map(\.timestamp), restoredLog.map(\.timestamp).sorted(), "log stays in time order")
        XCTAssertEqual(relaunched.supportActivity(for: "case-a").count, model.supportActivity(for: "case-a").count)
    }

    func testSnapshotNeverChangesAndChangesSinceQuestionAreListed() throws {
        let store = InMemoryWorkspaceStore()
        let (model, request) = try demoState(store)
        let question = try model.askQuestion(requestID: request.id, text: "Fictional question?")
        let session = try XCTUnwrap(model.activeSession)
        let warning = try XCTUnwrap(session.recordingState?.pendingAcknowledgment)
        tick()
        try record(model, .acknowledgeWarning(acknowledgment: warning), target: warning.itemID)
        XCTAssertEqual(model.supportRequest(request.id)?.questions.first?.snapshot, question.snapshot)
        XCTAssertEqual(model.changes(since: question).count, 1)
        XCTAssertEqual(self.model(store).changes(since: question).count, 1)
    }

    // MARK: - Validation

    func testRequestValidation() throws {
        let model = try configured(InMemoryWorkspaceStore())
        XCTAssertThrowsError(try model.requestSupport(caseID: "nope", contactID: "contact-a", arrangement: .remote, reason: "R")) {
            XCTAssertEqual($0 as? AppModelError, .unknownCase("nope"))
        }
        XCTAssertThrowsError(try model.requestSupport(caseID: "case-a", contactID: "nope", arrangement: .remote, reason: "R")) {
            XCTAssertEqual($0 as? SupportError, .unknownContact("nope"))
        }
        XCTAssertThrowsError(try model.requestSupport(caseID: "case-a", contactID: "contact-b", arrangement: .remote, reason: "R")) {
            XCTAssertEqual($0 as? SupportError, .contactNotRemoteCapable)
        }
        XCTAssertThrowsError(try model.requestSupport(caseID: "case-a", contactID: "contact-a", arrangement: .remote, reason: "  ")) {
            XCTAssertEqual($0 as? SupportError, .reasonRequired)
        }
        XCTAssertThrowsError(try model.respond(toRequest: "nope", accept: true)) {
            XCTAssertEqual($0 as? SupportError, .unknownRequest("nope"))
        }
        XCTAssertThrowsError(try model.askQuestion(requestID: "nope", text: "Q")) {
            XCTAssertEqual($0 as? SupportError, .unknownRequest("nope"))
        }
        XCTAssertNoThrow(try model.requestSupport(caseID: "case-a", contactID: "contact-b", arrangement: .inPerson, reason: "R"))
        XCTAssertEqual(model.supportRequests.count, 1)
    }

    func testAskingRequiresAcceptedRequestAndTheActiveSessionOfThatCase() throws {
        let model = try configured(InMemoryWorkspaceStore())
        let request = try model.requestSupport(caseID: "case-a", contactID: "contact-a", arrangement: .remote, reason: "R")
        XCTAssertThrowsError(try model.askQuestion(requestID: request.id, text: "Q")) {
            XCTAssertEqual($0 as? SupportError, .requestNotAccepted)
        }
        XCTAssertThrowsError(try model.sendMessage(requestID: request.id, text: "M", fromRep: false)) {
            XCTAssertEqual($0 as? SupportError, .requestNotAccepted)
        }
        try model.respond(toRequest: request.id, accept: true)
        XCTAssertThrowsError(try model.askQuestion(requestID: request.id, text: "Q")) {
            XCTAssertEqual($0 as? AppModelError, .noActiveSession)
        }
        try model.startOrResume(caseID: "case-b")
        XCTAssertThrowsError(try model.askQuestion(requestID: request.id, text: "Q")) {
            XCTAssertEqual($0 as? SupportError, .notActiveCase)
        }
        try model.startOrResume(caseID: "case-a")
        XCTAssertThrowsError(try model.askQuestion(requestID: request.id, text: " \n ")) {
            XCTAssertEqual($0 as? SupportError, .textRequired)
        }
        XCTAssertNoThrow(try model.askQuestion(requestID: request.id, text: "Q"))
    }

    func testDeclinedAndWithdrawnRequestsRejectQuestionsAndMessages() throws {
        let model = try configured(InMemoryWorkspaceStore())
        try model.startOrResume(caseID: "case-a")
        let declined = try model.requestSupport(caseID: "case-a", contactID: "contact-a", arrangement: .remote, reason: "R")
        try model.respond(toRequest: declined.id, accept: false)
        XCTAssertNoThrow(try model.respond(toRequest: declined.id, accept: false), "same answer is idempotent")
        XCTAssertThrowsError(try model.respond(toRequest: declined.id, accept: true)) {
            XCTAssertEqual($0 as? SupportError, .requestNotPending)
        }
        XCTAssertThrowsError(try model.askQuestion(requestID: declined.id, text: "Q")) {
            XCTAssertEqual($0 as? SupportError, .requestClosed)
        }
        XCTAssertEqual(model.currentRequest(for: "case-a")?.status, .declined)

        let withdrawn = try model.requestSupport(caseID: "case-a", contactID: "contact-a", arrangement: .remote, reason: "R2")
        try model.respond(toRequest: withdrawn.id, accept: true)
        try model.withdrawRequest(withdrawn.id)
        XCTAssertNil(model.currentRequest(for: "case-a"))
        XCTAssertThrowsError(try model.askQuestion(requestID: withdrawn.id, text: "Q")) {
            XCTAssertEqual($0 as? SupportError, .requestClosed)
        }
        XCTAssertThrowsError(try model.sendMessage(requestID: withdrawn.id, text: "M", fromRep: true)) {
            XCTAssertEqual($0 as? SupportError, .requestClosed)
        }
        XCTAssertThrowsError(try model.respond(toRequest: withdrawn.id, accept: true)) {
            XCTAssertEqual($0 as? SupportError, .requestClosed)
        }
        XCTAssertEqual(model.supportRequests(for: "case-a").map(\.status), [.declined, .withdrawn])
    }

    func testNewRequestWithdrawsTheOpenOneAndKeepsOneCurrentPlan() throws {
        let store = InMemoryWorkspaceStore()
        let model = try configured(store)
        let first = try model.requestSupport(caseID: "case-a", contactID: "contact-a", arrangement: .remote, reason: "R1")
        let other = try model.requestSupport(caseID: "case-b", contactID: "contact-a", arrangement: .remote, reason: "R")
        tick()
        let second = try model.requestSupport(caseID: "case-a", contactID: "contact-b", arrangement: .inPerson, reason: "R2")
        XCTAssertEqual(model.supportRequest(first.id)?.status, .withdrawn)
        XCTAssertEqual(model.supportRequest(first.id)?.withdrawnAt, second.requestedAt)
        XCTAssertEqual(model.currentRequest(for: "case-a")?.id, second.id)
        XCTAssertEqual(model.currentRequest(for: "case-b")?.id, other.id, "other cases are unaffected")
        XCTAssertThrowsError(try model.respond(toRequest: first.id, accept: true)) {
            XCTAssertEqual($0 as? SupportError, .requestClosed)
        }
        XCTAssertEqual(self.model(store).currentRequest(for: "case-a")?.id, second.id)
    }

    func testAskingIsAllowedWhileAcknowledgmentIsPendingAndSwitchingStaysBlocked() throws {
        let (model, request) = try demoState(InMemoryWorkspaceStore())
        XCTAssertNoThrow(try model.askQuestion(requestID: request.id, text: "Q"))
        XCTAssertThrowsError(try model.startOrResume(caseID: "case-b")) {
            XCTAssertEqual($0 as? AppModelError, .acknowledgmentPending)
        }
    }

    // MARK: - Failure and retry

    func testFailedSaveChangesNothingAndRetryWithSameIDSendsOnce() throws {
        let store = InMemoryWorkspaceStore()
        let (model, request) = try demoState(store)
        store.failWrites = true
        XCTAssertThrowsError(try model.sendMessage(requestID: request.id, text: "Reply", fromRep: true, messageID: "m-1")) {
            guard case .saveFailed = $0 as? AppModelError else { return XCTFail("expected saveFailed, got \($0)") }
        }
        XCTAssertNotNil(model.saveError)
        XCTAssertEqual(model.supportRequest(request.id)?.messages, [])
        XCTAssertThrowsError(try model.askQuestion(requestID: request.id, text: "Q"))
        XCTAssertEqual(model.supportRequest(request.id)?.questions, [])
        XCTAssertFalse(model.activeSession?.log.contains { $0.kind == .remoteMessage } ?? true)

        store.failWrites = false
        try model.sendMessage(requestID: request.id, text: "Reply", fromRep: true, messageID: "m-1")
        try model.sendMessage(requestID: request.id, text: "Reply", fromRep: true, messageID: "m-1")
        XCTAssertNil(model.saveError)
        XCTAssertEqual(model.supportRequest(request.id)?.messages.map(\.id), ["m-1"])
        XCTAssertEqual(model.activeSession?.log.filter { $0.kind == .remoteMessage }.count, 1)
    }

    // MARK: - Workspace edits and persistence

    func testRemovingAContactWithAnOpenRequestIsRefused() throws {
        let store = InMemoryWorkspaceStore()
        let model = try configured(store)
        let request = try model.requestSupport(caseID: "case-a", contactID: "contact-a", arrangement: .remote, reason: "R")
        let withoutA = configuration(contacts: [configuration().contacts[1]])
        XCTAssertThrowsError(try model.updateWorkspace(withoutA)) {
            XCTAssertEqual($0 as? SupportError, .contactInUse("contact-a"))
            XCTAssertEqual(($0 as? LocalizedError)?.errorDescription,
                           "This contact has support requests on a saved case, so it can't be removed.")
        }
        try model.withdrawRequest(request.id)
        XCTAssertNoThrow(try model.updateWorkspace(withoutA), "a withdrawn request keeps the contact's name")
        let relaunched = self.model(store)
        XCTAssertEqual(relaunched.loadState, .ready)
        XCTAssertEqual(relaunched.supportRequest(request.id)?.contactName, "Fictional rep A")
    }

    func testReducedSupportContextSurvivesRelaunch() throws {
        let store = InMemoryWorkspaceStore()
        let model = try configured(store)
        let session = try model.startOrResume(caseID: "case-a")
        model.sync.send(.reducedSupportChanged(procedureID: "case-a", on: true))
        XCTAssertTrue(session.reducedSupport)
        let relaunched = self.model(store)
        XCTAssertEqual(relaunched.activeSession?.reducedSupport, true)
        relaunched.sync.send(.reducedSupportChanged(procedureID: "case-a", on: false))
        XCTAssertEqual(self.model(store).activeSession?.reducedSupport, false)
    }

    func testSnapshotWithoutSupportKeysStillDecodes() throws {
        let store = InMemoryWorkspaceStore()
        let model = try configured(store)
        try model.startOrResume(caseID: "case-a")
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(store.data)) as? [String: Any])
        XCTAssertNotNil(object["supportRequests"])
        object["supportRequests"] = nil
        object["reducedSupportSessionIDs"] = nil
        store.data = try JSONSerialization.data(withJSONObject: object)
        guard case .loaded(let restored) = WorkspaceRepository(store: store).load() else { return XCTFail("expected loaded") }
        XCTAssertEqual(restored.supportRequests, [])
        XCTAssertEqual(restored.reducedSupportSessionIDs, [])
        XCTAssertEqual(self.model(store).loadState, .ready)
    }

    func testSnapshotValidationRejectsInconsistentSupportRecords() throws {
        let store = InMemoryWorkspaceStore()
        let (model, request) = try demoState(store)
        _ = try model.askQuestion(requestID: request.id, text: "Q")
        guard case .loaded(let valid) = WorkspaceRepository(store: store).load() else { return XCTFail("expected loaded") }
        XCTAssertNoThrow(try valid.validate())

        func rejects(_ change: (inout WorkspaceSnapshot) -> Void, file: StaticString = #filePath, line: UInt = #line) {
            var snapshot = valid
            change(&snapshot)
            XCTAssertThrowsError(try snapshot.validate(), file: file, line: line)
        }
        let stored = valid.supportRequests[0]
        rejects { $0.supportRequests.append(stored) }
        rejects { snapshot in
            snapshot.supportRequests[0] = SupportRequest(id: stored.id, workspaceID: "other", caseID: stored.caseID,
                contactID: stored.contactID, contactName: stored.contactName, contactRole: stored.contactRole,
                arrangement: stored.arrangement, reason: stored.reason, requestedByName: stored.requestedByName,
                requestedAt: stored.requestedAt, status: stored.status, respondedAt: stored.respondedAt,
                withdrawnAt: nil, questions: stored.questions, messages: stored.messages)
        }
        rejects { snapshot in
            snapshot.supportRequests[0] = SupportRequest(id: stored.id, workspaceID: stored.workspaceID, caseID: "missing",
                contactID: stored.contactID, contactName: stored.contactName, contactRole: stored.contactRole,
                arrangement: stored.arrangement, reason: stored.reason, requestedByName: stored.requestedByName,
                requestedAt: stored.requestedAt, status: stored.status, respondedAt: stored.respondedAt,
                withdrawnAt: nil, questions: [], messages: [])
        }
        rejects { snapshot in
            snapshot.supportRequests[0] = SupportRequest(id: stored.id, workspaceID: stored.workspaceID, caseID: stored.caseID,
                contactID: "missing", contactName: stored.contactName, contactRole: stored.contactRole,
                arrangement: stored.arrangement, reason: stored.reason, requestedByName: stored.requestedByName,
                requestedAt: stored.requestedAt, status: stored.status, respondedAt: stored.respondedAt,
                withdrawnAt: nil, questions: stored.questions, messages: stored.messages)
        }
        let question = stored.questions[0]
        rejects { $0.supportRequests[0].questions.append(question) }
        rejects { $0.reducedSupportSessionIDs = ["unknown-session"] }
    }

    // MARK: - Sync routing

    func testActionsAreBroadcastAndRemoteChangesAreAppliedOnce() throws {
        let sync = LocalSyncService()
        var received: [SyncEvent] = []
        let token = sync.subscribe { received.append($0) }
        let store = InMemoryWorkspaceStore()
        let (model, request) = try demoState(store, sync: sync)
        withExtendedLifetime(token) {}
        XCTAssertEqual(received.count, 2, "request and response were broadcast")
        guard case .support("workspace-a", .responded(request.id, true, _)) = received.last else {
            return XCTFail("expected a response event, got \(String(describing: received.last))")
        }

        // A change from another participant arrives through the same boundary.
        let remote = SupportMessage(id: "remote-1", requestID: request.id, senderName: "Fictional rep A",
                                    senderRole: .technicalRep, isFromRep: true, text: "Joining shortly.", sentAt: clock.now)
        sync.send(.support(workspaceID: "workspace-a", change: .messageSent(remote)))
        sync.send(.support(workspaceID: "workspace-a", change: .messageSent(remote)))
        sync.send(.support(workspaceID: "other-workspace", change: .messageSent(remote)))
        XCTAssertEqual(model.supportRequest(request.id)?.messages, [remote])
        XCTAssertEqual(self.model(store).supportRequest(request.id)?.messages, [remote], "remote change was saved")
        XCTAssertEqual(model.activeSession?.log.filter { $0.kind == .remoteMessage }.count, 1)
    }

    func testEventsDeliveredOffTheMainThreadAreHandledOnTheMainActor() async throws {
        let sync = LocalSyncService()
        let store = InMemoryWorkspaceStore()
        let model = try configured(store, sync: sync)
        try model.startOrResume(caseID: "case-a")
        let delivered = expectation(description: "delivered")
        DispatchQueue.global().async {
            sync.send(.reducedSupportChanged(procedureID: "case-a", on: true))
            DispatchQueue.main.async { delivered.fulfill() }
        }
        await fulfillment(of: [delivered], timeout: 5)
        XCTAssertEqual(model.activeSession?.reducedSupport, true)
    }

    func testReducerIsIdempotentAndRejectsConflictingIDs() throws {
        let request = SupportRequest(id: "r", workspaceID: "w", caseID: "c", contactID: "k", contactName: "Fictional rep",
            contactRole: .technicalRep, arrangement: .remote, reason: "R", requestedByName: "Fictional coordinator",
            requestedAt: clock.now, status: .requested, respondedAt: nil, withdrawnAt: nil, questions: [], messages: [])
        let once = try SupportChange.requested(request).applying(to: [])
        XCTAssertEqual(try SupportChange.requested(request).applying(to: once), once)
        let accepted = try SupportChange.responded(requestID: "r", accepted: true, at: clock.now).applying(to: once)
        XCTAssertEqual(try SupportChange.requested(request).applying(to: accepted), accepted)
        let message = SupportMessage(id: "m", requestID: "r", senderName: "A", senderRole: .technicalRep, isFromRep: true,
                                     text: "One", sentAt: clock.now)
        let withMessage = try SupportChange.messageSent(message).applying(to: accepted)
        let conflicting = SupportMessage(id: "m", requestID: "r", senderName: "A", senderRole: .technicalRep, isFromRep: true,
                                         text: "Two", sentAt: clock.now)
        XCTAssertThrowsError(try SupportChange.messageSent(conflicting).applying(to: withMessage)) {
            XCTAssertEqual($0 as? SupportError, .duplicateID("m"))
        }
    }
}
