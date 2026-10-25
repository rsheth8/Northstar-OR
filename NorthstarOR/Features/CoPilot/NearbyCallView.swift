import SwiftUI

/// Controls only. AppModel selects the call transport through SyncService.
struct NearbyCallView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("northstar-rep-signaling-url") private var server = "ws://"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Northstar.Space.s4) {
                    Text("Rep session and call").font(Northstar.Fonts.title)
                    Text("Two-way audio and the room camera connect to the Northstar rep page on your laptop. Use fictional content only; media is not saved.")
                        .font(Northstar.Fonts.body)
                    if let call = model.nearbyCall { CallStatusControls(call: call, end: model.endRepCall) }
                    Text("Laptop server").font(Northstar.Fonts.bodyStrong)
                    TextField("ws://192.168.1.20:8080", text: $server)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .keyboardType(.URL).textFieldStyle(.roundedBorder)
                        .frame(minHeight: Northstar.Target.minimum)
                        .accessibilityLabel("Signaling server").accessibilityIdentifier("call-signaling-url")
                    Text("On the same Wi-Fi, open http://localhost:8080 on the laptop and choose Join session. Share the case first; a call is optional. Use headphones for calls.")
                        .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                    NorthstarStatusLabel(model.isSharingSession ? model.linkState.label : "Case is not shared", tone: .info)
                    if let error = model.nearbyError { Text(error).foregroundStyle(Northstar.Palette.alert) }
                    Button("Share current case") {
                        model.startSharedSession(server: server.trimmingCharacters(in: .whitespacesAndNewlines))
                    }.buttonStyle(NorthstarSecondaryButtonStyle()).disabled(model.activeSession == nil)
                    if model.isSharingSession {
                        Button("Stop sharing and end call", action: model.stopNearbyLink)
                            .buttonStyle(NorthstarSecondaryButtonStyle())
                    }
                    if model.isSharingSession {
                        invitationControls
                    } else {
                        Button(model.nearbyCall == nil || model.linkState == .idle ? "Start call" : "Restart call") {
                            model.startRepCall(server: server.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                        .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard)).accessibilityIdentifier("start-call")
                    }
                    Divider()
                    if let session = model.activeSession {
                        CoPilotSupportPanel(session: session)
                    } else {
                        Text("Start or resume a case in Planner to send a saved question with its checklist context.")
                            .font(Northstar.Fonts.body)
                    }
                }
                .padding(Northstar.Space.s6)
            }
            .accessibilityIdentifier("rep-call-content")
            .background(Northstar.Palette.bgBase)
            .navigationTitle("Call rep").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct CallStatusControls: View {
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
                if call.localVideoTrack != nil {
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

private extension NearbyCallView {
    @ViewBuilder var invitationControls: some View {
        let invitation = model.callInvitation
        let ended = model.activeSession?.isFinished == true
        Text(invitationLabel).font(Northstar.Fonts.bodyStrong)
        if invitation?.state == .requested, invitation?.from == .rep {
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
                .disabled(ended)
                .accessibilityIdentifier("request-call")
        }
        if ended {
            Text("This recording has ended. A call cannot start.")
                .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
        }
    }
    var invitationLabel: String {
        switch model.callInvitation?.state {
        case .requested where model.callInvitation?.from == .rep: "Incoming call from the rep"
        case .requested: "Calling the rep"
        case .accepted: "Call accepted"
        case .declined: "Call declined"
        case .canceled: "Call canceled"
        case .expired: "Call request expired"
        case nil: "No call requested"
        }
    }
}
