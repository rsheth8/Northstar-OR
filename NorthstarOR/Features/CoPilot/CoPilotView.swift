import SwiftUI

struct CoPilotView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var announcer = VoiceAnnouncer()
    @State private var showWorkflow = false
    @State private var showActivity = false
    @State private var showSupport = false
    @State private var correction: CoPilotCorrectionRequest?
    @State private var commandError: String?

    var body: some View {
        if let session = model.activeSession {
            workspace(session)
        } else {
            NavigationStack {
                ContentUnavailableView("No active case", systemImage: "list.bullet.rectangle",
                    description: Text("Start or resume a case in Planner."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Northstar.Palette.bgRaised)
                    .navigationTitle("Co-pilot")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func workspace(_ session: CoPilotSession) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                context(session)
                GeometryReader { proxy in
                    let wide = proxy.size.width >= 1100 && !typeSize.isAccessibilitySize
                    let showRail = proxy.size.width >= 800 && !typeSize.isAccessibilitySize
                    HStack(spacing: 0) {
                        if showRail {
                            workflow(session).frame(width: wide ? 280 : 260)
                                .background(Northstar.Palette.bgBase)
                            Divider()
                        }
                        ScrollView {
                            currentItem(session)
                                .padding(Northstar.Space.s6)
                                .frame(maxWidth: 800, alignment: .leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Northstar.Palette.bgRaised)
                        if wide {
                            Divider()
                            activity(session).frame(width: 260)
                                .background(Northstar.Palette.bgBase)
                        }
                    }
                }
            }
            .foregroundStyle(Northstar.Palette.ink)
            .navigationTitle("Co-pilot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showWorkflow = true } label: { Label("Review items", systemImage: "list.bullet") }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showActivity = true } label: { Label("Activity", systemImage: "clock") }
                    Button { showSupport = true } label: { Label("Support context", systemImage: "headphones") }
                }
            }
            .sheet(isPresented: $showWorkflow) {
                NavigationStack {
                    workflow(session)
                        .navigationTitle("Workflow items")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showWorkflow = false } } }
                }
            }
            .sheet(isPresented: $showActivity) {
                NavigationStack {
                    activity(session)
                        .navigationTitle("Recorded activity")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showActivity = false } } }
                }
            }
            .sheet(isPresented: $showSupport) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Northstar.Space.s4) {
                            NorthstarStatusLabel("On this device", tone: .info, systemImage: "ipad.landscape")
                            Text("Support requests and acceptance are not available in this build. The Remote Support tab can add local technical-support messages to this recording.")
                                .font(Northstar.Fonts.body)
                            activity(session, messagesOnly: true)
                        }.padding(Northstar.Space.s6)
                    }
                    .navigationTitle("Support context")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSupport = false } } }
                }
            }
            .sheet(item: $correction) { request in
                CoPilotCorrectionSheet(request: request)
            }
        }
    }

    private func context(_ session: CoPilotSession) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Northstar.Space.s6) { contextFields(session) }
            VStack(alignment: .leading, spacing: Northstar.Space.s2) { contextFields(session) }
        }
        .padding(.horizontal, Northstar.Space.s6).padding(.vertical, Northstar.Space.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Northstar.Palette.bgSunken)
    }

    @ViewBuilder private func contextFields(_ session: CoPilotSession) -> some View {
        Text(session.procedure.reference ?? session.procedure.id).font(Northstar.Fonts.bodyStrong)
        Text(model.hospital(session.procedure.hospitalID)?.town ?? "Site not recorded")
            .font(Northstar.Fonts.supporting)
        Text(session.recordingSummary).font(Northstar.Fonts.supporting)
        if session.reducedSupport {
            NorthstarStatusLabel("Reduced-support context", tone: .attention)
        }
    }

    private func workflow(_ session: CoPilotSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                Text("Workflow").font(Northstar.Fonts.bodyStrong)
                    .padding(Northstar.Space.s4).accessibilityAddTraits(.isHeader)
                if session.pendingAlert != nil {
                    Text("Selection is pinned until acknowledgment or correction. All items remain available for review.")
                        .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                        .padding(.horizontal, Northstar.Space.s4)
                }
                ForEach(Array(session.procedure.steps.enumerated()), id: \.element.id) { index, step in
                    let status = session.recordingState?.itemStatuses[step.id] ?? .unrecorded
                    let selected = session.currentStep?.id == step.id
                    let activation = command(session, .selectItem, targetItemID: step.id).map(RecordingCommandActivation.init)
                    Button {
                        if apply(activation, to: session) { showWorkflow = false }
                    } label: {
                        HStack(alignment: .top, spacing: Northstar.Space.s3) {
                            Rectangle().fill(selected ? Northstar.Palette.ice : .clear).frame(width: 3)
                            Image(systemName: symbol(status)).foregroundStyle(tone(status).foreground)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                                Text("\(index + 1). \(step.title)")
                                    .font(selected ? Northstar.Fonts.bodyStrong : Northstar.Fonts.body)
                                    .foregroundStyle(Northstar.Palette.ink)
                                Text(label(status)).font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, Northstar.Space.s3).padding(.trailing, Northstar.Space.s4)
                        .frame(minHeight: Northstar.Target.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selected ? Northstar.Palette.iceSoft : .clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(session.pendingAlert != nil || activation == nil)
                    .accessibilityLabel("Item \(index + 1), \(step.title), \(label(status))")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }

    private func currentItem(_ session: CoPilotSession) -> some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s6) {
            if let commandError {
                NorthstarBanner(tone: .failure, title: "Action not recorded", message: commandError)
            }
            if !session.isRecordingSupported {
                ContentUnavailableView("Recording unavailable", systemImage: "doc.badge.ellipsis",
                    description: Text("This case does not use the supported fictional coordination template."))
            } else if let step = session.currentStep {
                let status = session.recordingState?.itemStatuses[step.id] ?? .unrecorded
                VStack(alignment: .leading, spacing: Northstar.Space.s3) {
                    Text("Current item \(session.currentIndex + 1)").font(Northstar.Fonts.label).foregroundStyle(Northstar.Palette.inkMuted)
                    Text(step.title).font(Northstar.Fonts.stepCurrent).accessibilityAddTraits(.isHeader)
                    Text(step.detail).font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
                    NorthstarStatusLabel(label(status), tone: tone(status), systemImage: symbol(status))
                }
                if let acknowledgment = session.recordingState?.pendingAcknowledgment {
                    NorthstarBanner(tone: .attention, title: "Deferred · Acknowledgment required",
                        message: "Acknowledgment leaves this item deferred. Review and correction remain available.")
                    let activation = command(session, .acknowledgeWarning(acknowledgment: acknowledgment)).map(RecordingCommandActivation.init)
                    Button("Acknowledge deferral") { _ = apply(activation, to: session) }
                        .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                        .accessibilityIdentifier("acknowledge-deferral")
                } else if status == .unrecorded {
                    let confirm = command(session, .recordConfirmation).map(RecordingCommandActivation.init)
                    let deferItem = command(session, .deferItem).map(RecordingCommandActivation.init)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Northstar.Target.spacing) { recordingActions(session, step: step, confirm: confirm, deferItem: deferItem) }
                        VStack(alignment: .leading, spacing: Northstar.Target.spacing) { recordingActions(session, step: step, confirm: confirm, deferItem: deferItem) }
                    }
                } else {
                    Text("Select another item to continue. Use Correct record to change this recorded statement.")
                        .font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
                    Button("Review items") { showWorkflow = true }.buttonStyle(NorthstarSecondaryButtonStyle())
                }
                if let request = correctionRequest(session, step: step) {
                    Button("Correct record") { correction = request }
                        .buttonStyle(NorthstarSecondaryButtonStyle(size: .large))
                }
                if let reply = session.log.last(where: { $0.kind == .remoteMessage }) {
                    Divider()
                    NorthstarBanner(tone: .info, title: "Latest local support message", message: reply.message)
                    Text(reply.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                }
            } else {
                Text(session.recordingSummary).font(Northstar.Fonts.title)
                Text("This record describes team statements, not clinical work or outcomes.")
                    .font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted)
                Button("Review items") { showWorkflow = true }.buttonStyle(NorthstarSecondaryButtonStyle(size: .large))
            }
        }
    }

    @ViewBuilder private func recordingActions(_ session: CoPilotSession, step: ProcedureStep,
        confirm: RecordingCommandActivation?, deferItem: RecordingCommandActivation?) -> some View {
        Button("Record confirmation") { _ = apply(confirm, to: session) }
            .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
            .accessibilityIdentifier("record-confirmation")
        Button("Defer item") {
            if apply(deferItem, to: session), step.isRequired {
                announcer.say("\(step.title) was deferred. Acknowledgment required.")
            }
        }
        .buttonStyle(NorthstarSecondaryButtonStyle(size: .large))
        .accessibilityIdentifier("defer-item")
    }

    private func activity(_ session: CoPilotSession, messagesOnly: Bool = false) -> some View {
        let entries = session.log.filter { !messagesOnly || $0.kind == .remoteMessage }
        return ScrollView {
            VStack(alignment: .leading, spacing: Northstar.Space.s4) {
                Text(messagesOnly ? "Local messages" : "Recent activity").font(Northstar.Fonts.bodyStrong).accessibilityAddTraits(.isHeader)
                if entries.isEmpty { Text("No activity recorded.").font(Northstar.Fonts.body).foregroundStyle(Northstar.Palette.inkMuted) }
                ForEach(entries.reversed()) { entry in
                    VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(Northstar.Fonts.supporting).monospacedDigit().foregroundStyle(Northstar.Palette.inkMuted)
                        Text(entry.message).font(Northstar.Fonts.body)
                            .foregroundStyle(entry.kind == .alert ? Northstar.Palette.amber : Northstar.Palette.ink)
                    }
                    Divider()
                }
            }.padding(Northstar.Space.s4).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func apply(_ activation: RecordingCommandActivation?, to session: CoPilotSession) -> Bool {
        guard let activation else { return false }
        do {
            try model.record(activation.command(at: .now))
            commandError = nil
            return true
        } catch {
            commandError = "The recording changed or this action is unavailable. Review the current item and try again."
            return false
        }
    }

    /// Commands carry the configured local participant as a stated actor, not verified identity.
    private func command(_ session: CoPilotSession, _ action: SessionCommandAction, targetItemID: String? = nil) -> SessionCommand? {
        session.makeCommand(action, targetItemID: targetItemID, actor: model.workspace?.localParticipant)
    }

    private func correctionRequest(_ session: CoPilotSession, step: ProcedureStep) -> CoPilotCorrectionRequest? {
        let original = session.events.last { event in
            guard event.targetItemID == step.id else { return false }
            switch event.payload {
            case .confirmationRecorded, .itemDeferred, .recordCorrected: return true
            default: return false
            }
        }
        guard let original,
              let base = command(session, .correctRecord(originalEventID: original.id, newStatus: .unrecorded, reason: nil), targetItemID: step.id)
        else { return nil }
        return CoPilotCorrectionRequest(title: step.title, base: base, originalEventID: original.id)
    }

    private func label(_ status: RecordedItemStatus) -> String {
        switch status { case .unrecorded: "Unrecorded"; case .deferred: "Deferred"; case .teamConfirmed: "Team-confirmed" }
    }
    private func symbol(_ status: RecordedItemStatus) -> String {
        switch status { case .unrecorded: "circle"; case .deferred: "exclamationmark.triangle.fill"; case .teamConfirmed: "checkmark.circle.fill" }
    }
    private func tone(_ status: RecordedItemStatus) -> NorthstarTone {
        switch status { case .unrecorded: .neutral; case .deferred: .attention; case .teamConfirmed: .success }
    }
}
