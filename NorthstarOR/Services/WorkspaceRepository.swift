import Foundation

// F18 v1: bounded local storage for one fictional workspace. Not an institutional audit,
// backup or access-control system. Plans and pending messages are added after F06 lands.

/// Identifies one unsent draft. Case and session are optional so workspace-level drafts fit.
struct DraftKey: Hashable, Codable {
    let workspaceID: String
    let caseID: String?
    let sessionID: String?
    /// Which input the draft belongs to, e.g. "supportQuestion" or "caseNote".
    let kind: String
}

struct DraftRecord: Hashable, Codable {
    let key: DraftKey
    var text: String
    var updatedAt: Date
}

/// A session's accepted state with the events that produced it. Both validate on decode.
struct StoredSession: Hashable, Codable {
    var state: SessionRecordingState
    var events: [SessionEvent]
}

/// Everything the app retains between launches. An empty snapshot is a fresh install.
struct WorkspaceSnapshot: Hashable, Codable {
    static let supportedFormatVersion = 1
    var formatVersion = supportedFormatVersion
    var workspace: WorkspaceConfiguration?
    /// Simulated forecasts keyed by site ID.
    var forecasts: [String: StormForecast] = [:]
    var cases: [Procedure] = []
    var sessions: [StoredSession] = []
    var drafts: [DraftRecord] = []

    static let empty = WorkspaceSnapshot()

    /// Checks membership and identity across records. Throws `RepositoryError.invalidSnapshot`.
    func validate() throws {
        guard formatVersion == Self.supportedFormatVersion else { throw invalid("unsupported format version \(formatVersion)") }
        guard let workspace else {
            guard forecasts.isEmpty, cases.isEmpty, sessions.isEmpty, drafts.isEmpty else {
                throw invalid("records exist without a workspace")
            }
            return
        }
        do { try workspace.validate() } catch { throw invalid("workspace: \(error)") }

        let siteIDs = Set(workspace.sites.map(\.id))
        for siteID in forecasts.keys where !siteIDs.contains(siteID) { throw invalid("forecast for unknown site \(siteID)") }

        var caseIDs = Set<String>()
        for item in cases {
            guard caseIDs.insert(item.id).inserted else { throw invalid("duplicate case \(item.id)") }
            guard item.workspaceID == workspace.id else { throw invalid("case \(item.id) belongs to another workspace") }
            guard siteIDs.contains(item.hospitalID) else { throw invalid("case \(item.id) uses unknown site \(item.hospitalID)") }
        }

        var sessionCases: [String: String] = [:]
        var eventIDs = Set<String>()
        for session in sessions {
            let identity = session.state.identity
            do { try session.state.validate() } catch { throw invalid("session \(identity.sessionID): \(error)") }
            guard sessionCases[identity.sessionID] == nil else { throw invalid("duplicate session \(identity.sessionID)") }
            guard identity.workspaceID == workspace.id else { throw invalid("session \(identity.sessionID) belongs to another workspace") }
            guard caseIDs.contains(identity.caseID) else { throw invalid("session \(identity.sessionID) has no case \(identity.caseID)") }
            sessionCases[identity.sessionID] = identity.caseID
            for event in session.events {
                do { try event.validate() } catch { throw invalid("event \(event.id): \(error)") }
                guard event.identity == identity else { throw invalid("event \(event.id) belongs to another session") }
                guard eventIDs.insert(event.id).inserted else { throw invalid("duplicate event \(event.id)") }
            }
        }

        var draftKeys = Set<DraftKey>()
        for draft in drafts {
            let key = draft.key
            guard draftKeys.insert(key).inserted else { throw invalid("duplicate draft \(key.kind)") }
            guard key.workspaceID == workspace.id else { throw invalid("draft \(key.kind) belongs to another workspace") }
            if let caseID = key.caseID, !caseIDs.contains(caseID) { throw invalid("draft \(key.kind) has no case \(caseID)") }
            if let sessionID = key.sessionID {
                guard let caseID = sessionCases[sessionID], caseID == key.caseID else {
                    throw invalid("draft \(key.kind) has no matching session \(sessionID)")
                }
            }
        }
    }

    private func invalid(_ reason: String) -> RepositoryError { .invalidSnapshot(reason) }
}

enum WorkspaceLoadResult: Equatable {
    /// Nothing stored yet. Sample content is never loaded implicitly.
    case empty
    case loaded(WorkspaceSnapshot)
    /// Written by a newer format; saving is blocked so the data is not overwritten.
    case unsupportedVersion(Int)
    /// Damaged or invalid; saving is blocked until the data is explicitly set aside.
    case unreadable(String)
}

struct SaveReceipt: Equatable {
    let savedAt: Date
}

enum RepositoryError: Error, Equatable {
    /// Stored data could not be read; it must be set aside before anything is saved.
    case blockedByUnreadableData
    case invalidSnapshot(String)
    /// Nothing was saved. Callers keep their unsaved state and offer retry.
    case writeFailed(String)
    case nothingToSetAside
}

/// Raw byte storage, injectable so tests can simulate failures.
protocol WorkspaceStore: AnyObject {
    /// nil when nothing has been stored.
    func read() throws -> Data?
    /// Must replace the stored data completely or leave it unchanged.
    func write(_ data: Data) throws
    /// Moves the current data aside under `label` without deleting it.
    func setAside(label: String) throws
}

/// Single JSON file in Application Support, replaced atomically on each write.
final class FileWorkspaceStore: WorkspaceStore {
    let directory: URL
    let fileURL: URL

    init(directory: URL, fileName: String = "workspace.json") {
        self.directory = directory
        self.fileURL = directory.appendingPathComponent(fileName)
    }

    static func applicationSupport() throws -> FileWorkspaceStore {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                               appropriateFor: nil, create: true)
        return FileWorkspaceStore(directory: base.appendingPathComponent("NorthstarOR", isDirectory: true))
    }

    func read() throws -> Data? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try Data(contentsOf: fileURL)
    }

    func write(_ data: Data) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    func setAside(label: String) throws {
        let target = directory.appendingPathComponent("workspace.unreadable-\(label).json")
        try FileManager.default.moveItem(at: fileURL, to: target)
    }
}

/// For tests and previews. `failWrites` simulates a full disk or permission error.
final class InMemoryWorkspaceStore: WorkspaceStore {
    var data: Data?
    var failWrites = false
    private(set) var setAside: [String: Data] = [:]

    init(data: Data? = nil) { self.data = data }

    func read() throws -> Data? { data }

    func write(_ data: Data) throws {
        if failWrites { throw CocoaError(.fileWriteOutOfSpace) }
        self.data = data
    }

    func setAside(label: String) throws {
        guard let data else { throw CocoaError(.fileNoSuchFile) }
        setAside[label] = data
        self.data = nil
    }
}

/// Loads and saves the workspace snapshot. Refuses to overwrite data it could not read.
final class WorkspaceRepository {
    private enum Access { case unchecked, writable, blocked }

    private let store: WorkspaceStore
    private let clock: () -> Date
    private var access = Access.unchecked

    init(store: WorkspaceStore, clock: @escaping () -> Date = Date.init) {
        self.store = store
        self.clock = clock
    }

    /// True after loading data that is unreadable or from a newer format.
    var isSavingBlocked: Bool { access == .blocked }

    func load() -> WorkspaceLoadResult {
        let result = readSnapshot()
        switch result {
        case .empty, .loaded: access = .writable
        case .unsupportedVersion, .unreadable: access = .blocked
        }
        return result
    }

    /// Validates, then writes. A receipt means the write completed; any throw means nothing changed.
    @discardableResult
    func save(_ snapshot: WorkspaceSnapshot) throws -> SaveReceipt {
        if access == .unchecked { _ = load() }
        guard access == .writable else { throw RepositoryError.blockedByUnreadableData }
        try snapshot.validate()
        let data: Data
        do { data = try Self.encoder.encode(snapshot) } catch { throw RepositoryError.writeFailed("\(error)") }
        do { try store.write(data) } catch { throw RepositoryError.writeFailed("\(error)") }
        return SaveReceipt(savedAt: clock())
    }

    /// Keeps the unreadable data under a timestamped name, then allows a fresh start.
    func setAsideUnreadableData() throws {
        if access == .unchecked { _ = load() }
        guard access == .blocked else { throw RepositoryError.nothingToSetAside }
        let label = String(Int(clock().timeIntervalSince1970))
        do { try store.setAside(label: label) } catch { throw RepositoryError.writeFailed("\(error)") }
        access = .writable
    }

    private func readSnapshot() -> WorkspaceLoadResult {
        let data: Data?
        do { data = try store.read() } catch { return .unreadable("read failed: \(error)") }
        guard let data else { return .empty }

        struct Header: Decodable { let formatVersion: Int }
        guard let header = try? JSONDecoder().decode(Header.self, from: data) else {
            return .unreadable("missing or invalid format version")
        }
        guard header.formatVersion == WorkspaceSnapshot.supportedFormatVersion else {
            return .unsupportedVersion(header.formatVersion)
        }
        do {
            let snapshot = try JSONDecoder().decode(WorkspaceSnapshot.self, from: data)
            try snapshot.validate()
            return .loaded(snapshot)
        } catch {
            return .unreadable("\(error)")
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
