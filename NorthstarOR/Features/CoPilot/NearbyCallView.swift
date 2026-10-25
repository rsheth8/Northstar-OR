import SwiftUI

/// Controls only. AppModel selects the call transport through SyncService.
struct NearbyCallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Northstar.Space.s4) {
                    Text("Rep session and call").font(Northstar.Fonts.title)
                    Text("Connect the room iPad and rep’s Mac running Northstar on the same Wi-Fi. Use headphones for calls. Fictional content only; media is not saved.")
                        .font(Northstar.Fonts.body)
                    NorthstarStatusLabel(model.linkState.label, tone: .info)
                    if let call = model.nearbyCall { CallStatusControls(call: call, end: model.endRepCall) }
                    if let error = model.nearbyError { Text(error).foregroundStyle(Northstar.Palette.alert) }
                    NavigationLink("Connect another Northstar device") { NearbyLinkSheet() }
                        .buttonStyle(NorthstarSecondaryButtonStyle())
                    invitationControls
                    Divider()
                    if model.demoPost == .room, let session = model.activeSession {
                        CoPilotSupportPanel(session: session)
                    } else if model.demoPost == .rep, let origin = model.remoteSession?.origin {
                        SupportThreadView(entries: model.supportThread(sessionID: origin.sessionID))
                        SessionNoteComposer()
                    } else {
                        Text("Start or resume a case in Planner to send a saved question with its checklist context.")
                            .font(Northstar.Fonts.body)
                    }
                }
                .padding(Northstar.Space.s6)
            }
            .accessibilityIdentifier("rep-call-content")
            .background(Northstar.Palette.bgBase)
            .navigationTitle("Session and call").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct CallStatusControls: View {
    @ObservedObject var call: NearbyCallController
    let end: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: Northstar.Space.s3) {
            NorthstarStatusLabel(call.status, tone: call.linkState == .disconnected ? .failure : .info)
                .accessibilityIdentifier("call-status")
            Text(call.cameraStatus).font(Northstar.Fonts.supporting)
            Text("Room camera · shared with the laptop")
                .font(Northstar.Fonts.bodyStrong)
            ZStack {
                Northstar.Palette.bgSunken
                if (call.localVideoTrack != nil || call.remoteVideoTrack != nil) && !call.cameraStatus.contains("camera off") {
                    NearbyCallCameraPreview(call: call)
                } else {
                    ContentUnavailableView("Camera preview", systemImage: "video.slash",
                        description: Text(call.cameraStatus))
                }
            }
            .frame(height: 220).clipShape(RoundedRectangle(cornerRadius: Northstar.Radius.sm))
            .accessibilityLabel("Room camera preview")
            .accessibilityIdentifier("call-camera-preview")
            Text(call.muted ? "Microphone muted for this call" : "Microphone on for this call")
                .font(Northstar.Fonts.bodyStrong)
                .accessibilityIdentifier("call-microphone-state")
            HStack(spacing: Northstar.Space.s3) {
                Button { call.setMuted(!call.muted) } label: {
                    Label(call.muted ? "Unmute microphone" : "Mute microphone",
                        systemImage: call.muted ? "mic.slash.fill" : "mic.fill")
                }
                .buttonStyle(NorthstarSecondaryButtonStyle())
                .accessibilityIdentifier("call-mute")
                Button("End call", action: end).buttonStyle(NorthstarSecondaryButtonStyle())
            }
            if call.localVideoTrack != nil || call.cameraEnabled || call.canSwitchCamera {
            HStack(spacing: Northstar.Space.s3) {
                Button(call.cameraEnabled ? "Turn camera off" : "Turn camera on") { call.setCameraEnabled(!call.cameraEnabled) }
                    .buttonStyle(NorthstarSecondaryButtonStyle())
                    .disabled(call.status != "In call" || call.cameraStatus.contains("unavailable") || call.cameraStatus.contains("access is off"))
                    .accessibilityIdentifier("call-camera-enabled")
                Button("Flip camera") { call.switchCamera() }
                    .buttonStyle(NorthstarSecondaryButtonStyle())
                    .disabled(!call.canSwitchCamera || !call.cameraEnabled)
                    .accessibilityIdentifier("call-camera-flip")
            }
            }
        }
    }
}

private extension NearbyCallView {
    @ViewBuilder var invitationControls: some View {
        let invitation = model.callInvitation
        let ended = model.supportRecordingEnded
        Text(invitationLabel).font(Northstar.Fonts.bodyStrong)
        if invitation?.state == .requested, invitation?.from.rawValue != model.demoPost.rawValue {
            Button("Accept call") { model.acceptInvitation() }
                .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                .disabled(ended)
            Button("Decline call") { model.declineInvitation() }
                .buttonStyle(NorthstarSecondaryButtonStyle())
        } else if invitation?.state == .requested {
            Button("Cancel call request") { model.cancelInvitation() }
                .buttonStyle(NorthstarSecondaryButtonStyle())
        } else {
            Button("Request call") { model.requestCall() }
                .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                .disabled(ended || !isConnected || invitation?.state == .accepted)
                .accessibilityIdentifier("request-call")
        }
        if ended {
            Text("This recording has ended. A call cannot start.")
                .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
        }
    }
    var isConnected: Bool { if case .connected = model.linkState { return true }; return false }
    var invitationLabel: String {
        switch model.callInvitation?.state {
        case .requested where model.callInvitation?.from.rawValue != model.demoPost.rawValue: "Incoming call"
        case .requested: "Waiting for call acceptance"
        case .accepted: "Call accepted"
        case .declined: "Call declined"
        case .canceled: "Call canceled"
        case .expired: "Call request expired"
        case nil: "No call requested"
        }
    }
}
