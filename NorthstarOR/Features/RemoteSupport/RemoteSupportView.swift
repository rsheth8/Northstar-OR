import SwiftUI

/// Live local context until the immutable request/receipt contracts land.
struct RemoteSupportView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var drafts: [String: String] = [:]
    @State private var senderID: String?
    @State private var sendError: String?

    private var senders: [DeviceRep] { model.reps.filter { $0.statedRole == .technicalRep } }
    private var sender: DeviceRep? {
        if let senderID { return senders.first { $0.id == senderID } }
        return senders.first
    }
    private var draft: Binding<String> {
        let id = model.activeSession?.identity.sessionID ?? ""
        return Binding(get: { drafts[id, default: ""] }, set: { drafts[id] = $0 })
    }

    var body: some View {
        if let session = model.activeSession {
            workspace(session)
        } else {
            NavigationStack {
                ContentUnavailableView("No active case", systemImage: "headphones",
                    description: Text("Start or resume a case in Planner."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Northstar.Palette.bgRaised)
                    .navigationTitle("Remote Support")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func workspace(_ session: CoPilotSession) -> some View {
        NavigationStack {
            GeometryReader { proxy in
                if proxy.size.width >= 1000 && !typeSize.isAccessibilitySize {
                    HStack(spacing: 0) {
                        ScrollView { brief(session).padding(Northstar.Space.s6) }
                            .frame(maxWidth: .infinity)
                            .background(Northstar.Palette.bgRaised)
                        Divider()
                        VStack(spacing: 0) {
                            // Keep the newest message in view when the keyboard shortens this pane.
                            ScrollView { conversation(session).padding(Northstar.Space.s4) }
                                .defaultScrollAnchor(.bottom)
                            composer
                        }
                        .frame(width: 360)
                        .background(Northstar.Palette.bgBase)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Northstar.Space.s6) {
                            brief(session)
                            Divider()
                            conversation(session)
                        }
                        .padding(Northstar.Space.s6)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) { composer }
                }
            }
            .background(Northstar.Palette.bgRaised)
            .foregroundStyle(Northstar.Palette.ink)
            .navigationTitle("Remote Support")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func brief(_ session: CoPilotSession) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s6) {
            VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                Text("Team question").font(Northstar.Fonts.label).foregroundStyle(Northstar.Palette.inkMuted)
                Text("No team question recorded").font(Northstar.Fonts.title)
                    .accessibilityAddTraits(.isHeader)
                Text("This build shares the current recording on this device. Contextual requests and question acknowledgment are not available yet.")
                    .font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
            }
            Divider()
            section("Current case context") {
                Text(session.procedure.reference ?? session.procedure.id).font(Northstar.Fonts.display)
                Text(session.procedure.name).font(Northstar.Fonts.body)
                Text(model.hospital(session.procedure.hospitalID)?.name ?? "Site not recorded")
                    .font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
                NorthstarStatusLabel("Live local context · Not a request snapshot", tone: .info, systemImage: "ipad.landscape")
            }
            Divider()
            section("Unresolved items") {
                let items = session.procedure.steps.filter { session.recordingState?.itemStatuses[$0.id] != .teamConfirmed }
                if items.isEmpty { Text("No unresolved items recorded.").font(Northstar.Fonts.body) }
                ForEach(items) { step in
                    itemRow(step, status: session.recordingState?.itemStatuses[step.id] ?? .unrecorded)
                }
            }
            Divider()
            section("Recorded confirmations") {
                let items = session.procedure.steps.filter { session.recordingState?.itemStatuses[$0.id] == .teamConfirmed }
                if items.isEmpty { Text("No team confirmations recorded.").font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted) }
                ForEach(items) { step in itemRow(step, status: .teamConfirmed) }
            }
            Divider()
            section("Support context") {
                NorthstarStatusLabel(session.reducedSupport ? "Reduced-support context recorded" : "Standard support context recorded", tone: .neutral)
                Text("A support context label is not a request, acceptance or connection.")
                    .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func conversation(_ session: CoPilotSession) -> some View {
        let messages = session.log.filter { $0.kind == .remoteMessage }
        return section("Conversation") {
            Text("Messages on this device").font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
            if messages.isEmpty {
                Text("No local messages yet").font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
                    .padding(.vertical, Northstar.Space.s6)
            }
            ForEach(messages) { entry in
                VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                    Text(entry.message).font(Northstar.Fonts.body).textSelection(.enabled)
                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(Northstar.Fonts.supporting).monospacedDigit().foregroundStyle(Northstar.Palette.inkMuted)
                }
                .padding(.vertical, Northstar.Space.s2)
                Divider()
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            if let sendError {
                Text(sendError).font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.alert)
                    .accessibilityIdentifier("support-send-error")
            }
            Menu {
                ForEach(senders) { rep in
                    Button(rep.name) { senderID = rep.id }
                }
            } label: {
                Label(sender.map { "Local sender: \($0.name)" } ?? "No technical rep configured", systemImage: "person.crop.circle")
                    .font(Northstar.Fonts.supporting)
                    .frame(minHeight: Northstar.Target.minimum)
            }
            .disabled(senders.isEmpty)
            TextField("Write a local technical-support message", text: draft, axis: .vertical)
                .font(Northstar.Fonts.body)
                .lineLimit(1...4)
                .padding(Northstar.Space.s3)
                .frame(minHeight: Northstar.Target.minimum)
                .background(Northstar.Palette.bgRaised, in: RoundedRectangle(cornerRadius: Northstar.Radius.sm))
                .overlay { RoundedRectangle(cornerRadius: Northstar.Radius.sm).strokeBorder(Northstar.Palette.indicator) }
                .accessibilityIdentifier("support-draft")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Northstar.Space.s3) { composerActions }
                VStack(alignment: .leading, spacing: Northstar.Space.s3) { composerActions }
            }
        }
        .padding(Northstar.Space.s4)
        .background(Northstar.Palette.bgBase)
    }

    @ViewBuilder private var composerActions: some View {
        Menu("Suggested text") {
            ForEach(FictionalCoordinationTemplate.technicalSupportReplies, id: \.self) { prompt in
                Button(prompt) { draft.wrappedValue = prompt }
            }
        }
        .buttonStyle(NorthstarSecondaryButtonStyle())
        Button("Send locally", action: send)
            .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
            .disabled(sender == nil || draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("support-send")
    }

    private func send() {
        guard let session = model.activeSession else { return }
        let text = draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let sender, !text.isEmpty else { return }
        let previousIDs = Set(session.log.map(\.id))
        model.sync.send(.remoteMessage(procedureID: session.procedure.id, from: sender.name, text: text))
        // SyncService currently returns no receipt. Confirm only the observable
        // synchronous local effect; retain the draft if routing did not occur.
        if session.log.contains(where: { !previousIDs.contains($0.id) && $0.kind == .remoteMessage }) {
            drafts[session.identity.sessionID] = ""
            sendError = nil
        } else {
            sendError = "Message not added on this device. Your draft is kept; try again."
        }
    }

    private func itemRow(_ step: ProcedureStep, status: RecordedItemStatus) -> some View {
        HStack(alignment: .top, spacing: Northstar.Space.s3) {
            Image(systemName: status == .teamConfirmed ? "checkmark.circle.fill" : status == .deferred ? "exclamationmark.triangle.fill" : "circle")
                .foregroundStyle(status == .teamConfirmed ? Northstar.Palette.aurora : status == .deferred ? Northstar.Palette.amber : Northstar.Palette.indicator)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Northstar.Space.s1) {
                Text(step.title).font(Northstar.Fonts.body)
                Text(status == .teamConfirmed ? "Team-confirmed" : status == .deferred ? "Deferred" : "Unrecorded")
                    .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            Text(title).font(Northstar.Fonts.bodyStrong).accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
