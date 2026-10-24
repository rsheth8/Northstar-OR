import XCTest
@testable import NorthstarOR

final class CoPilotSessionTests: XCTestCase {
    private let time = Date(timeIntervalSince1970: 1_800_000_000)
    private func session(caseID: String = "new-case", workspace: String = "new-workspace", run: String = "run-a") -> CoPilotSession {
        CoPilotSession(procedure: FictionalCoordinationTemplate.makeProcedure(id: caseID, name: "Independent fictional case",
            hospitalID: "new-site", scheduledAt: time, durationMinutes: 45, workspaceID: workspace), now: time, sessionID: run)
    }
    private func command(_ session: CoPilotSession, _ action: SessionCommandAction, target: String? = nil,
                         id: String = UUID().uuidString, source: RecordingInputSource = .touch) throws -> SessionCommand {
        try XCTUnwrap(session.makeCommand(action, targetItemID: target, source: source, at: time, intentID: id))
    }
    private func apply(_ session: CoPilotSession, _ action: SessionCommandAction, target: String? = nil) throws {
        _ = try session.apply(command(session, action, target: target))
    }
    private func reject(_ session: CoPilotSession, _ command: SessionCommand, _ error: RecordingCommandError,
                        file: StaticString = #filePath, line: UInt = #line) {
        let state = session.recordingState
        let events = session.events
        let log = session.log
        XCTAssertThrowsError(try session.apply(command), file: file, line: line) { XCTAssertEqual($0 as? RecordingCommandError, error, file: file, line: line) }
        XCTAssertEqual(session.recordingState, state, file: file, line: line)
        XCTAssertEqual(session.events, events, file: file, line: line)
        XCTAssertEqual(session.log, log, file: file, line: line)
    }

    func testRequiredDeferralPinsItemUntilMatchingAcknowledgmentWithoutAdvance() throws {
        let s = session()
        try apply(s, .recordConfirmation)
        let event = try s.apply(command(s, .deferItem))
        let warning = try XCTUnwrap(s.recordingState?.pendingAcknowledgment)
        XCTAssertEqual(s.currentStep?.id, "device-check")
        XCTAssertEqual(s.pendingAlert?.id, "device-check")
        XCTAssertEqual(s.recordingState?.itemStatuses["device-check"], .deferred)
        XCTAssertEqual(warning.deferralEventID, event.id)
        try apply(s, .acknowledgeWarning(acknowledgment: warning))
        XCTAssertNil(s.pendingAlert)
        XCTAssertEqual(s.currentStep?.id, "device-check")
        XCTAssertEqual(s.status(of: s.procedure.steps[1]), .skipped)
        try apply(s, .selectItem, target: "programmer")
        XCTAssertEqual(s.currentStep?.id, "programmer")
        XCTAssertEqual(s.recordingState?.itemStatuses["device-check"], .deferred)
    }

    func testGateRejectsAllRecordingAndSelectionInputsButSupportAndReviewPreserveIt() throws {
        let s = session()
        try apply(s, .deferItem)
        for source in RecordingInputSource.allCases {
            for action in [SessionCommandAction.recordConfirmation, .deferItem, .selectItem] {
                let target = action == .selectItem ? "programmer" : "timeout"
                reject(s, try command(s, action, target: target, source: source), .acknowledgmentPending)
            }
        }
        let state = s.recordingState
        let events = s.events
        _ = ContextPackage(session: s, hospital: nil)
        s.receiveRemoteMessage("Fictional support reply", from: "Local participant", at: time)
        s.setReducedSupport(true, at: time)
        XCTAssertEqual(s.recordingState, state)
        XCTAssertEqual(s.events, events)
        XCTAssertEqual(s.currentStep?.id, "timeout")
    }

    func testDuplicateIntentReturnsOriginalEventAfterAdvanceAndInterveningAction() throws {
        let s = session()
        let c = try command(s, .recordConfirmation, id: "one-intent")
        let first = try s.apply(c)
        try apply(s, .selectItem, target: "closure")
        let state = s.recordingState
        let log = s.log
        XCTAssertEqual(try s.apply(c), first)
        XCTAssertEqual(s.recordingState, state)
        XCTAssertEqual(s.events.count, 2)
        XCTAssertEqual(s.log, log)
        let conflict = try command(s, .deferItem, id: "one-intent")
        reject(s, conflict, .intentConflict)
    }

    func testStaleTouchOrVoiceCannotRetargetTheNextItem() throws {
        let s = session()
        let touch = try command(s, .recordConfirmation)
        let voice = try command(s, .recordConfirmation, source: .voice)
        _ = try s.apply(touch)
        XCTAssertEqual(s.currentStep?.id, "device-check")
        reject(s, voice, .staleVersion)
        let oldTarget = try command(s, .deferItem, target: "timeout")
        reject(s, oldTarget, .targetNotSelected)
    }

    func testWrongWorkspaceCaseAndRunCannotCrossSessionBoundaries() throws {
        let s = session()
        for other in [session(caseID: "another"), session(workspace: "another"), session(run: "another")] {
            reject(s, try command(other, .recordConfirmation), .wrongSession)
        }
        XCTAssertEqual(s.recordingState?.version, 0)
    }

    func testSelectionChangesNoRecordedStatusAndCanRevisitAnyItem() throws {
        let s = session()
        let before = s.recordingState?.itemStatuses
        try apply(s, .selectItem, target: "closure")
        XCTAssertEqual(s.currentStep?.id, "closure")
        XCTAssertEqual(s.recordingState?.itemStatuses, before)
        try apply(s, .recordConfirmation)
        XCTAssertNil(s.currentStep)
        try apply(s, .selectItem, target: "timeout")
        XCTAssertEqual(s.currentStep?.id, "timeout")
        XCTAssertFalse(s.allConfirmationsRecorded)
        reject(s, try command(s, .selectItem, target: "unknown"), .unknownItem)
    }

    func testCorrectionSupersedesPinnedWarningPreservesOriginalAndDoesNotAcknowledge() throws {
        let s = session()
        let original = try s.apply(command(s, .deferItem))
        let warning = try XCTUnwrap(s.recordingState?.pendingAcknowledgment)
        let correction = try s.apply(command(s, .correctRecord(originalEventID: original.id, newStatus: .teamConfirmed, reason: "Team corrected its report")))
        XCTAssertEqual(s.events.first, original)
        XCTAssertEqual(s.events.count, 2)
        XCTAssertNil(s.pendingAlert)
        XCTAssertEqual(s.currentStep?.id, "timeout")
        XCTAssertEqual(s.recordingState?.itemStatuses["timeout"], .teamConfirmed)
        XCTAssertEqual(correction.payload, .recordCorrected(originalEventID: original.id, newStatus: .teamConfirmed,
            reason: "Team corrected its report", supersededAcknowledgmentID: warning.id, acknowledgmentID: nil))
        reject(s, try command(s, .acknowledgeWarning(acknowledgment: warning)), .acknowledgmentMismatch)
        reject(s, try command(s, .correctRecord(originalEventID: original.id, newStatus: .unrecorded, reason: nil)), .correctionNotCurrent)
    }

    func testCorrectionToDeferredCreatesFreshGateAndOldAcknowledgmentCannotClearIt() throws {
        let s = session()
        let old = try s.apply(command(s, .deferItem))
        let oldWarning = try XCTUnwrap(s.recordingState?.pendingAcknowledgment)
        let correction = try s.apply(command(s, .correctRecord(originalEventID: old.id, newStatus: .deferred, reason: "Revised report")))
        let fresh = try XCTUnwrap(s.recordingState?.pendingAcknowledgment)
        XCTAssertNotEqual(fresh.id, oldWarning.id)
        XCTAssertEqual(fresh.deferralEventID, correction.id)
        reject(s, try command(s, .acknowledgeWarning(acknowledgment: oldWarning)), .acknowledgmentMismatch)
        try apply(s, .acknowledgeWarning(acknowledgment: fresh))
        XCTAssertEqual(s.currentStep?.id, "timeout")
        XCTAssertEqual(s.recordingState?.itemStatuses["timeout"], .deferred)
    }

    func testCorrectionOnlyReferencesLatestRecordingForSameItemAndPinnedItem() throws {
        let s = session()
        let selection = try s.apply(command(s, .selectItem, target: "device-check"))
        reject(s, try command(s, .correctRecord(originalEventID: selection.id, newStatus: .teamConfirmed, reason: nil)), .correctionNotCurrent)
        let first = try s.apply(command(s, .recordConfirmation))
        try apply(s, .selectItem, target: "device-check")
        reject(s, try command(s, .recordConfirmation), .alreadyRecorded)
        try apply(s, .selectItem, target: "timeout")
        let deferred = try s.apply(command(s, .deferItem))
        reject(s, try command(s, .correctRecord(originalEventID: first.id, newStatus: .unrecorded, reason: nil), target: "device-check"), .acknowledgmentPending)
        reject(s, try command(s, .correctRecord(originalEventID: first.id, newStatus: .unrecorded, reason: nil)), .correctionNotCurrent)
        try apply(s, .correctRecord(originalEventID: deferred.id, newStatus: .unrecorded, reason: nil))
        XCTAssertNil(s.pendingAlert)
        XCTAssertEqual(s.recordingState?.itemStatuses["timeout"], .unrecorded)
    }

    func testActorSourceTimeAreSnapshotsAndVersionsNotClockOrdered() throws {
        let s = session()
        let actor = LocalParticipant(id: "actor", workspaceID: "new-workspace", displayName: "Stated participant", statedRole: .orTeam)
        let c = try XCTUnwrap(s.makeCommand(.deferItem, actor: actor, source: .keyboard, at: time, intentID: "defer"))
        let first = try s.apply(c)
        let warning = try XCTUnwrap(s.recordingState?.pendingAcknowledgment)
        let ack = try XCTUnwrap(s.makeCommand(.acknowledgeWarning(acknowledgment: warning), actor: actor, source: .remote,
                                            at: time.addingTimeInterval(-60), intentID: "ack"))
        let second = try s.apply(ack)
        XCTAssertEqual(first.actor, actor)
        XCTAssertEqual(first.source, .keyboard)
        XCTAssertEqual(first.occurredAt, time)
        XCTAssertEqual(second.acceptedVersion, 2)
        XCTAssertLessThan(second.occurredAt, first.occurredAt)
        try XCTUnwrap(s.recordingState).validate()
        for event in s.events { try event.validate() }
    }

    func testUnsupportedOrInvalidIdentityCannotRecord() throws {
        var p = session().procedure
        p.templateReference = CoordinationTemplateReference(id: "unknown", version: 1)
        let unsupported = CoPilotSession(procedure: p, now: time)
        XCTAssertNil(unsupported.recordingState)
        XCTAssertNil(unsupported.makeCommand(.recordConfirmation))
        reject(unsupported, try command(session(), .recordConfirmation), .unsupportedRecording)
        let invalid = session(caseID: "")
        XCTAssertFalse(invalid.isRecordingSupported)
    }

    func testPlannerFlagReachesCoPilotThroughSync() {
        let model = AppModel(sync: LocalSyncService())
        model.sync.send(.reducedSupportChanged(procedureID: model.activeSession.procedure.id, on: true))
        XCTAssertTrue(model.activeSession.reducedSupport)
    }
    func testVoiceCommandParsing() {
        XCTAssertEqual(VoiceCommand.parse("Step complete"), .complete)
        XCTAssertEqual(VoiceCommand.parse("skip this one"), .skip)
        XCTAssertEqual(VoiceCommand.parse("confirm"), .confirm)
        XCTAssertNil(VoiceCommand.parse("hand me the clamp"))
    }
}
