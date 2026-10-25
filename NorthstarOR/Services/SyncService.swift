import Foundation

/// Events shared between the planner (laptop/iPad), the co-pilot (iPad), and the remote rep.
enum SyncEvent: Codable, Hashable {
    case reducedSupportChanged(procedureID: String, on: Bool)
    case logAppended(procedureID: String, entry: LogEntry)
    case remoteMessage(procedureID: String, from: String, text: String)
    /// A support request, response, question, acknowledgment or message (F06/F07). Already
    /// applied by the sender; receivers apply it idempotently.
    case support(workspaceID: String, change: SupportChange)
}

/// The shared backend boundary. Handlers may be called on any thread; receivers hop to their
/// own actor. Features only talk to this protocol,
/// so the backend (Firebase, a small Node server, or MultipeerConnectivity) can be swapped
/// without touching UI code. See docs/TASKS.md for the open decision.
protocol SyncService: AnyObject {
    func send(_ event: SyncEvent)
    /// Returns a token; keep it alive for as long as you want events.
    func subscribe(_ handler: @escaping (SyncEvent) -> Void) -> SyncSubscription
}

final class SyncSubscription {
    private let onCancel: () -> Void
    init(onCancel: @escaping () -> Void) { self.onCancel = onCancel }
    deinit { onCancel() }
}

/// In-process implementation for previews, tests, and single-device demos.
final class LocalSyncService: SyncService {
    private var handlers: [UUID: (SyncEvent) -> Void] = [:]

    func send(_ event: SyncEvent) {
        for handler in handlers.values { handler(event) }
    }

    func subscribe(_ handler: @escaping (SyncEvent) -> Void) -> SyncSubscription {
        let id = UUID()
        handlers[id] = handler
        return SyncSubscription { [weak self] in self?.handlers[id] = nil }
    }
}
