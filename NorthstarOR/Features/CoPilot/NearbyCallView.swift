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
                    Text("Nearby rep call").font(Northstar.Fonts.title)
                    Text("Two-way audio and the room camera connect to the Northstar rep page on your laptop. Use fictional content only; media is not saved.")
                        .font(Northstar.Fonts.body)
                    if let call = model.nearbyCall { CallStatusControls(call: call, end: model.stopNearbyLink) }
                    Text("Signaling server").font(Northstar.Fonts.bodyStrong)
                    TextField("ws://192.168.1.20:8080", text: $server)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .keyboardType(.URL).textFieldStyle(.roundedBorder)
                        .frame(minHeight: Northstar.Target.minimum)
                        .accessibilityLabel("Signaling server").accessibilityIdentifier("call-signaling-url")
                    Text("On the laptop, open http://localhost:8080 and join with headphones. Use the laptop’s network address here. Starting a call replaces the nearby-iPad link.")
                        .font(Northstar.Fonts.supporting).foregroundStyle(Northstar.Palette.inkMuted)
                    Button(model.nearbyCall == nil || model.linkState == .idle ? "Start call" : "Restart call") {
                        model.startRepCall(server: server.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard)).accessibilityIdentifier("start-call")
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
            HStack(spacing: Northstar.Space.s3) {
                Button(call.muted ? "Unmute" : "Mute") { call.setMuted(!call.muted) }
                    .buttonStyle(NorthstarSecondaryButtonStyle()).disabled(call.status != "In call")
                Button("End call", action: end).buttonStyle(NorthstarSecondaryButtonStyle())
            }
        }
    }
}
