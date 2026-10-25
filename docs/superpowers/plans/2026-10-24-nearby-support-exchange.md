# Nearby two-iPad support exchange

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Two iPads on the same network can pass one support question, its frozen checklist snapshot, a question acknowledgment, and a reply, with Co-pilot and Remote Support screens that show those states honestly.

**Architecture:** The room iPad owns checklist recording in the existing `CoPilotSession`. A support question is a separate value, with an immutable context snapshot, stored beside the session and never written into `SessionEvent` or `SessionRecordingState`. `NearbyTransport` is the only network boundary. Tests use an in-memory pair. The shipping transport is Multipeer Connectivity, started only when someone taps “Look for nearby iPad.” With no peer, the same iPad still shows the question on the Remote Support tab and the label stays “On this device.”

**Tech Stack:** SwiftUI, iPadOS 17, existing `Northstar` tokens, `XCTest`, Apple `MultipeerConnectivity`. No new package.

**Spec:** This file is the spec. Also follow [docs/CONNECTED_SUPPORT_HANDOFF.md](../../CONNECTED_SUPPORT_HANDOFF.md), [docs/DESIGN.md](../../DESIGN.md) Remote Support contract, and [docs/PRODUCT.md](../../PRODUCT.md). Do not implement video, camera, AI, voice, or a hospital/internet backend.

## Global Constraints

- Baseline is `main` at `f4e0736` (`Define approved contextual support interactions and verification (#45)`). Branch: `sync/nearby-support-exchange`.
- The worktree already has uncommitted owner edits in `docs/DEMO_READINESS.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/PARTNER_EXECUTION.md`, and `docs/TASKS.md`. Do not stage, revert, or rewrite those four files.
- F05 already pins a required deferral. Do not reopen `skipCurrentStep`. Do not add cases to `SessionEventPayload`. `CoPilotSession.restore` replays those events; a new payload breaks old saves.
- `WorkspaceSnapshot.supportedFormatVersion` stays `1`. Add `supportQuestions` with `decodeIfPresent` defaulting to `[]`, matching the comment in `WorkspaceSnapshot.init(from:)`.
- A reply, a question acknowledgment, and a nearby connection never change `RecordedItemStatus`.
- Delivery words are only: `On this device`, `Waiting for the other iPad`, `Received on the other iPad`, `Not sent. Your question is kept.` Do not write Delivered, Live, Connected to the hospital, or Accepted arrangement unless that exact state exists.
- Nearby success is two iPads in the same room. The label is `Nearby`. It is not evidence the rep is in another city.
- Clinical specialists stay out of the recipient list. Recipients are contacts with `statedRole == .technicalRep`.
- Copy documents reports. Do not tell the team to proceed, and do not assess the procedure.
- Views call `AppModel` only. No `MultipeerConnectivity` import in a view.
- Primary buttons use `NorthstarPrimaryButtonStyle` (72 pt). Other controls are at least 44 pt. Colors come from `Northstar.Palette`.
- Respect Reduce Motion: a reply may fade in over 180 ms; when `accessibilityReduceMotion` is set, show it immediately. No pulse, glow, orb, or flashing border.
- One question is current per session. A newer send appends another question; it does not edit the older snapshot.
- `xcodebuild test -scheme NorthstarOR -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` must pass. If that simulator name is missing, pick any installed iPad simulator and name it in the PR.
- Commit only this branch’s files. Do not push unless the user asks.

## File structure

- Create `NorthstarOR/Models/SupportExchange.swift` — question, snapshot, envelopes, pure apply rules.
- Create `NorthstarORTests/SupportExchangeTests.swift` — those rules.
- Create `NorthstarOR/Services/NearbyTransport.swift` — protocol, idle transport, paired loopback.
- Create `NorthstarOR/Services/MultipeerNearbyTransport.swift` — device transport.
- Create `NorthstarOR/Features/CoPilot/SupportRequestSheet.swift` — question composer.
- Create `NorthstarOR/Features/RemoteSupport/SupportBriefView.swift` — join brief.
- Modify `NorthstarOR/Services/WorkspaceRepository.swift` — additive `supportQuestions`.
- Modify `NorthstarOR/App/AppModel.swift` — send, receive, persist, link state.
- Modify `NorthstarOR/Features/CoPilot/CoPilotView.swift` — request button and reply banner.
- Modify `NorthstarOR/Features/RemoteSupport/RemoteSupportView.swift` — brief instead of the placeholder.
- Modify `NorthstarOR/App/RootView.swift` — nearby control in the header row.
- Modify `project.yml` — local network usage string and Bonjour service.
- Create `docs/evidence/nearby-support/README.md` — device script. Screenshots are captured on two iPads, not invented.

---

### Task 1: Support exchange values

**Files:**
- Create: `NorthstarOR/Models/SupportExchange.swift`
- Test: `NorthstarORTests/SupportExchangeTests.swift`

**Interfaces:**
- Consumes: `RecordedItemStatus`, `LocalParticipant`, `ProcedureStep`.
- Produces: `SupportQuestion`, `SupportContextSnapshot`, `SupportEnvelope`, `SupportExchange.apply(_:to:current:)`.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import NorthstarOR

final class SupportExchangeTests: XCTestCase {
    private let time = Date(timeIntervalSince1970: 1_800_000_000)
    private let actor = LocalParticipant(id: "room-1", workspaceID: "ws", displayName: "Room team", statedRole: .orTeam)
    private let rep = LocalParticipant(id: "rep-1", workspaceID: "ws", displayName: "Ana", statedRole: .technicalRep)

    private func snapshot(status: RecordedItemStatus = .deferred) -> SupportContextSnapshot {
        SupportContextSnapshot(capturedAt: time, caseReference: "case-a", caseName: "Fictional pacemaker case",
            siteName: "Fictional North Shore", deviceFamily: "pacemaker", templateID: "fictional-pacemaker-coordination",
            templateVersion: 1, selectedItemID: "device-check", selectedItemTitle: "Fictional device details confirmation",
            reducedSupport: true, logisticalReason: "110 minutes of simulated travel",
            lines: [ChecklistLineSnapshot(id: "device-check", title: "Fictional device details confirmation",
                                          status: status, normallyCoveredByRep: true)],
            recentEvents: ["Item deferred: Fictional device details confirmation"])
    }

    func testBlankQuestionIsRejectedAndSnapshotStaysFrozen() {
        let frozen = snapshot()
        XCTAssertThrowsError(try SupportQuestion.make(id: "q1", workspaceID: "ws", caseID: "case-a", sessionID: "run-a",
            text: "   ", sender: actor, recipientContactID: "ana", recipientName: "Ana", sentAt: time, snapshot: frozen))
        var live = frozen
        live.lines[0] = ChecklistLineSnapshot(id: "device-check", title: live.lines[0].title,
                                               status: .teamConfirmed, normallyCoveredByRep: true)
        let question = try! SupportQuestion.make(id: "q1", workspaceID: "ws", caseID: "case-a", sessionID: "run-a",
            text: "Which mock model reference should we use?", sender: actor, recipientContactID: "ana",
            recipientName: "Ana", sentAt: time, snapshot: frozen)
        XCTAssertEqual(question.snapshot.lines[0].status, .deferred)
        XCTAssertEqual(question.delivery, .onThisDevice)
        XCTAssertEqual(live.lines[0].status, .teamConfirmed)
    }

    func testAcknowledgementAndReplyDoNotChangeTheSnapshot() {
        let question = try! SupportQuestion.make(id: "q1", workspaceID: "ws", caseID: "case-a", sessionID: "run-a",
            text: "Which mock model reference should we use?", sender: actor, recipientContactID: "ana",
            recipientName: "Ana", sentAt: time, snapshot: snapshot())
        let acknowledged = try! SupportExchange.acknowledge(question, by: rep, at: time.addingTimeInterval(60))
        let answered = try! SupportExchange.reply(acknowledged, text: "Use fictional model NS-100.", from: "Ana",
                                                   at: time.addingTimeInterval(120))
        XCTAssertEqual(answered.snapshot.lines[0].status, .deferred)
        XCTAssertEqual(answered.questionAcknowledgedBy, "Ana")
        XCTAssertEqual(answered.replyText, "Use fictional model NS-100.")
        XCTAssertEqual(SupportExchange.changedLineCount(snapshot: answered.snapshot, live: snapshot(status: .unrecorded)), 1)
    }

    func testDuplicateEnvelopeAndForeignSessionAreIgnored() {
        let question = try! SupportQuestion.make(id: "q1", workspaceID: "ws", caseID: "case-a", sessionID: "run-a",
            text: "Which mock model reference should we use?", sender: actor, recipientContactID: "ana",
            recipientName: "Ana", sentAt: time, snapshot: snapshot())
        let envelope = SupportEnvelope(id: "env-1", kind: .question, sentAt: time, question: question,
                                       acknowledgement: nil, reply: nil, context: nil, receiptForID: nil)
        var state = SupportInbox(questions: [], seenEnvelopeIDs: [])
        state = SupportExchange.apply(envelope, to: state, currentSessionID: "run-a")
        state = SupportExchange.apply(envelope, to: state, currentSessionID: "run-a")
        XCTAssertEqual(state.questions.count, 1)
        let other = SupportExchange.apply(envelope, to: SupportInbox(questions: [], seenEnvelopeIDs: []), currentSessionID: "other-run")
        XCTAssertTrue(other.questions.isEmpty)
    }
}
```

- [ ] **Step 2: Run the test and confirm it fails to compile**

Run: `xcodebuild test -scheme NorthstarOR -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:NorthstarORTests/SupportExchangeTests`

Expected: compile failure because `SupportQuestion` does not exist.

- [ ] **Step 3: Write the model**

```swift
import Foundation

struct ChecklistLineSnapshot: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let status: RecordedItemStatus
    let normallyCoveredByRep: Bool
}

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
}

enum SupportDelivery: String, Codable, Hashable {
    case onThisDevice
    case waitingForPeer
    case receivedByPeer
    case failed
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
    var questionAcknowledgedAt: Date?
    var questionAcknowledgedBy: String?
    var replyText: String?
    var replyAt: Date?
    var replySenderName: String?
    var delivery: SupportDelivery

    static func make(id: String, workspaceID: String, caseID: String, sessionID: String, text: String,
                     sender: LocalParticipant, recipientContactID: String, recipientName: String,
                     sentAt: Date, snapshot: SupportContextSnapshot) throws -> SupportQuestion {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SupportExchangeError.blankQuestion }
        guard !id.isEmpty, !workspaceID.isEmpty, !caseID.isEmpty, !sessionID.isEmpty,
              !recipientContactID.isEmpty, !recipientName.isEmpty else { throw SupportExchangeError.missingIdentity }
        return SupportQuestion(id: id, workspaceID: workspaceID, caseID: caseID, sessionID: sessionID, text: trimmed,
            sender: sender, recipientContactID: recipientContactID, recipientName: recipientName, sentAt: sentAt,
            snapshot: snapshot, questionAcknowledgedAt: nil, questionAcknowledgedBy: nil, replyText: nil,
            replyAt: nil, replySenderName: nil, delivery: .onThisDevice)
    }
}

struct QuestionAcknowledgement: Hashable, Codable {
    let questionID: String
    let by: String
    let at: Date
}

struct SupportReply: Hashable, Codable {
    let questionID: String
    let text: String
    let from: String
    let at: Date
}

enum SupportEnvelopeKind: String, Codable {
    case question, questionAcknowledgement, reply, contextUpdate, receipt
}

struct SupportEnvelope: Identifiable, Hashable, Codable {
    let id: String
    let kind: SupportEnvelopeKind
    let sentAt: Date
    let question: SupportQuestion?
    let acknowledgement: QuestionAcknowledgement?
    let reply: SupportReply?
    let context: SupportContextSnapshot?
    let contextSessionID: String?
    let receiptForID: String?
}

struct SupportInbox: Equatable {
    var questions: [SupportQuestion]
    var seenEnvelopeIDs: Set<String>
    var liveContext: [String: SupportContextSnapshot] = [:]
}

enum SupportExchangeError: Error, Equatable {
    case blankQuestion, missingIdentity, unknownQuestion, blankReply
}

enum SupportExchange {
    static func acknowledge(_ question: SupportQuestion, by actor: LocalParticipant, at time: Date) throws -> SupportQuestion {
        var copy = question
        copy.questionAcknowledgedAt = time
        copy.questionAcknowledgedBy = actor.displayName
        return copy
    }

    static func reply(_ question: SupportQuestion, text: String, from name: String, at time: Date) throws -> SupportQuestion {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SupportExchangeError.blankReply }
        var copy = question
        copy.replyText = trimmed
        copy.replyAt = time
        copy.replySenderName = name
        return copy
    }

    static func changedLineCount(snapshot: SupportContextSnapshot, live: SupportContextSnapshot) -> Int {
        let liveStatus = Dictionary(uniqueKeysWithValues: live.lines.map { ($0.id, $0.status) })
        return snapshot.lines.filter { liveStatus[$0.id] != $0.status }.count
    }

    static func apply(_ envelope: SupportEnvelope, to inbox: SupportInbox, currentSessionID: String?) -> SupportInbox {
        var next = inbox
        guard next.seenEnvelopeIDs.insert(envelope.id).inserted else { return next }
        switch envelope.kind {
        case .question:
            guard let question = envelope.question, currentSessionID == nil || question.sessionID == currentSessionID else { return inbox }
            next.questions.removeAll { $0.id == question.id }
            next.questions.append(question)
        case .questionAcknowledgement:
            guard let ack = envelope.acknowledgement, let index = next.questions.firstIndex(where: { $0.id == ack.questionID }) else { return next }
            next.questions[index].questionAcknowledgedAt = ack.at
            next.questions[index].questionAcknowledgedBy = ack.by
        case .reply:
            guard let reply = envelope.reply, let index = next.questions.firstIndex(where: { $0.id == reply.questionID }) else { return next }
            next.questions[index].replyText = reply.text
            next.questions[index].replyAt = reply.at
            next.questions[index].replySenderName = reply.from
        case .contextUpdate:
            guard let sessionID = envelope.contextSessionID, let context = envelope.context else { return next }
            next.liveContext[sessionID] = context
        case .receipt:
            guard let id = envelope.receiptForID, let index = next.questions.firstIndex(where: { $0.id == id }) else { return next }
            if next.questions[index].delivery == .waitingForPeer {
                next.questions[index].delivery = .receivedByPeer
            }
        }
        return next
    }
}
```

Fix `testDuplicateEnvelopeAndForeignSessionAreIgnored`: a duplicate call of `apply` on a foreign session currently returns `inbox` before recording the envelope id when the session mismatches. That is what the test wants (`other.questions` empty). The duplicate path returns the already-seen inbox unchanged. Keep that.

`contextUpdate` must not require `currentSessionID` to match, because the rep device may not have that run locally. The question path does require a match when `currentSessionID` is non-nil. The room sends questions with the active session id. The rep applies them with `currentSessionID: nil` so a self-contained brief can arrive before the rep has that case. Pass `nil` from the rep role and the active id from the room role. Document that in Task 2.

- [ ] **Step 4: Run the test**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add NorthstarOR/Models/SupportExchange.swift NorthstarORTests/SupportExchangeTests.swift
git commit -m "$(cat <<'EOF'
Add a frozen support-question snapshot separate from checklist recording.

EOF
)"
```

---

### Task 2: AppModel send and receive, including persistence

**Files:**
- Modify: `NorthstarOR/Services/WorkspaceRepository.swift` (`WorkspaceSnapshot`)
- Create: `NorthstarOR/Services/NearbyTransport.swift`
- Modify: `NorthstarOR/App/AppModel.swift`
- Test: `NorthstarORTests/SupportExchangeTests.swift` (add the loopback tests at the bottom)

**Interfaces:**
- Consumes: `SupportQuestion`, `SupportEnvelope`, `SupportExchange.apply`.
- Produces:
  - `AppModel.sendSupportQuestion(text:recipient:)`
  - `AppModel.acknowledgeQuestion(_ id: String)`
  - `AppModel.sendSupportReply(_ id: String, text: String)`
  - `AppModel.latestQuestion(for sessionID: String?) -> SupportQuestion?`
  - `AppModel.linkState: NearbyLinkState`
  - `AppModel.demoPost: DemoPost`

- [ ] **Step 1: Write the failing loopback test**

Add to `SupportExchangeTests.swift`:

```swift
func testQuestionOnOneModelArrivesOnTheOtherAndReplyDoesNotConfirmTheItem() throws {
    let storeA = InMemoryWorkspaceStore()
    let storeB = InMemoryWorkspaceStore()
    let linkA = PairedNearbyTransport()
    let linkB = PairedNearbyTransport()
    linkA.other = linkB
    linkB.other = linkA
    let room = AppModel(sync: LocalSyncService(), store: storeA, nearby: linkA, post: .room)
    let rep = AppModel(sync: LocalSyncService(), store: storeB, nearby: linkB, post: .rep)
    try room.loadSampleWorkspace()
    try rep.loadSampleWorkspace()
    let caseID = SampleData.Record.northShoreCase.rawValue
    try room.startOrResume(caseID: caseID)
    let session = try XCTUnwrap(room.activeSession)
    _ = try session.apply(try XCTUnwrap(session.makeCommand(.deferItem, at: Date(timeIntervalSince1970: 1_800_000_000))))
    let ana = try XCTUnwrap(room.reps.first { $0.statedRole == .technicalRep })
    try room.sendSupportQuestion(text: "Which mock model reference should we use?", recipient: ana)
    let seen = try XCTUnwrap(rep.latestQuestion(for: nil))
    XCTAssertEqual(seen.text, "Which mock model reference should we use?")
    XCTAssertEqual(seen.snapshot.lines.first { $0.id == session.currentStep?.id }?.status, .deferred)
    try rep.acknowledgeQuestion(seen.id)
    try rep.sendSupportReply(seen.id, text: "Use fictional model NS-100.")
    let back = try XCTUnwrap(room.latestQuestion(for: session.identity.sessionID))
    XCTAssertEqual(back.replyText, "Use fictional model NS-100.")
    XCTAssertEqual(back.delivery, .receivedByPeer)
    XCTAssertEqual(session.recordingState?.itemStatuses[session.currentStep?.id ?? ""], .deferred)
}

func testOldSnapshotWithoutQuestionsStillLoads() throws {
    let store = InMemoryWorkspaceStore()
    let model = AppModel(sync: LocalSyncService(), store: store, nearby: IdleNearbyTransport(), post: .room)
    try model.loadSampleWorkspace()
    let data = try XCTUnwrap(store.data)
    var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    object.removeValue(forKey: "supportQuestions")
    store.data = try JSONSerialization.data(withJSONObject: object)
    model.load()
    XCTAssertEqual(model.loadState, .ready)
    XCTAssertNil(model.latestQuestion(for: nil))
}
```

- [ ] **Step 2: Run it and confirm compile failure**

Expected: `PairedNearbyTransport` and `sendSupportQuestion` are missing.

- [ ] **Step 3: Add the transport pair and the snapshot field**

`NorthstarOR/Services/NearbyTransport.swift`:

```swift
import Foundation

enum NearbyLinkState: Equatable {
    case idle, looking, connected(peerName: String), disconnected
}

enum NearbyTransportError: Error, Equatable { case notConnected, encodeFailed }

@MainActor
protocol NearbyTransport: AnyObject {
    var linkState: NearbyLinkState { get }
    var onEnvelope: ((SupportEnvelope) -> Void)? { get set }
    var onLinkState: ((NearbyLinkState) -> Void)? { get set }
    func start()
    func stop()
    func send(_ envelope: SupportEnvelope) throws
}

@MainActor
final class IdleNearbyTransport: NearbyTransport {
    var linkState: NearbyLinkState = .idle
    var onEnvelope: ((SupportEnvelope) -> Void)?
    var onLinkState: ((NearbyLinkState) -> Void)?
    func start() {}
    func stop() {}
    func send(_ envelope: SupportEnvelope) throws { throw NearbyTransportError.notConnected }
}

/// Test double. Each side holds the other. Sending applies on the other immediately.
@MainActor
final class PairedNearbyTransport: NearbyTransport {
    weak var other: PairedNearbyTransport?
    var linkState: NearbyLinkState = .connected(peerName: "Paired iPad")
    var onEnvelope: ((SupportEnvelope) -> Void)?
    var onLinkState: ((NearbyLinkState) -> Void)?
    func start() { linkState = .connected(peerName: "Paired iPad") }
    func stop() { linkState = .idle }
    func send(_ envelope: SupportEnvelope) throws {
        guard let other else { throw NearbyTransportError.notConnected }
        other.onEnvelope?(envelope)
    }
}
```

In `WorkspaceSnapshot`, add `var supportQuestions: [SupportQuestion] = []`. Add `supportQuestions` to `CodingKeys` and:

```swift
supportQuestions = try values.decodeIfPresent([SupportQuestion].self, forKey: .supportQuestions) ?? []
```

Do not require a question's case to already be the active session. In `validate()`, for each question require non-empty ids and `question.workspaceID == workspace.id`. Do not require the case to exist, so a rep iPad can keep a self-contained brief. Skip duplicate question ids.

- [ ] **Step 4: Route questions through AppModel**

Extend `AppModel.init` with `nearby: NearbyTransport? = nil` and `post: DemoPost = .room`. Default `nearby` to `IdleNearbyTransport()` so existing call sites keep compiling. `AppModel.launching` also uses the idle transport. Multipeer is attached in Task 5 only after the user taps the button.

```swift
enum DemoPost: String { case room, rep }
```

Hold `private(set) var questions: [SupportQuestion] = []`, `private var seenEnvelopeIDs: Set<String> = []`, `private var liveContext: [String: SupportContextSnapshot] = []`, and `private(set) var linkState: NearbyLinkState = .idle`.

On init, assign:

```swift
nearby.onEnvelope = { [weak self] envelope in self?.receive(envelope) }
nearby.onLinkState = { [weak self] state in self?.linkState = state }
```

`sendSupportQuestion` builds a snapshot from `activeSession`: every step's id, title, `recordingState` status, and `normallyCoveredByRep`; hospital name from `hospital(_:)` or `Site not recorded`; procedure reference or id; `session.reducedSupport`; `logisticalReason` set to `recommendation(for: session.procedure).reasons.first`; and `Array(session.log.suffix(8).map(\.message))`. `reasons` is `[String]` on `CoverageMatcher.Recommendation`. An empty `reasons` array stores nil, and the brief shows `Not recorded`.

Delivery is `.waitingForPeer` when `linkState` is `.connected`, otherwise `.onThisDevice`. Append the question, persist through the existing `persist(snapshot())` path by including `questions` in `WorkspaceSnapshot`, then `try nearby.send` the `.question` envelope. On throw, set that question's `delivery` to `.failed` and keep it in `questions`. Do not remove the text. The sheet reads the failure and keeps the draft.

`acknowledgeQuestion` and `sendSupportReply` update the local question through `SupportExchange.acknowledge` / `.reply`, persist, and send `.questionAcknowledgement` or `.reply`. The sender's display name for a reply is the workspace `localParticipant.displayName` when `post == .rep`; if that participant is missing, use the recipient name stored on the question. Do not call `CoPilotSession.apply`.

`receive` runs `SupportExchange.apply`, assigns the resulting questions and `liveContext`, then calls the existing `persist(snapshot())` when a workspace is loaded. `liveContext` stays in memory only. A relaunch keeps the frozen question and drops the “changed since request” overlay until the next context update. If the envelope kind is `.question`, `.questionAcknowledgement`, or `.reply`, and the link is connected, send one `.receipt` whose `receiptForID` is the question id, not the envelope id. Do not receipt a receipt. A failed persist leaves the in-memory question in place and sets `saveError`; it does not drop the reply.

After a successful `CoPilotSession.apply` inside the existing recording path, if `post == .room` and a question exists for that session, send a `.contextUpdate` with a freshly built snapshot and `contextSessionID`. Do not let a failed nearby send roll back the checklist command.

`restore` copies `snapshot.supportQuestions` into `questions`. `snapshot()` writes `questions` back.

`latestQuestion(for:)` returns the last question whose `sessionID` matches, or the last question when the argument is nil.

Guard `sendSupportQuestion` with `post == .room` and a non-nil supported `activeSession`. Rep post throws `AppModelError.recordingUnavailable` for checklist commands if a public recording method is added. Existing view commands stay on the session; Task 3 hides them for `.rep`.

- [ ] **Step 5: Run SupportExchangeTests and AppModelTests**

Expected: new tests PASS. Existing `AppModelTests` still PASS. If `init` signature churn breaks a call, pass the new arguments only where the test needs them; defaults cover the rest.

- [ ] **Step 6: Commit**

```bash
git add NorthstarOR/Services/NearbyTransport.swift NorthstarOR/Services/WorkspaceRepository.swift NorthstarOR/App/AppModel.swift NorthstarORTests/SupportExchangeTests.swift NorthstarORTests/AppModelTests.swift
git commit -m "$(cat <<'EOF'
Route a support question and reply between two local app models.

EOF
)"
```

---

### Task 3: Co-pilot request and reply UI

**Files:**
- Create: `NorthstarOR/Features/CoPilot/SupportRequestSheet.swift`
- Modify: `NorthstarOR/Features/CoPilot/CoPilotView.swift`

**Interfaces:**
- Consumes: `AppModel.sendSupportQuestion`, `latestQuestion`, `demoPost`, `linkState`.

- [ ] **Step 1: Add the sheet**

`SupportRequestSheet` takes the technical-rep contacts, a draft binding, an error string, and `onSend: (DeviceRep) -> Void`. Layout, top to bottom:

- Title `Request support`.
- `Picker` labeled `Recipient` listing only `statedRole == .technicalRep`. Empty list shows “Add a technical rep in Workspace settings.” and disables Send.
- `TextField("What should the rep answer?", text: axis: .vertical)` with line limit 1...4, identifier `support-question-draft`.
- A read-only block titled `Context that will be sent` listing the selected item title and each unresolved line title from the current session. This is a preview; the snapshot is taken inside `sendSupportQuestion`.
- Primary `Send question` (`NorthstarPrimaryButtonStyle(tone: .standard)`), identifier `support-question-send`.
- If `error` is non-nil, show it in `Northstar.Palette.alert` above the button.

The sheet does not mention delivery. The parent shows delivery after send.

- [ ] **Step 2: Wire Co-pilot**

In the current-item column of `CoPilotView`, below the recording actions and above the correction button:

- If `model.demoPost == .rep`, replace the confirm/defer buttons with the text “This iPad is the rep. Checklist recording stays on the room iPad.” Keep the current item title visible.
- If `model.demoPost == .room`, show `Button("Request support")` even while `pendingAcknowledgment` is non-nil. Identifier `request-support`. It sets `showRequest = true` and does not call `apply`.
- Present `SupportRequestSheet`. On send, call `model.sendSupportQuestion`. Success clears the draft and dismisses. Failure leaves the sheet open and shows `Not sent. Your question is kept.`
- Replace the `remoteMessage` banner with the latest `SupportQuestion` for this session. If `replyText` is non-nil, banner title `Reply from {replySenderName}`, message the reply text, tone `.info`. Under it, supporting text `This reply does not confirm the checklist item.` and the reply time.
- If there is a question and no reply, show a `NorthstarStatusLabel` whose title is the delivery sentence: `On this device`, `Waiting for the other iPad`, `Received on the other iPad`, or `Not sent. Your question is kept.`
- Fade the reply banner with `.animation(.easeOut(duration: 0.18), value: question.replyAt)` only when `accessibilityReduceMotion` is false.

Leave the old local message log in the activity list so existing messages still show. Do not keep sending new support through `SyncEvent.remoteMessage`.

- [ ] **Step 3: Build**

Run the unit tests named in Task 2. Then build the app scheme. Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add NorthstarOR/Features/CoPilot/SupportRequestSheet.swift NorthstarOR/Features/CoPilot/CoPilotView.swift
git commit -m "$(cat <<'EOF'
Let the room request support and see a reply without closing the deferred item.

EOF
)"
```

---

### Task 4: Remote Support join brief

**Files:**
- Create: `NorthstarOR/Features/RemoteSupport/SupportBriefView.swift`
- Modify: `NorthstarOR/Features/RemoteSupport/RemoteSupportView.swift`

**Interfaces:**
- Consumes: `latestQuestion`, `acknowledgeQuestion`, `sendSupportReply`, `liveContext` via a small `AppModel.liveContext(for sessionID: String) -> SupportContextSnapshot?` added in this task.

- [ ] **Step 1: Build the brief view**

`SupportBriefView` shows, in this order, using `Northstar.Fonts` and `Northstar.Palette.ink` / `inkMuted`:

1. Eyebrow `Team question`. If `question == nil`, title `No question from the team yet` and stop.
2. The question text as `Northstar.Fonts.title`, then `{sender.displayName} · {sentAt short time}`.
3. `Acknowledge question` when `questionAcknowledgedAt == nil`. Primary, 72 pt, identifier `acknowledge-question`. Hidden after acknowledgment. Then status `Question acknowledged by {name}`.
4. Case reference, case name, site, device family, template id and version, snapshot time. Missing strings read `Not recorded`.
5. `Unresolved in the request`. Lines from `question.snapshot.lines` whose status is not `.teamConfirmed`. Empty copy: `No unresolved items in the request.` Each deferred row uses the amber triangle and the word `Deferred`. Each unrecorded row uses `Unrecorded`.
6. `Recorded in the request`. Confirmed lines, or `No team confirmations in the request.`
7. `Lines the in-room rep usually covers`. Snapshot lines with `normallyCoveredByRep == true`. This is a label, not a new status.
8. `Why support is remote`. `logisticalReason` or `Not recorded`. If `reducedSupport` is true, add `Reduced-support context recorded`.
9. `Changed since request`. Count from `SupportExchange.changedLineCount` against `live`. Zero reads `No later checklist change recorded.` A non-zero count reads `{n} checklist line(s) changed since the request.` Do not replace the snapshot lists above.
10. Reply composer: `TextField("Write a technical-support reply")`, the existing `FictionalCoordinationTemplate.technicalSupportReplies` menu labeled `Suggested text`, and primary `Send reply`, identifier `support-reply-send`. Disable Send when the question is nil or the field is blank.

- [ ] **Step 2: Replace the placeholder brief**

In `RemoteSupportView`, replace the “No team question recorded / not available yet” header and the live unresolved/confirmed sections with `SupportBriefView` bound to `model.latestQuestion(for: model.activeSession?.identity.sessionID)`. When the rep post has no active session, pass `model.latestQuestion(for: nil)`.

Remove the local sender menu and `sync.send(.remoteMessage...)`. Keep a short supporting line under the navigation title area: `Messages stay with this case. A nearby iPad is required before this leaves the device.`

Show `NorthstarStatusLabel` for `model.linkState`: `On this device` when `.idle`, `Nearby · looking` when `.looking`, `Nearby · {peerName}` when `.connected`, `Nearby · disconnected` when `.disconnected`.

- [ ] **Step 3: Build and run the unit tests**

Expected: BUILD SUCCEEDED and `NorthstarORTests` PASS.

- [ ] **Step 4: Commit**

```bash
git add NorthstarOR/Features/RemoteSupport/SupportBriefView.swift NorthstarOR/Features/RemoteSupport/RemoteSupportView.swift NorthstarOR/App/AppModel.swift
git commit -m "$(cat <<'EOF'
Show the rep the frozen question brief and a separate reply action.

EOF
)"
```

---

### Task 5: Nearby link on two iPads

**Files:**
- Create: `NorthstarOR/Services/MultipeerNearbyTransport.swift`
- Modify: `NorthstarOR/App/RootView.swift`
- Modify: `NorthstarOR/App/AppModel.swift`
- Modify: `project.yml`

**Interfaces:**
- Consumes: `NearbyTransport`.
- Produces: `AppModel.startNearbyLink()`, `AppModel.stopNearbyLink()`, header control.

- [ ] **Step 1: Add the permission keys**

In `project.yml` under the app target `settings.base`, add:

```yaml
INFOPLIST_KEY_NSLocalNetworkUsageDescription: "Northstar OR connects two nearby iPads so a technical rep can receive the team's question and reply."
INFOPLIST_KEY_NSBonjourServices: "_nstar-or._tcp"
```

Run `xcodegen generate`. Open the generated Info.plist and confirm `NSBonjourServices` is an array containing `_nstar-or._tcp`. If XcodeGen wrote a single string that is not an array, set `info.properties.NSBonjourServices` to that one-item list instead. Do not commit `NorthstarOR.xcodeproj`.

- [ ] **Step 2: Implement Multipeer behind the protocol**

`MultipeerNearbyTransport` is `@MainActor`, service type `nstar-or` (15 characters or fewer). Peer display name is `OR-` plus four random characters. `start()` advertises and browses. `stop()` stops both and disconnects the session.

When the browser finds a peer whose display name is greater than ours, invite that peer with a 20 second timeout. The advertiser accepts the invitation into the existing `MCSession`. This avoids both sides inviting.

Map `MCSessionState.connected` to `.connected(peerName:)`. When the last peer drops, set `.disconnected`. `send` JSON-encodes the envelope and uses `MCSession.send(_:toPeers:with: .reliable)`. No connected peer throws `NearbyTransportError.notConnected`.

Delegate callbacks hop to the main actor before touching `onEnvelope` or `onLinkState`. Implement the required stream and resource delegate methods as empty.

`AppModel.startNearbyLink()` replaces the idle transport with `MultipeerNearbyTransport()`, rebinds the callbacks, and calls `start()`. `stopNearbyLink()` stops it and sets `linkState` to `.idle`. Do not start Multipeer from `launching()` or from unit tests.

- [ ] **Step 3: Add the header control**

`RootView`, in the ready workspace header row, trailing side: a 44 pt button, `Look for nearby iPad` or `Stop nearby link` when `linkState` is `.looking` or `.connected`. Next to it, a `Picker` or menu `This iPad` with `Room` and `Rep`, bound to `model.demoPost`. Changing post does not change checklist state.

Under the header, one supporting line, always visible on the ready shell: `Fictional coordination record. Nearby links two iPads on the same network. This app does not decide whether a procedure proceeds.`

- [ ] **Step 4: Run the unit tests**

Expected: PASS. Multipeer is not exercised here.

- [ ] **Step 5: Commit**

```bash
git add NorthstarOR/Services/MultipeerNearbyTransport.swift NorthstarOR/App/AppModel.swift NorthstarOR/App/RootView.swift project.yml
git commit -m "$(cat <<'EOF'
Add an explicit nearby iPad link for the support question and reply.

EOF
)"
```

---

### Task 6: Device proof

**Files:**
- Create: `docs/evidence/nearby-support/README.md`

- [ ] **Step 1: Write the evidence note before capturing**

The note lists the checks below and leaves each result as `not run` until a human records it. Do not mark a check passed from the simulator alone.

1. Load the sample workspace on iPad A and iPad B. A is Room. B is Rep. Both tap `Look for nearby iPad` and allow Local Network. The label becomes `Nearby ·` plus a peer name.
2. On A, start the fictional North Shore case, defer the current required item, and send `Which mock model reference should we use?` to a technical rep. B shows that exact text, the deferred line, and the snapshot time. B has not asked the room anything.
3. On A, acknowledge the deferral. The item stays deferred. B still shows the original snapshot and `1 checklist line changed since the request.`
4. B taps `Acknowledge question`, then sends `Use fictional model NS-100.` A shows `Reply from` that name, and the item is still deferred.
5. Turn on airplane mode on B. A’s next send stays on screen as `Not sent. Your question is kept.` The label becomes `Nearby · disconnected`. Re-enable the network, tap `Look for nearby iPad` again, and retry once.
6. Capture one default-text landscape screenshot and one largest accessibility text screenshot of the brief and of the Co-pilot reply. State whether VoiceOver, keyboard, and Reduce Motion were tried.

- [ ] **Step 2: Run the automated suite once more**

```bash
xcodebuild test -scheme NorthstarOR -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'
```

Expected: TEST SUCCEEDED.

- [ ] **Step 3: Commit the note**

```bash
git add docs/evidence/nearby-support/README.md
git commit -m "$(cat <<'EOF'
Record the two-iPad support check that still has to be run on device.

EOF
)"
```

Screenshots from a real run can be added in a follow-up commit. Do not add fake images.

## Out of scope

- Video or a camera stream.
- Accepting a coordinator plan, reschedule, or superseded-plan revisions. The recipient on the question is not an accepted coverage plan. Planner copy that says plan acceptance is unavailable stays until that separate slice lands.
- Internet sync, accounts, and any label that says the rep is remote from the building.
- Editing `SessionRecordingState` schema or the checklist template.
- Staging the four dirty docs already in the worktree.

## Self-check

- Frozen snapshot: Task 1 test and Task 6 step 3.
- Reply does not confirm the item: Task 2 loopback test and Task 3 banner copy.
- Same-device fallback: idle transport sets `On this device`.
- Two-device path: Task 5 Multipeer plus Task 6.
- Old saves still open: Task 2 `testOldSnapshotWithoutQuestionsStillLoads`.
- No video and no hospital transport: Global Constraints and Out of scope.
