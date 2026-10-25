import XCTest
@testable import NorthstarOR

/// F07 core hub: persisted workspace, cases and sessions. All data is fictional.
@MainActor
final class AppModelTests: XCTestCase {
    private let time = Date(timeIntervalSince1970: 1_800_000_000)

    private func model(_ store: InMemoryWorkspaceStore) -> AppModel {
        AppModel(store: store, clock: { self.time }, draftSaveDelay: .seconds(600))
    }

    private func configuration(name: String = "Fictional workspace") -> WorkspaceConfiguration {
        let site = Hospital(id: "site-a", name: "Fictional facility", town: "Example town", workspaceID: "workspace-a",
                            timeZoneIdentifier: "America/Chicago")
        let contact = DeviceRep(id: "contact-a", name: "Fictional contact", homeBase: "Example town", skills: ["pacemaker"],
                                driveMinutes: [:], isAvailable: true, canSupportRemotely: true, workspaceID: "workspace-a",
                                statedRole: .technicalRep)
        return WorkspaceConfiguration(id: "workspace-a", name: name, sites: [site], contacts: [contact],
            localParticipant: LocalParticipant(id: "participant-a", workspaceID: "workspace-a",
                                               displayName: "Fictional coordinator", statedRole: .coordinator))
    }

    private func caseInput(_ id: String, title: String? = nil, hoursFromNow: Double = 1) -> CaseInput {
        CaseInput(id: id, workspaceID: "workspace-a", reference: "REF-\(id)", title: title ?? "Fictional case \(id)",
                  siteID: "site-a", scheduledAt: time.addingTimeInterval(hoursFromNow * 3600), durationMinutes: 60,
                  deviceFamily: "pacemaker", templateReference: FictionalCoordinationTemplate.reference)
    }

    private func configured(_ store: InMemoryWorkspaceStore, cases ids: [String] = ["case-a", "case-b"]) throws -> AppModel {
        let model = model(store)
        try model.createWorkspace(configuration())
        for (index, id) in ids.enumerated() { try model.saveCase(caseInput(id, hoursFromNow: Double(index + 1))) }
        return model
    }

    @discardableResult
    private func record(_ model: AppModel, _ action: SessionCommandAction, target: String? = nil,
                        intent: String = UUID().uuidString) throws -> SessionEvent {
        let session = try XCTUnwrap(model.activeSession)
        let command = try XCTUnwrap(session.makeCommand(action, targetItemID: target, actor: model.workspace?.localParticipant,
                                                        at: time, intentID: intent))
        return try model.record(command)
    }

    // MARK: - Load states

    func testFreshInstallNeedsSetupWithNoSampleContent() {
        let model = model(InMemoryWorkspaceStore())
        XCTAssertEqual(model.loadState, .needsSetup)
        XCTAssertNil(model.workspace)
        XCTAssertEqual(model.cases, [])
        XCTAssertNil(model.activeSession)
        XCTAssertEqual(model.reps, [])
    }

    func testUnreadableDataBlocksAndCanBeSetAside() throws {
        let store = InMemoryWorkspaceStore(data: Data("{ not json".utf8))
        let model = model(store)
        guard case .blocked = model.loadState else { return XCTFail("expected blocked, got \(model.loadState)") }
        XCTAssertTrue(model.canSetAsideStoredData)
        XCTAssertThrowsError(try model.createWorkspace(configuration()))
        try model.setAsideUnreadableData()
        XCTAssertEqual(model.loadState, .needsSetup)
        XCTAssertEqual(store.setAside.count, 1)
        XCTAssertNoThrow(try model.createWorkspace(configuration()))
    }

    func testTransientReadFailureBlocksWithoutOfferingSetAside() throws {
        let store = InMemoryWorkspaceStore()
        _ = try configured(store)
        store.failReads = true
        let relaunched = model(store)
        guard case .blocked = relaunched.loadState else { return XCTFail("expected blocked") }
        XCTAssertFalse(relaunched.canSetAsideStoredData)
        store.failReads = false
        relaunched.load()
        XCTAssertEqual(relaunched.loadState, .ready)
        XCTAssertEqual(relaunched.cases.count, 2)
    }

    // MARK: - Workspace and cases

    func testWorkspaceAndCasesPersistAcrossRelaunch() throws {
        let store = InMemoryWorkspaceStore()
        let model = try configured(store)
        XCTAssertEqual(model.loadState, .ready)
        XCTAssertEqual(model.lastSavedAt, time)
        var renamed = configuration(name: "Renamed fictional workspace")
        renamed.contacts[0].name = "Edited fictional contact"
        try model.updateWorkspace(renamed)

        let relaunched = self.model(store)
        XCTAssertEqual(relaunched.loadState, .ready)
        XCTAssertEqual(relaunched.workspace?.name, "Renamed fictional workspace")
        XCTAssertEqual(relaunched.reps.map(\.name), ["Edited fictional contact"])
        XCTAssertEqual(relaunched.cases.map(\.id), ["case-a", "case-b"])
        XCTAssertNil(relaunched.activeSession)
        XCTAssertEqual(relaunched.selectedDestination, .planner)
    }

    func testCasesAreSortedAndEditKeepsIdentity() throws {
        let store = InMemoryWorkspaceStore()
        let model = model(store)
        try model.createWorkspace(configuration())
        try model.saveCase(caseInput("late", hoursFromNow: 5))
        try model.saveCase(caseInput("early", hoursFromNow: 1))
        XCTAssertEqual(model.cases.map(\.id), ["early", "late"])
        var edit = caseInput("late", title: "Renamed fictional case", hoursFromNow: 0.5)
        edit.reference = "REF-late"
        let edited = try model.saveCase(edit)
        XCTAssertEqual(edited.name, "Renamed fictional case")
        XCTAssertEqual(model.cases.map(\.id), ["late", "early"])
        XCTAssertThrowsError(try model.saveCase(caseInput("dupe", title: "Fictional case early"))) {
            XCTAssertEqual($0 as? WorkspaceContractError, .duplicateCaseTitle)
        }
        XCTAssertEqual(self.model(store).cases.map(\.name), ["Renamed fictional case", "Fictional case early"])
    }

    func testCreateAndSampleRequireNoExistingWorkspace() throws {
        let model = model(InMemoryWorkspaceStore())
        try model.createWorkspace(configuration())
        XCTAssertThrowsError(try model.loadSampleWorkspace()) { XCTAssertEqual($0 as? AppModelError, .workspaceAlreadyConfigured) }
        XCTAssertThrowsError(try model.createWorkspace(configuration())) { XCTAssertEqual($0 as? AppModelError, .workspaceAlreadyConfigured) }
    }

    func testSampleWorkspaceIsExplicitAndStartsNothing() throws {
        let store = InMemoryWorkspaceStore()
        let model = model(store)
        try model.loadSampleWorkspace()
        XCTAssertEqual(model.loadState, .ready)
        XCTAssertEqual(model.cases.map(\.id), ["proc-1", "proc-2", "proc-3"])
        XCTAssertEqual(model.reps.count, 3)
        XCTAssertNil(model.activeSession)
        XCTAssertEqual(model.forecasts.count, 3)
        XCTAssertEqual(self.model(store).cases.count, 3)
        XCTAssertThrowsError(try model.startOrResume(caseID: "proc-2")) { XCTAssertEqual($0 as? AppModelError, .recordingUnavailable) }
        XCTAssertNil(model.activeSession)
    }

    func testLaunchArgumentsSelectSampleOrEmptyInMemoryStore() {
        let sample = AppModel.launching(arguments: ["-NorthstarSampleWorkspace"])
        XCTAssertEqual(sample.activeCaseID, "proc-1")
        XCTAssertEqual(sample.activeSession?.procedure.id, "proc-1")
        XCTAssertEqual(sample.selectedDestination, .coPilot)
        let reset = AppModel.launching(arguments: ["-NorthstarResetStore"])
        XCTAssertEqual(reset.loadState, .needsSetup)
    }

    // MARK: - Sessions

    func testRecordingPersistsAndRestoresIdenticallyAfterRelaunch() throws {
        let store = InMemoryWorkspaceStore()
        let model = try configured(store)
        XCTAssertThrowsError(try record(model, .recordConfirmation)) // no active session
        let session = try model.startOrResume(caseID: "case-a")
        XCTAssertTrue(model.session(for: "case-a") === session)
        try record(model, .recordConfirmation)
        let deferral = try record(model, .deferItem)
        let ack = try XCTUnwrap(session.recordingState?.pendingAcknowledgment)
        try record(model, .acknowledgeWarning(acknowledgment: ack))
        try record(model, .correctRecord(originalEventID: deferral.id, newStatus: .teamConfirmed, reason: "Team clarified"),
                   target: deferral.targetItemID)

        let relaunched = self.model(store)
        let restored = try XCTUnwrap(relaunched.activeSession)
        XCTAssertEqual(relaunched.activeCaseID, "case-a")
        XCTAssertEqual(relaunched.selectedDestination, .coPilot)
        XCTAssertEqual(restored.identity, session.identity)
        XCTAssertEqual(restored.recordingState, session.recordingState)
        XCTAssertEqual(restored.events, session.events)
        XCTAssertEqual(restored.log.map(\.message), session.log.map(\.message))
        XCTAssertEqual(restored.log.map(\.timestamp), session.log.map(\.timestamp))
        XCTAssertNil(relaunched.session(for: "case-b"))
    }

    func testRestoredSessionKeepsDuplicateIntentGuards() throws {
        let store = InMemoryWorkspaceStore()
        let model = try configured(store)
        try model.startOrResume(caseID: "case-a")
        let session = try XCTUnwrap(model.activeSession)
        let command = try XCTUnwrap(session.makeCommand(.recordConfirmation, actor: model.workspace?.localParticipant,
                                                        at: time, intentID: "intent-1"))
        // Captured against version 0, before anything was recorded.
        let stale = try XCTUnwrap(session.makeCommand(.deferItem, actor: model.workspace?.localParticipant,
                                                      at: time, intentID: "intent-2"))
        let original = try model.record(command)

        let relaunched = self.model(store)
        // An identical retry after relaunch returns the original event without a new record.
        XCTAssertEqual(try relaunched.record(command), original)
        XCTAssertEqual(relaunched.activeSession?.events.count, 1)
        // Reusing the intent for a different action is rejected.
        let restored = try XCTUnwrap(relaunched.activeSession)
        let conflicting = try XCTUnwrap(restored.makeCommand(.deferItem, actor: relaunched.workspace?.localParticipant,
                                                             at: time, intentID: "intent-1"))
        XCTAssertThrowsError(try relaunched.record(conflicting)) { XCTAssertEqual($0 as? RecordingCommandError, .intentConflict) }
        // A stale command from before relaunch cannot retarget the next item.
        XCTAssertThrowsError(try relaunched.record(stale)) { XCTAssertEqual($0 as? RecordingCommandError, .staleVersion) }
    }

    func testSwitchingIsBlockedWhileAcknowledgmentIsPending() throws {
        let model = try configured(InMemoryWorkspaceStore())
        let first = try model.startOrResume(caseID: "case-a")
        try record(model, .deferItem)
        XCTAssertThrowsError(try model.startOrResume(caseID: "case-b")) { XCTAssertEqual($0 as? AppModelError, .acknowledgmentPending) }
        XCTAssertEqual(model.activeCaseID, "case-a")
        XCTAssertTrue(try model.startOrResume(caseID: "case-a") === first)
        try record(model, .acknowledgeWarning(acknowledgment: XCTUnwrap(first.recordingState?.pendingAcknowledgment)))
        let second = try model.startOrResume(caseID: "case-b")
        XCTAssertEqual(model.activeCaseID, "case-b")
        // Explicit resume returns the same saved run, not a new one.
        XCTAssertTrue(try model.startOrResume(caseID: "case-a") === first)
        XCTAssertTrue(model.session(for: "case-b") === second)
    }

    func testUnknownCaseCannotStart() throws {
        let model = try configured(InMemoryWorkspaceStore())
        XCTAssertThrowsError(try model.startOrResume(caseID: "missing")) { XCTAssertEqual($0 as? AppModelError, .unknownCase("missing")) }
    }

    // MARK: - Save failures

    func testFailedSaveKeepsPreviousStateAndShowsPersistentError() throws {
        let store = InMemoryWorkspaceStore()
        let model = try configured(store)
        try model.startOrResume(caseID: "case-a")
        store.failWrites = true
        XCTAssertThrowsError(try model.saveCase(caseInput("case-c"))) {
            guard case AppModelError.saveFailed = $0 else { return XCTFail("expected saveFailed, got \($0)") }
        }
        XCTAssertEqual(model.cases.map(\.id), ["case-a", "case-b"])
        XCTAssertNotNil(model.saveError)
        XCTAssertThrowsError(try model.updateWorkspace(configuration(name: "Unsaved name")))
        XCTAssertEqual(model.workspace?.name, "Fictional workspace")

        // A recorded event stands on screen; the error explains it is not saved yet.
        let event = try record(model, .recordConfirmation)
        XCTAssertEqual(model.activeSession?.events.last, event)
        XCTAssertNotNil(model.saveError)
        XCTAssertEqual(self.model(store).activeSession?.events.count, 0)

        store.failWrites = false
        try model.retrySave()
        XCTAssertNil(model.saveError)
        XCTAssertEqual(self.model(store).activeSession?.events, [event])
    }

    // MARK: - Unrestorable sessions

    func testStoredSessionWithMismatchedItemsIsKeptButNotRestored() throws {
        let store = InMemoryWorkspaceStore()
        let model = try configured(store)
        let caseA = try XCTUnwrap(model.cases.first)
        let identity = SessionIdentity(workspaceID: "workspace-a", caseID: caseA.id, sessionID: "foreign-run")
        let state = SessionRecordingState(identity: identity, templateReference: FictionalCoordinationTemplate.reference,
                                          startedAt: time, version: 0, itemStatuses: ["not-a-step": .unrecorded],
                                          selectedItemID: "not-a-step", pendingAcknowledgment: nil)
        let snapshot = WorkspaceSnapshot(workspace: configuration(), cases: model.cases,
                                         sessions: [StoredSession(state: state, events: [])], activeCaseID: caseA.id)
        try WorkspaceRepository(store: store).save(snapshot)

        let relaunched = self.model(store)
        XCTAssertEqual(relaunched.loadState, .ready)
        XCTAssertNil(relaunched.activeSession)
        XCTAssertEqual(relaunched.unreadableSessionCaseIDs, [caseA.id])
        XCTAssertThrowsError(try relaunched.startOrResume(caseID: caseA.id)) {
            XCTAssertEqual($0 as? AppModelError, .sessionUnreadable(caseA.id))
        }
        // Other saves keep the unreadable session unchanged.
        try relaunched.startOrResume(caseID: "case-b")
        guard case .loaded(let stored) = WorkspaceRepository(store: store).load() else { return XCTFail("expected loaded") }
        XCTAssertTrue(stored.sessions.contains(StoredSession(state: state, events: [])))
        XCTAssertEqual(stored.sessions.count, 2)
    }

    func testRestoreRejectsTamperedHistory() throws {
        let model = try configured(InMemoryWorkspaceStore())
        let session = try model.startOrResume(caseID: "case-a")
        try record(model, .recordConfirmation)
        let procedure = try XCTUnwrap(model.cases.first)
        let stored = try XCTUnwrap(session.storedSession)
        XCTAssertEqual(try CoPilotSession.restore(procedure: procedure, from: stored).recordingState, session.recordingState)

        // State that does not follow from the events.
        let other = SessionRecordingState(identity: stored.state.identity, templateReference: stored.state.templateReference,
            startedAt: stored.state.startedAt, version: 1,
            itemStatuses: stored.state.itemStatuses.mapValues { _ in .unrecorded },
            selectedItemID: stored.state.selectedItemID, pendingAcknowledgment: nil)
        XCTAssertThrowsError(try CoPilotSession.restore(procedure: procedure, from: StoredSession(state: other, events: stored.events)))
        // Events for a different case.
        XCTAssertThrowsError(try CoPilotSession.restore(procedure: model.cases[1], from: stored)) {
            XCTAssertEqual($0 as? SessionRestoreError, .caseMismatch)
        }
    }

    // MARK: - Drafts

    func testDraftSavesAreCoalescedAndRestored() throws {
        let store = InMemoryWorkspaceStore()
        let model = try configured(store)
        let key = DraftKey(workspaceID: "workspace-a", caseID: "case-a", sessionID: nil, kind: "caseNote")
        let writes = store.writeCount
        for text in ["F", "Fi", "Fictional note"] { try model.setDraft(text, for: key) }
        XCTAssertEqual(model.draft(for: key), "Fictional note")
        XCTAssertEqual(store.writeCount, writes)
        model.flushPendingSave()
        XCTAssertEqual(store.writeCount, writes + 1)
        XCTAssertEqual(self.model(store).draft(for: key), "Fictional note")
        XCTAssertThrowsError(try model.setDraft("x", for: DraftKey(workspaceID: "workspace-a", caseID: "missing", sessionID: nil, kind: "caseNote")))
    }

    func testSelectedDestinationIsSettable() throws {
        let model = try configured(InMemoryWorkspaceStore())
        model.selectedDestination = .remoteSupport
        XCTAssertEqual(model.selectedDestination, .remoteSupport)
    }
}
