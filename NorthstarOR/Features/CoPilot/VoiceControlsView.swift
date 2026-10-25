import SwiftUI
import AVFoundation
import Combine

struct VoiceControlsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    let session: CoPilotSession
    let correctionOpen: Bool
    var showUnresolved: () -> Void
    @State private var service = VoiceCommandService()
    @State private var router = VoiceCommandRouter()
    @State private var captured: SessionCommand?
    @State private var error: String?
    @State private var observedCallStatus: String?
    @State private var permissionRequest = UUID()

    private var blocked: Bool {
        model.demoPost != .room || VoiceAudioPolicy.callOwnsAudio(invitationAccepted: model.callInvitation?.state == .accepted, status: observedCallStatus ?? model.nearbyCall?.status) || correctionOpen || session.isFinished || session.isEnded
    }
    private var context: String {
        "\(session.identity.sessionID):\(session.events.count):\(session.currentStep?.id ?? "none"):\(blocked):\(model.selectedDestination):\(String(describing: model.callInvitation)): choose-actor-\(model.workspace?.localParticipant.id ?? "none")"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            Label(status, systemImage: service.state == .listening ? "mic.fill" : "mic.slash")
                .font(Northstar.Fonts.bodyStrong)
            Text("Say “record confirmation”, “defer this item”, or “acknowledge deferral”. Review, then tap to record. You can also say “open Planner”, “open Co-pilot”, “show unresolved items”, or “stop listening”. Listening ends after eight seconds.")
                .font(Northstar.Fonts.supporting)
            if let heard = router.heard { Text("Heard: \(heard)").font(Northstar.Fonts.supporting) }
            if let pending = router.pending {
                Text("\(actionLabel(pending)) · \(session.procedure.reference ?? session.procedure.id) · \(session.currentStep?.title ?? "Item")")
                    .font(Northstar.Fonts.bodyStrong)
                Button("Record reviewed voice action") {
                    guard !blocked, let command = router.take() else { stop(); return }
                    do { try model.record(command); error = nil } catch { self.error = "Action not recorded. The record changed or the action is unavailable. Review the current item." }
                    stop()
                }.buttonStyle(NorthstarPrimaryButtonStyle())
            } else if service.state == .processing {
                Text("No supported action recognized. Use touch or listen again.").font(Northstar.Fonts.supporting)
            }
            if let error { Text(error).font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.alert) }
            ViewThatFits(in: .horizontal) {
                HStack { listeningButtons }
                VStack(alignment: .leading) { listeningButtons }
            }
        }
        .onReceive(model.nearbyCall?.$status.eraseToAnyPublisher() ?? Just("Call ended").eraseToAnyPublisher()) { status in
            observedCallStatus = status
            if VoiceAudioPolicy.callOwnsAudio(invitationAccepted: model.callInvitation?.state == .accepted, status: status) { stop() }
        }
        .onChange(of: context) { _, _ in stop() }
        .onChange(of: scenePhase) { _, value in if value != .active { stop() } }
        .onReceive(NotificationCenter.default.publisher(for: .northstarWillSpeak)) { _ in stop() }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in stop() }
        .onDisappear { stop() }
    }
    @ViewBuilder private var listeningButtons: some View {
        Button("Listen for one command") { start() }
            .buttonStyle(NorthstarSecondaryButtonStyle(size: .large))
            .disabled(blocked || service.state == .listening)
        Button("Stop / cancel") { stop() }
            .buttonStyle(NorthstarSecondaryButtonStyle(size: .large))
    }
    private var status: String {
        if blocked { return "Voice unavailable · use touch controls" }
        switch service.state {
        case .off: return "Voice off"
        case .listening: return "Listening · one command"
        case .processing: return "Processing · review heard action"
        case .unavailable: return "Voice unavailable · permissions or on-device recognition required"
        }
    }
    private func actionLabel(_ command: SessionCommand) -> String {
        switch command.action {
        case .recordConfirmation: return "Record team confirmation"
        case .deferItem: return "Defer item"
        case .acknowledgeWarning: return "Acknowledge deferral; item stays deferred"
        default: return "Review action"
        }
    }
    private func start() {
        stop()
        guard !VoiceAnnouncer.isSpeaking else { error = "Wait for the spoken alert to finish, then listen again."; return }
        let token = UUID(); permissionRequest = token
        Task { @MainActor in
            guard await service.requestPermissions(), permissionRequest == token,
                  scenePhase == .active, !blocked, !VoiceAnnouncer.isSpeaking else { return }
            let action: SessionCommandAction = session.recordingState?.pendingAcknowledgment.map { .acknowledgeWarning(acknowledgment: $0) } ?? .recordConfirmation
            captured = session.makeCommand(action, actor: model.workspace?.localParticipant, source: .voice)
            service.onFinal = { id, transcript in
                switch VoiceCommand.parse(transcript) {
                case .openPlanner: stop(); model.selectedDestination = .planner
                case .openCoPilot: stop(); model.selectedDestination = .coPilot
                case .showUnresolved: stop(); showUnresolved()
                case .stopListening: stop()
                default: router.receive(id: id, transcript: transcript, isFinal: true, captured: captured)
                }
            }
            do { try service.start() } catch { self.error = "Voice is unavailable. Touch controls remain available."; service.stop() }
        }
    }
    private func stop() {
        permissionRequest = UUID(); service.stop(); router.invalidate(); captured = nil
    }
}
