import SwiftUI

struct SupportRequestSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @FocusState private var questionFocused: Bool
    @State private var recipientID = ""
    @State private var error: String?
    @State private var pendingQuestionID: String?
    private var contacts: [DeviceRep] { model.reps.filter { $0.statedRole == .technicalRep } }
    private var draft: Binding<String> {
        Binding(get: { (try? model.supportDraftKey()).map { model.draft(for: $0) } ?? "" }, set: {
            if let key = try? model.supportDraftKey() { try? model.setDraft($0, for: key) }
        })
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipient") {
                    if contacts.isEmpty { Text("Add a technical rep in Workspace settings.") }
                    else { Picker("Recipient", selection: $recipientID) { ForEach(contacts) { Text($0.name).tag($0.id) } } }
                }
                Section("Team question") {
                    TextEditor(text: draft).focused($questionFocused).frame(minHeight: 110)
                        .accessibilityLabel("What should the rep answer?").accessibilityIdentifier("support-question-draft")
                        .disabled(pendingQuestionID != nil)
                }
                Section {
                    if let error { NorthstarBanner(tone: .failure, title: "Not sent", message: error) }
                    Button(pendingQuestionID == nil ? "Send question" : "Retry same question") { send() }
                        .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                        .disabled(contacts.isEmpty || draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("support-question-send")
                }
                Section("Talk live") {
                    WorkspaceCallAction()
                    Text("Your question draft stays saved when you request a call.").font(Northstar.Fonts.supporting)
                }
                Section("Context that will be sent") {
                    if let context = try? model.supportSnapshot() {
                        Text(context.selectedItemTitle ?? "No selected item").font(Northstar.Fonts.bodyStrong)
                        ForEach(context.lines.filter { $0.status != .teamConfirmed }) { line in
                            VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                                Text(line.title).font(Northstar.Fonts.bodyStrong)
                                Text(line.status == .deferred ? "Recorded as deferred" : "No confirmation recorded")
                                    .font(Northstar.Fonts.supporting)
                                Button("Ask about this item") {
                                    let topic = "Question about “\(line.title)”: "
                                    if !draft.wrappedValue.contains(topic) {
                                        draft.wrappedValue += draft.wrappedValue.isEmpty ? topic : "\n" + topic
                                    }
                                    questionFocused = true
                                }
                                .buttonStyle(NorthstarSecondaryButtonStyle())
                                .disabled(pendingQuestionID != nil)
                                .accessibilityLabel("Ask about \(line.title)")
                                .accessibilityIdentifier("support-topic-\(line.id)")
                            }
                        }
                    }
                    Text("These are recorded checklist states. Ask about an item to add it to your draft; this never changes its checklist status. The snapshot is captured when you send.").font(Northstar.Fonts.supporting)
                }

            }
            .accessibilityIdentifier("support-request-form")
            .navigationTitle("Request support").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { model.flushPendingSave(); dismiss() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done typing") { questionFocused = false }
                }
            }
            .onAppear { recipientID = contacts.first?.id ?? "" }
            .onChange(of: model.callInvitation?.state) { _, state in
                if state == .requested || state == .accepted { model.flushPendingSave(); dismiss() }
            }
        }
    }
    private func send() {
        questionFocused = false
        guard let rep = contacts.first(where: { $0.id == recipientID }) else { return }
        do {
            if let id = pendingQuestionID, let q = model.questions.first(where: { $0.id == id }) { try model.retrySupportMessage(q.messageID) }
            else {
                do { _ = try model.sendSupportQuestion(text: draft.wrappedValue, recipient: rep) }
                catch { pendingQuestionID = model.latestQuestion(for: model.activeSession?.identity.sessionID)?.id; throw error }
            }
            draft.wrappedValue = ""; model.flushPendingSave(); dismiss()
        } catch { self.error = "Not sent. Your question is kept." }
    }
}
