import XCTest
@testable import NorthstarOR

@MainActor
final class WorkspaceRepositoryTests: XCTestCase {
    private let time = Date(timeIntervalSince1970: 1_800_000_000)
    private var catalog: [CoordinationTemplate] { [FictionalCoordinationTemplate.template] }

    // MARK: - Load outcomes

    func testFreshInstallLoadsEmptyWithoutSampleContent() {
        let repository = WorkspaceRepository(store: InMemoryWorkspaceStore(), clock: { self.time })
        XCTAssertEqual(repository.load(), .empty)
        XCTAssertFalse(repository.isSavingBlocked)
    }

    func testRoundTripKeepsIndependentCasesSessionsAndDrafts() throws {
        let store = InMemoryWorkspaceStore()
        let snapshot = try populatedSnapshot()
        let receipt = try WorkspaceRepository(store: store, clock: { self.time }).save(snapshot)
        XCTAssertEqual(receipt.savedAt, time)

        // A new repository over the same store models a relaunch.
        let relaunched = WorkspaceRepository(store: store, clock: { self.time })
        guard case .loaded(let restored) = relaunched.load() else { return XCTFail("expected loaded snapshot") }
        XCTAssertEqual(restored, snapshot)
        XCTAssertEqual(restored.cases.map(\.id), ["case-a", "case-b"])
        XCTAssertEqual(restored.sessions.map(\.state.identity.caseID), ["case-a"])
        XCTAssertEqual(restored.sessions.first?.events.count, 1)
    }

    func testDraftsStaySeparatePerCase() throws {
        let store = InMemoryWorkspaceStore()
        try WorkspaceRepository(store: store, clock: { self.time }).save(try populatedSnapshot())
        guard case .loaded(let restored) = WorkspaceRepository(store: store).load() else { return XCTFail("expected loaded") }
        let a = restored.drafts.first { $0.key.caseID == "case-a" }
        let b = restored.drafts.first { $0.key.caseID == "case-b" }
        XCTAssertEqual(a?.text, "Draft question for case A")
        XCTAssertEqual(b?.text, "Draft note for case B")
    }

    // MARK: - Failure and recovery

    func testFailedWriteThrowsAndKeepsPreviousData() throws {
        let store = InMemoryWorkspaceStore()
        let repository = WorkspaceRepository(store: store, clock: { self.time })
        let first = try populatedSnapshot()
        try repository.save(first)
        let previous = store.data

        var changed = first
        changed.workspace?.name = "Renamed fictional workspace"
        store.failWrites = true
        XCTAssertThrowsError(try repository.save(changed)) { error in
            guard case RepositoryError.writeFailed = error else { return XCTFail("expected writeFailed, got \(error)") }
        }
        XCTAssertEqual(store.data, previous)
        guard case .loaded(let restored) = WorkspaceRepository(store: store).load() else { return XCTFail("expected loaded") }
        XCTAssertEqual(restored.workspace?.name, "Fictional workspace")
    }

    func testUnreadableDataIsReportedAndNeverOverwritten() throws {
        let garbage = Data("{ not json".utf8)
        let store = InMemoryWorkspaceStore(data: garbage)
        let repository = WorkspaceRepository(store: store, clock: { self.time })
        guard case .unreadable = repository.load() else { return XCTFail("expected unreadable") }
        XCTAssertTrue(repository.isSavingBlocked)
        XCTAssertThrowsError(try repository.save(try populatedSnapshot())) { error in
            XCTAssertEqual(error as? RepositoryError, .blockedByUnreadableData)
        }
        XCTAssertEqual(store.data, garbage)
    }

    func testSaveWithoutLoadStillRefusesToOverwriteUnreadableData() throws {
        let garbage = Data("{ not json".utf8)
        let store = InMemoryWorkspaceStore(data: garbage)
        XCTAssertThrowsError(try WorkspaceRepository(store: store).save(try populatedSnapshot())) { error in
            XCTAssertEqual(error as? RepositoryError, .blockedByUnreadableData)
        }
        XCTAssertEqual(store.data, garbage)
    }

    func testNewerFormatVersionIsUnsupportedAndBlocksSaving() throws {
        let store = InMemoryWorkspaceStore(data: Data(#"{"formatVersion": 99}"#.utf8))
        let repository = WorkspaceRepository(store: store)
        XCTAssertEqual(repository.load(), .unsupportedVersion(99))
        XCTAssertTrue(repository.isSavingBlocked)
    }

    func testInvalidSessionInFileCountsAsUnreadable() throws {
        let store = InMemoryWorkspaceStore()
        try WorkspaceRepository(store: store).save(try populatedSnapshot())
        // Corrupt one nested field: an empty session ID fails session validation on decode.
        let text = String(decoding: store.data!, as: UTF8.self).replacingOccurrences(of: "\"session-a\"", with: "\"\"")
        store.data = Data(text.utf8)
        guard case .unreadable = WorkspaceRepository(store: store).load() else { return XCTFail("expected unreadable") }
    }

    func testSettingAsideUnreadableDataAllowsAFreshStart() throws {
        let garbage = Data("{ not json".utf8)
        let store = InMemoryWorkspaceStore(data: garbage)
        let repository = WorkspaceRepository(store: store, clock: { self.time })
        _ = repository.load()
        try repository.setAsideUnreadableData()
        XCTAssertEqual(Array(store.setAside.values), [garbage], "the unreadable data is kept, not deleted")
        XCTAssertFalse(repository.isSavingBlocked)
        XCTAssertEqual(repository.load(), .empty)
        try repository.save(try populatedSnapshot())
        guard case .loaded = repository.load() else { return XCTFail("expected loaded after fresh save") }
    }

    func testSetAsideIsRefusedWhenNothingIsUnreadable() throws {
        let repository = WorkspaceRepository(store: InMemoryWorkspaceStore())
        _ = repository.load()
        XCTAssertThrowsError(try repository.setAsideUnreadableData()) { error in
            XCTAssertEqual(error as? RepositoryError, .nothingToSetAside)
        }
    }

    // MARK: - Validation before writing

    func testForeignWorkspaceCaseIsRejectedBeforeWriting() throws {
        let store = InMemoryWorkspaceStore()
        var snapshot = try populatedSnapshot()
        snapshot.cases[1].workspaceID = "workspace-other"
        XCTAssertThrowsError(try WorkspaceRepository(store: store).save(snapshot)) { error in
            guard case RepositoryError.invalidSnapshot = error else { return XCTFail("expected invalidSnapshot, got \(error)") }
        }
        XCTAssertNil(store.data)
    }

    func testOrphanedSessionAndDraftAreRejected() throws {
        // Drafts are cleared so only the missing case can trigger the rejection.
        var orphanSession = try populatedSnapshot()
        orphanSession.cases.removeFirst()
        orphanSession.drafts = []
        XCTAssertThrowsError(try WorkspaceRepository(store: InMemoryWorkspaceStore()).save(orphanSession)) { error in
            XCTAssertEqual(error as? RepositoryError, .invalidSnapshot("session session-a has no case case-a"))
        }

        var orphanDraft = try populatedSnapshot()
        orphanDraft.drafts.append(DraftRecord(key: DraftKey(workspaceID: "workspace-a", caseID: "case-missing", sessionID: nil, kind: "note"),
                                              text: "x", updatedAt: time))
        XCTAssertThrowsError(try WorkspaceRepository(store: InMemoryWorkspaceStore()).save(orphanDraft))
    }

    func testRecordsWithoutAWorkspaceAreRejected() throws {
        var snapshot = try populatedSnapshot()
        snapshot.workspace = nil
        XCTAssertThrowsError(try WorkspaceRepository(store: InMemoryWorkspaceStore()).save(snapshot))
        XCTAssertNoThrow(try WorkspaceRepository(store: InMemoryWorkspaceStore()).save(.empty))
    }

    // MARK: - File store

    func testFileStoreRoundTripsAtomicallyAndSetsAside() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("northstar-repo-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileWorkspaceStore(directory: directory)
        XCTAssertNil(try store.read())

        let snapshot = try populatedSnapshot()
        try WorkspaceRepository(store: store, clock: { self.time }).save(snapshot)
        guard case .loaded(let restored) = WorkspaceRepository(store: FileWorkspaceStore(directory: directory)).load() else {
            return XCTFail("expected loaded from disk")
        }
        XCTAssertEqual(restored, snapshot)

        try store.write(Data("{ not json".utf8))
        let repository = WorkspaceRepository(store: store, clock: { self.time })
        guard case .unreadable = repository.load() else { return XCTFail("expected unreadable") }
        try repository.setAsideUnreadableData()
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertFalse(names.contains("workspace.json"))
        XCTAssertTrue(names.contains { $0.hasPrefix("workspace.unreadable-") })
    }

    // MARK: - Additive decoding and recovery details

    func testV1SnapshotMissingOptionalKeysDecodesWithDefaults() throws {
        let store = InMemoryWorkspaceStore()
        try WorkspaceRepository(store: store, clock: { self.time }).save(try populatedSnapshot())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(store.data)) as? [String: Any])
        object["drafts"] = nil
        object["forecasts"] = nil
        object["activeCaseID"] = nil
        store.data = try JSONSerialization.data(withJSONObject: object)
        guard case .loaded(let restored) = WorkspaceRepository(store: store).load() else { return XCTFail("expected loaded") }
        XCTAssertEqual(restored.drafts, [])
        XCTAssertEqual(restored.forecasts, [:])
        XCTAssertNil(restored.activeCaseID)
        XCTAssertEqual(restored.cases.map(\.id), ["case-a", "case-b"])
    }

    func testMinimalV1SnapshotWithOnlyVersionAndWorkspaceDecodes() throws {
        let workspace = try JSONEncoder().encode(configuration())
        let json = "{\"formatVersion\":1,\"workspace\":\(String(decoding: workspace, as: UTF8.self))}"
        guard case .loaded(let restored) = WorkspaceRepository(store: InMemoryWorkspaceStore(data: Data(json.utf8))).load() else {
            return XCTFail("expected loaded")
        }
        XCTAssertEqual(restored.workspace, configuration())
        XCTAssertEqual(restored.cases, [])
        XCTAssertEqual(restored.sessions, [])
    }

    func testUnknownExtraKeyIsIgnored() throws {
        let store = InMemoryWorkspaceStore()
        let snapshot = try populatedSnapshot()
        try WorkspaceRepository(store: store, clock: { self.time }).save(snapshot)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(store.data)) as? [String: Any])
        object["futureAdditiveField"] = ["anything": 1]
        store.data = try JSONSerialization.data(withJSONObject: object)
        guard case .loaded(let restored) = WorkspaceRepository(store: store).load() else { return XCTFail("expected loaded") }
        XCTAssertEqual(restored, snapshot)
    }

    func testTransientReadFailureIsRetryableAndNotSetAside() throws {
        let store = InMemoryWorkspaceStore()
        try WorkspaceRepository(store: store, clock: { self.time }).save(try populatedSnapshot())
        let previous = store.data
        store.failReads = true
        let repository = WorkspaceRepository(store: store, clock: { self.time })
        guard case .readFailed = repository.load() else { return XCTFail("expected readFailed") }
        XCTAssertFalse(repository.isSavingBlocked)
        XCTAssertThrowsError(try repository.setAsideUnreadableData()) { XCTAssertEqual($0 as? RepositoryError, .nothingToSetAside) }
        XCTAssertThrowsError(try repository.save(try populatedSnapshot())) { XCTAssertEqual($0 as? RepositoryError, .storageUnavailable) }
        XCTAssertEqual(store.data, previous)
        store.failReads = false
        guard case .loaded = repository.load() else { return XCTFail("expected loaded after retry") }
        XCTAssertNoThrow(try repository.save(try populatedSnapshot()))
    }

    func testSetAsideLabelsAreUniqueAtTheSameInstant() throws {
        let store = InMemoryWorkspaceStore(data: Data("{ not json".utf8))
        let first = WorkspaceRepository(store: store, clock: { self.time })
        _ = first.load()
        try first.setAsideUnreadableData()
        store.data = Data("{ also not json".utf8)
        let second = WorkspaceRepository(store: store, clock: { self.time })
        _ = second.load()
        try second.setAsideUnreadableData()
        XCTAssertEqual(store.setAside.count, 2)
    }

    func testActiveCaseMustHaveAStoredSession() throws {
        var snapshot = try populatedSnapshot()
        snapshot.activeCaseID = "case-b"
        XCTAssertThrowsError(try snapshot.validate())
        snapshot.activeCaseID = "case-a"
        XCTAssertNoThrow(try snapshot.validate())
    }

    // MARK: - Fixtures (fictional only)

    private func populatedSnapshot() throws -> WorkspaceSnapshot {
        let workspace = configuration()
        let first = try caseInput(id: "case-a", reference: "A-1", title: "Fictional case A")
            .makeProcedure(in: workspace, existingCases: [], templates: catalog)
        let second = try caseInput(id: "case-b", reference: "B-2", title: "Fictional case B")
            .makeProcedure(in: workspace, existingCases: [first], templates: catalog)
        let identity = SessionIdentity(workspaceID: workspace.id, caseID: first.id, sessionID: "session-a")
        let itemID = first.steps[0].id
        let state = SessionRecordingState(identity: identity, templateReference: FictionalCoordinationTemplate.reference,
                                          startedAt: time, version: 1,
                                          itemStatuses: Dictionary(uniqueKeysWithValues: first.steps.map { ($0.id, RecordedItemStatus.unrecorded) }),
                                          selectedItemID: itemID, pendingAcknowledgment: nil)
        let event = SessionEvent(id: "event-1", intentID: "intent-1", identity: identity, actor: workspace.localParticipant,
                                 source: .touch, occurredAt: time, acceptedVersion: 1, targetItemID: itemID, payload: .itemSelected)
        return WorkspaceSnapshot(
            workspace: workspace,
            forecasts: ["site-a": StormForecast(summary: "Simulated light snow", roadClosureInHours: nil, snowfallInches: 2, asOf: time)],
            cases: [first, second],
            sessions: [StoredSession(state: state, events: [event])],
            drafts: [
                DraftRecord(key: DraftKey(workspaceID: workspace.id, caseID: "case-a", sessionID: "session-a", kind: "supportQuestion"),
                            text: "Draft question for case A", updatedAt: time),
                DraftRecord(key: DraftKey(workspaceID: workspace.id, caseID: "case-b", sessionID: nil, kind: "caseNote"),
                            text: "Draft note for case B", updatedAt: time),
            ])
    }

    private func configuration() -> WorkspaceConfiguration {
        let site = Hospital(id: "site-a", name: "Fictional facility", town: "Example town", workspaceID: "workspace-a",
                            timeZoneIdentifier: "America/Chicago", roomLabels: ["Room A"])
        let contact = DeviceRep(id: "contact-a", name: "Fictional contact", homeBase: "Example town", skills: ["pacemaker"],
                                driveMinutes: [:], isAvailable: true, canSupportRemotely: true, workspaceID: "workspace-a",
                                statedRole: .technicalRep)
        return WorkspaceConfiguration(id: "workspace-a", name: "Fictional workspace", sites: [site], contacts: [contact],
            localParticipant: LocalParticipant(id: "participant-a", workspaceID: "workspace-a",
                                               displayName: "Fictional coordinator", statedRole: .coordinator))
    }

    private func caseInput(id: String, reference: String, title: String) -> CaseInput {
        CaseInput(id: id, workspaceID: "workspace-a", reference: reference, title: title, siteID: "site-a",
                  scheduledAt: time, durationMinutes: 60, deviceFamily: "pacemaker",
                  templateReference: FictionalCoordinationTemplate.reference)
    }
}
