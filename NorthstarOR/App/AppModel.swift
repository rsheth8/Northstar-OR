import Foundation
import Observation

/// User-readable failures from the hub. Messages are calm and describe app state only.
enum AppModelError: Error, Equatable, LocalizedError {
    case noWorkspace
    case workspaceAlreadyConfigured
    case foreignWorkspace
    case unknownCase(String)
    case recordingUnavailable
    case sessionUnreadable(String)
    case acknowledgmentPending
    case noActiveSession
    case invalidDraft
    case siteInUse(String)
    case notReadyForSetup
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .noWorkspace: "Set up a workspace on this device first."
        case .workspaceAlreadyConfigured: "A workspace is already set up on this device."
        case .foreignWorkspace: "This change belongs to a different workspace."
        case .unknownCase: "This case is not in the workspace."
        case .recordingUnavailable: "Recording is unavailable for this case. It does not use the supported fictional coordination template."
        case .sessionUnreadable: "The saved recording for this case could not be read. It has been kept unchanged."
        case .acknowledgmentPending: "The active recording has a deferral awaiting acknowledgment. Acknowledge or correct it before switching cases."
        case .noActiveSession: "No active case. Start or resume a case in Planner."
        case .invalidDraft: "This draft does not belong to a saved case or session."
        case .siteInUse: "A saved case uses this site. Move or remove that case first."
        case .notReadyForSetup: "Saved data on this device isn't available right now. Nothing was changed."
        case .saveFailed(let message): message
        }
    }
}

/// App-wide state shared by every screen: the persisted workspace, its cases and recording
/// sessions, plus the sync boundary. Every workspace, case and recording change is saved as a
/// full snapshot through `WorkspaceRepository`.
@MainActor
@Observable
final class AppModel {
    enum LoadState: Equatable { case loading, needsSetup, ready, blocked(String) }
    enum Destination: Hashable { case coPilot, planner, remoteSupport }

    let sync: SyncService
    private(set) var loadState: LoadState = .loading
    private(set) var workspace: WorkspaceConfiguration?
    /// This workspace's cases, sorted by schedule.
    private(set) var cases: [Procedure] = []
    /// Simulated forecasts keyed by site ID.
    private(set) var forecasts: [String: StormForecast] = [:]
    private(set) var planningEvidenceRecords: [PlanningEvidence] = []
    private(set) var activeCaseID: String?
    /// nil until a case is explicitly started or resumed.
    private(set) var activeSession: CoPilotSession?
    /// Persistent, user-readable; cleared by the next successful save.
    private(set) var saveError: String?
    private(set) var lastSavedAt: Date?
    var selectedDestination: Destination = .coPilot
    /// Cases whose saved session could not be rebuilt. Their stored data is kept as-is.
    private(set) var unreadableSessionCaseIDs: Set<String> = []

    var reps: [DeviceRep] { workspace?.contacts ?? [] }
    var hospitals: [Hospital] { workspace?.sites ?? [] }
    /// True when stored data is unreadable or from a newer format and can be set aside.
    /// False for a transient read failure, which is retried with `load()` instead.
    var canSetAsideStoredData: Bool { repository.isSavingBlocked }
    /// True after a transient read failure (including storage unavailable at launch);
    /// `load()` then re-reads the real store.
    private(set) var canRetryLoad = false

    static let templates = [FictionalCoordinationTemplate.template]
    static let sampleWorkspaceID = "sample-workspace"

    var demoPost: DemoPost = .room {
        didSet { if oldValue != demoPost { stopNearbyLink() } }
    }
    private(set) var questions: [SupportQuestion] = []
    private(set) var sessionNotes: [SessionNote] = []
    private(set) var remoteSession: SharedSessionSnapshot?
    private(set) var remoteSessionCurrent = false
    var supportAlertsEnabled = false
    private(set) var supportAlert: String?
    @ObservationIgnored private var supportAnnouncer = VoiceAnnouncer()
    private var supportActor: LocalParticipant? {
        guard let actor = workspace?.localParticipant else { return nil }
        return LocalParticipant(id: actor.id + ":" + demoPost.rawValue, workspaceID: actor.workspaceID,
                                displayName: actor.displayName, statedRole: demoPost == .rep ? .technicalRep : actor.statedRole)
    }
    private(set) var linkState: NearbyLinkState = .idle
    private(set) var nearbyPeers: [NearbyPeer] = []
    private(set) var nearbyInvitation: NearbyPeer?
    private(set) var nearbyCall: NearbyCallController?
    private(set) var nearbyError: String?
    private var supportContext: [SupportOrigin: SupportContextSnapshot] = [:]

    private let repository: WorkspaceRepository
    private let clock: () -> Date
    private let draftSaveDelay: Duration
    @ObservationIgnored private var subscription: SyncSubscription?
    /// The current run per case (one run per case for now).
    @ObservationIgnored private var sessions: [String: CoPilotSession] = [:]
    /// Stored sessions not loaded live (unreadable or superseded); written back unchanged.
    @ObservationIgnored private var retainedSessions: [StoredSession] = []
    private var drafts: [DraftRecord] = []
    @ObservationIgnored private var pendingDraftSave: Task<Void, Never>?

    init(sync: SyncService = LocalSyncService(), store: WorkspaceStore = InMemoryWorkspaceStore(),
         clock: @escaping () -> Date = Date.init, draftSaveDelay: Duration = .milliseconds(800), post: DemoPost = .room) {
        self.sync = sync
        self.demoPost = post
        self.clock = clock
        self.draftSaveDelay = draftSaveDelay
        self.repository = WorkspaceRepository(store: store, clock: clock)
        subscription = sync.subscribe { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }
        bindNearby()
        load()
    }

    /// The app's model for this launch. `-NorthstarResetStore` starts from an empty in-memory
    /// store; `-NorthstarSampleWorkspace` loads the sample workspace in memory and starts proc-1.
    static func launching(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppModel {
        if arguments.contains("-NorthstarSampleWorkspace") {
            let model = AppModel()
            try? model.loadSampleWorkspace()
            _ = try? model.startOrResume(caseID: SampleData.Record.northShoreCase.rawValue)
            model.selectedDestination = .coPilot
            return model
        }
        if arguments.contains("-NorthstarResetStore") { return AppModel() }
        // Never fall back to a throwaway store: if Application Support is unavailable the
        // load is a retryable read failure and nothing can be saved until a retry succeeds.
        let model = AppModel(store: DeferredWorkspaceStore { try FileWorkspaceStore.applicationSupport() })
        #if targetEnvironment(macCatalyst)
        model.demoPost = .rep
        model.selectedDestination = .remoteSupport
        #endif
        return model
    }

    // MARK: - Loading

    /// Reads the stored snapshot. Sample content is never loaded implicitly.
    func load() {
        resetState()
        canRetryLoad = false
        switch repository.load() {
        case .empty:
            loadState = .needsSetup
        case .loaded(let snapshot):
            restore(snapshot)
            loadState = workspace == nil ? .needsSetup : .ready
        case .unsupportedVersion(let version):
            loadState = .blocked("Saved data on this device uses a newer format (version \(version)). It has not been changed.")
        case .unreadable:
            loadState = .blocked("Saved data on this device could not be read. It has not been changed. You can set it aside and start fresh; the file is kept on this device.")
        case .readFailed:
            canRetryLoad = true
            loadState = .blocked("Saved data on this device could not be opened right now. Nothing was changed. Try again.")
        }
    }

    /// Keeps the unreadable data under a new name, then starts at setup.
    func setAsideUnreadableData() throws {
        do { try repository.setAsideUnreadableData() } catch {
            throw AppModelError.saveFailed("The saved data could not be set aside. Nothing was changed.")
        }
        load()
    }

    // MARK: - Workspace

    func createWorkspace(_ config: WorkspaceConfiguration) throws {
        guard workspace == nil else { throw AppModelError.workspaceAlreadyConfigured }
        guard loadState == .needsSetup else { throw AppModelError.notReadyForSetup }
        try config.validate()
        try persist(WorkspaceSnapshot(workspace: config))
        workspace = config
        loadState = .ready
        selectedDestination = demoPost == .rep ? .remoteSupport : .planner
    }

    /// Explicitly loads the fictional sample workspace. Only allowed before setup.
    func loadSampleWorkspace() throws {
        guard workspace == nil else { throw AppModelError.workspaceAlreadyConfigured }
        guard loadState == .needsSetup else { throw AppModelError.notReadyForSetup }
        let sample = Self.sampleWorkspace(asOf: clock(), post: demoPost)
        try sample.workspace.validate()
        let sorted = Self.sorted(sample.cases)
        try persist(WorkspaceSnapshot(workspace: sample.workspace, forecasts: sample.forecasts, cases: sorted))
        workspace = sample.workspace
        cases = sorted
        forecasts = sample.forecasts
        loadState = .ready
        selectedDestination = demoPost == .rep ? .remoteSupport : .planner
    }

    /// Clears this device's workspace and records, then returns to setup so a fresh workspace
    /// or the sample can be loaded (e.g. before a rehearsal). Ends any nearby link and call
    /// first. Other devices keep their own records.
    func startOverOnThisDevice() throws {
        guard workspace != nil else { throw AppModelError.noWorkspace }
        stopNearbyLink()
        supportAlert = nil
        try persist(WorkspaceSnapshot())
        load()
    }

    func updateWorkspace(_ config: WorkspaceConfiguration) throws {
        guard let workspace else { throw AppModelError.noWorkspace }
        guard config.id == workspace.id else { throw AppModelError.foreignWorkspace }
        try config.validate()
        let siteIDs = Set(config.sites.map(\.id))
        // Cases must still reference existing sites; forecasts for removed sites are dropped.
        if let orphan = cases.first(where: { !siteIDs.contains($0.hospitalID) }) {
            throw AppModelError.siteInUse(orphan.hospitalID)
        }
        let nextForecasts = forecasts.filter { siteIDs.contains($0.key) }
        var updated = snapshot(workspace: config, forecasts: nextForecasts)
        updated.planningEvidenceRecords = planningEvidenceRecords.filter { siteIDs.contains($0.siteID) }
        try persist(updated)
        self.workspace = config
        forecasts = nextForecasts
        planningEvidenceRecords = updated.planningEvidenceRecords
    }

    // MARK: - Cases

    /// Creates a case, or edits the case with the same ID. A live session of an edited case
    /// shows the new title/schedule/site; its identity, template and items are unchanged.
    @discardableResult
    func saveCase(_ input: CaseInput) throws -> Procedure {
        guard let workspace else { throw AppModelError.noWorkspace }
        let procedure: Procedure
        if let previous = cases.first(where: { $0.id == input.id }) {
            procedure = try input.updating(previous, in: workspace, existingCases: cases, templates: Self.templates)
        } else {
            procedure = try input.makeProcedure(in: workspace, existingCases: cases, templates: Self.templates)
        }
        let nextCases = Self.sorted(cases.filter { $0.id != procedure.id } + [procedure])
        try persist(snapshot(cases: nextCases))
        cases = nextCases
        sessions[procedure.id]?.refreshCaseDetails(procedure)
        publishSharedSession()
        return procedure
    }

    // MARK: - Sessions

    func session(for caseID: String) -> CoPilotSession? { sessions[caseID] }

    /// Explicitly starts a new run or resumes the saved one. Switching away is blocked while
    /// the active session has a pending acknowledgment. Does not change `selectedDestination`.
    @discardableResult
    func startOrResume(caseID: String) throws -> CoPilotSession {
        guard demoPost == .room else { throw AppModelError.recordingUnavailable }
        guard workspace != nil else { throw AppModelError.noWorkspace }
        guard let procedure = cases.first(where: { $0.id == caseID }) else { throw AppModelError.unknownCase(caseID) }
        if let activeSession, activeCaseID != caseID, activeSession.pendingAlert != nil {
            throw AppModelError.acknowledgmentPending
        }
        let session: CoPilotSession
        var nextSessions = sessions
        if let existing = sessions[caseID] {
            session = existing
        } else {
            guard !unreadableSessionCaseIDs.contains(caseID) else { throw AppModelError.sessionUnreadable(caseID) }
            session = CoPilotSession(procedure: procedure, now: clock())
            guard session.isRecordingSupported else { throw AppModelError.recordingUnavailable }
            nextSessions[caseID] = session
        }
        try persist(snapshot(sessions: nextSessions, activeCaseID: caseID))
        sessions = nextSessions
        if activeCaseID != nil, activeCaseID != caseID, isSharingSession || nearbyCall != nil { stopNearbyLink() }
        activeCaseID = caseID
        activeSession = session
        publishSharedSession()
        return session
    }

    /// Applies a recording command to the active session, then saves. A rejected command
    /// throws and changes nothing. An accepted event stands even if saving fails (it was
    /// recorded on screen); `saveError` then explains it persistently and the next successful
    /// save, or `retrySave()`, includes it.
    @discardableResult
    func record(_ command: SessionCommand) throws -> SessionEvent {
        guard demoPost == .room else { throw AppModelError.recordingUnavailable }
        guard let activeSession else { throw AppModelError.noActiveSession }
        let event = try activeSession.apply(command)
        try? persist(snapshot())
        publishSupportContext()
        return event
    }

    /// Saves the current full snapshot again, e.g. after a failed save.
    func retrySave() throws {
        guard workspace != nil else { throw AppModelError.noWorkspace }
        try persist(snapshot())
        if demoPost == .rep, let remoteSession, case .connected = linkState {
            receiveSharedSession(remoteSession)
        } else { publishSharedSession() }
    }

    // MARK: - Drafts

    func draft(for key: DraftKey) -> String {
        drafts.first { $0.key == key }?.text ?? ""
    }

    /// Updates the draft in memory now; saving is coalesced so keystrokes do not each write
    /// the file. An empty draft is removed.
    func setDraft(_ text: String, for key: DraftKey) throws {
        guard let workspace, key.workspaceID == workspace.id else { throw AppModelError.invalidDraft }
        if let caseID = key.caseID, !cases.contains(where: { $0.id == caseID }) { throw AppModelError.invalidDraft }
        if let sessionID = key.sessionID {
            guard let caseID = key.caseID, sessions[caseID]?.identity.sessionID == sessionID else {
                throw AppModelError.invalidDraft
            }
        }
        drafts.removeAll { $0.key == key }
        if !text.isEmpty { drafts.append(DraftRecord(key: key, text: text, updatedAt: clock())) }
        scheduleDraftSave()
    }

    /// Writes any coalesced draft change now (e.g. when the app moves to the background).
    func flushPendingSave() {
        guard pendingDraftSave != nil else { return }
        pendingDraftSave?.cancel()
        pendingDraftSave = nil
        try? persist(snapshot())
    }

    // MARK: - Contextual support (separate from checklist events)

    func supportSnapshot(fullHistory: Bool = false) throws -> SupportContextSnapshot {
        guard let session = activeSession, let state = session.recordingState,
              let template = session.procedure.templateReference else { throw AppModelError.noActiveSession }
        let procedure = session.procedure
        let acknowledgments = session.events.compactMap { event -> String? in
            if case .warningAcknowledged(let ack) = event.payload { return ack.id }
            return nil
        }
        return SupportContextSnapshot(capturedAt: clock(), caseReference: procedure.reference ?? procedure.id,
            caseName: procedure.name, siteName: hospital(procedure.hospitalID)?.name ?? "Not recorded",
            deviceFamily: procedure.deviceFamily, templateID: template.id, templateVersion: template.version,
            selectedItemID: session.currentStep?.id, selectedItemTitle: session.currentStep?.title,
            reducedSupport: session.reducedSupport, logisticalReason: recommendation(for: procedure).reasons.first,
            lines: procedure.steps.map { .init(id: $0.id, title: $0.title,
                status: state.itemStatuses[$0.id] ?? .unrecorded, normallyCoveredByRep: $0.normallyCoveredByRep) },
            recentEvents: session.events.suffix(fullHistory ? session.events.count : 8).map { event in
                let action: String
                switch event.payload {
                case .itemSelected: action = "Item selected"
                case .confirmationRecorded: action = "Team confirmation recorded"
                case .itemDeferred: action = "Item deferred"
                case .warningAcknowledged: action = "Deferral warning acknowledged"
                case .recordCorrected: action = "Record corrected; original retained"
                }
                let title = procedure.steps.first { $0.id == event.targetItemID }?.title ?? "Item"
                return "\(event.occurredAt.formatted(date: .omitted, time: .shortened)) · \(event.actor.displayName) · \(event.source.rawValue) · \(title): \(action)"
            },
            recordingRevision: state.version, acknowledgmentIDs: Array(Set(acknowledgments)).sorted())
    }

    func latestQuestion(for sessionID: String?) -> SupportQuestion? {
        questions.last { sessionID == nil || $0.sessionID == sessionID }
    }
    func liveContext(for question: SupportQuestion) -> SupportContextSnapshot? { supportContext[question.origin] }
    func supportDraftKey(question: SupportQuestion? = nil) throws -> DraftKey {
        guard let workspace else { throw AppModelError.noWorkspace }
        if let question {
            return DraftKey(workspaceID: workspace.id, caseID: nil, sessionID: nil, kind: "supportReply:" + question.id)
        }
        guard let session = activeSession else { throw AppModelError.noActiveSession }
        return DraftKey(workspaceID: workspace.id, caseID: session.procedure.id,
            sessionID: session.identity.sessionID, kind: "supportQuestion")
    }
    func noteDraftKey() throws -> DraftKey {
        guard let workspace else { throw AppModelError.noWorkspace }
        if demoPost == .room, let session = activeSession {
            return DraftKey(workspaceID: workspace.id, caseID: session.procedure.id,
                            sessionID: session.identity.sessionID, kind: "sessionNote")
        }
        guard let origin = supportOrigin else { throw AppModelError.noActiveSession }
        return DraftKey(workspaceID: workspace.id, caseID: nil, sessionID: nil, kind: "sessionNote:" + origin.workspaceID + ":" + origin.caseID + ":" + origin.sessionID)
    }

    @discardableResult
    func sendSupportQuestion(text: String, recipient: DeviceRep) throws -> SupportQuestion {
        guard demoPost == .room, let workspace, let session = activeSession,
              session.isRecordingSupported, reps.contains(where: { $0.id == recipient.id && $0.statedRole == .technicalRep }) else { throw AppModelError.recordingUnavailable }
        let question = try SupportQuestion.make(id: UUID().uuidString, workspaceID: workspace.id,
            caseID: session.procedure.id, sessionID: session.identity.sessionID, text: text, sender: workspace.localParticipant,
            recipientContactID: recipient.id, recipientName: recipient.name, sentAt: clock(), snapshot: supportSnapshot())
        questions.append(question)
        try persist(snapshot())
        publishSharedSession()
        try transmitSupport(.question(question))
        return questions.last { $0.id == question.id }!
    }

    @discardableResult
    func sendSessionNote(text: String) throws -> SessionNote {
        guard let workspace else { throw AppModelError.noWorkspace }
        let origin: SupportOrigin
        guard let actor = supportActor else { throw AppModelError.noWorkspace }
        if demoPost == .room {
            guard let session = activeSession else { throw AppModelError.noActiveSession }
            origin = SupportOrigin(workspaceID: session.identity.workspaceID, caseID: session.identity.caseID, sessionID: session.identity.sessionID)
        } else if let shared = remoteSession, remoteSessionCurrent {
            origin = shared.origin
        } else if let question = latestQuestion(for: nil), !(sync.nearby is MultipeerNearbyTransport) {
            origin = question.origin
        } else {
            throw AppModelError.noActiveSession
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let kept = sessionNotes.last(where: { $0.origin == origin && $0.actor.id == actor.id && $0.text == trimmed && $0.delivery != .receivedByPeer }) {
            try persist(snapshot())
            try transmitSupport(.note(kept))
            return sessionNotes.last { $0.id == kept.id }!
        }
        let note = try SessionNote.make(id: UUID().uuidString, workspaceID: origin.workspaceID, caseID: origin.caseID,
                                        sessionID: origin.sessionID, text: text, actor: actor, sentAt: clock())
        sessionNotes.append(note)
        try persist(snapshot())
        publishSharedSession()
        try transmitSupport(.note(note))
        return sessionNotes.last { $0.id == note.id }!
    }

    func supportThread(sessionID: String) -> [SupportThreadEntry] {
        SupportExchange.thread(questions: questions, notes: sessionNotes, sessionID: sessionID)
    }

    private func respondingActor(for question: SupportQuestion) throws -> LocalParticipant {
        guard let workspace else { throw AppModelError.noWorkspace }
        if demoPost == .rep {
            if remoteSessionCurrent, remoteSession?.origin != question.origin { throw AppModelError.foreignWorkspace }
            return supportActor ?? workspace.localParticipant
        }
        guard question.workspaceID == workspace.id, linkState == .idle,
              let contact = reps.first(where: { $0.id == question.recipientContactID && $0.statedRole == .technicalRep }) else {
            throw AppModelError.recordingUnavailable
        }
        return LocalParticipant(id: contact.id, workspaceID: workspace.id, displayName: contact.name, statedRole: .technicalRep)
    }
    func acknowledgeQuestion(_ id: String) throws {
        guard let index = questions.firstIndex(where: { $0.id == id }) else { throw SupportExchangeError.unknownMessage }
        _ = try respondingActor(for: questions[index])
        if questions[index].acknowledgement == nil {
            questions[index] = try SupportExchange.acknowledge(questions[index], by: respondingActor(for: questions[index]), at: clock())
            try persist(snapshot())
        }
        if let envelope = questions[index].acknowledgementEnvelope { try transmitSupport(envelope) }
    }
    func sendSupportReply(_ id: String, text: String) throws {
        guard let index = questions.firstIndex(where: { $0.id == id }) else { throw SupportExchangeError.unknownMessage }
        _ = try respondingActor(for: questions[index])
        if questions[index].reply == nil {
            questions[index] = try SupportExchange.reply(questions[index], text: text, from: respondingActor(for: questions[index]), at: clock())
            try persist(snapshot())
        }
        if let envelope = questions[index].replyEnvelope { try transmitSupport(envelope) }
    }
    func retrySupportMessage(_ messageID: String) throws {
        if let note = sessionNotes.first(where: { $0.messageID == messageID }) {
            guard supportOrigin == note.origin else { throw AppModelError.foreignWorkspace }
            try persist(snapshot())
            try transmitSupport(.note(note))
            return
        }
        for question in questions {
            let candidates = [SupportEnvelope.question(question), question.acknowledgementEnvelope, question.replyEnvelope].compactMap { $0 }
            if let envelope = candidates.first(where: { $0.id == messageID }) {
                if envelope.kind == .question {
                    guard demoPost == .room, question.workspaceID == workspace?.id else { throw AppModelError.foreignWorkspace }
                } else { _ = try respondingActor(for: question) }
                try transmitSupport(envelope)
                return
            }
        }
        throw SupportExchangeError.unknownMessage
    }
    private func transmitSupport(_ envelope: SupportEnvelope) throws {
        let current = SupportInbox(questions: questions, liveContext: supportContext, messages: sessionNotes)
        if linkState == .idle {
            let inbox = try SupportExchange.markDelivery(messageID: envelope.id, delivery: .onThisDevice, in: current)
            questions = inbox.questions
            sessionNotes = inbox.messages
            try persist(snapshot()); return
        }
        var inbox = try SupportExchange.markDelivery(messageID: envelope.id, delivery: .waitingForPeer, in: current)
        questions = inbox.questions
        sessionNotes = inbox.messages
        try persist(snapshot())
        do {
            try sync.sendSupport(envelope)
        } catch {
            inbox = try SupportExchange.markDelivery(messageID: envelope.id, delivery: .failed,
                in: SupportInbox(questions: questions, messages: sessionNotes))
            questions = inbox.questions
            sessionNotes = inbox.messages
            try? persist(snapshot())
            throw error
        }
    }
    private func receiveSupport(_ envelope: SupportEnvelope) {
        guard loadState == .ready else { return }
        // Room accepts responses to its retained questions; Rep accepts self-contained briefs.
        if demoPost == .room, envelope.kind == .question || envelope.kind == .contextUpdate { return }
        if demoPost == .rep, envelope.kind == .questionAcknowledgement || envelope.kind == .reply { return }
        let activeOrigin = activeSession.map {
            SupportOrigin(workspaceID: $0.identity.workspaceID, caseID: $0.identity.caseID, sessionID: $0.identity.sessionID)
        }
        let noteGate = envelope.kind == .note ? (demoPost == .room ? activeOrigin : remoteSession?.origin) : nil
        let applied = SupportExchange.apply(envelope, to: SupportInbox(questions: questions, liveContext: supportContext, messages: sessionNotes),
                                            current: noteGate)
        guard applied.accepted else { return }
        questions = applied.inbox.questions
        supportContext = applied.inbox.liveContext
        sessionNotes = applied.inbox.messages
        do { try persist(snapshot()) } catch { return }
        if envelope.kind != .receipt { publishSharedSession() }
        if applied.receiptForID != nil, envelope.kind != .contextUpdate, case .connected = linkState {
            try? sync.sendSupport(.receipt(for: envelope, at: clock()))
        }
    }
    private func publishSupportContext() {
        publishSharedSession()
        guard demoPost == .room, let session = activeSession,
              let question = latestQuestion(for: session.identity.sessionID), let context = try? supportSnapshot() else { return }
        supportContext[question.origin] = context
        if case .connected = linkState { try? sync.sendSupport(.context(context, for: question)) }
    }
    private func bindNearby() {
        linkState = sync.nearby.linkState
        sync.nearby.onEnvelope = { [weak self] in self?.receiveSupport($0) }
        sync.nearby.onLinkState = { [weak self] state in
            guard let self else { return }
            self.linkState = state
            if state == .disconnected || state == .idle {
                self.remoteSessionCurrent = false
                self.invitationTimer?.cancel()
                self.endRepCall()
                self.callInvitation = nil
            }
            if case .connected = state, self.demoPost == .room {
                self.publishSharedSession()
                self.retryPendingSupport()
            }
            self.refreshNearbyDiscovery()
        }
        sync.nearby.onSnapshot = { [weak self] in self?.receiveSharedSession($0) }
        sync.nearby.onInvitation = { [weak self] in self?.receiveInvitation($0) }
        sync.nearby.onCallSignal = { [weak self] in self?.receiveCallSignal($0) }
        sync.nearby.onDiscoveryChange = { [weak self] in self?.refreshNearbyDiscovery() }
        refreshNearbyDiscovery()
    }
    private func refreshNearbyDiscovery() {
        nearbyPeers = sync.nearby.peers; nearbyInvitation = sync.nearby.invitation; nearbyError = sync.nearby.errorMessage
    }
    func installNearbyTransport(_ transport: NearbyTransport) {
        nearbyCall?.stop()
        sync.installNearby(transport); nearbyCall = transport as? NearbyCallController; bindNearby()
    }
    var isSharingSession: Bool { sync.nearby.supportsSession }
    var supportOrigin: SupportOrigin? {
        if demoPost == .rep { return remoteSession?.origin ?? latestQuestion(for: nil)?.origin }
        return activeSession.map { SupportOrigin(workspaceID: $0.identity.workspaceID, caseID: $0.identity.caseID, sessionID: $0.identity.sessionID) }
    }
    var supportRecordingEnded: Bool {
        demoPost == .room ? activeSession?.isFinished == true : remoteSession?.recordingSummary.hasPrefix("Recording ended") == true
    }
    private func receiveSharedSession(_ incoming: SharedSessionSnapshot) {
        guard demoPost == .rep else { return }
        if remoteSessionCurrent, let previous = remoteSession, previous.origin == incoming.origin,
           incoming.context.recordingRevision < previous.context.recordingRevision { return }
        if remoteSession?.origin != incoming.origin { endRepCall(); callInvitation = nil; invitationTimer?.cancel() }
        let previous = remoteSession
        let wasCurrent = remoteSessionCurrent
        remoteSession = incoming
        if let previous, previous.origin == incoming.origin {
            let deferred = incoming.context.lines.filter { line in
                line.status == .deferred && previous.context.lines.first(where: { $0.id == line.id })?.status != .deferred
            }
            let newQuestions = incoming.questions.filter { q in !previous.questions.contains(where: { $0.id == q.id }) }
            if !deferred.isEmpty || !newQuestions.isEmpty {
                supportAlert = !newQuestions.isEmpty ? "A question is waiting on this case." : "\(deferred[0].title) was deferred."
                if supportAlertsEnabled, callInvitation?.state != .accepted, let supportAlert { supportAnnouncer.say(supportAlert) }
            }
        }
        supportContext[incoming.origin] = incoming.context
        // Merge the room's durable records without replacing locally pending messages.
        for question in incoming.questions {
            if let index = questions.firstIndex(where: { $0.origin == question.origin && $0.id == question.id }) {
                questions[index] = SupportExchange.mergingSnapshot(question, local: questions[index])
            } else { questions.append(question) }
        }
        for note in incoming.messages {
            if !sessionNotes.contains(where: { $0.messageID == note.messageID }) { sessionNotes.append(note) }
            if incoming.saved, note.actor.id == supportActor?.id,
               let marked = try? SupportExchange.markDelivery(messageID: note.messageID, delivery: .receivedByPeer, in: SupportInbox(questions: questions, messages: sessionNotes)) {
                sessionNotes = marked.messages
            }
        }
        do { try persist(snapshot()) } catch { remoteSessionCurrent = false; return }
        remoteSessionCurrent = true
        for question in incoming.questions { try? sync.sendSupport(.receipt(for: .question(question), at: clock())) }
        for note in incoming.messages where note.actor.id != supportActor?.id {
            try? sync.sendSupport(.receipt(for: .note(note), at: clock()))
        }
        if !wasCurrent { retryPendingSupport() }
    }
    private func retryPendingSupport() {
        guard let origin = supportOrigin, case .connected = linkState else { return }
        let notes = sessionNotes.filter { $0.origin == origin && $0.actor.id == supportActor?.id && $0.delivery != .receivedByPeer }
        for note in notes { try? retrySupportMessage(note.messageID) }
        for question in questions.filter({ $0.origin == origin }) {
            if demoPost == .room, question.delivery != .receivedByPeer { try? retrySupportMessage(question.messageID) }
            if demoPost == .rep {
                if let ack = question.acknowledgement, ack.delivery != .receivedByPeer { try? retrySupportMessage(ack.id) }
                if let reply = question.reply, reply.delivery != .receivedByPeer { try? retrySupportMessage(reply.id) }
            }
        }
    }
    private(set) var callInvitation: CallInvitation?
    private var sharedServer = ""
    private var invitationTimer: Task<Void, Never>?
    func startSharedSession(server: String) {
        guard demoPost == .room, activeSession != nil else { return }
        sharedServer = server
        let transport = SharedSessionTransport(server: server)
        transport.onRefresh = { [weak self] in self?.publishSharedSession() }
        transport.onInvitation = { [weak self] in self?.receiveInvitation($0) }
        installNearbyTransport(transport)
        transport.start()
    }
    private var localCallSide: CallInvitation.Side { demoPost == .room ? .room : .rep }
    func requestCall() {
        guard let origin = supportOrigin, isSharingSession, case .connected = linkState else {
            nearbyError = "Connect to the other Northstar device before requesting a call."; return
        }
        guard !supportRecordingEnded else { nearbyError = "This recording has ended. A call cannot start."; return }
        guard demoPost == .room || remoteSessionCurrent else { return }
        guard callInvitation?.state != .requested, callInvitation?.state != .accepted else { return }
        let invitation = CallInvitation(id: UUID().uuidString, origin: origin, from: localCallSide, state: .requested, sentAt: clock())
        do { try sync.nearby.sendInvitation(invitation) } catch { nearbyError = "Call request was not sent. Reconnect and retry."; return }
        callInvitation = invitation
        nearbyError = nil
        armInvitationTimer(invitation)
    }
    func acceptInvitation() { respondToInvitation(accept: true) }
    func declineInvitation() { respondToInvitation(accept: false) }
    func cancelInvitation() {
        guard var invitation = callInvitation, invitation.state == .requested, invitation.from == localCallSide else { return }
        invitation.state = .canceled
        callInvitation = invitation; invitationTimer?.cancel(); sendInvitation(invitation)
    }
    private func invitationIsFresh(_ value: CallInvitation) -> Bool {
        let age = clock().timeIntervalSince(value.sentAt)
        return age >= -5 && age < 30
    }
    private func respondToInvitation(accept: Bool) {
        guard var invitation = callInvitation, invitation.state == .requested,
              invitation.from != localCallSide, invitation.origin == supportOrigin else { return }
        guard invitationIsFresh(invitation), !supportRecordingEnded else {
            invitation.state = .expired; callInvitation = invitation; sendInvitation(invitation); return
        }
        invitation.state = accept ? .accepted : .declined
        do { try sync.nearby.sendInvitation(invitation) } catch { nearbyError = "Response was not sent. Reconnect and retry."; return }
        callInvitation = invitation; invitationTimer?.cancel()
        if accept { startAcceptedCall() }
    }
    private func receiveInvitation(_ incoming: CallInvitation) {
        guard incoming.origin == supportOrigin, case .connected = linkState else { return }
        if incoming.state == .requested {
            guard incoming.from != localCallSide, invitationIsFresh(incoming), !supportRecordingEnded,
                  callInvitation?.state != .accepted else {
                var rejected = incoming; rejected.state = .declined; sendInvitation(rejected); return
            }
            if let current = callInvitation, current.state == .requested, current.id != incoming.id {
                if incoming.id < current.id {
                    var canceled = current; canceled.state = .canceled; sendInvitation(canceled)
                } else {
                    var declined = incoming; declined.state = .declined; sendInvitation(declined); return
                }
            }
            callInvitation = incoming; armInvitationTimer(incoming)
            return
        }
        guard let current = callInvitation, current.id == incoming.id,
              current.origin == incoming.origin, current.from == incoming.from, current.sentAt == incoming.sentAt,
              current.state == .requested else { return }
        if incoming.state == .accepted {
            guard current.from == localCallSide, invitationIsFresh(current), !supportRecordingEnded else { return }
            callInvitation = incoming; invitationTimer?.cancel(); startAcceptedCall()
        } else {
            callInvitation = incoming; invitationTimer?.cancel()
        }
    }
    private func sendInvitation(_ invitation: CallInvitation) {
        do { try sync.nearby.sendInvitation(invitation) } catch { nearbyError = "Call request was not sent. Reconnect and retry." }
    }
    private func armInvitationTimer(_ invitation: CallInvitation) {
        invitationTimer?.cancel()
        let remaining = max(0, 30 - clock().timeIntervalSince(invitation.sentAt))
        invitationTimer = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(remaining)) } catch { return }
            guard !Task.isCancelled, let self, self.callInvitation?.id == invitation.id, self.callInvitation?.state == .requested else { return }
            var expired = invitation; expired.state = .expired
            self.callInvitation = expired; self.sendInvitation(expired)
        }
    }
    private func startAcceptedCall() {
        guard callInvitation?.state == .accepted, !supportRecordingEnded else { return }
        if sync.nearby is MultipeerNearbyTransport {
            let call = NearbyCallController(role: demoPost) { [weak self] payload in
                guard let self, let invitation = self.callInvitation, invitation.state == .accepted else { return }
                try? self.sync.nearby.sendCallSignal(.init(callID: invitation.id, origin: invitation.origin, payload: payload))
            }
            nearbyCall?.stop(); nearbyCall = call
            call.onLinkState = { [weak self, weak call] state in
                guard let self, let call, self.nearbyCall === call, state == .disconnected else { return }
                self.nearbyError = call.status
                self.endRepCall()
            }
            call.start()
        } else { startRepCall(server: sharedServer) }
    }
    private func receiveCallSignal(_ signal: NativeCallSignal) {
        guard let invitation = callInvitation, invitation.state == .accepted,
              signal.callID == invitation.id, signal.origin == invitation.origin else { return }
        if signal.payload == "end" { nearbyCall?.stop(); callInvitation = nil; return }
        nearbyCall?.receiveSignal(signal.payload)
    }
    private func publishSharedSession() {
        guard demoPost == .room, sync.nearby.supportsSession, case .connected = linkState,
              let session = activeSession, let context = try? supportSnapshot(fullHistory: true) else { return }
        let identity = session.identity
        let origin = SupportOrigin(workspaceID: identity.workspaceID, caseID: identity.caseID, sessionID: identity.sessionID)
        let snapshot = SharedSessionSnapshot(origin: origin, context: context,
            recordingSummary: session.recordingSummary, saved: saveError == nil,
            questions: saveError == nil ? questions.filter { $0.origin == origin } : [],
            messages: saveError == nil ? sessionNotes.filter { $0.origin == origin } : [])
        do { try sync.nearby.publish(snapshot) } catch { nearbyError = error.localizedDescription }
    }
    func endRepCall() {
        if let invitation = callInvitation, invitation.state == .accepted {
            try? sync.nearby.sendCallSignal(.init(callID: invitation.id, origin: invitation.origin, payload: "end"))
        }
        nearbyCall?.stop()
        if callInvitation?.state == .accepted { callInvitation = nil }
    }
    func startRepCall(server: String) {
        guard demoPost == .room, callInvitation?.state == .accepted, !supportRecordingEnded else { return }
        let call = NearbyCallController(signalingURL: server)
        if isSharingSession {
            nearbyCall?.stop()
            nearbyCall = call
            // The independent session transport owns support messages during calls.
        } else { installNearbyTransport(call) }
        call.start()
    }
    func startNearbyLink() { installNearbyTransport(MultipeerNearbyTransport(role: demoPost)); sync.nearby.start() }
    func stopNearbyLink() {
        invitationTimer?.cancel()
        callInvitation = nil
        nearbyCall?.stop(); sync.nearby.stop(); linkState = .idle; refreshNearbyDiscovery()
    }
    func inviteNearby(_ id: String) throws { try sync.nearby.invite(id) }
    func answerNearbyInvitation(accept: Bool) { sync.nearby.respondToInvitation(accept: accept) }

    // MARK: - Planning helpers

    func recommendation(for procedure: Procedure) -> CoverageMatcher.Recommendation {
        CoverageMatcher().recommend(for: procedure, reps: reps, forecast: planningEvidence(for: procedure.hospitalID)?.forecast, now: clock())
    }

    func planningEvidence(for siteID: String) -> PlanningEvidence? {
        planningEvidenceRecords.filter { $0.siteID == siteID }.max { $0.revision < $1.revision }
            ?? forecasts[siteID].map { PlanningEvidence.legacy(siteID: siteID, forecast: $0) }
    }

    @discardableResult
    func savePlanningEvidence(_ proposed: PlanningEvidence, expectedRevision: Int?) throws -> PlanningEvidence {
        guard workspace != nil else { throw AppModelError.noWorkspace }
        guard hospitals.contains(where: { $0.id == proposed.siteID }) else { throw WorkspaceContractError.unknownSite(proposed.siteID) }
        let previous = planningEvidence(for: proposed.siteID)
        guard previous?.revision == expectedRevision else { throw PlanningEvidence.ValidationError.invalid("Planning evidence changed. Reopen the editor before saving.") }
        var evidence = proposed
        evidence.id = UUID().uuidString
        evidence.revision = (previous?.revision ?? 0) + 1
        evidence.recordedAt = clock()
        try evidence.validate()
        let records = planningEvidenceRecords + [evidence]
        var next = snapshot()
        next.planningEvidenceRecords = records
        try persist(next)
        planningEvidenceRecords = records
        return evidence
    }

    func hospital(_ id: String) -> Hospital? { hospitals.first { $0.id == id } }

    // MARK: - Private

    private func handle(_ event: SyncEvent) {
        guard let activeSession else { return }
        switch event {
        case .reducedSupportChanged(let id, let on) where demoPost == .room && id == activeSession.procedure.id:
            activeSession.setReducedSupport(on)
            try? persist(snapshot())
            publishSupportContext()
        case .remoteMessage(let id, let from, let text) where id == activeSession.procedure.id:
            activeSession.receiveRemoteMessage(text, from: from)
        default:
            break
        }
    }

    private func resetState() {
        pendingDraftSave?.cancel()
        pendingDraftSave = nil
        workspace = nil
        cases = []
        forecasts = [:]
        planningEvidenceRecords = []
        activeCaseID = nil
        activeSession = nil
        sessions = [:]
        retainedSessions = []
        drafts = []
        questions = []
        sessionNotes = []
        remoteSession = nil; remoteSessionCurrent = false
        supportContext = [:]
        unreadableSessionCaseIDs = []
        saveError = nil
        loadState = .loading
    }

    private func restore(_ snapshot: WorkspaceSnapshot) {
        workspace = snapshot.workspace
        cases = Self.sorted(snapshot.cases)
        forecasts = snapshot.forecasts
        planningEvidenceRecords = snapshot.planningEvidenceRecords
        drafts = snapshot.drafts
        questions = snapshot.supportQuestions
        sessionNotes = snapshot.sessionNotes
        remoteSession = snapshot.remoteSession; remoteSessionCurrent = false
        // The latest run per case is live; anything else is retained unchanged.
        var visitedCases = Set<String>()
        for stored in snapshot.sessions.sorted(by: Self.sessionOrder).reversed() {
            let caseID = stored.state.identity.caseID
            guard visitedCases.insert(caseID).inserted else {
                retainedSessions.append(stored)
                continue
            }
            // Note: restore requires the case's items to match the session's history.
            guard let procedure = cases.first(where: { $0.id == caseID }),
                  let session = try? CoPilotSession.restore(procedure: procedure, from: stored) else {
                retainedSessions.append(stored)
                unreadableSessionCaseIDs.insert(caseID)
                continue
            }
            sessions[caseID] = session
            unreadableSessionCaseIDs.remove(caseID)
        }
        if let caseID = snapshot.activeCaseID, let session = sessions[caseID] {
            activeCaseID = caseID
            activeSession = session
        }
        selectedDestination = activeSession == nil ? .planner : .coPilot
    }

    /// The full snapshot from current state, with optional replacements for a pending change.
    private func snapshot(workspace: WorkspaceConfiguration? = nil, forecasts: [String: StormForecast]? = nil,
                          cases: [Procedure]? = nil, sessions: [String: CoPilotSession]? = nil,
                          activeCaseID: String?? = nil) -> WorkspaceSnapshot {
        let live = (sessions ?? self.sessions).values.compactMap(\.storedSession)
        return WorkspaceSnapshot(workspace: workspace ?? self.workspace, forecasts: forecasts ?? self.forecasts,
                                 cases: cases ?? self.cases,
                                 sessions: (retainedSessions + live).sorted(by: Self.sessionOrder),
                                 drafts: drafts.sorted { ($0.updatedAt, $0.key.kind) < ($1.updatedAt, $1.key.kind) },
                                 activeCaseID: activeCaseID ?? self.activeCaseID, supportQuestions: questions,
                                 sessionNotes: sessionNotes, remoteSession: remoteSession, planningEvidenceRecords: planningEvidenceRecords)
    }

    /// Saves before the caller commits its change. On failure sets a persistent `saveError`.
    private func persist(_ snapshot: WorkspaceSnapshot) throws {
        do {
            let receipt = try repository.save(snapshot)
            lastSavedAt = receipt.savedAt
            saveError = nil
            // A full save includes every draft, so a pending coalesced save is not needed.
            pendingDraftSave?.cancel()
            pendingDraftSave = nil
        } catch {
            let message = Self.message(for: error)
            saveError = message
            throw AppModelError.saveFailed(message)
        }
    }

    private func scheduleDraftSave() {
        pendingDraftSave?.cancel()
        let delay = draftSaveDelay
        pendingDraftSave = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            self.pendingDraftSave = nil
            try? self.persist(self.snapshot())
        }
    }

    private static func message(for error: Error) -> String {
        switch error as? RepositoryError {
        case .blockedByUnreadableData:
            "Couldn't save on this device. Saved data could not be read, so it won't be overwritten."
        case .storageUnavailable:
            "Couldn't save on this device right now. Your changes are still here; try again."
        default:
            "Couldn't save on this device. Your changes are still here."
        }
    }

    private static func sorted(_ cases: [Procedure]) -> [Procedure] {
        cases.sorted { ($0.scheduledAt, $0.id) < ($1.scheduledAt, $1.id) }
    }

    private static func sessionOrder(_ a: StoredSession, _ b: StoredSession) -> Bool {
        (a.state.startedAt, a.state.identity.sessionID) < (b.state.startedAt, b.state.identity.sessionID)
    }

    struct SampleWorkspace {
        let workspace: WorkspaceConfiguration
        let cases: [Procedure]
        let forecasts: [String: StormForecast]
    }

    /// Fictional sample content as ordinary workspace records. Never progress or acceptance.
    /// On the rep station the local participant is the sample's remote technical rep.
    nonisolated static func sampleWorkspace(asOf: Date, post: DemoPost = .room) -> SampleWorkspace {
        let seed = SampleData.make(clock: { asOf })
        let id = "sample-workspace"
        let sites = seed.hospitals.map { site -> Hospital in
            var site = site
            site.workspaceID = id
            site.timeZoneIdentifier = "America/Chicago"
            return site
        }
        let contacts = seed.reps.map { rep -> DeviceRep in
            var rep = rep
            rep.workspaceID = id
            return rep
        }
        let cases = seed.procedures.map { procedure -> Procedure in
            var procedure = procedure
            procedure.workspaceID = id
            procedure.reference = procedure.reference ?? procedure.id
            return procedure
        }
        let participant = post == .rep
            ? LocalParticipant(id: "sample-rep-participant", workspaceID: id,
                               displayName: contacts.first?.name ?? "Fictional technical rep", statedRole: .technicalRep)
            : LocalParticipant(id: "sample-participant", workspaceID: id,
                               displayName: "Jordan Ellis", statedRole: .coordinator)
        let config = WorkspaceConfiguration(id: id, name: "Arrowhead Cardiac Coverage (fictional)", sites: sites,
                                            contacts: contacts, localParticipant: participant)
        return SampleWorkspace(workspace: config, cases: cases, forecasts: seed.forecasts)
    }
}
