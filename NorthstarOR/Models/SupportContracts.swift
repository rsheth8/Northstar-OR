import Foundation

// F06 support contracts. Everything here is local to this device and fictional. A request,
// its acceptance, a question's acknowledgment and a message are separate recorded states;
// none of them means delivery, connection or clinical readiness.

/// How the named contact would support the case.
enum SupportArrangement: String, Hashable, Codable, CaseIterable {
    case inPerson, remote

    var label: String {
        switch self {
        case .inPerson: "In person"
        case .remote: "Remote"
        }
    }
}

/// The coordinator's request, answered by the named contact. Withdrawn means superseded or
/// cancelled by the coordinator.
enum SupportRequestStatus: String, Hashable, Codable, CaseIterable {
    case requested, accepted, declined, withdrawn

    var label: String {
        switch self {
        case .requested: "Requested"
        case .accepted: "Accepted"
        case .declined: "Declined"
        case .withdrawn: "Withdrawn"
        }
    }

    /// Requested or accepted: the request still stands.
    var isOpen: Bool { self == .requested || self == .accepted }
}

/// What the team had recorded when it asked a question. Built once, then never changed:
/// later recording appears only as events after `recordingVersion`.
struct SupportContextSnapshot: Hashable, Codable {
    struct ItemSnapshot: Identifiable, Hashable, Codable {
        let id: String
        let title: String
        let isRequired: Bool
        let status: RecordedItemStatus
    }

    let workspaceID: String
    let caseID: String
    let sessionID: String
    let caseReference: String?
    let caseTitle: String
    let siteName: String
    let siteTown: String
    let deviceFamily: String
    let scheduledAt: Date
    /// e.g. "Fictional pacemaker coordination, version 1".
    let templateLabel: String
    let templateReference: CoordinationTemplateReference?
    let currentItemID: String?
    let currentItemTitle: String?
    /// The deferred item awaiting the team's acknowledgment, if any.
    let pendingAcknowledgmentItemTitle: String?
    /// Every item not yet confirmed, in template order (deferred or not recorded).
    let unresolved: [ItemSnapshot]
    /// Items with a recorded team confirmation, in template order.
    let confirmed: [ItemSnapshot]
    /// The item of the most recent event that recorded a confirmation.
    let mostRecentConfirmationTitle: String?
    let arrangement: SupportArrangement
    let logisticalReason: String
    let contactName: String
    let askedByName: String
    let askedByRole: ParticipantRole
    /// Accepted session events included in this snapshot.
    let recordingVersion: Int
    let capturedAt: Date

    var deferred: [ItemSnapshot] { unresolved.filter { $0.status == .deferred } }
}

struct SupportQuestion: Identifiable, Hashable, Codable {
    let id: String
    let requestID: String
    let sessionID: String
    /// The team's exact words.
    let text: String
    let askedByName: String
    let askedByRole: ParticipantRole
    let askedAt: Date
    let snapshot: SupportContextSnapshot
    /// The contact acknowledged reading the question. Not a reply and not delivery.
    var acknowledgedAt: Date?
    var acknowledgedByName: String?

    var isAcknowledged: Bool { acknowledgedAt != nil }
}

/// A message written on this device. `isFromRep` tells the contact's messages from the team's.
struct SupportMessage: Identifiable, Hashable, Codable {
    let id: String
    let requestID: String
    let senderName: String
    let senderRole: ParticipantRole
    let isFromRep: Bool
    let text: String
    let sentAt: Date
}

struct SupportRequest: Identifiable, Hashable, Codable {
    let id: String
    let workspaceID: String
    let caseID: String
    let contactID: String
    /// The contact's name and role when requested, so history reads the same after edits.
    let contactName: String
    let contactRole: ParticipantRole
    let arrangement: SupportArrangement
    /// The coordinator's recorded logistical reason.
    let reason: String
    let requestedByName: String
    let requestedAt: Date
    var status: SupportRequestStatus
    /// When the contact accepted or declined.
    var respondedAt: Date?
    var withdrawnAt: Date?
    var questions: [SupportQuestion]
    var messages: [SupportMessage]
}

/// Plain, non-directive explanations for refused support actions.
enum SupportError: Error, Equatable, LocalizedError {
    case unknownContact(String)
    case unknownRequest(String)
    case unknownQuestion(String)
    case reasonRequired
    case textRequired
    case textTooLong
    case contactNotRemoteCapable
    case requestNotPending
    case requestNotAccepted
    case requestClosed
    case notCurrentRequest
    case notActiveCase
    case duplicateID(String)
    case contactInUse(String)

    static let maximumTextLength = 2000

    var errorDescription: String? {
        switch self {
        case .unknownContact: "This contact is not in the workspace."
        case .unknownRequest: "This support request is not on this device."
        case .unknownQuestion: "This question is not part of the support request."
        case .reasonRequired: "Add the logistical reason for this request."
        case .textRequired: "Write a message first."
        case .textTooLong: "This message is too long. Shorten it and try again."
        case .contactNotRemoteCapable: "This contact is not set up for remote support. Choose in person or another contact."
        case .requestNotPending: "This request has already been answered."
        case .requestNotAccepted: "The contact has not accepted this request yet."
        case .requestClosed: "This request was declined or withdrawn. Request support again to continue."
        case .notCurrentRequest: "This is no longer the current request for the case."
        case .notActiveCase: "Questions can be asked from the case being recorded. Resume this case first."
        case .duplicateID: "This support entry already exists with different content."
        case .contactInUse: "This contact has support requests on a saved case, so it can't be removed."
        }
    }
}

/// One support change. Local commands produce these, apply them with `applying(to:)`, then
/// broadcast them through `SyncService`, so a later transport can deliver the same values.
enum SupportChange: Hashable, Codable {
    /// A new request; any open request for the same case is withdrawn at the same time.
    case requested(SupportRequest)
    case responded(requestID: String, accepted: Bool, at: Date)
    case withdrawn(requestID: String, at: Date)
    case questionAsked(SupportQuestion)
    case questionAcknowledged(requestID: String, questionID: String, byName: String, at: Date)
    case messageSent(SupportMessage)

    var requestID: String {
        switch self {
        case .requested(let request): request.id
        case .responded(let id, _, _), .withdrawn(let id, _), .questionAcknowledged(let id, _, _, _): id
        case .questionAsked(let question): question.requestID
        case .messageSent(let message): message.requestID
        }
    }

    /// State transitions only; workspace, contact and session checks happen in `AppModel`.
    /// Repeating an identical change returns the same requests (idempotent); a conflicting
    /// reuse of an ID throws.
    func applying(to requests: [SupportRequest]) throws -> [SupportRequest] {
        var next = requests
        if case .requested(let request) = self {
            if let existing = next.first(where: { $0.id == request.id }) {
                // Same request seen again (possibly after later changes): nothing to do.
                guard existing.contactID == request.contactID, existing.caseID == request.caseID,
                      existing.arrangement == request.arrangement, existing.reason == request.reason,
                      existing.requestedAt == request.requestedAt else { throw SupportError.duplicateID(request.id) }
                return next
            }
            for index in next.indices where next[index].caseID == request.caseID && next[index].status.isOpen {
                next[index].status = .withdrawn
                next[index].withdrawnAt = request.requestedAt
            }
            next.append(request)
            return next
        }
        guard let index = next.firstIndex(where: { $0.id == requestID }) else { throw SupportError.unknownRequest(requestID) }
        var request = next[index]
        switch self {
        case .requested:
            break
        case .responded(_, let accepted, let time):
            let answer: SupportRequestStatus = accepted ? .accepted : .declined
            if request.status == answer { return next }
            guard request.status == .requested else {
                throw request.status == .withdrawn ? SupportError.requestClosed : SupportError.requestNotPending
            }
            request.status = answer
            request.respondedAt = time
        case .withdrawn(_, let time):
            if request.status == .withdrawn { return next }
            guard request.status.isOpen else { throw SupportError.requestClosed }
            request.status = .withdrawn
            request.withdrawnAt = time
        case .questionAsked(let question):
            if let existing = request.questions.first(where: { $0.id == question.id }) {
                guard existing.text == question.text, existing.askedAt == question.askedAt else {
                    throw SupportError.duplicateID(question.id)
                }
                return next
            }
            try request.requireAccepted()
            request.questions.append(question)
        case .questionAcknowledged(_, let questionID, let name, let time):
            guard let q = request.questions.firstIndex(where: { $0.id == questionID }) else {
                throw SupportError.unknownQuestion(questionID)
            }
            if request.questions[q].isAcknowledged { return next }
            try request.requireAccepted()
            request.questions[q].acknowledgedAt = time
            request.questions[q].acknowledgedByName = name
        case .messageSent(let message):
            if let existing = request.messages.first(where: { $0.id == message.id }) {
                guard existing == message else { throw SupportError.duplicateID(message.id) }
                return next
            }
            try request.requireAccepted()
            request.messages.append(message)
        }
        next[index] = request
        return next
    }
}

private extension SupportRequest {
    func requireAccepted() throws {
        switch status {
        case .accepted: return
        case .requested: throw SupportError.requestNotAccepted
        case .declined, .withdrawn: throw SupportError.requestClosed
        }
    }
}

// MARK: - Readable activity for the Co-pilot log

extension SupportRequest {
    /// Team-visible support history as log entries, oldest first. Rebuilt from the stored
    /// request after relaunch, so the session log shows the same support history.
    var activityEntries: [LogEntry] {
        var entries = [SupportActivity.requested(self)]
        // Only a response sets respondedAt; a declined request is never withdrawn afterwards.
        if let respondedAt {
            entries.append(SupportActivity.responded(self, accepted: status != .declined, at: respondedAt))
        }
        for question in questions {
            entries.append(SupportActivity.asked(question, contactName: contactName))
            if let at = question.acknowledgedAt {
                entries.append(SupportActivity.acknowledged(question, contactName: contactName, at: at))
            }
        }
        for message in messages { entries.append(SupportActivity.message(message, contactName: contactName)) }
        if let withdrawnAt { entries.append(SupportActivity.withdrawn(self, at: withdrawnAt)) }
        return entries.sorted { $0.timestamp < $1.timestamp }
    }
}

enum SupportActivity {
    static func requested(_ request: SupportRequest) -> LogEntry {
        LogEntry(.note, "Support requested from \(request.contactName) (\(request.arrangement.label.lowercased())). On this device.",
                 at: request.requestedAt)
    }

    static func responded(_ request: SupportRequest, accepted: Bool, at time: Date) -> LogEntry {
        LogEntry(.note, "\(request.contactName) \(accepted ? "accepted" : "declined") the support request.", at: time)
    }

    static func withdrawn(_ request: SupportRequest, at time: Date) -> LogEntry {
        LogEntry(.note, "Support request to \(request.contactName) withdrawn.", at: time)
    }

    static func asked(_ question: SupportQuestion, contactName: String) -> LogEntry {
        LogEntry(.note, "Question for \(contactName) from \(question.askedByName): \(question.text)", at: question.askedAt)
    }

    static func acknowledged(_ question: SupportQuestion, contactName: String, at time: Date) -> LogEntry {
        LogEntry(.note, "\(question.acknowledgedByName ?? contactName) acknowledged the question.", at: time)
    }

    /// Contact messages use `.remoteMessage` so Co-pilot shows them as incoming replies.
    static func message(_ message: SupportMessage, contactName: String) -> LogEntry {
        message.isFromRep
            ? LogEntry(.remoteMessage, "\(message.senderName): \(message.text)", at: message.sentAt)
            : LogEntry(.note, "\(message.senderName) to \(contactName): \(message.text)", at: message.sentAt)
    }
}
