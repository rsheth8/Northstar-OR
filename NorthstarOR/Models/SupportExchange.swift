import Foundation

struct ChecklistLineSnapshot: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let status: RecordedItemStatus
    let normallyCoveredByRep: Bool
}

/// A value copy of coordination context. No field grants permission to record a case.
struct SupportContextSnapshot: Hashable, Codable {
    var capturedAt: Date
    var caseReference: String
    var caseName: String
    var siteName: String
    var deviceFamily: String
    var templateID: String
    var templateVersion: Int
    var selectedItemID: String?
    var selectedItemTitle: String?
    var reducedSupport: Bool
    var logisticalReason: String?
    var lines: [ChecklistLineSnapshot]
    var recentEvents: [String]
    var recordingRevision: Int
    var acknowledgmentIDs: [String]

    fileprivate var isValid: Bool {
        !caseReference.supportBlank && !templateID.supportBlank && templateVersion > 0 && recordingRevision >= 0 &&
        !lines.isEmpty && Set(lines.map(\.id)).count == lines.count &&
        lines.allSatisfy { !$0.id.supportBlank && !$0.title.supportBlank } &&
        Set(acknowledgmentIDs).count == acknowledgmentIDs.count && acknowledgmentIDs.allSatisfy { !$0.supportBlank } &&
        (selectedItemID == nil || lines.contains { $0.id == selectedItemID }) &&
        ((selectedItemID == nil) == (selectedItemTitle == nil))
    }
}

/// The source room's identity, even when retained in another workspace.
struct SupportOrigin: Hashable, Codable {
    let workspaceID: String
    let caseID: String
    let sessionID: String
    fileprivate var isValid: Bool { [workspaceID, caseID, sessionID].allSatisfy { !$0.supportBlank } }
}

enum SupportDelivery: String, Codable, Hashable {
    case onThisDevice, waitingForPeer, receivedByPeer, failed
}

struct QuestionAcknowledgement: Identifiable, Hashable, Codable {
    let id: String
    let questionID: String
    let actor: LocalParticipant
    let at: Date
    fileprivate(set) var delivery: SupportDelivery = .onThisDevice
    var by: String { actor.displayName }
}

struct SessionNote: Identifiable, Hashable, Codable {
    let id: String
    let workspaceID: String
    let caseID: String
    let sessionID: String
    let text: String
    let actor: LocalParticipant
    let sentAt: Date
    fileprivate(set) var delivery: SupportDelivery = .onThisDevice

    var origin: SupportOrigin { .init(workspaceID: workspaceID, caseID: caseID, sessionID: sessionID) }
    var messageID: String {
        [workspaceID, caseID, sessionID, id].map { "\($0.utf8.count):\($0)" }.joined() + ":note"
    }

    static func make(id: String, workspaceID: String, caseID: String, sessionID: String, text: String,
                     actor: LocalParticipant, sentAt: Date) throws -> SessionNote {
        guard !text.supportBlank else { throw SupportExchangeError.blankQuestion }
        let note = SessionNote(id: id, workspaceID: workspaceID, caseID: caseID, sessionID: sessionID,
                               text: text.trimmingCharacters(in: .whitespacesAndNewlines), actor: actor, sentAt: sentAt)
        guard note.isValid else { throw SupportExchangeError.invalidIdentityOrContext }
        return note
    }

    fileprivate var isValid: Bool { origin.isValid && !id.supportBlank && !text.supportBlank && actor.supportValid }
}

struct SupportReply: Identifiable, Hashable, Codable {
    let id: String
    let questionID: String
    let text: String
    let actor: LocalParticipant
    let at: Date
    fileprivate(set) var delivery: SupportDelivery = .onThisDevice
    var from: String { actor.displayName }
}

struct SupportQuestion: Identifiable, Hashable, Codable {
    let id: String
    let workspaceID: String
    let caseID: String
    let sessionID: String
    let text: String
    let sender: LocalParticipant
    let recipientContactID: String
    let recipientName: String
    let sentAt: Date
    let snapshot: SupportContextSnapshot
    fileprivate(set) var acknowledgement: QuestionAcknowledgement?
    fileprivate(set) var reply: SupportReply?
    fileprivate(set) var delivery: SupportDelivery = .onThisDevice

    var origin: SupportOrigin { .init(workspaceID: workspaceID, caseID: caseID, sessionID: sessionID) }
    /// Length-prefixed components prevent ambiguous identities across origins or question IDs.
    var messageID: String {
        [workspaceID, caseID, sessionID, id].map { "\($0.utf8.count):\($0)" }.joined() + ":question"
    }
    var acknowledgementMessageID: String { messageID + ":ack" }
    var replyMessageID: String { messageID + ":reply" }
    var questionAcknowledgedAt: Date? { acknowledgement?.at }
    var questionAcknowledgedBy: String? { acknowledgement?.by }
    var replyText: String? { reply?.text }
    var replyAt: Date? { reply?.at }
    var replySenderName: String? { reply?.from }

    static func make(id: String, workspaceID: String, caseID: String, sessionID: String, text: String,
                     sender: LocalParticipant, recipientContactID: String, recipientName: String,
                     sentAt: Date, snapshot: SupportContextSnapshot) throws -> SupportQuestion {
        guard !text.supportBlank else { throw SupportExchangeError.blankQuestion }
        let question = Self(id: id, workspaceID: workspaceID, caseID: caseID, sessionID: sessionID,
                            text: text.trimmingCharacters(in: .whitespacesAndNewlines), sender: sender,
                            recipientContactID: recipientContactID, recipientName: recipientName,
                            sentAt: sentAt, snapshot: snapshot)
        guard question.isValid else { throw SupportExchangeError.invalidIdentityOrContext }
        return question
    }

    fileprivate var isValid: Bool {
        origin.isValid && !id.supportBlank && !text.supportBlank && !recipientContactID.supportBlank &&
        !recipientName.supportBlank && sender.supportValid && sender.workspaceID == workspaceID && snapshot.isValid
    }
    fileprivate var brief: SupportQuestion {
        var copy = self
        copy.acknowledgement = nil
        copy.reply = nil
        copy.delivery = .onThisDevice
        return copy
    }
    var acknowledgementEnvelope: SupportEnvelope? {
        acknowledgement.map { .init(id: $0.id, kind: .questionAcknowledgement, sentAt: $0.at,
                                    origin: origin, questionID: id, acknowledgement: $0) }
    }
    var replyEnvelope: SupportEnvelope? {
        reply.map { .init(id: $0.id, kind: .reply, sentAt: $0.at, origin: origin, questionID: id, reply: $0) }
    }
}

enum SupportEnvelopeKind: String, Hashable, Codable {
    case question, questionAcknowledgement, reply, contextUpdate, receipt, note
}

/// Exactly one payload is allowed; receipts carry only receiptForID. Decoding is not validation.
struct SupportEnvelope: Identifiable, Hashable, Codable {
    let id: String
    let kind: SupportEnvelopeKind
    let sentAt: Date
    let origin: SupportOrigin
    let questionID: String
    var question: SupportQuestion? = nil
    var acknowledgement: QuestionAcknowledgement? = nil
    var reply: SupportReply? = nil
    var context: SupportContextSnapshot? = nil
    var receiptForID: String? = nil
    var note: SessionNote? = nil

    static func question(_ question: SupportQuestion) -> Self {
        .init(id: question.messageID, kind: .question, sentAt: question.sentAt,
              origin: question.origin, questionID: question.id, question: question.brief)
    }
    static func context(_ context: SupportContextSnapshot, for question: SupportQuestion) -> Self {
        .init(id: question.messageID + ":context:\(context.recordingRevision)", kind: .contextUpdate,
              sentAt: context.capturedAt, origin: question.origin, questionID: question.id, context: context)
    }
    /// Call only for a result whose receiptForID is nonnil; never receipt a receipt.
    static func note(_ note: SessionNote) -> Self {
        .init(id: note.messageID, kind: .note, sentAt: note.sentAt, origin: note.origin, questionID: note.id, note: note)
    }
    static func receipt(for envelope: Self, at time: Date = Date()) -> Self {
        .init(id: envelope.id + ":receipt", kind: .receipt, sentAt: time,
              origin: envelope.origin, questionID: envelope.questionID, receiptForID: envelope.id)
    }
}

struct SupportInbox: Equatable, Codable {
    var questions: [SupportQuestion] = []
    var liveContext: [SupportOrigin: SupportContextSnapshot] = [:]
    var messages: [SessionNote] = []
}

struct SupportThreadEntry: Identifiable, Equatable {
    let id: String
    let at: Date
    let title: String
    let text: String
    let delivery: SupportDelivery?
}

struct SupportApplyResult: Equatable {
    let inbox: SupportInbox
    let accepted: Bool
    /// Exact successfully applied message, including an identical replay; nil for rejection or receipts.
    let receiptForID: String?
}

enum SupportExchangeError: Error, Equatable {
    case blankQuestion, invalidIdentityOrContext, blankReply, conflictingMessage, unknownMessage
}

enum SupportExchange {
    static func acknowledge(_ question: SupportQuestion, by actor: LocalParticipant, at time: Date) throws -> SupportQuestion {
        guard question.isValid && actor.supportValid else { throw SupportExchangeError.invalidIdentityOrContext }
        let ack = QuestionAcknowledgement(id: question.acknowledgementMessageID, questionID: question.id, actor: actor, at: time)
        if let existing = question.acknowledgement {
            guard sameAcknowledgement(existing, ack) else { throw SupportExchangeError.conflictingMessage }
            return question
        }
        var copy = question
        copy.acknowledgement = ack
        return copy
    }

    static func reply(_ question: SupportQuestion, text: String, from actor: LocalParticipant, at time: Date) throws -> SupportQuestion {
        guard !text.supportBlank else { throw SupportExchangeError.blankReply }
        guard question.isValid && actor.supportValid else { throw SupportExchangeError.invalidIdentityOrContext }
        let reply = SupportReply(id: question.replyMessageID, questionID: question.id,
                                 text: text.trimmingCharacters(in: .whitespacesAndNewlines), actor: actor, at: time)
        if let existing = question.reply {
            guard sameReply(existing, reply) else { throw SupportExchangeError.conflictingMessage }
            return question
        }
        var copy = question
        copy.reply = reply
        return copy
    }

    /// Counts added, removed or changed statuses by ID. Warning acknowledgments are context, not item state.
    static func changedLineCount(snapshot: SupportContextSnapshot, live: SupportContextSnapshot) -> Int {
        let before = Dictionary(snapshot.lines.map { ($0.id, $0.status) }, uniquingKeysWith: { first, _ in first })
        let after = Dictionary(live.lines.map { ($0.id, $0.status) }, uniquingKeysWith: { first, _ in first })
        return Set(before.keys).union(after.keys).filter { before[$0] != after[$0] }.count
    }

    /// Explicit delivery attempts reuse the retained message. Received is terminal; local work never calls this implicitly.
    static func markDelivery(messageID: String, delivery: SupportDelivery, in inbox: SupportInbox) throws -> SupportInbox {
        var next = inbox
        let noteIndices = next.messages.indices.filter { next.messages[$0].messageID == messageID }
        let indices = next.questions.indices.filter {
            let question = next.questions[$0]
            return question.messageID == messageID || question.acknowledgement?.id == messageID || question.reply?.id == messageID
        }
        if noteIndices.count == 1, indices.isEmpty, let noteIndex = noteIndices.first {
            if next.messages[noteIndex].delivery != .receivedByPeer { next.messages[noteIndex].delivery = delivery }
            return next
        }
        guard indices.count == 1, noteIndices.isEmpty, let index = indices.first else { throw SupportExchangeError.unknownMessage }
        if next.questions[index].messageID == messageID {
            if next.questions[index].delivery != .receivedByPeer { next.questions[index].delivery = delivery }
        } else if next.questions[index].acknowledgement?.id == messageID {
            if next.questions[index].acknowledgement?.delivery != .receivedByPeer { next.questions[index].acknowledgement?.delivery = delivery }
        } else if next.questions[index].reply?.delivery != .receivedByPeer {
            next.questions[index].reply?.delivery = delivery
        }
        return next
    }

    /// `current == nil` accepts self-contained incoming briefs without importing their case.
    /// Non-nil gates new questions, not responses for known retained questions from inactive sessions.
    static func apply(_ envelope: SupportEnvelope, to inbox: SupportInbox, current: SupportOrigin?) -> SupportApplyResult {
        let rejected = SupportApplyResult(inbox: inbox, accepted: false, receiptForID: nil)
        guard envelope.origin.isValid, !envelope.id.supportBlank, !envelope.questionID.supportBlank else { return rejected }
        let payloadCount = [envelope.question != nil, envelope.acknowledgement != nil, envelope.reply != nil,
                            envelope.context != nil, envelope.receiptForID != nil, envelope.note != nil].filter { $0 }.count
        guard payloadCount == 1 else { return rejected }
        if envelope.kind == .note {
            guard let note = envelope.note, note.isValid, note.origin == envelope.origin, note.id == envelope.questionID,
                  note.messageID == envelope.id, note.sentAt == envelope.sentAt else { return rejected }
            if let existing = inbox.messages.first(where: { $0.id == note.id || $0.messageID == note.messageID }) {
                guard sameNote(existing, note) else { return rejected }
                return .init(inbox: inbox, accepted: true, receiptForID: envelope.id)
            }
            guard current == nil || current == note.origin else { return rejected }
            var stored = note
            stored.delivery = .onThisDevice
            var inserted = inbox
            inserted.messages.append(stored)
            return .init(inbox: inserted, accepted: true, receiptForID: envelope.id)
        }
        if envelope.kind == .receipt, let target = envelope.receiptForID, envelope.id == target + ":receipt" {
            let noteIndices = inbox.messages.indices.filter { inbox.messages[$0].messageID == target }
            if noteIndices.count == 1, let noteIndex = noteIndices.first, inbox.messages[noteIndex].origin == envelope.origin {
                guard inbox.messages[noteIndex].delivery != .onThisDevice,
                      let updated = try? markDelivery(messageID: target, delivery: .receivedByPeer, in: inbox) else { return rejected }
                return .init(inbox: updated, accepted: true, receiptForID: nil)
            }
            if noteIndices.count > 1 { return rejected }
        }
        // Ambiguous retained IDs are never routed by first match.
        let indices = inbox.questions.indices.filter { inbox.questions[$0].id == envelope.questionID }
        guard indices.count <= 1 else { return rejected }
        var next = inbox
        if envelope.kind == .question {
            guard let q = envelope.question, q.isValid, q.acknowledgement == nil, q.reply == nil,
                  q.origin == envelope.origin, q.id == envelope.questionID, q.messageID == envelope.id,
                  q.sentAt == envelope.sentAt else { return rejected }
            if let index = indices.first {
                guard inbox.questions[index].brief == q.brief else { return rejected }
            } else {
                guard current == nil || current == q.origin else { return rejected }
                next.questions.append(q.brief)
            }
            // Context is shared by origin: a later brief establishes a floor for every question in that run.
            if let cached = next.liveContext[q.origin],
               next.questions.contains(where: { $0.origin == q.origin && $0.snapshot.recordingRevision > cached.recordingRevision }) {
                next.liveContext[q.origin] = nil
            }
        } else {
            guard let index = indices.first, inbox.questions[index].origin == envelope.origin else { return rejected }
            let q = inbox.questions[index]
            switch envelope.kind {
            case .question, .note: return rejected
            case .questionAcknowledgement:
                guard let ack = envelope.acknowledgement, ack.id == q.acknowledgementMessageID,
                      ack.id == envelope.id, ack.questionID == q.id, ack.actor.supportValid, ack.at == envelope.sentAt,
                      q.acknowledgement == nil || sameAcknowledgement(q.acknowledgement!, ack) else { return rejected }
                if q.acknowledgement == nil {
                    var local = ack
                    local.delivery = .onThisDevice
                    next.questions[index].acknowledgement = local
                }
            case .reply:
                guard let reply = envelope.reply, reply.id == q.replyMessageID, reply.id == envelope.id,
                      reply.questionID == q.id, reply.actor.supportValid, !reply.text.supportBlank, reply.at == envelope.sentAt,
                      q.reply == nil || sameReply(q.reply!, reply) else { return rejected }
                if q.reply == nil {
                    var local = reply
                    local.delivery = .onThisDevice
                    next.questions[index].reply = local
                }
            case .contextUpdate:
                guard let context = envelope.context, context.isValid,
                      envelope.id == q.messageID + ":context:\(context.recordingRevision)",
                      envelope.sentAt == context.capturedAt,
                      context.caseReference == q.snapshot.caseReference,
                      context.templateID == q.snapshot.templateID, context.templateVersion == q.snapshot.templateVersion,
                      context.lines.map(\.id) == q.snapshot.lines.map(\.id) else { return rejected }
                let retainedSnapshots = inbox.questions.filter { $0.origin == q.origin }.map(\.snapshot)
                guard retainedSnapshots.allSatisfy({
                    context.recordingRevision > $0.recordingRevision || context == $0
                }) else { return rejected }
                if let previous = inbox.liveContext[q.origin] {
                    guard context.recordingRevision > previous.recordingRevision || context == previous else { return rejected }
                }
                next.liveContext[q.origin] = context
            case .receipt:
                guard let target = envelope.receiptForID, envelope.id == target + ":receipt" else { return rejected }
                let delivery: SupportDelivery?
                if target == q.messageID { delivery = q.delivery }
                else if target == q.acknowledgement?.id { delivery = q.acknowledgement?.delivery }
                else if target == q.reply?.id { delivery = q.reply?.delivery }
                else { return rejected }
                guard let delivery, delivery != .onThisDevice,
                      let updated = try? markDelivery(messageID: target, delivery: .receivedByPeer, in: next) else { return rejected }
                next = updated
            }
        }
        return .init(inbox: next, accepted: true, receiptForID: envelope.kind == .receipt ? nil : envelope.id)
    }

    /// Questions stay first-class. Plain messages share the same time order and never change a checklist line.
    static func thread(questions: [SupportQuestion], notes: [SessionNote], sessionID: String) -> [SupportThreadEntry] {
        var ranked: [(SupportThreadEntry, Int)] = []
        for question in questions where question.sessionID == sessionID {
            ranked.append((.init(id: question.messageID, at: question.sentAt, title: "Team question", text: question.text, delivery: question.delivery), 0))
            if let ack = question.acknowledgement {
                ranked.append((.init(id: ack.id, at: ack.at, title: "Acknowledged by \(ack.by)", text: "Question acknowledged", delivery: ack.delivery), 1))
            }
            if let reply = question.reply {
                ranked.append((.init(id: reply.id, at: reply.at, title: "Reply from \(reply.from)", text: reply.text, delivery: reply.delivery), 2))
            }
        }
        for note in notes where note.sessionID == sessionID {
            ranked.append((.init(id: note.messageID, at: note.sentAt, title: note.actor.displayName, text: note.text, delivery: note.delivery), 3))
        }
        return ranked.sorted {
            ($0.0.at, $0.1, $0.0.id) < ($1.0.at, $1.1, $1.0.id)
        }.map(\.0)
    }

    private static func sameAcknowledgement(_ lhs: QuestionAcknowledgement, _ rhs: QuestionAcknowledgement) -> Bool {
        lhs.id == rhs.id && lhs.questionID == rhs.questionID && lhs.actor == rhs.actor && lhs.at == rhs.at
    }
    private static func sameReply(_ lhs: SupportReply, _ rhs: SupportReply) -> Bool {
        lhs.id == rhs.id && lhs.questionID == rhs.questionID && lhs.text == rhs.text && lhs.actor == rhs.actor && lhs.at == rhs.at
    }
    private static func sameNote(_ lhs: SessionNote, _ rhs: SessionNote) -> Bool {
        lhs.id == rhs.id && lhs.origin == rhs.origin && lhs.text == rhs.text && lhs.actor == rhs.actor && lhs.sentAt == rhs.sentAt
    }
}

private extension String {
    var supportBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
private extension LocalParticipant {
    var supportValid: Bool { !id.supportBlank && !workspaceID.supportBlank && !displayName.supportBlank }
}

extension SupportExchange {
    static func mergingSnapshot(_ room: SupportQuestion, local: SupportQuestion) -> SupportQuestion {
        var result = room
        result.acknowledgement = local.acknowledgement ?? room.acknowledgement
        result.reply = local.reply ?? room.reply
        return result
    }
}
