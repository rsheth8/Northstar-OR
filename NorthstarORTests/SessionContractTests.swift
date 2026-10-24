import XCTest
@testable import NorthstarOR

final class SessionContractTests: XCTestCase {
    private let time = Date(timeIntervalSince1970: 1_800_000_000)
    private let identity = SessionIdentity(workspaceID: "workspace-a", caseID: "case-a", sessionID: "run-a")
    private var actor: LocalParticipant {
        LocalParticipant(id: "actor-a", workspaceID: "workspace-a", displayName: "Fictional team", statedRole: .orTeam)
    }
    private var warning: RequiredAcknowledgment {
        RequiredAcknowledgment(id: "warning-a", itemID: "item-a", deferralEventID: "deferral-a")
    }

    func testSessionIdentitySeparatesRunsCasesAndWorkspaces() throws {
        XCTAssertEqual(try roundTrip(identity), identity)
        XCTAssertNotEqual(identity, SessionIdentity(workspaceID: "workspace-a", caseID: "case-a", sessionID: "run-b"))
        XCTAssertNotEqual(identity, SessionIdentity(workspaceID: "workspace-a", caseID: "case-b", sessionID: "run-a"))
        XCTAssertNotEqual(identity, SessionIdentity(workspaceID: "workspace-b", caseID: "case-a", sessionID: "run-a"))
        expect(.required("session.sessionID")) {
            try SessionIdentity(workspaceID: "workspace-a", caseID: "case-a", sessionID: " \n ").validate()
        }
    }

    func testSourceLabelsAndActorIdentityRemainStableAcrossRoundTrip() throws {
        XCTAssertEqual(RecordingInputSource.allCases.map(\.label), ["Touch", "Keyboard", "Voice", "Remote command"])
        for source in RecordingInputSource.allCases {
            let value = command(source: source)
            let decoded = try roundTrip(value)
            XCTAssertEqual(decoded.actor, actor)
            XCTAssertEqual(decoded.source, source)
            XCTAssertEqual(decoded.id, "intent-a")
        }
        var renamed = actor
        renamed.displayName = "Renamed fictional team"
        XCTAssertEqual(renamed.id, actor.id)
    }

    func testSelectionAndRecordedStatusAreIndependent() throws {
        let state = recordingState(statuses: ["item-a": .teamConfirmed, "item-b": .deferred], selected: "item-a")
        try state.validate()
        let decoded = try roundTrip(state)
        XCTAssertEqual(decoded.selectedItemID, "item-a")
        XCTAssertEqual(decoded.itemStatuses["item-a"], .teamConfirmed)
        XCTAssertEqual(decoded.itemStatuses["item-b"], .deferred)
        XCTAssertEqual(decoded.templateReference, FictionalCoordinationTemplate.reference)
        let deselected = recordingState(statuses: decoded.itemStatuses, selected: nil)
        try deselected.validate()
        XCTAssertEqual(deselected.itemStatuses, decoded.itemStatuses)
        XCTAssertNil(deselected.selectedItemID)
    }

    func testCommandsRetainOriginalTargetVersionAndIntentForEveryAction() throws {
        let actions: [SessionCommandAction] = [
            .selectItem, .recordConfirmation, .deferItem,
            .acknowledgeWarning(acknowledgment: warning),
            .correctRecord(originalEventID: "event-before", newStatus: .unrecorded, reason: "Entered on wrong item")
        ]
        for action in actions {
            let value = command(action: action)
            XCTAssertEqual(try roundTrip(value), value)
            XCTAssertEqual(value.targetItemID, "item-a")
            XCTAssertEqual(value.expectedVersion, 7)
            XCTAssertEqual(value.identity.sessionID, "run-a")
            XCTAssertEqual(value.issuedAt, time)
        }
    }

    func testAcceptedEventsCarrySequenceWithoutOrderingByWallClock() throws {
        let first = event(id: "event-a", version: 8, at: time)
        let later = event(id: "event-b", version: 9, at: time.addingTimeInterval(-60))
        XCTAssertEqual(try roundTrip(first), first)
        XCTAssertEqual(try roundTrip(later), later)
        XCTAssertGreaterThan(later.acceptedVersion, first.acceptedVersion)
        XCTAssertLessThan(later.occurredAt, first.occurredAt)
        XCTAssertEqual(later.intentID, "intent-a")
    }

    func testDeferralAcknowledgmentAndCorrectionReferencesRoundTripWithoutRewritingOriginal() throws {
        let deferred = event(id: "deferral-a", payload: .itemDeferred(acknowledgmentID: warning.id))
        let acknowledged = event(id: "ack-event", payload: .warningAcknowledged(acknowledgment: warning))
        let corrected = event(id: "correction-a", payload: .recordCorrected(originalEventID: deferred.id,
            newStatus: .unrecorded, reason: "Fictional entry corrected", supersededAcknowledgmentID: warning.id))
        for value in [deferred, acknowledged, corrected] { XCTAssertEqual(try roundTrip(value), value) }
        XCTAssertEqual(deferred.payload, .itemDeferred(acknowledgmentID: "warning-a"))
        let pending = recordingState(statuses: ["item-a": .deferred], selected: "item-a", pending: warning)
        XCTAssertEqual(try roundTrip(pending).itemStatuses["item-a"], .deferred)
    }

    func testCorrectionCanSupersedeOldGateAndCreateDistinctNewDeferralGate() throws {
        let value = event(id: "new-deferral", payload: .recordCorrected(originalEventID: "old-deferral", newStatus: .deferred,
            reason: nil, supersededAcknowledgmentID: "old-warning", acknowledgmentID: "new-warning"))
        XCTAssertEqual(try roundTrip(value), value)
        let nextWarning = RequiredAcknowledgment(id: "new-warning", itemID: "item-a", deferralEventID: value.id)
        let state = recordingState(statuses: ["item-a": .deferred], pending: nextWarning)
        XCTAssertEqual(try roundTrip(state).pendingAcknowledgment?.deferralEventID, value.id)
        expect(.inconsistentAcknowledgment) {
            try event(payload: .recordCorrected(originalEventID: "old-deferral", newStatus: .teamConfirmed, reason: nil,
                supersededAcknowledgmentID: nil, acknowledgmentID: "new-warning")).validate()
        }
        expect(.inconsistentAcknowledgment) {
            try event(payload: .recordCorrected(originalEventID: "old-deferral", newStatus: .deferred, reason: nil,
                supersededAcknowledgmentID: "same-warning", acknowledgmentID: "same-warning")).validate()
        }
    }

    func testSelectionAndNonRequiredDeferralEventPayloadsPreserveMetadata() throws {
        for payload: SessionEventPayload in [.itemSelected, .itemDeferred(acknowledgmentID: nil)] {
            let value = event(payload: payload)
            XCTAssertEqual(try roundTrip(value), value)
            XCTAssertEqual(value.actor.id, "actor-a")
            XCTAssertEqual(value.targetItemID, "item-a")
        }
    }

    func testPendingGateRequiresSelectedDeferredItemAndLinkedDeferralIdentity() {
        expect(.inconsistentAcknowledgment) {
            try recordingState(statuses: ["item-a": .deferred, "item-b": .unrecorded], selected: "item-b", pending: warning).validate()
        }
        expect(.inconsistentAcknowledgment) {
            try recordingState(statuses: ["item-a": .teamConfirmed], selected: "item-a", pending: warning).validate()
        }
        expect(.targetMismatch) {
            try command(action: .acknowledgeWarning(acknowledgment:
                RequiredAcknowledgment(id: "warning-b", itemID: "item-b", deferralEventID: "event-b"))).validate()
        }
        expect(.required("acknowledgment.deferralEventID")) {
            try RequiredAcknowledgment(id: "warning-a", itemID: "item-a", deferralEventID: " ").validate()
        }
    }

    func testCommandRejectsMissingIdentityForeignActorInvalidVersionAndTime() {
        expect(.required("command.id")) { try command(id: " ").validate() }
        expect(.required("targetItemID")) { try command(target: " ").validate() }
        expect(.invalidVersion) { try command(version: -1).validate() }
        expect(.invalidTimestamp) { try command(at: Date(timeIntervalSince1970: .infinity)).validate() }
        let foreign = LocalParticipant(id: actor.id, workspaceID: "workspace-b", displayName: actor.displayName, statedRole: actor.statedRole)
        expect(.foreignActor) { try command(actor: foreign).validate() }
        let unnamed = LocalParticipant(id: "actor-a", workspaceID: "workspace-a", displayName: " ", statedRole: .orTeam)
        expect(.required("actor.displayName")) { try command(actor: unnamed).validate() }
    }

    func testCorrectionRequiresOriginalEventAndNonBlankOptionalReason() {
        expect(.required("correction.originalEventID")) {
            try command(action: .correctRecord(originalEventID: " ", newStatus: .deferred, reason: nil)).validate()
        }
        expect(.required("correction.reason")) {
            try command(action: .correctRecord(originalEventID: "old", newStatus: .deferred, reason: " \n ")).validate()
        }
        expect(.selfReferencingEvent) {
            try event(payload: .recordCorrected(originalEventID: "event-a", newStatus: .teamConfirmed,
                reason: nil, supersededAcknowledgmentID: nil)).validate()
        }
    }

    func testEventRejectsInvalidSequenceIntentAndMismatchedAcknowledgment() {
        expect(.invalidVersion) { try event(version: 0).validate() }
        expect(.required("event.intentID")) { try event(intent: "").validate() }
        expect(.targetMismatch) {
            try event(payload: .warningAcknowledged(acknowledgment:
                RequiredAcknowledgment(id: "ack-b", itemID: "item-b", deferralEventID: "old"))).validate()
        }
        expect(.selfReferencingEvent) {
            try event(payload: .warningAcknowledged(acknowledgment:
                RequiredAcknowledgment(id: "ack-a", itemID: "item-a", deferralEventID: "event-a"))).validate()
        }
    }

    func testStateRejectsUnknownSelectionEmptyItemsAndUnpinnedTemplate() {
        expect(.unknownItem("missing")) { try recordingState(selected: "missing").validate() }
        expect(.emptyItems) { try recordingState(statuses: [:], selected: nil).validate() }
        expect(.required("item.id")) { try recordingState(statuses: [" ": .unrecorded], selected: nil).validate() }
        let invalid = SessionRecordingState(identity: identity, templateReference: CoordinationTemplateReference(id: "template", version: 0),
            startedAt: time, version: 0, itemStatuses: ["item-a": .unrecorded], selectedItemID: "item-a", pendingAcknowledgment: nil)
        expect(.invalidTemplateReference) { try invalid.validate() }
    }

    func testSchemaMissingAndFutureVersionsFailForStateCommandAndEvent() throws {
        try assertSchemaRejected(recordingState(), as: SessionRecordingState.self)
        try assertSchemaRejected(command(), as: SessionCommand.self)
        try assertSchemaRejected(event(), as: SessionEvent.self)
    }

    func testDecodingRejectsMalformedValuesRatherThanSilentlyRepairing() throws {
        try assertDecodeRejected(command(target: ""), as: SessionCommand.self)
        try assertDecodeRejected(event(version: 0), as: SessionEvent.self)
        try assertDecodeRejected(recordingState(selected: "missing"), as: SessionRecordingState.self)
        try assertDecodeRejected(recordingState(statuses: ["item-a": .teamConfirmed], pending: warning), as: SessionRecordingState.self)
    }

    func testUnknownEnumCannotBecomeAConfirmationAndLegacyStateIsNotInferred() throws {
        let data = Data("\"completed\"".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(RecordedItemStatus.self, from: data))
        let legacy = Data("{\"statuses\":{\"item-a\":\"current\"},\"currentIndex\":0}".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SessionRecordingState.self, from: legacy))
        let unknownTemplate = SessionRecordingState(identity: identity, templateReference: CoordinationTemplateReference(id: "unknown-template", version: 99),
            startedAt: time, version: 0, itemStatuses: ["item-a": .unrecorded], selectedItemID: nil, pendingAcknowledgment: nil)
        // Structural decoding retains the pin; F05 checks it against the authoritative catalog before recording.
        XCTAssertEqual(try roundTrip(unknownTemplate), unknownTemplate)
    }

    private func command(id: String = "intent-a", target: String = "item-a", version: Int = 7,
                         source: RecordingInputSource = .touch, action: SessionCommandAction = .recordConfirmation,
                         actor: LocalParticipant? = nil, at: Date? = nil) -> SessionCommand {
        SessionCommand(id: id, identity: identity, actor: actor ?? self.actor, source: source, issuedAt: at ?? time,
                       expectedVersion: version, targetItemID: target, action: action)
    }

    private func event(id: String = "event-a", intent: String = "intent-a", version: Int = 8, at: Date? = nil,
                       payload: SessionEventPayload = .confirmationRecorded) -> SessionEvent {
        SessionEvent(id: id, intentID: intent, identity: identity, actor: actor, source: .touch, occurredAt: at ?? time,
                     acceptedVersion: version, targetItemID: "item-a", payload: payload)
    }

    private func recordingState(statuses: [String: RecordedItemStatus] = ["item-a": .unrecorded], selected: String? = "item-a",
                                pending: RequiredAcknowledgment? = nil) -> SessionRecordingState {
        SessionRecordingState(identity: identity, templateReference: FictionalCoordinationTemplate.reference, startedAt: time,
            version: 7, itemStatuses: statuses, selectedItemID: selected, pendingAcknowledgment: pending)
    }

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
    }

    private func expect(_ error: SessionContractError, _ action: () throws -> Void) {
        XCTAssertThrowsError(try action()) { XCTAssertEqual($0 as? SessionContractError, error) }
    }

    private func assertSchemaRejected<T: Codable>(_ value: T, as type: T.Type) throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any])
        json["schemaVersion"] = 99
        let future = try JSONSerialization.data(withJSONObject: json)
        XCTAssertThrowsError(try JSONDecoder().decode(type, from: future)) {
            XCTAssertEqual($0 as? SessionContractError, .unsupportedSchemaVersion(99))
        }
        json.removeValue(forKey: "schemaVersion")
        XCTAssertThrowsError(try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: json)))
    }

    private func assertDecodeRejected<T: Codable>(_ value: T, as type: T.Type) throws {
        let data = try JSONEncoder().encode(value)
        XCTAssertThrowsError(try JSONDecoder().decode(type, from: data))
    }
}
