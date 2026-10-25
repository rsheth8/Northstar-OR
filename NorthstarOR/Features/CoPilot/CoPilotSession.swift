import Foundation
import Observation

/// A stored session that cannot be rebuilt into the same live state. Its data is kept, not repaired.
enum SessionRestoreError: Error, Equatable {
    case caseMismatch
    case unsupportedRecording
    case itemsDoNotMatchCase
    case historyMismatch(eventID: String)
    case stateMismatch
}

enum RecordingCommandError: Error, Equatable {
    case unsupportedRecording, wrongSession, staleVersion, unknownItem, targetNotSelected
    case acknowledgmentPending, acknowledgmentMismatch, intentConflict, correctionNotCurrent, alreadyRecorded
}

/// Recording authority for one run. All checklist writes pass through targeted F04 commands.
/// Support/log adapters remain local-only until F07; they cannot mutate recording selection/state.
@Observable
final class CoPilotSession {
    /// Case details may be refreshed by a planning edit; identity, template and items never change.
    private(set) var procedure: Procedure
    let identity: SessionIdentity
    let startedAt: Date
    private(set) var events: [SessionEvent] = []
    private(set) var log: [LogEntry] = []
    private(set) var reducedSupport: Bool
    private var itemStatuses: [String: RecordedItemStatus]
    private var selectedItemID: String?
    private var pendingAcknowledgment: RequiredAcknowledgment?
    private var acceptedCommands: [String: SessionCommand] = [:]

    init(procedure: Procedure, reducedSupport: Bool = false, now: Date = .now,
         sessionID: String = UUID().uuidString) {
        self.procedure = procedure
        self.identity = SessionIdentity(workspaceID: procedure.workspaceID ?? "local-unconfigured",
                                        caseID: procedure.id, sessionID: sessionID)
        self.startedAt = now
        self.reducedSupport = reducedSupport
        self.itemStatuses = [:]
        if FictionalCoordinationTemplate.supports(procedure),
           (try? identity.validate()) != nil, now.timeIntervalSinceReferenceDate.isFinite {
            itemStatuses = Dictionary(uniqueKeysWithValues: procedure.steps.map { ($0.id, .unrecorded) })
            selectedItemID = procedure.steps.first?.id
        }
    }

    /// Rebuilds a saved run by replaying its accepted events through `apply`, so a restored
    /// session behaves exactly like the live one: same state, log, version and duplicate-intent
    /// guards (an identical retry returns the original event; a conflicting reuse is rejected).
    /// Any disagreement with the stored state throws instead of repairing or crashing.
    static func restore(procedure: Procedure, from stored: StoredSession) throws -> CoPilotSession {
        let state = stored.state
        let identity = state.identity
        guard identity.caseID == procedure.id, identity.workspaceID == procedure.workspaceID,
              state.templateReference == procedure.templateReference else { throw SessionRestoreError.caseMismatch }
        guard Set(state.itemStatuses.keys) == Set(procedure.steps.map(\.id)),
              procedure.steps.count == state.itemStatuses.count else { throw SessionRestoreError.itemsDoNotMatchCase }
        let session = CoPilotSession(procedure: procedure, now: state.startedAt, sessionID: identity.sessionID)
        guard session.isRecordingSupported, session.identity == identity else { throw SessionRestoreError.unsupportedRecording }
        for event in stored.events {
            let replayed: SessionEvent
            do { replayed = try session.apply(event.replayCommand) } catch {
                throw SessionRestoreError.historyMismatch(eventID: event.id)
            }
            guard replayed == event else { throw SessionRestoreError.historyMismatch(eventID: event.id) }
        }
        guard session.recordingState == state else { throw SessionRestoreError.stateMismatch }
        return session
    }

    /// Applies a planning edit's title/schedule/site to this run. Refused unless the case's
    /// identity, template pin and items are unchanged, so recorded state stays valid.
    @discardableResult
    func refreshCaseDetails(_ updated: Procedure) -> Bool {
        guard updated.id == procedure.id, updated.workspaceID == procedure.workspaceID,
              updated.templateReference == procedure.templateReference, updated.steps == procedure.steps,
              updated.deviceFamily == procedure.deviceFamily else { return false }
        procedure = updated
        return true
    }

    /// The persisted form of this run, or nil when recording is unsupported.
    var storedSession: StoredSession? {
        recordingState.map { StoredSession(state: $0, events: events) }
    }

    var isRecordingSupported: Bool { !itemStatuses.isEmpty }
    var recordingState: SessionRecordingState? {
        guard isRecordingSupported, let reference = procedure.templateReference else { return nil }
        return SessionRecordingState(identity: identity, templateReference: reference, startedAt: startedAt,
            version: events.count, itemStatuses: itemStatuses, selectedItemID: selectedItemID,
            pendingAcknowledgment: pendingAcknowledgment)
    }
    var currentStep: ProcedureStep? { procedure.steps.first { $0.id == selectedItemID } }
    var currentIndex: Int { procedure.steps.firstIndex { $0.id == selectedItemID } ?? procedure.steps.count }
    var pendingAlert: ProcedureStep? { procedure.steps.first { $0.id == pendingAcknowledgment?.itemID } }
    /// Legacy view projection only. Selection never overwrites the canonical recorded state.
    var statuses: [String: StepStatus] {
        Dictionary(uniqueKeysWithValues: itemStatuses.map { id, status in
            let displayed: StepStatus
            switch status {
            case .unrecorded: displayed = id == selectedItemID ? .current : .upcoming
            case .deferred: displayed = .skipped
            case .teamConfirmed: displayed = .completed
            }
            return (id, displayed)
        })
    }
    func status(of step: ProcedureStep) -> StepStatus { statuses[step.id] ?? .upcoming }
    var isFinished: Bool { isRecordingSupported && selectedItemID == nil }
    var allConfirmationsRecorded: Bool {
        isRecordingSupported && itemStatuses.values.allSatisfy { $0 == .teamConfirmed }
    }
    var recordingSummary: String {
        guard isRecordingSupported else { return "Recording unavailable — no supported coordination template" }
        if allConfirmationsRecorded { return "All team confirmations recorded" }
        let unresolved = itemStatuses.values.filter { $0 != .teamConfirmed }.count
        if isFinished { return "Recording ended — \(unresolved) unresolved item\(unresolved == 1 ? "" : "s")" }
        return "\(unresolved) confirmation\(unresolved == 1 ? "" : "s") unresolved"
    }

    /// Capture when displaying/recognizing an action, not inside a delayed callback.
    /// F07 supplies the configured participant. The default is an unconfigured local UI adapter,
    /// never verified identity. A retry must reuse the returned value unchanged.
    func makeCommand(_ action: SessionCommandAction, targetItemID: String? = nil,
                     actor: LocalParticipant? = nil, source: RecordingInputSource = .touch,
                     at time: Date = .now, intentID: String = UUID().uuidString) -> SessionCommand? {
        guard isRecordingSupported, let target = targetItemID ?? selectedItemID else { return nil }
        return SessionCommand(id: intentID, identity: identity,
            actor: actor ?? LocalParticipant(id: "local-unconfigured", workspaceID: identity.workspaceID,
                                            displayName: "Local team (unconfigured)", statedRole: .orTeam),
            source: source, issuedAt: time, expectedVersion: events.count, targetItemID: target, action: action)
    }

    /// Atomic: rejected commands leave recording state, accepted intent IDs and log untouched.
    /// Equal retries return the original event even after the selected item/version changes.
    @discardableResult
    func apply(_ command: SessionCommand) throws -> SessionEvent {
        guard isRecordingSupported else { throw RecordingCommandError.unsupportedRecording }
        try command.validate()
        guard command.identity == identity else { throw RecordingCommandError.wrongSession }
        if let previous = acceptedCommands[command.id] {
            guard previous == command else { throw RecordingCommandError.intentConflict }
            // Accepted intent IDs and events are written together below.
            return events.first { $0.intentID == command.id }!
        }
        guard command.expectedVersion == events.count else { throw RecordingCommandError.staleVersion }
        guard let item = procedure.steps.first(where: { $0.id == command.targetItemID }) else {
            throw RecordingCommandError.unknownItem
        }
        if let pendingAcknowledgment {
            switch command.action {
            case .acknowledgeWarning: break
            case .correctRecord where item.id == pendingAcknowledgment.itemID: break
            default: throw RecordingCommandError.acknowledgmentPending
            }
        }
        let eventID = "recording:\(command.id)"
        let warningID = "warning:\(eventID)"
        var nextStatuses = itemStatuses
        var nextSelection = selectedItemID
        var nextWarning = pendingAcknowledgment
        let payload: SessionEventPayload
        let entry: LogEntry?
        switch command.action {
        case .selectItem:
            nextSelection = item.id
            payload = .itemSelected
            entry = nil
        case .recordConfirmation, .deferItem:
            guard item.id == selectedItemID else { throw RecordingCommandError.targetNotSelected }
            guard itemStatuses[item.id] == .unrecorded else { throw RecordingCommandError.alreadyRecorded }
            if command.action == .recordConfirmation {
                nextStatuses[item.id] = .teamConfirmed
                payload = .confirmationRecorded
                entry = LogEntry(.stepCompleted, "Team confirmation recorded: \(item.title)", at: command.issuedAt)
                let nextIndex = currentIndex + 1
                nextSelection = procedure.steps.indices.contains(nextIndex) ? procedure.steps[nextIndex].id : nil
            } else {
                nextStatuses[item.id] = .deferred
                if item.isRequired {
                    nextWarning = RequiredAcknowledgment(id: warningID, itemID: item.id, deferralEventID: eventID)
                }
                payload = .itemDeferred(acknowledgmentID: nextWarning?.id)
                entry = LogEntry(item.isRequired ? .alert : .stepSkipped,
                    "Item deferred: \(item.title)" + (item.isRequired ? ". Acknowledgment required." : ""), at: command.issuedAt)
            }
        case .acknowledgeWarning(let acknowledgment):
            guard acknowledgment == pendingAcknowledgment else { throw RecordingCommandError.acknowledgmentMismatch }
            nextWarning = nil
            payload = .warningAcknowledged(acknowledgment: acknowledgment)
            entry = LogEntry(.note, "Team acknowledged warning; item remains deferred: \(item.title)", at: command.issuedAt)
        case .correctRecord(let originalID, let newStatus, let reason):
            let latest = events.last { $0.targetItemID == item.id && $0.recordsItemStatus }
            guard latest?.id == originalID else { throw RecordingCommandError.correctionNotCurrent }
            let supersededID = pendingAcknowledgment?.id
            nextStatuses[item.id] = newStatus
            nextWarning = newStatus == .deferred && item.isRequired
                ? RequiredAcknowledgment(id: warningID, itemID: item.id, deferralEventID: eventID) : nil
            // Creating a required warning also pins its item, even when corrected from history.
            if nextWarning != nil { nextSelection = item.id }
            payload = .recordCorrected(originalEventID: originalID, newStatus: newStatus, reason: reason,
                                       supersededAcknowledgmentID: supersededID, acknowledgmentID: nextWarning?.id)
            entry = LogEntry(.note, "Record corrected: \(item.title) — \(newStatus.rawValue)" + (reason.map { ". \($0)" } ?? ""), at: command.issuedAt)
        }
        let event = SessionEvent(id: eventID, intentID: command.id, identity: identity, actor: command.actor,
            source: command.source, occurredAt: command.issuedAt, acceptedVersion: events.count + 1,
            targetItemID: item.id, payload: payload)
        try event.validate()
        let nextState = SessionRecordingState(identity: identity, templateReference: procedure.templateReference!,
            startedAt: startedAt, version: event.acceptedVersion, itemStatuses: nextStatuses,
            selectedItemID: nextSelection, pendingAcknowledgment: nextWarning)
        try nextState.validate()
        itemStatuses = nextStatuses
        selectedItemID = nextSelection
        pendingAcknowledgment = nextWarning
        acceptedCommands[command.id] = command
        events.append(event)
        if let entry { log.append(entry) }
        return event
    }

    func setReducedSupport(_ on: Bool, at time: Date = .now) {
        guard on != reducedSupport else { return }
        reducedSupport = on
        log.append(LogEntry(.modeChange, on ? "Reduced-support mode on" : "Reduced-support mode off", at: time))
    }
    func receiveRemoteMessage(_ text: String, from name: String, at time: Date = .now) {
        log.append(LogEntry(.remoteMessage, "\(name): \(text)", at: time))
    }
    /// Adds readable support history (F07) in time order. Display only: never changes recording.
    func appendSupportActivity(_ entries: [LogEntry]) {
        for entry in entries {
            let index = log.lastIndex { $0.timestamp <= entry.timestamp }.map { $0 + 1 } ?? 0
            log.insert(entry, at: index)
        }
    }
}

private extension SessionEvent {
    /// The exact command that produced this event, used to replay saved history.
    var replayCommand: SessionCommand {
        let action: SessionCommandAction
        switch payload {
        case .itemSelected: action = .selectItem
        case .confirmationRecorded: action = .recordConfirmation
        case .itemDeferred: action = .deferItem
        case .warningAcknowledged(let acknowledgment): action = .acknowledgeWarning(acknowledgment: acknowledgment)
        case .recordCorrected(let originalEventID, let newStatus, let reason, _, _):
            action = .correctRecord(originalEventID: originalEventID, newStatus: newStatus, reason: reason)
        }
        return SessionCommand(id: intentID, identity: identity, actor: actor, source: source, issuedAt: occurredAt,
                              expectedVersion: acceptedVersion - 1, targetItemID: targetItemID, action: action)
    }

    var recordsItemStatus: Bool {
        switch payload {
        case .confirmationRecorded, .itemDeferred, .recordCorrected: true
        case .itemSelected, .warningAcknowledged: false
        }
    }
}

/// A rendered control keeps its target/version/intent. First activation supplies the
/// human action time; retries keep the entire resulting command, including that time.
final class RecordingCommandActivation {
    private let captured: SessionCommand
    private var activated: SessionCommand?

    init(_ captured: SessionCommand) { self.captured = captured }

    func command(at time: Date) -> SessionCommand {
        if let activated { return activated }
        let command = SessionCommand(id: captured.id, identity: captured.identity, actor: captured.actor,
            source: captured.source, issuedAt: time, expectedVersion: captured.expectedVersion,
            targetItemID: captured.targetItemID, action: captured.action)
        activated = command
        return command
    }
}
