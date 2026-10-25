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
    @ObservationIgnored private var pendingDraftSave: Task<Void, Never>?

    init(sync: SyncService = LocalSyncService(), store: WorkspaceStore = InMemoryWorkspaceStore(),
         clock: @escaping () -> Date = Date.init, draftSaveDelay: Duration = .milliseconds(800)) {
        self.sync = sync
        self.clock = clock
        self.draftSaveDelay = draftSaveDelay
        self.repository = WorkspaceRepository(store: store, clock: clock)
        subscription = sync.subscribe { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
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

    // MARK: - Planning helpers

    func recommendation(for procedure: Procedure) -> CoverageMatcher.Recommendation {
        CoverageMatcher().recommend(for: procedure, reps: reps, forecast: forecasts[procedure.hospitalID])
    }

    func hospital(_ id: String) -> Hospital? { hospitals.first { $0.id == id } }

    // MARK: - Private

    private func handle(_ event: SyncEvent) {
        guard let activeSession else { return }
        switch event {
        case .reducedSupportChanged(let id, let on) where id == activeSession.procedure.id:
            activeSession.setReducedSupport(on)
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
        activeCaseID = nil
        activeSession = nil
        sessions = [:]
        retainedSessions = []
        drafts = []
        unreadableSessionCaseIDs = []
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
                                 activeCaseID: activeCaseID ?? self.activeCaseID)
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
