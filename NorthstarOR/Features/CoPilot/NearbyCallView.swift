import SwiftUI

/// Controls only. AppModel selects the call transport through SyncService.
struct NearbyCallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var microphonePermission: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Northstar.Space.s4) {
                    Text("Rep session and call").font(Northstar.Fonts.title)
                    Text("Connect the room iPad and rep’s Mac running Northstar on the same Wi-Fi. Use headphones for calls. Fictional content only; media is not saved.")
                        .font(Northstar.Fonts.body)
                    NorthstarStatusLabel(model.linkState.label, tone: .info)
                    if model.nearbyCall?.status != "In call" {
                        Button("Set up microphone") {
                            Task {
                                let allowed = await NearbyCallController.requestMicrophoneAccess()
                                microphonePermission = allowed ? "Microphone access allowed. Reconnect and accept a call when ready." : "Microphone access is off. On Mac, open System Settings → Privacy & Security → Microphone and enable Northstar OR. On iPad, enable Microphone in Northstar’s Settings."
                            }
                        }
                        .buttonStyle(NorthstarSecondaryButtonStyle())
                        .accessibilityIdentifier("setup-call-microphone")
                        if let microphonePermission { Text(microphonePermission).font(Northstar.Fonts.supporting) }
                    }
                    if let call = model.nearbyCall, model.callInvitation?.state == .accepted { WorkspaceCallMedia(call: call, compact: false, end: model.endRepCall) }
                    if let error = model.nearbyError { Text(error).foregroundStyle(Northstar.Palette.alert) }
                    NavigationLink("Connect another Northstar device") { NearbyLinkSheet() }
                        .buttonStyle(NorthstarSecondaryButtonStyle())
                    WorkspaceCallAction()
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
