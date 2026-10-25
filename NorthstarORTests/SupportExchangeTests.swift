import XCTest
@testable import NorthstarOR

final class SupportExchangeTests: XCTestCase {
    let time = Date(timeIntervalSince1970: 1_800_000_000)
    var actor: LocalParticipant { .init(id: "room", workspaceID: "origin", displayName: "Fictional Room", statedRole: .orTeam) }
    var rep: LocalParticipant { .init(id: "rep", workspaceID: "different", displayName: "Fictional Rep", statedRole: .technicalRep) }
    var snapshot: SupportContextSnapshot {
        .init(capturedAt: time, caseReference: "case", caseName: "Fictional case", siteName: "Fictional site",
              deviceFamily: "pacemaker", templateID: "template", templateVersion: 1,
              selectedItemID: "line", selectedItemTitle: "Details", reducedSupport: true,
              logisticalReason: "Travel", lines: [.init(id: "line", title: "Details", status: .deferred, normallyCoveredByRep: true)],
              recentEvents: [], recordingRevision: 1, acknowledgmentIDs: [])
    }
    func question(_ text: String = "Which fictional reference?") throws -> SupportQuestion {
        try .make(id: "q", workspaceID: "origin", caseID: "case", sessionID: "run", text: text,
                  sender: actor, recipientContactID: "contact", recipientName: "Fictional Rep", sentAt: time, snapshot: snapshot)
    }
    func testFrozenBriefAndAcknowledgmentContext() throws {
        XCTAssertThrowsError(try question(" \n"))
        let q = try question()
        var later = snapshot
        later.recordingRevision = 2
        later.acknowledgmentIDs = ["warning-ack"]
        XCTAssertEqual(SupportExchange.changedLineCount(snapshot: q.snapshot, live: later), 0)
        XCTAssertNotEqual(q.snapshot, later)
        let answered = try SupportExchange.reply(SupportExchange.acknowledge(q, by: rep, at: time), text: "Fictional reference", from: rep, at: time)
        XCTAssertEqual(answered.snapshot, snapshot)
        XCTAssertEqual(answered.replyText, "Fictional reference")
        XCTAssertEqual(answered.delivery, .onThisDevice)
        XCTAssertEqual(answered.acknowledgement?.delivery, .onThisDevice)
        XCTAssertEqual(answered.reply?.delivery, .onThisDevice)
        XCTAssertThrowsError(try SupportExchange.reply(answered, text: "Replacement", from: rep, at: time))
    }
    func testReplayAfterPersistencePreservesReplyAndRejectsConflictingQuestion() throws {
        let q = try question()
        let answered = try SupportExchange.reply(q, text: "Fictional reference", from: rep, at: time)
        let inbox = try JSONDecoder().decode(SupportInbox.self, from: JSONEncoder().encode(SupportInbox(questions: [answered])))
        let replay = SupportExchange.apply(.question(q), to: inbox, current: nil)
        XCTAssertTrue(replay.accepted)
        XCTAssertEqual(replay.receiptForID, q.messageID)
        XCTAssertEqual(replay.inbox.questions[0].replyText, "Fictional reference")
        let conflict = SupportExchange.apply(.question(try question("Changed question")), to: inbox, current: nil)
        XCTAssertFalse(conflict.accepted)
        XCTAssertNil(conflict.receiptForID)
        XCTAssertEqual(conflict.inbox, inbox)
    }
    func testExactReceiptsAndIndependentDelivery() throws {
        let q = try SupportExchange.acknowledge(question(), by: rep, at: time)
        let answered = try SupportExchange.reply(q, text: "Fictional reference", from: rep, at: time)
        var inbox = SupportInbox(questions: [answered])
        inbox = try SupportExchange.markDelivery(messageID: answered.messageID, delivery: .waitingForPeer, in: inbox)
        inbox = try SupportExchange.markDelivery(messageID: answered.reply!.id, delivery: .waitingForPeer, in: inbox)
        let result = SupportExchange.apply(.receipt(for: answered.replyEnvelope!), to: inbox, current: nil)
        XCTAssertTrue(result.accepted)
        XCTAssertNil(result.receiptForID)
        XCTAssertEqual(result.inbox.questions[0].reply?.delivery, .receivedByPeer)
        XCTAssertEqual(result.inbox.questions[0].delivery, .waitingForPeer)
        XCTAssertEqual(result.inbox.questions[0].acknowledgement?.delivery, .onThisDevice)
        let unknown = SupportEnvelope(id: "unknown-receipt", kind: .receipt, sentAt: time, origin: q.origin, questionID: q.id, receiptForID: "unknown")
        XCTAssertFalse(SupportExchange.apply(unknown, to: inbox, current: nil).accepted)
    }
    func testUnknownMalformedForeignAndOutOfOrderResponsesAreRejectedWithoutConsumption() throws {
        let q = try question()
        let answered = try SupportExchange.reply(q, text: "Fictional reference", from: rep, at: time)
        let empty = SupportInbox()
        let early = SupportExchange.apply(answered.replyEnvelope!, to: empty, current: nil)
        XCTAssertFalse(early.accepted)
        XCTAssertEqual(early.inbox, empty)
        let received = SupportExchange.apply(.question(q), to: empty, current: nil)
        XCTAssertTrue(received.accepted) // Other workspace is valid origin.
        XCTAssertTrue(SupportExchange.apply(answered.replyEnvelope!, to: received.inbox, current: nil).accepted)
        let foreign = SupportOrigin(workspaceID: "origin", caseID: "case", sessionID: "other")
        XCTAssertFalse(SupportExchange.apply(.question(q), to: empty, current: foreign).accepted)
        // A known retained question accepts replies while a different case is active.
        XCTAssertTrue(SupportExchange.apply(answered.replyEnvelope!, to: received.inbox, current: foreign).accepted)
        let malformed = SupportEnvelope(id: "bad", kind: .reply, sentAt: time, origin: q.origin, questionID: q.id)
        XCTAssertFalse(SupportExchange.apply(malformed, to: received.inbox, current: nil).accepted)
        let wrong = SupportEnvelope(id: answered.reply!.id, kind: .reply, sentAt: time, origin: foreign, questionID: q.id, reply: answered.reply)
        XCTAssertFalse(SupportExchange.apply(wrong, to: received.inbox, current: nil).accepted)
    }
    func testInvalidSnapshotIDsAndOriginCannotEnterInbox() throws {
        var invalid = snapshot
        invalid.lines.append(invalid.lines[0])
        XCTAssertThrowsError(try SupportQuestion.make(id: "q", workspaceID: "origin", caseID: "case", sessionID: "run", text: "Question", sender: actor, recipientContactID: "contact", recipientName: "Rep", sentAt: time, snapshot: invalid))
        XCTAssertThrowsError(try SupportQuestion.make(id: "q", workspaceID: "wrong", caseID: "case", sessionID: "run", text: "Question", sender: actor, recipientContactID: "contact", recipientName: "Rep", sentAt: time, snapshot: snapshot))
        let q = try question()
        let ambiguous = SupportInbox(questions: [q, q])
        XCTAssertThrowsError(try SupportExchange.markDelivery(messageID: q.messageID, delivery: .waitingForPeer, in: ambiguous))
        XCTAssertFalse(SupportExchange.apply(.question(q), to: ambiguous, current: nil).accepted)
        XCTAssertFalse(SupportExchange.apply(.question(q), to: ambiguous, current: nil).inbox.questions.isEmpty)
        XCTAssertEqual(SupportExchange.changedLineCount(snapshot: snapshot, live: invalid), 0)
    }
    func testContextCannotBorrowAQuestionIdentityAndRevisionMustAdvance() throws {
        let q = try question()
        let inbox = SupportInbox(questions: [q])
        var later = snapshot
        later.recordingRevision = 2
        later.acknowledgmentIDs = ["warning-ack"]
        let borrowed = SupportEnvelope(id: q.messageID, kind: .contextUpdate, sentAt: time,
                                       origin: q.origin, questionID: q.id, context: later)
        XCTAssertFalse(SupportExchange.apply(borrowed, to: inbox, current: nil).accepted)
        let update = SupportEnvelope.context(later, for: q)
        let result = SupportExchange.apply(update, to: inbox, current: nil)
        XCTAssertTrue(result.accepted)
        XCTAssertEqual(result.inbox.questions[0].snapshot.recordingRevision, 1)
        XCTAssertEqual(result.inbox.liveContext[q.origin]?.acknowledgmentIDs, ["warning-ack"])
        XCTAssertEqual(SupportExchange.changedLineCount(snapshot: q.snapshot, live: later), 0)
        XCTAssertTrue(SupportExchange.apply(update, to: result.inbox, current: nil).accepted)
        var conflicting = later
        conflicting.acknowledgmentIDs = ["different-ack"]
        XCTAssertFalse(SupportExchange.apply(.context(conflicting, for: q), to: result.inbox, current: nil).accepted)
        var stale = snapshot
        stale.acknowledgmentIDs = ["unversioned-ack"]
        XCTAssertFalse(SupportExchange.apply(.context(stale, for: q), to: inbox, current: nil).accepted)
    }

    func testReplyBeforeAcknowledgmentAndIndependentAcknowledgmentReceiptSurviveRelaunch() throws {
        let q = try question()
        let replyFirst = try SupportExchange.reply(q, text: "Fictional reply", from: rep, at: time)
        let acknowledged = try SupportExchange.acknowledge(replyFirst, by: rep, at: time.addingTimeInterval(1))
        var inbox = SupportExchange.apply(.question(q), to: SupportInbox(), current: nil).inbox
        inbox = SupportExchange.apply(replyFirst.replyEnvelope!, to: inbox, current: nil).inbox
        inbox = SupportExchange.apply(acknowledged.acknowledgementEnvelope!, to: inbox, current: nil).inbox
        XCTAssertEqual(inbox.questions[0].replyText, "Fictional reply")
        XCTAssertEqual(inbox.questions[0].questionAcknowledgedBy, "Fictional Rep")
        inbox = try SupportExchange.markDelivery(messageID: q.acknowledgementMessageID, delivery: .waitingForPeer, in: inbox)
        let restored = try JSONDecoder().decode(SupportInbox.self, from: JSONEncoder().encode(inbox))
        let receipt = SupportExchange.apply(.receipt(for: acknowledged.acknowledgementEnvelope!), to: restored, current: nil)
        XCTAssertEqual(receipt.inbox.questions[0].acknowledgement?.delivery, .receivedByPeer)
        XCTAssertEqual(receipt.inbox.questions[0].delivery, .onThisDevice)
        XCTAssertEqual(receipt.inbox.questions[0].reply?.delivery, .onThisDevice)
        let replay = SupportExchange.apply(acknowledged.acknowledgementEnvelope!, to: receipt.inbox, current: nil)
        XCTAssertTrue(replay.accepted)
        XCTAssertEqual(replay.inbox, receipt.inbox)
        let conflict = try SupportExchange.reply(q, text: "Conflicting reply", from: rep, at: time)
        XCTAssertFalse(SupportExchange.apply(conflict.replyEnvelope!, to: replay.inbox, current: nil).accepted)
    }

    func testNewerQuestionPreventsDelayedContextFromRollingBackTheOrigin() throws {
        let first = try SupportExchange.reply(question(), text: "Retained fictional reply", from: rep, at: time)
        var revisionTwo = snapshot
        revisionTwo.recordingRevision = 2
        revisionTwo.acknowledgmentIDs = ["ack-at-two"]
        let delayed = SupportEnvelope.context(revisionTwo, for: first)
        let cached = SupportExchange.apply(delayed, to: SupportInbox(questions: [first]), current: nil)
        XCTAssertTrue(cached.accepted)

        var revisionFive = snapshot
        revisionFive.recordingRevision = 5
        revisionFive.acknowledgmentIDs = ["ack-at-five"]
        let second = try SupportQuestion.make(id: "q2", workspaceID: "origin", caseID: "case", sessionID: "run",
                                             text: "Later fictional question?", sender: actor, recipientContactID: "contact",
                                             recipientName: "Fictional Rep", sentAt: time, snapshot: revisionFive)
        let newer = SupportExchange.apply(.question(second), to: cached.inbox, current: nil)
        XCTAssertTrue(newer.accepted)
        XCTAssertEqual(newer.receiptForID, second.messageID)
        XCTAssertNil(newer.inbox.liveContext[first.origin])
        XCTAssertEqual(newer.inbox.questions[0], first)
        XCTAssertEqual(newer.inbox.questions[1].snapshot.recordingRevision, 5)

        // No cache is necessary for the newest retained brief to establish a revision floor.
        let retained = SupportInbox(questions: [first, second])
        for inbox in [retained, newer.inbox] {
            let rejected = SupportExchange.apply(delayed, to: inbox, current: nil)
            XCTAssertFalse(rejected.accepted)
            XCTAssertNil(rejected.receiptForID)
            XCTAssertEqual(rejected.inbox, inbox)
        }
        var revisionSix = revisionFive
        revisionSix.recordingRevision = 6
        let currentUpdate = SupportEnvelope.context(revisionSix, for: first)
        let advanced = SupportExchange.apply(currentUpdate, to: newer.inbox, current: nil)
        XCTAssertTrue(advanced.accepted)
        XCTAssertEqual(advanced.receiptForID, currentUpdate.id)
        XCTAssertEqual(advanced.inbox.liveContext[first.origin]?.recordingRevision, 6)
        let duplicate = SupportExchange.apply(.question(second), to: advanced.inbox, current: nil)
        XCTAssertTrue(duplicate.accepted)
        XCTAssertEqual(duplicate.inbox, advanced.inbox)
        XCTAssertEqual(advanced.inbox.questions[0].replyText, "Retained fictional reply")
    }

}
