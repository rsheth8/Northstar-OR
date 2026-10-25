import Foundation

/// Events shared between the planner (laptop/iPad), the co-pilot (iPad), and the remote rep.
enum SyncEvent: Codable, Hashable {
    case reducedSupportChanged(procedureID: String, on: Bool)
    case logAppended(procedureID: String, entry: LogEntry)
    case remoteMessage(procedureID: String, from: String, text: String)
}

/// The shared backend boundary. Features only talk to this protocol,
/// so the backend (Firebase, a small Node server, or MultipeerConnectivity) can be swapped
/// without touching UI code. See docs/TASKS.md for the open decision.
protocol SyncService: AnyObject {
    func send(_ event: SyncEvent)
    /// Returns a token; keep it alive for as long as you want events.
    func subscribe(_ handler: @escaping (SyncEvent) -> Void) -> SyncSubscription
    @MainActor var nearby: NearbyTransport { get }
    @MainActor func installNearby(_ transport: NearbyTransport)
    @MainActor func sendSupport(_ envelope: SupportEnvelope) throws
}

final class SyncSubscription {
    private let onCancel: () -> Void
    init(onCancel: @escaping () -> Void) { self.onCancel = onCancel }
    deinit { onCancel() }
}

/// In-process implementation for previews, tests, and single-device demos.
final class LocalSyncService: SyncService {
    private var handlers: [UUID: (SyncEvent) -> Void] = [:]
    @MainActor private var transport: NearbyTransport?
    init() {}
    @MainActor init(nearby: NearbyTransport) { transport = nearby }
    @MainActor var nearby: NearbyTransport {
        if let transport { return transport }
        let idle = IdleNearbyTransport()
        transport = idle
        return idle
    }
    @MainActor func installNearby(_ transport: NearbyTransport) {
        self.transport?.onEnvelope = nil
        self.transport?.onLinkState = nil
        self.transport?.onDiscoveryChange = nil
        self.transport?.stop()
        self.transport = transport
    }
    @MainActor func sendSupport(_ envelope: SupportEnvelope) throws { try nearby.send(envelope) }

    func send(_ event: SyncEvent) {
        for handler in handlers.values { handler(event) }
    }

    func subscribe(_ handler: @escaping (SyncEvent) -> Void) -> SyncSubscription {
        let id = UUID()
        handlers[id] = handler
        return SyncSubscription { [weak self] in self?.handlers[id] = nil }
    }
}
