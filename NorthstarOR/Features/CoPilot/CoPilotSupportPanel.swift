import SwiftUI

/// The persistent support column in the approved Focus layout.
struct CoPilotSupportPanel: View {
    @Environment(AppModel.self) private var model
    let session: CoPilotSession
    @State private var recipientID = ""
    @State private var composing = false
    @State private var pendingQuestionID: String?
    @State private var error: String?
    @FocusState private var editing: Bool
    private var contacts: [DeviceRep] { model.reps.filter { $0.statedRole == .technicalRep } }
    private var question: SupportQuestion? { model.latestQuestion(for: session.identity.sessionID) }
    private var draft: Binding<String> {
        Binding(get: { (try? model.supportDraftKey()).map { model.draft(for: $0) } ?? "" }, set: {
            if let key = try? model.supportDraftKey() { try? model.setDraft($0, for: key) }
        })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s4) {
            HStack {
                Text("Support, in context").font(Northstar.Fonts.bodyStrong)
                Spacer()
                Image(systemName: "headphones").foregroundStyle(Northstar.Palette.ice)
            }
            if let question, !composing {
                Label(question.recipientName, systemImage: "person.crop.circle").font(Northstar.Fonts.bodyStrong)
                Text("Fictional technical rep").font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                NorthstarStatusLabel(question.delivery.label, tone: question.delivery == .failed ? .failure : .info)
                Divider()
                Text("TEAM’S QUESTION").font(Northstar.Fonts.label).foregroundStyle(Northstar.Palette.inkMuted)
                Text(question.text).font(Northstar.Fonts.bodyStrong)
                Text(question.sentAt.formatted(date: .omitted, time: .shortened)).font(Northstar.Fonts.supporting)
                DisclosureGroup("Request snapshot") {
                    Text("\(question.snapshot.caseReference) · \(question.snapshot.siteName)")
                    ForEach(question.snapshot.lines.filter { $0.status != .teamConfirmed }) { line in
                        Label(line.title, systemImage: line.status == .deferred ? "exclamationmark.triangle" : "circle")
                    }
                }.font(Northstar.Fonts.supporting)
                if let acknowledgment = question.acknowledgement {
                    NorthstarStatusLabel("Question acknowledged by \(acknowledgment.by)", tone: .success)
                } else { Text("Question not acknowledged").font(Northstar.Fonts.supporting) }
                if let reply = question.reply {
                    NorthstarBanner(tone: .info, title: "Reply from \(reply.from)", message: reply.text)
                } else { Text("Awaiting a reply").font(Northstar.Fonts.supporting) }
                if model.demoPost == .room, model.linkState != .idle, question.delivery != .receivedByPeer {
                    Button("Send this saved question") {
                        do { try model.retrySupportMessage(question.messageID); error = nil }
                        catch { self.error = "Not sent. Your question is kept." }
                    }.buttonStyle(NorthstarSecondaryButtonStyle())
                }
                Button("View support exchange") { model.selectedDestination = .remoteSupport }
                    .buttonStyle(NorthstarSecondaryButtonStyle())
                if model.demoPost == .room {
                    Button("Ask another question") { composing = true; pendingQuestionID = nil }
                        .frame(minHeight: Northstar.Target.minimum)
                }
            } else if model.demoPost == .room, session.isRecordingSupported {
                if contacts.isEmpty {
                    Text("Add a technical rep in Workspace settings.")
                } else {
                    Picker("Technical rep", selection: $recipientID) {
                        ForEach(contacts) { Text($0.name).tag($0.id) }
                    }.frame(minHeight: Northstar.Target.minimum)
                    Text("Fictional contact · Role is stated, not authenticated.")
                        .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                    Divider()
                    Text("What does the team need?").font(Northstar.Fonts.bodyStrong)
                    TextEditor(text: draft).focused($editing).frame(minHeight: 130)
                        .padding(Northstar.Space.s2).background(Northstar.Palette.bgRaised)
                        .overlay(RoundedRectangle(cornerRadius: Northstar.Radius.sm).stroke(Northstar.Palette.indicator))
                        .accessibilityLabel("Your support question").accessibilityIdentifier("focus-support-draft")
                        .disabled(pendingQuestionID != nil)
                    DisclosureGroup("Review attached context") {
                        if let context = try? model.supportSnapshot() {
                            Text("\(context.caseReference) · \(context.siteName)")
                            ForEach(context.lines.filter { $0.status != .teamConfirmed }) { line in Text(line.title) }
                        }
                    }.font(Northstar.Fonts.supporting)
                    Text("Snapshot captured when you send.").font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                    Button(pendingQuestionID == nil ? "Request support" : "Retry same question", action: send)
                        .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                        .disabled(draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("focus-support-send")
                    Text("Available with or without a deferred item.").font(Northstar.Fonts.supporting)
                }
            } else {
                Text("Open Remote Support to review questions from the room iPad.")
            }
            if let error { NorthstarBanner(tone: .failure, title: "Question kept", message: error) }
            Divider()
            SupportThreadView(entries: model.supportThread(sessionID: session.identity.sessionID))
            if model.demoPost == .room { SessionNoteComposer() }
            Text("A reply does not confirm a checklist item.").font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
        }
        .foregroundStyle(Northstar.Palette.ink)
        .onAppear { recipientID = contacts.first?.id ?? "" }
        .onChange(of: session.identity.sessionID) { _, _ in composing = false; pendingQuestionID = nil; error = nil }
    }
    private func send() {
        guard let rep = contacts.first(where: { $0.id == recipientID }) else { return }
        editing = false
        composing = true
        let previousQuestionID = question?.id
        do {
            if let id = pendingQuestionID, let question = model.questions.first(where: { $0.id == id }) {
                try model.retrySupportMessage(question.messageID)
            } else {
                do { _ = try model.sendSupportQuestion(text: draft.wrappedValue, recipient: rep) }
                catch {
                    if question?.id != previousQuestionID { pendingQuestionID = question?.id }
                    throw error
                }
            }
            draft.wrappedValue = ""; model.flushPendingSave(); composing = false; error = nil
        } catch { self.error = "Not sent. Your original question and context are kept for retry." }
    }
}
