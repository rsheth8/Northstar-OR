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
    private(set) var activeCaseID: String?
    /// nil until a case is explicitly started or resumed.
    private(set) var activeSession: CoPilotSession?
    /// Persistent, user-readable; cleared by the next successful save.
    private(set) var saveError: String?
    private(set) var lastSavedAt: Date?
    var selectedDestination: Destination = .coPilot
    /// Cases whose saved session could not be rebuilt. Their stored data is kept as-is.
    private(set) var unreadableSessionCaseIDs: Set<String> = []
    /// Every support request in this workspace, oldest first, with questions and messages.
    private(set) var supportRequests: [SupportRequest] = []

    var reps: [DeviceRep] { workspace?.contacts ?? [] }
    var hospitals: [Hospital] { workspace?.sites ?? [] }
    /// True when stored data is unreadable or from a newer format and can be set aside.
    /// False for a transient read failure, which is retried with `load()` instead.
    var canSetAsideStoredData: Bool { repository.isSavingBlocked }

    static let templates = [FictionalCoordinationTemplate.template]
    static let sampleWorkspaceID = "sample-workspace"

    private let repository: WorkspaceRepository
    private let clock: () -> Date
    private let draftSaveDelay: Duration
    @ObservationIgnored private var subscription: SyncSubscription?
    /// The current run per case (one run per case for now).
    @ObservationIgnored private var sessions: [String: CoPilotSession] = [:]
    /// Stored sessions not loaded live (unreadable or superseded); written back unchanged.
    @ObservationIgnored private var retainedSessions: [StoredSession] = []
    @ObservationIgnored private var drafts: [DraftRecord] = []
    /// Reduced-support context of retained (not live) sessions, written back unchanged.
    @ObservationIgnored private var retainedReducedSupportSessionIDs: Set<String> = []
    @ObservationIgnored private var pendingDraftSave: Task<Void, Never>?

    init(sync: SyncService = LocalSyncService(), store: WorkspaceStore = InMemoryWorkspaceStore(),
         clock: @escaping () -> Date = Date.init, draftSaveDelay: Duration = .milliseconds(800)) {
        self.sync = sync
        self.clock = clock
        self.draftSaveDelay = draftSaveDelay
        self.repository = WorkspaceRepository(store: store, clock: clock)
        // A transport may call back on any thread; always handle events on the main actor.
        subscription = sync.subscribe { [weak self] event in
            if Thread.isMainThread {
                MainActor.assumeIsolated { self?.handle(event) }
            } else {
                DispatchQueue.main.async { MainActor.assumeIsolated { self?.handle(event) } }
            }
        }
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
        do {
            return AppModel(store: try FileWorkspaceStore.applicationSupport())
        } catch {
            let model = AppModel()
            model.loadState = .blocked("Storage on this device is unavailable, so nothing can be saved. Restart the app to try again.")
            return model
        }
    }

    // MARK: - Loading

    /// Reads the stored snapshot. Sample content is never loaded implicitly.
    func load() {
        resetState()
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
        try config.validate()
        try persist(WorkspaceSnapshot(workspace: config))
        workspace = config
        loadState = .ready
        selectedDestination = .planner
    }

    /// Explicitly loads the fictional sample workspace. Only allowed before setup.
    func loadSampleWorkspace() throws {
        guard workspace == nil else { throw AppModelError.workspaceAlreadyConfigured }
        let sample = Self.sampleWorkspace(asOf: clock())
        try sample.workspace.validate()
        let sorted = Self.sorted(sample.cases)
        try persist(WorkspaceSnapshot(workspace: sample.workspace, forecasts: sample.forecasts, cases: sorted))
        workspace = sample.workspace
        cases = sorted
        forecasts = sample.forecasts
        loadState = .ready
        selectedDestination = .planner
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
        let contactIDs = Set(config.contacts.map(\.id))
        if let request = supportRequests.first(where: { $0.status != .withdrawn && !contactIDs.contains($0.contactID) }) {
            throw SupportError.contactInUse(request.contactID)
        }
        let nextForecasts = forecasts.filter { siteIDs.contains($0.key) }
        try persist(snapshot(workspace: config, forecasts: nextForecasts))
        self.workspace = config
        forecasts = nextForecasts
    }

    // MARK: - Cases

    /// Creates a case, or edits the case with the same ID. Existing sessions keep the case
    /// snapshot they were started with until the next launch.
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
        return procedure
    }

    // MARK: - Sessions

    func session(for caseID: String) -> CoPilotSession? { sessions[caseID] }

    /// Explicitly starts a new run or resumes the saved one. Switching away is blocked while
    /// the active session has a pending acknowledgment. Does not change `selectedDestination`.
    @discardableResult
    func startOrResume(caseID: String) throws -> CoPilotSession {
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
            session.appendSupportActivity(supportActivity(for: caseID))
            nextSessions[caseID] = session
        }
        try persist(snapshot(sessions: nextSessions, activeCaseID: caseID))
        sessions = nextSessions
        activeCaseID = caseID
        activeSession = session
        return session
    }

    /// Applies a recording command to the active session, then saves. A rejected command
    /// throws and changes nothing. An accepted event stands even if saving fails (it was
    /// recorded on screen); `saveError` then explains it persistently and the next successful
    /// save, or `retrySave()`, includes it.
    @discardableResult
    func record(_ command: SessionCommand) throws -> SessionEvent {
        guard let activeSession else { throw AppModelError.noActiveSession }
        let event = try activeSession.apply(command)
        try? persist(snapshot())
        return event
    }

    /// Saves the current full snapshot again, e.g. after a failed save.
    func retrySave() throws {
        guard workspace != nil else { throw AppModelError.noWorkspace }
        try persist(snapshot())
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

    // MARK: - Support (F06/F07)

    /// This case's requests, oldest first, including withdrawn and declined ones.
    func supportRequests(for caseID: String) -> [SupportRequest] {
        supportRequests.filter { $0.caseID == caseID }
    }

    /// The case's one current plan: its latest request, unless that was withdrawn.
    func currentRequest(for caseID: String) -> SupportRequest? {
        guard let latest = supportRequests.last(where: { $0.caseID == caseID }), latest.status != .withdrawn else { return nil }
        return latest
    }

    func supportRequest(_ id: String) -> SupportRequest? { supportRequests.first { $0.id == id } }

    /// Requests a named contact for a case. Any open request for the case is withdrawn.
    @discardableResult
    func requestSupport(caseID: String, contactID: String, arrangement: SupportArrangement, reason: String,
                        requestID: String = UUID().uuidString) throws -> SupportRequest {
        guard let workspace else { throw AppModelError.noWorkspace }
        guard cases.contains(where: { $0.id == caseID }) else { throw AppModelError.unknownCase(caseID) }
        guard let contact = workspace.contacts.first(where: { $0.id == contactID }) else {
            throw SupportError.unknownContact(contactID)
        }
        if arrangement == .remote, !contact.canSupportRemotely { throw SupportError.contactNotRemoteCapable }
        let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reason.isEmpty else { throw SupportError.reasonRequired }
        guard reason.count <= SupportError.maximumTextLength else { throw SupportError.textTooLong }
        let request = SupportRequest(id: requestID, workspaceID: workspace.id, caseID: caseID, contactID: contact.id,
            contactName: contact.name, contactRole: contact.statedRole ?? .technicalRep, arrangement: arrangement,
            reason: reason, requestedByName: workspace.localParticipant.displayName, requestedAt: clock(),
            status: .requested, respondedAt: nil, withdrawnAt: nil, questions: [], messages: [])
        try apply(.requested(request), broadcast: true)
        return supportRequest(requestID) ?? request
    }

    /// The coordinator withdraws a requested or accepted request. Repeating it changes nothing.
    func withdrawRequest(_ id: String) throws {
        guard workspace != nil else { throw AppModelError.noWorkspace }
        guard supportRequest(id) != nil else { throw SupportError.unknownRequest(id) }
        try apply(.withdrawn(requestID: id, at: clock()), broadcast: true)
    }

    /// The named contact accepts or declines (rep role on this device). Repeating the same
    /// answer changes nothing; changing an answer is refused.
    func respond(toRequest id: String, accept: Bool) throws {
        guard workspace != nil else { throw AppModelError.noWorkspace }
        guard supportRequest(id) != nil else { throw SupportError.unknownRequest(id) }
        try apply(.responded(requestID: id, accepted: accept, at: clock()), broadcast: true)
    }

    /// Asks the accepted contact a question from the case being recorded. Allowed while an
    /// acknowledgment is pending; recording state is not changed. The snapshot is captured now
    /// and never updated.
    @discardableResult
    func askQuestion(requestID: String, text: String, questionID: String = UUID().uuidString) throws -> SupportQuestion {
        guard let workspace else { throw AppModelError.noWorkspace }
        guard let request = supportRequest(requestID) else { throw SupportError.unknownRequest(requestID) }
        if let existing = request.questions.first(where: { $0.id == questionID }) { return existing }
        try Self.requireAccepted(request)
        guard currentRequest(for: request.caseID)?.id == request.id else { throw SupportError.notCurrentRequest }
        let text = try Self.validatedText(text)
        guard let session = activeSession else { throw AppModelError.noActiveSession }
        guard activeCaseID == request.caseID, session.procedure.id == request.caseID else { throw SupportError.notActiveCase }
        let participant = workspace.localParticipant
        let now = clock()
        let snapshot = Self.supportSnapshot(session: session, site: hospital(session.procedure.hospitalID), request: request,
                                            askedBy: participant, at: now)
        let question = SupportQuestion(id: questionID, requestID: request.id, sessionID: session.identity.sessionID,
            text: text, askedByName: participant.displayName, askedByRole: participant.statedRole, askedAt: now,
            snapshot: snapshot, acknowledgedAt: nil, acknowledgedByName: nil)
        try apply(.questionAsked(question), broadcast: true)
        return question
    }

    /// The contact acknowledges the question. Acknowledging again changes nothing.
    func acknowledgeQuestion(requestID: String, questionID: String) throws {
        guard workspace != nil else { throw AppModelError.noWorkspace }
        guard let request = supportRequest(requestID) else { throw SupportError.unknownRequest(requestID) }
        guard let question = request.questions.first(where: { $0.id == questionID }) else {
            throw SupportError.unknownQuestion(questionID)
        }
        if question.isAcknowledged { return }
        try apply(.questionAcknowledged(requestID: requestID, questionID: questionID, byName: request.contactName,
                                        at: clock()), broadcast: true)
    }

    /// A message from the contact (`fromRep`) or from the team (the workspace's local
    /// participant). Requires an accepted request. Retrying with the same `messageID` after a
    /// failed save sends it once.
    @discardableResult
    func sendMessage(requestID: String, text: String, fromRep: Bool,
                     messageID: String = UUID().uuidString) throws -> SupportMessage {
        guard let workspace else { throw AppModelError.noWorkspace }
        guard let request = supportRequest(requestID) else { throw SupportError.unknownRequest(requestID) }
        if let existing = request.messages.first(where: { $0.id == messageID }) { return existing }
        try Self.requireAccepted(request)
        let text = try Self.validatedText(text)
        let participant = workspace.localParticipant
        let message = SupportMessage(id: messageID, requestID: requestID,
            senderName: fromRep ? request.contactName : participant.displayName,
            senderRole: fromRep ? request.contactRole : participant.statedRole,
            isFromRep: fromRep, text: text, sentAt: clock())
        try apply(.messageSent(message), broadcast: true)
        return message
    }

    /// Recording events accepted after the question's snapshot, for "Changes since the
    /// question". Empty when the session is not live on this device.
    func changes(since question: SupportQuestion) -> [SessionEvent] {
        guard let session = sessions.values.first(where: { $0.identity.sessionID == question.sessionID }) else { return [] }
        return session.events.filter { $0.acceptedVersion > question.snapshot.recordingVersion }
    }

    /// Readable support history for a case, oldest first (also merged into its session log).
    func supportActivity(for caseID: String) -> [LogEntry] {
        supportRequests(for: caseID).flatMap(\.activityEntries).sorted { $0.timestamp < $1.timestamp }
    }

    /// Captures what the session has recorded right now as an immutable value.
    static func supportSnapshot(session: CoPilotSession, site: Hospital?, request: SupportRequest,
                                askedBy: LocalParticipant, at time: Date) -> SupportContextSnapshot {
        let procedure = session.procedure
        let statuses = session.recordingState?.itemStatuses ?? [:]
        let items = procedure.steps.map {
            SupportContextSnapshot.ItemSnapshot(id: $0.id, title: $0.title, isRequired: $0.isRequired,
                                                status: statuses[$0.id] ?? .unrecorded)
        }
        let lastConfirmation = session.events.last { event in
            switch event.payload {
            case .confirmationRecorded: true
            case .recordCorrected(_, let status, _, _, _): status == .teamConfirmed
            default: false
            }
        }
        let template = templates.first { $0.reference == procedure.templateReference }
        let templateLabel = template.map { "\($0.name), version \($0.reference.version)" } ?? "No supported template"
        return SupportContextSnapshot(workspaceID: session.identity.workspaceID, caseID: procedure.id,
            sessionID: session.identity.sessionID, caseReference: procedure.reference, caseTitle: procedure.name,
            siteName: site?.name ?? "Site not recorded", siteTown: site?.town ?? "", deviceFamily: procedure.deviceFamily,
            scheduledAt: procedure.scheduledAt, templateLabel: templateLabel, templateReference: procedure.templateReference,
            currentItemID: session.currentStep?.id, currentItemTitle: session.currentStep?.title,
            pendingAcknowledgmentItemTitle: session.pendingAlert?.title,
            unresolved: items.filter { $0.status != .teamConfirmed }, confirmed: items.filter { $0.status == .teamConfirmed },
            mostRecentConfirmationTitle: lastConfirmation.flatMap { event in procedure.steps.first { $0.id == event.targetItemID }?.title },
            arrangement: request.arrangement, logisticalReason: request.reason, contactName: request.contactName,
            askedByName: askedBy.displayName, askedByRole: askedBy.statedRole,
            recordingVersion: session.events.count, capturedAt: time)
    }

    // MARK: - Planning helpers

    func recommendation(for procedure: Procedure) -> CoverageMatcher.Recommendation {
        CoverageMatcher().recommend(for: procedure, reps: reps, forecast: forecasts[procedure.hospitalID])
    }

    func hospital(_ id: String) -> Hospital? { hospitals.first { $0.id == id } }

    // MARK: - Private

    private func handle(_ event: SyncEvent) {
        if case .support(let workspaceID, let change) = event {
            guard workspaceID == workspace?.id else { return }
            // Local changes are already applied (a no-op here); changes from elsewhere are
            // applied and saved, or ignored if they don't fit this device's records.
            try? apply(change, broadcast: false)
            return
        }
        guard let activeSession else { return }
        switch event {
        case .reducedSupportChanged(let id, let on) where id == activeSession.procedure.id:
            guard activeSession.reducedSupport != on else { return }
            activeSession.setReducedSupport(on, at: clock())
            // Session context, not recording: if saving fails, saveError explains it and the
            // next successful save includes it.
            try? persist(snapshot())
        case .remoteMessage(let id, let from, let text) where id == activeSession.procedure.id:
            activeSession.receiveRemoteMessage(text, from: from)
        default:
            break
        }
    }

    /// Applies one support change: save first, then commit, add readable session-log entries
    /// and (for local actions) broadcast. A repeated change is a no-op. On a failed save
    /// nothing changes and `saveError` explains it.
    private func apply(_ change: SupportChange, broadcast: Bool) throws {
        guard let workspace else { throw AppModelError.noWorkspace }
        let before = supportRequests
        let next = try change.applying(to: before)
        guard next != before else { return }
        try persist(snapshot(supportRequests: next))
        supportRequests = next
        appendActivity(for: change, before: before)
        if broadcast { sync.send(.support(workspaceID: workspace.id, change: change)) }
    }

    private func appendActivity(for change: SupportChange, before: [SupportRequest]) {
        guard let request = supportRequest(change.requestID), let session = sessions[request.caseID] else { return }
        var entries: [LogEntry] = []
        switch change {
        case .requested:
            for old in before where old.caseID == request.caseID && old.status.isOpen {
                entries.append(SupportActivity.withdrawn(old, at: request.requestedAt))
            }
            entries.append(SupportActivity.requested(request))
        case .responded(_, let accepted, let time):
            entries.append(SupportActivity.responded(request, accepted: accepted, at: time))
        case .withdrawn(_, let time):
            entries.append(SupportActivity.withdrawn(request, at: time))
        case .questionAsked(let question):
            entries.append(SupportActivity.asked(question, contactName: request.contactName))
        case .questionAcknowledged(_, let questionID, _, let time):
            if let question = request.questions.first(where: { $0.id == questionID }) {
                entries.append(SupportActivity.acknowledged(question, contactName: request.contactName, at: time))
            }
        case .messageSent(let message):
            entries.append(SupportActivity.message(message, contactName: request.contactName))
        }
        session.appendSupportActivity(entries)
    }

    private static func requireAccepted(_ request: SupportRequest) throws {
        switch request.status {
        case .accepted: return
        case .requested: throw SupportError.requestNotAccepted
        case .declined, .withdrawn: throw SupportError.requestClosed
        }
    }

    private static func validatedText(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SupportError.textRequired }
        guard trimmed.count <= SupportError.maximumTextLength else { throw SupportError.textTooLong }
        return trimmed
    }

    private func resetState() {
        pendingDraftSave?.cancel()
        pendingDraftSave = nil
        workspace = nil
        cases = []
        forecasts = [:]
        activeCaseID = nil
        activeSession = nil
        sessions = [:]
        retainedSessions = []
        drafts = []
        unreadableSessionCaseIDs = []
        supportRequests = []
        retainedReducedSupportSessionIDs = []
        saveError = nil
        loadState = .loading
    }

    private func restore(_ snapshot: WorkspaceSnapshot) {
        workspace = snapshot.workspace
        cases = Self.sorted(snapshot.cases)
        forecasts = snapshot.forecasts
        drafts = snapshot.drafts
        // The latest run per case is live; anything else is retained unchanged.
        for stored in snapshot.sessions.sorted(by: Self.sessionOrder) {
            let caseID = stored.state.identity.caseID
            guard let procedure = cases.first(where: { $0.id == caseID }),
                  let session = try? CoPilotSession.restore(procedure: procedure, from: stored) else {
                retainedSessions.append(stored)
                if sessions[caseID] == nil { unreadableSessionCaseIDs.insert(caseID) }
                continue
            }
            if let older = sessions[caseID]?.storedSession { retainedSessions.append(older) }
            sessions[caseID] = session
            unreadableSessionCaseIDs.remove(caseID)
        }
        supportRequests = snapshot.supportRequests
        let reduced = Set(snapshot.reducedSupportSessionIDs)
        for (caseID, session) in sessions {
            if reduced.contains(session.identity.sessionID) { session.setReducedSupport(true, at: session.startedAt) }
            session.appendSupportActivity(supportActivity(for: caseID))
        }
        retainedReducedSupportSessionIDs = reduced.filter { id in retainedSessions.contains { $0.state.identity.sessionID == id } }
        if let caseID = snapshot.activeCaseID, let session = sessions[caseID] {
            activeCaseID = caseID
            activeSession = session
        }
        selectedDestination = activeSession == nil ? .planner : .coPilot
    }

    /// The full snapshot from current state, with optional replacements for a pending change.
    private func snapshot(workspace: WorkspaceConfiguration? = nil, forecasts: [String: StormForecast]? = nil,
                          cases: [Procedure]? = nil, sessions: [String: CoPilotSession]? = nil,
                          activeCaseID: String?? = nil, supportRequests: [SupportRequest]? = nil) -> WorkspaceSnapshot {
        let liveSessions = (sessions ?? self.sessions).values
        let live = liveSessions.compactMap(\.storedSession)
        let reduced = retainedReducedSupportSessionIDs.union(liveSessions.filter(\.reducedSupport).map(\.identity.sessionID))
        return WorkspaceSnapshot(workspace: workspace ?? self.workspace, forecasts: forecasts ?? self.forecasts,
                                 cases: cases ?? self.cases,
                                 sessions: (retainedSessions + live).sorted(by: Self.sessionOrder),
                                 drafts: drafts.sorted { ($0.updatedAt, $0.key.kind) < ($1.updatedAt, $1.key.kind) },
                                 activeCaseID: activeCaseID ?? self.activeCaseID,
                                 supportRequests: supportRequests ?? self.supportRequests,
                                 reducedSupportSessionIDs: reduced.sorted())
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
    nonisolated static func sampleWorkspace(asOf: Date) -> SampleWorkspace {
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
        let config = WorkspaceConfiguration(id: id, name: "Sample fictional workspace", sites: sites, contacts: contacts,
            localParticipant: LocalParticipant(id: "sample-participant", workspaceID: id,
                                               displayName: "Sample coordinator", statedRole: .coordinator))
        return SampleWorkspace(workspace: config, cases: cases, forecasts: seed.forecasts)
    }
}
