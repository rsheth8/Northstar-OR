import Foundation

/// A new run gets a new sessionID even when workspace/case stay the same.
struct SessionIdentity: Hashable, Codable {
    let workspaceID: String
    let caseID: String
    let sessionID: String

    func validate() throws {
        try requireSessionValue(workspaceID, "session.workspaceID")
        try requireSessionValue(caseID, "session.caseID")
        try requireSessionValue(sessionID, "session.sessionID")
    }
}

/// How an explicit human command entered the app, not evidence of delivery or identity.
enum RecordingInputSource: String, Codable, CaseIterable {
    case touch, keyboard, voice, remote

    var label: String {
        switch self {
        case .touch: "Touch"
        case .keyboard: "Keyboard"
        case .voice: "Voice"
        case .remote: "Remote command"
        }
    }
}

/// Recorded workflow only; neither selection nor clinical readiness is a status.
enum RecordedItemStatus: String, Hashable, Codable {
    case unrecorded, deferred, teamConfirmed
}

/// The warning's identity is distinct from the item and the event that deferred it.
/// A correction that records deferral can also be the triggering deferralEventID.
struct RequiredAcknowledgment: Identifiable, Hashable, Codable {
    let id: String
    let itemID: String
    let deferralEventID: String

    func validate() throws {
        try requireSessionValue(id, "acknowledgment.id")
        try requireSessionValue(itemID, "acknowledgment.itemID")
        try requireSessionValue(deferralEventID, "acknowledgment.deferralEventID")
    }
}

enum SessionContractError: Error, Equatable {
    case required(String)
    case unsupportedSchemaVersion(Int)
    case invalidVersion
    case invalidTimestamp
    case foreignActor
    case invalidTemplateReference
    case emptyItems
    case unknownItem(String)
    case inconsistentAcknowledgment
    case targetMismatch
    case selfReferencingEvent
}

/// Codable state for F05/F18; this is not a second live store or a replay engine.
/// Unknown template pins are retained; the authoritative catalog must authorize recording.
/// Directly constructed values require validate(); decoding validates automatically.
struct SessionRecordingState: Hashable, Codable {
    static let supportedSchemaVersion = 1
    let identity: SessionIdentity
    let templateReference: CoordinationTemplateReference
    let startedAt: Date
    /// Accepted session sequence. Zero is the initial state; timestamps are not causal order.
    let version: Int
    let itemStatuses: [String: RecordedItemStatus]
    let selectedItemID: String?
    let pendingAcknowledgment: RequiredAcknowledgment?
    var endedAt: Date? = nil
    private(set) var schemaVersion: Int = supportedSchemaVersion

    func validate() throws {
        try validateSessionSchema(schemaVersion)
        try identity.validate()
        guard version >= 0 else { throw SessionContractError.invalidVersion }
        try validateSessionTime(startedAt)
        guard !templateReference.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              templateReference.version > 0 else { throw SessionContractError.invalidTemplateReference }
        guard !itemStatuses.isEmpty else { throw SessionContractError.emptyItems }
        for itemID in itemStatuses.keys { try requireSessionValue(itemID, "item.id") }
        if let selectedItemID {
            try requireSessionValue(selectedItemID, "selectedItemID")
            guard itemStatuses[selectedItemID] != nil else { throw SessionContractError.unknownItem(selectedItemID) }
        }
        if let endedAt { try validateSessionTime(endedAt); guard pendingAcknowledgment == nil else { throw SessionContractError.inconsistentAcknowledgment } }
        if let pendingAcknowledgment {
            try pendingAcknowledgment.validate()
            guard selectedItemID == pendingAcknowledgment.itemID,
                  itemStatuses[pendingAcknowledgment.itemID] == .deferred else {
                throw SessionContractError.inconsistentAcknowledgment
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, identity, templateReference, startedAt, version, itemStatuses, selectedItemID, pendingAcknowledgment, endedAt
    }
}

extension SessionRecordingState {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        try validateSessionSchema(schemaVersion)
        identity = try values.decode(SessionIdentity.self, forKey: .identity)
        templateReference = try values.decode(CoordinationTemplateReference.self, forKey: .templateReference)
        startedAt = try values.decode(Date.self, forKey: .startedAt)
        version = try values.decode(Int.self, forKey: .version)
        itemStatuses = try values.decode([String: RecordedItemStatus].self, forKey: .itemStatuses)
        selectedItemID = try values.decodeIfPresent(String.self, forKey: .selectedItemID)
        pendingAcknowledgment = try values.decodeIfPresent(RequiredAcknowledgment.self, forKey: .pendingAcknowledgment)
        endedAt = try values.decodeIfPresent(Date.self, forKey: .endedAt)
        try validate()
    }
}

enum SessionCommandAction: Hashable, Codable {
    case endRecording, reopenRecording
    case selectItem
    case recordConfirmation
    case deferItem
    case acknowledgeWarning(acknowledgment: RequiredAcknowledgment)
    case correctRecord(originalEventID: String, newStatus: RecordedItemStatus, reason: String?)
}

/// Captured against the displayed target/version. Never retarget this to the next item.
/// Structural validation does not apply the command, deduplicate it, or authorize its actor.
/// F05 checks the current session/version/target, pending gate and prior-event references.
struct SessionCommand: Identifiable, Hashable, Codable {
    static let supportedSchemaVersion = 1
    /// Stable intent ID; retries reuse it and deliberately new actions get a new ID.
    let id: String
    let identity: SessionIdentity
    /// Immutable value snapshot of a stated local participant; not authentication.
    let actor: LocalParticipant
    let source: RecordingInputSource
    let issuedAt: Date
    let expectedVersion: Int
    let targetItemID: String
    let action: SessionCommandAction
    private(set) var schemaVersion: Int = supportedSchemaVersion

    func validate() throws {
        try validateSessionSchema(schemaVersion)
        try requireSessionValue(id, "command.id")
        try validateSessionContext(identity, actor: actor, target: targetItemID, time: issuedAt)
        guard expectedVersion >= 0 else { throw SessionContractError.invalidVersion }
        switch action {
        case .selectItem, .recordConfirmation, .deferItem, .endRecording, .reopenRecording: break
        case .acknowledgeWarning(let acknowledgment):
            try acknowledgment.validate()
            guard acknowledgment.itemID == targetItemID else { throw SessionContractError.targetMismatch }
        case .correctRecord(let originalEventID, _, let reason):
            try validateSessionCorrection(originalEventID, reason: reason)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, id, identity, actor, source, issuedAt, expectedVersion, targetItemID, action
    }
}

extension SessionCommand {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        try validateSessionSchema(schemaVersion)
        id = try values.decode(String.self, forKey: .id)
        identity = try values.decode(SessionIdentity.self, forKey: .identity)
        actor = try values.decode(LocalParticipant.self, forKey: .actor)
        source = try values.decode(RecordingInputSource.self, forKey: .source)
        issuedAt = try values.decode(Date.self, forKey: .issuedAt)
        expectedVersion = try values.decode(Int.self, forKey: .expectedVersion)
        targetItemID = try values.decode(String.self, forKey: .targetItemID)
        action = try values.decode(SessionCommandAction.self, forKey: .action)
        try validate()
    }
}

enum SessionEventPayload: Hashable, Codable {
    case recordingEnded, recordingReopened
    case itemSelected
    case confirmationRecorded
    case itemDeferred(acknowledgmentID: String?)
    /// Records that the warning was seen; does not change the deferred item status.
    case warningAcknowledged(acknowledgment: RequiredAcknowledgment)
    /// Old history remains. Supersession is explicit and is never an acknowledgment.
    /// A correction to required deferred status can establish a fresh warning identity.
    case recordCorrected(originalEventID: String, newStatus: RecordedItemStatus, reason: String?,
                         supersededAcknowledgmentID: String?, acknowledgmentID: String? = nil)
}

/// One accepted recording/selection event, ordered by the session authority's sequence.
/// All payloads here originate in explicit human intents; F06 supplies support contracts.
/// Metadata and payload are value snapshots, not references to the current view/model.
struct SessionEvent: Identifiable, Hashable, Codable {
    static let supportedSchemaVersion = 1
    let id: String
    let intentID: String
    let identity: SessionIdentity
    let actor: LocalParticipant
    let source: RecordingInputSource
    let occurredAt: Date
    let acceptedVersion: Int
    let targetItemID: String
    let payload: SessionEventPayload
    private(set) var schemaVersion: Int = supportedSchemaVersion

    func validate() throws {
        try validateSessionSchema(schemaVersion)
        try requireSessionValue(id, "event.id")
        try requireSessionValue(intentID, "event.intentID")
        try validateSessionContext(identity, actor: actor, target: targetItemID, time: occurredAt)
        guard acceptedVersion > 0 else { throw SessionContractError.invalidVersion }
        switch payload {
        case .itemSelected, .confirmationRecorded, .recordingEnded, .recordingReopened: break
        case .itemDeferred(let acknowledgmentID):
            if let acknowledgmentID { try requireSessionValue(acknowledgmentID, "acknowledgment.id") }
        case .warningAcknowledged(let acknowledgment):
            try acknowledgment.validate()
            guard acknowledgment.itemID == targetItemID else { throw SessionContractError.targetMismatch }
            guard acknowledgment.deferralEventID != id else { throw SessionContractError.selfReferencingEvent }
        case .recordCorrected(let originalEventID, let newStatus, let reason, let supersededID, let acknowledgmentID):
            try validateSessionCorrection(originalEventID, reason: reason)
            guard originalEventID != id else { throw SessionContractError.selfReferencingEvent }
            if let supersededID { try requireSessionValue(supersededID, "correction.supersededAcknowledgmentID") }
            if let acknowledgmentID {
                try requireSessionValue(acknowledgmentID, "acknowledgment.id")
                guard newStatus == .deferred, acknowledgmentID != supersededID else {
                    throw SessionContractError.inconsistentAcknowledgment
                }
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, id, intentID, identity, actor, source, occurredAt, acceptedVersion, targetItemID, payload
    }
}

extension SessionEvent {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        try validateSessionSchema(schemaVersion)
        id = try values.decode(String.self, forKey: .id)
        intentID = try values.decode(String.self, forKey: .intentID)
        identity = try values.decode(SessionIdentity.self, forKey: .identity)
        actor = try values.decode(LocalParticipant.self, forKey: .actor)
        source = try values.decode(RecordingInputSource.self, forKey: .source)
        occurredAt = try values.decode(Date.self, forKey: .occurredAt)
        acceptedVersion = try values.decode(Int.self, forKey: .acceptedVersion)
        targetItemID = try values.decode(String.self, forKey: .targetItemID)
        payload = try values.decode(SessionEventPayload.self, forKey: .payload)
        try validate()
    }
}

private func requireSessionValue(_ value: String, _ field: String) throws {
    guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw SessionContractError.required(field)
    }
}

private func validateSessionSchema(_ version: Int) throws {
    guard version == 1 else { throw SessionContractError.unsupportedSchemaVersion(version) }
}

private func validateSessionTime(_ time: Date) throws {
    guard time.timeIntervalSinceReferenceDate.isFinite else { throw SessionContractError.invalidTimestamp }
}

private func validateSessionContext(_ identity: SessionIdentity, actor: LocalParticipant, target: String, time: Date) throws {
    try identity.validate()
    try requireSessionValue(actor.id, "actor.id")
    try requireSessionValue(actor.displayName, "actor.displayName")
    guard actor.workspaceID == identity.workspaceID else { throw SessionContractError.foreignActor }
    try requireSessionValue(target, "targetItemID")
    try validateSessionTime(time)
}

private func validateSessionCorrection(_ originalEventID: String, reason: String?) throws {
    try requireSessionValue(originalEventID, "correction.originalEventID")
    if let reason { try requireSessionValue(reason, "correction.reason") }
}
