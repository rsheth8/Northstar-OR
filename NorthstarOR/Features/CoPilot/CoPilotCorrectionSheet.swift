import SwiftUI

/// Captures the original target and version before the editor is presented.
struct CoPilotCorrectionRequest: Identifiable {
    var id: String { base.id }
    let title: String
    let base: SessionCommand
    let originalEventID: String
}

struct CoPilotCorrectionSheet: View {
    let session: CoPilotSession
    let request: CoPilotCorrectionRequest
    @Environment(\.dismiss) private var dismiss
    @State private var status: RecordedItemStatus = .unrecorded
    @State private var reason = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(request.title).font(Northstar.Fonts.bodyStrong)
                    Text("Correct a recorded statement. The earlier record remains in history.")
                }
                Section("Corrected state") {
                    Picker("Recorded state", selection: $status) {
                        Text("Unrecorded").tag(RecordedItemStatus.unrecorded)
                        Text("Deferred").tag(RecordedItemStatus.deferred)
                        Text("Team-confirmed").tag(RecordedItemStatus.teamConfirmed)
                    }
                    TextField("Reason (optional)", text: $reason, axis: .vertical)
                    Text("A required deferred item needs acknowledgment. Changing it to another state supersedes its pending warning.")
                        .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                }
                if let error {
                    Section { Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Northstar.Palette.alert) }
                }
                Section {
                    Button("Save correction", action: save)
                        .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                }
            }
            .navigationTitle("Correct record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func save() {
        let base = request.base
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let command = SessionCommand(id: base.id, identity: base.identity, actor: base.actor, source: base.source,
            issuedAt: .now, expectedVersion: base.expectedVersion, targetItemID: base.targetItemID,
            action: .correctRecord(originalEventID: request.originalEventID, newStatus: status, reason: trimmed.isEmpty ? nil : trimmed))
        do {
            try session.apply(command)
            dismiss()
        } catch {
            self.error = "The record changed. Your edits are kept here; cancel and reopen the current record to try again."
        }
    }
}
