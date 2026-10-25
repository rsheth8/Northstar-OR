import SwiftUI

struct RemoteSupportView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedQuestionID: String?
    private var current: SupportQuestion? {
        if let id = selectedQuestionID, let q = model.questions.first(where: { $0.id == id }) { return q }
        return model.latestQuestion(for: model.demoPost == .rep ? nil : model.activeSession?.identity.sessionID)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Northstar.Space.s4) {
                    NorthstarStatusLabel(model.linkState.label, tone: .info, systemImage: "ipad.landscape")
                    Text("Messages stay with this case. Connect a nearby iPad or rep call to send messages off this device.").font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                    if !model.questions.isEmpty {
                        Picker("Saved requests", selection: Binding(get: { current?.id ?? "" }, set: { selectedQuestionID = $0 })) {
                            ForEach(model.questions) { q in Text("\(q.snapshot.caseReference) · \(q.sentAt.formatted(date: .omitted, time: .shortened))").tag(q.id) }
                        }.frame(minHeight: Northstar.Target.minimum)
                    }
                    if let current { SupportBriefView(question: current).id(current.id) }
                    else { ContentUnavailableView("No question from the team yet", systemImage: "headphones", description: Text(model.demoPost == .rep ? "Look for the room iPad to receive its self-contained request brief." : "Request support from the current Co-pilot item, including while an acknowledgment is pending.")) }
                }.padding(Northstar.Space.s6).frame(maxWidth: 1000, alignment: .leading).frame(maxWidth: .infinity)
            }.background(Northstar.Palette.bgRaised)
            .navigationTitle("Remote Support").navigationBarTitleDisplayMode(.inline)
        }
    }
}
