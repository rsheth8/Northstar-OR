import SwiftUI

/// Read-only retained recording review; unresolved statements stay first.
struct SessionReviewView: View {
    @Environment(AppModel.self) private var model
    let session: CoPilotSession
    var body: some View {
        List {
            Section("Unresolved items") {
                ForEach(session.procedure.steps.filter { session.recordingState?.itemStatuses[$0.id] != .teamConfirmed }) { step in
                    VStack(alignment: .leading) {
                        Text(step.title).font(Northstar.Fonts.bodyStrong)
                        Text(session.recordingState?.itemStatuses[step.id] == .deferred ? "Deferred" : "Unrecorded")
                    }
                }
            }
            Section("Recorded history · newest first") {
                ForEach(session.events.reversed()) { event in
                    VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                        Text(session.procedure.steps.first { $0.id == event.targetItemID }?.title ?? "Workflow item")
                            .font(Northstar.Fonts.bodyStrong)
                        Text(summary(event.payload))
                        Text("\(event.actor.displayName) · \(event.source.rawValue) · \(event.occurredAt.formatted())")
                            .font(Northstar.Fonts.supporting)
                    }
                }
            }
            Section("Support exchange") {
                SupportThreadView(entries: model.supportThread(sessionID: session.identity.sessionID))
            }
            Section { Text("These are recorded team statements, not clinical outcomes. Corrections preserve the original event.") }
        }
    }
    private func summary(_ payload: SessionEventPayload) -> String {
        switch payload {
        case .itemSelected: return "Item selected"
        case .confirmationRecorded: return "Team confirmation recorded"
        case .itemDeferred: return "Item deferred"
        case .warningAcknowledged: return "Warning acknowledged; item remains deferred"
        case .recordCorrected(_, let status, let reason, _, _):
            return "Corrected to \(status.rawValue); original retained" + (reason.map { " · \($0)" } ?? "")
        }
    }
}
