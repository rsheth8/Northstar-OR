import SwiftUI

/// What the remote device rep sees: the context package plus quick prompts to send to the OR.
/// Starter layout only. The planner lane owns this screen.
struct RemoteSupportView: View {
    @Environment(AppModel.self) private var model
    @State private var draft = ""
    private let repName = "Ana Lindqvist"
    private let quickPrompts = ["Re-check lead connection", "Confirm thresholds before closing", "I'm watching, continue"]

    var body: some View {
        let session = model.activeSession
        let package = ContextPackage(session: session, hospital: model.hospital(session.procedure.hospitalID))

        NavigationStack {
            List {
                Section("Context package") {
                    LabeledContent("Procedure", value: package.procedureName)
                    LabeledContent("Hospital", value: package.hospital)
                    LabeledContent("Current step", value: package.currentStep)
                    if package.needsEscalation {
                        ForEach(package.deviations, id: \.self) {
                            Label($0, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Northstar.Palette.amber)
                        }
                    }
                }
                Section("Recent log") {
                    ForEach(package.recentLog.reversed()) { Text($0.message).font(Northstar.Fonts.log) }
                }
                Section("Send a prompt to the OR") {
                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button(prompt) { send(prompt, procedureID: session.procedure.id) }
                    }
                    HStack {
                        TextField("Custom prompt", text: $draft)
                        Button("Send") { send(draft, procedureID: session.procedure.id); draft = "" }
                            .disabled(draft.isEmpty)
                    }
                }
            }
            .navigationTitle("Remote Support Link")
        }
    }

    private func send(_ text: String, procedureID: String) {
        model.sync.send(.remoteMessage(procedureID: procedureID, from: repName, text: text))
    }
}
