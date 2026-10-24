import Foundation
import Observation

/// App-wide state shared by every screen. Holds the simulated data and the sync boundary.
@Observable
final class AppModel {
    let sync: SyncService
    var hospitals = SampleData.hospitals
    var reps = SampleData.reps
    var forecasts = SampleData.forecasts
    var procedures = SampleData.procedures
    /// The procedure running on the co-pilot right now (the demo case).
    var activeSession: CoPilotSession

    @ObservationIgnored private var subscription: SyncSubscription?

    init(sync: SyncService = LocalSyncService()) {
        self.sync = sync
        self.activeSession = CoPilotSession(procedure: SampleData.procedures[0])
        subscription = sync.subscribe { [weak self] event in self?.handle(event) }
    }

    func recommendation(for procedure: Procedure) -> CoverageMatcher.Recommendation {
        CoverageMatcher().recommend(for: procedure, reps: reps, forecast: forecasts[procedure.hospitalID])
    }

    func hospital(_ id: String) -> Hospital? { hospitals.first { $0.id == id } }

    private func handle(_ event: SyncEvent) {
        switch event {
        case .reducedSupportChanged(let id, let on) where id == activeSession.procedure.id:
            activeSession.setReducedSupport(on)
        case .remoteMessage(let id, let from, let text) where id == activeSession.procedure.id:
            activeSession.receiveRemoteMessage(text, from: from)
        default:
            break
        }
    }
}
