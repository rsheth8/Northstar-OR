import SwiftUI

struct SupportBriefView: View {
    @Environment(AppModel.self) private var model
    let question: SupportQuestion
    @FocusState private var replyFocused: Bool
    @State private var error: String?
    private var replyDraft: Binding<String> {
        Binding(get: { (try? model.supportDraftKey(question: question)).map { model.draft(for: $0) } ?? "" }, set: {
            if let key = try? model.supportDraftKey(question: question) { try? model.setDraft($0, for: key) }
        })
    }
    private var canRespond: Bool { model.demoPost == .rep || (model.linkState == .idle && question.workspaceID == model.workspace?.id) }
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s6) {
            Text("Team question").font(Northstar.Fonts.label).foregroundStyle(Northstar.Palette.inkMuted)
            Text(question.text).font(Northstar.Fonts.title).accessibilityAddTraits(.isHeader)
            Text("\(question.sender.displayName) · \(question.sentAt.formatted(date: .omitted, time: .shortened))")
            NorthstarStatusLabel(question.delivery.label, tone: question.delivery == .failed ? .failure : .info)
            if model.demoPost == .room, model.linkState != .idle, question.workspaceID == model.workspace?.id, question.delivery != .receivedByPeer {
                Button("Send this saved question") {
                    perform { try model.retrySupportMessage(question.messageID) }
                }.buttonStyle(NorthstarSecondaryButtonStyle())
            }
            if let ack = question.acknowledgement {
                NorthstarStatusLabel("Question acknowledged by \(ack.by)", tone: .success)
                delivery(ack.delivery, messageID: ack.id)
            } else if canRespond {
                Button("Acknowledge question") { perform { try model.acknowledgeQuestion(question.id) } }
                    .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard)).accessibilityIdentifier("acknowledge-question")
            }
            Text("\(question.snapshot.lines.filter { $0.status != .teamConfirmed }.count) unresolved items in the request").font(Northstar.Fonts.bodyStrong)
            replySection
            if let error { NorthstarBanner(tone: .failure, title: "Action not sent", message: error) }
            DisclosureGroup("Original request context") {
            Divider()
            Group {
                LabeledContent("Case", value: question.snapshot.caseReference)
                LabeledContent("Title", value: known(question.snapshot.caseName))
                LabeledContent("Site", value: known(question.snapshot.siteName))
                LabeledContent("Device family", value: known(question.snapshot.deviceFamily))
                LabeledContent("Template", value: "\(question.snapshot.templateID) · v\(question.snapshot.templateVersion)")
                LabeledContent("Snapshot", value: question.snapshot.capturedAt.formatted())
            }.font(Northstar.Fonts.body)
            lines("Unresolved in the request", question.snapshot.lines.filter { $0.status != .teamConfirmed }, empty: "No unresolved items in the request.")
            lines("Recorded in the request", question.snapshot.lines.filter { $0.status == .teamConfirmed }, empty: "No team confirmations in the request.")
            lines("Lines the in-room rep usually covers", question.snapshot.lines.filter(\.normallyCoveredByRep), empty: "None recorded.")
            VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                Text("Why support is remote").font(Northstar.Fonts.bodyStrong)
                Text(question.snapshot.logisticalReason ?? "Not recorded")
                if question.snapshot.reducedSupport { Text("Reduced-support context recorded") }
            }
            VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                Text("Changed since request").font(Northstar.Fonts.bodyStrong)
                if let live = model.liveContext(for: question) {
                    Text("\(SupportExchange.changedLineCount(snapshot: question.snapshot, live: live)) checklist lines changed since the request.")
                    if live.acknowledgmentIDs != question.snapshot.acknowledgmentIDs { Text("Deferral acknowledgment context changed. Deferred items remain unresolved.") }
                    Text("Last context update: \(live.capturedAt.formatted(date: .omitted, time: .shortened))")
                } else { Text("Later context is unavailable. The original request remains shown above.") }
            }
            if !question.snapshot.recentEvents.isEmpty {
                DisclosureGroup("Recent recorded events at request") {
                    ForEach(Array(question.snapshot.recentEvents.enumerated()), id: \.offset) { _, text in Text(text).font(Northstar.Fonts.supporting) }
                }
            }
            }
            Text("A reply does not confirm a checklist item. A local role is not verified identity.").font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
        }.foregroundStyle(Northstar.Palette.ink)
    }
    @ViewBuilder private var replySection: some View {
        if let reply = question.reply {
            NorthstarBanner(tone: .info, title: "Reply from \(reply.from)", message: reply.text)
            Text(reply.at.formatted()).font(Northstar.Fonts.supporting)
            delivery(reply.delivery, messageID: reply.id)
        } else if canRespond {
            Text(model.demoPost == .rep ? "Reply as \(model.workspace?.localParticipant.displayName ?? question.recipientName)" : "Reply locally as \(question.recipientName)").font(Northstar.Fonts.bodyStrong)
            TextEditor(text: replyDraft).focused($replyFocused).frame(minHeight: 120).accessibilityLabel("Write a technical-support reply").accessibilityIdentifier("support-reply-draft")
            Menu("Suggested text") { ForEach(FictionalCoordinationTemplate.technicalSupportReplies, id: \.self) { text in Button(text) { replyDraft.wrappedValue = text } } }.frame(minHeight: Northstar.Target.minimum)
            Button("Send reply") { replyFocused = false; perform { try model.sendSupportReply(question.id, text: replyDraft.wrappedValue); replyDraft.wrappedValue = ""; model.flushPendingSave() } }
                .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                .disabled(replyDraft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("support-reply-send")
        }
    }
    private func known(_ value: String) -> String { value.isEmpty ? "Not recorded" : value }
    private func perform(_ action: () throws -> Void) { do { try action(); error = nil } catch { self.error = "The action is kept on this device. Retry when the nearby link is available." } }
    @ViewBuilder private func delivery(_ state: SupportDelivery, messageID: String) -> some View {
        NorthstarStatusLabel(state.label, tone: state == .failed ? .failure : .info)
        if canRespond, state == .failed || state == .waitingForPeer {
            Button("Retry this message") { perform { try model.retrySupportMessage(messageID) } }.buttonStyle(NorthstarSecondaryButtonStyle())
        }
    }
    private func lines(_ title: String, _ values: [ChecklistLineSnapshot], empty: String) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            Text(title).font(Northstar.Fonts.bodyStrong)
            if values.isEmpty { Text(empty) }
            ForEach(values) { line in
                Label("\(line.title) · \(line.status == .deferred ? "Deferred" : line.status == .teamConfirmed ? "Team-confirmed" : "Unrecorded")", systemImage: line.status == .deferred ? "exclamationmark.triangle" : line.status == .teamConfirmed ? "checkmark.circle" : "circle")
                    .foregroundStyle(line.status == .deferred ? Northstar.Palette.amber : Northstar.Palette.ink)
            }
        }
    }
}
