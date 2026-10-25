import SwiftUI

struct RemoteSupportView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedQuestionID: String?
    @State private var showingCoverage = false
    private var visibleQuestions: [SupportQuestion] {
        if model.demoPost == .rep, let origin = model.remoteSession?.origin { return model.questions.filter { $0.origin == origin } }
        if model.demoPost == .room, let session = model.activeSession { return model.questions.filter { $0.sessionID == session.identity.sessionID } }
        return model.questions
    }
    private var current: SupportQuestion? {
        if let id = selectedQuestionID, let q = visibleQuestions.first(where: { $0.id == id }) { return q }
        return visibleQuestions.last
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Northstar.Space.s4) {
                    NorthstarStatusLabel(model.linkState.label, tone: .info, systemImage: "ipad.landscape")
                    Text("Messages stay with this case. Connect Northstar on the room iPad and the rep’s Mac to exchange updates.").font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                    WorkspaceCallAction()
                    if model.demoPost == .room, let session = model.activeSession {
                        Text("Current room record").font(Northstar.Fonts.title)
                        Text(session.procedure.name).font(Northstar.Fonts.bodyStrong)
                        Text(session.recordingSummary)
                        Text(model.isSharingSession ? "Sharing this case with the laptop session. Calls are separate from the case connection." : "Choose Connect devices on both devices before calling.")
                            .font(Northstar.Fonts.supporting)
                    }
                    if model.demoPost == .rep {
                        Toggle("Spoken support alerts", isOn: Binding(get: { model.supportAlertsEnabled }, set: { model.supportAlertsEnabled = $0 }))
                        if let alert = model.supportAlert { NorthstarBanner(tone: .attention, title: "Room update", message: alert) }
                    }
                    if model.demoPost == .rep, let shared = model.remoteSession {
                        NativeSessionBrief(snapshot: shared, current: model.remoteSessionCurrent)
                    }
                    if !visibleQuestions.isEmpty {
                        Picker("Saved requests", selection: Binding(get: { current?.id ?? "" }, set: { selectedQuestionID = $0 })) {
                            ForEach(visibleQuestions) { q in Text("\(q.snapshot.caseReference) · \(q.sentAt.formatted(date: .omitted, time: .shortened))").tag(q.id) }
                        }.frame(minHeight: Northstar.Target.minimum)
                    }
                    if let current { SupportBriefView(question: current).id(current.id) }
                    else { ContentUnavailableView("No question from the team yet", systemImage: "headphones", description: Text(model.demoPost == .rep ? "The connected room must start or resume a recording in Planner. Its live recap appears here; a question is optional." : "Request support from the current Co-pilot item, including while an acknowledgment is pending.")) }
                    if let sessionID = (model.demoPost == .rep ? model.remoteSession?.origin.sessionID : nil) ?? current?.sessionID ?? (model.demoPost == .room ? model.activeSession?.identity.sessionID : nil) {
                        Divider()
                        SupportThreadView(entries: model.supportThread(sessionID: sessionID))
                        SessionNoteComposer()
                    }
                }.padding(Northstar.Space.s6).frame(maxWidth: 1000, alignment: .leading).frame(maxWidth: .infinity)
            }.background(Northstar.Palette.bgRaised)
            .navigationTitle("Remote Support").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if model.demoPost == .rep {
                        Button("Coverage requests (\(model.incomingCoveragePlans.count))") { showingCoverage = true }
                            .accessibilityIdentifier("open-coverage-requests")
                    }
                }
            }
            .sheet(isPresented: $showingCoverage) { CoverageRequestsView() }
        }
    }
}

private struct NativeSessionBrief: View {
    let snapshot: SharedSessionSnapshot
    let current: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            Text(snapshot.context.caseName).font(Northstar.Fonts.title)
            Text("\(snapshot.context.caseReference) · \(snapshot.context.siteName)")
            NorthstarStatusLabel(current ? "Live room record" : "Disconnected · last saved copy", tone: current ? .info : .attention)
            Text(snapshot.recordingSummary)
            if let selected = snapshot.context.selectedItemTitle {
                Label("Room selected: \(selected)", systemImage: "location.circle")
                    .font(Northstar.Fonts.bodyStrong)
            }
            if !snapshot.saved { NorthstarBanner(tone: .attention, title: "Room has unsaved changes", message: "This update is not yet saved on the room device.") }
            ForEach(snapshot.context.lines) { line in
                Label("\(line.title) · \(line.status == .teamConfirmed ? "Team-confirmed" : line.status == .deferred ? "Deferred" : "Unrecorded")",
                      systemImage: line.status == .teamConfirmed ? "checkmark.circle" : line.status == .deferred ? "exclamationmark.triangle" : "circle")
            }
            DisclosureGroup("Recorded activity") {
                ForEach(Array(snapshot.context.recentEvents.enumerated()), id: \.offset) { _, event in Text(event) }
            }
            Text("Checklist changes are recorded by the room team. Messages and calls leave deferred items unresolved.")
                .font(Northstar.Fonts.supporting)
        }
    }
}
