import SwiftUI

struct NearbyLinkSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Communication") {
                    NorthstarStatusLabel(model.linkState.label, tone: .info, systemImage: "ipad.landscape")
                    Text("Use Northstar in Room mode on the iPad and Rep mode on the Mac or a second iPad. Keep both apps open on the same Wi-Fi. Peer names identify devices, not verified people.")
                    if model.linkState == .idle || model.linkState == .disconnected {
                        Button("Find Northstar devices") { model.startNearbyLink() }
                            .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                    }
                    if model.linkState != .idle {
                        Button("Stop nearby link") { model.stopNearbyLink() }.buttonStyle(NorthstarSecondaryButtonStyle())
                    }
                }
                if let invitation = model.nearbyInvitation {
                    Section("Invitation from \(invitation.name)") {
                        Button("Accept this device") { model.answerNearbyInvitation(accept: true) }
                            .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                        Button("Decline") { model.answerNearbyInvitation(accept: false) }.frame(minHeight: Northstar.Target.minimum)
                    }
                }
                if model.linkState == .looking {
                    Section("Choose the other device") {
                        if model.nearbyPeers.isEmpty { Text("No opposite-role device found yet. Start discovery in Northstar on both devices.") }
                        ForEach(model.nearbyPeers) { peer in
                            Button("Invite \(peer.name)") { do { try model.inviteNearby(peer.id); error = nil } catch { self.error = "Invitation could not be sent. Stop and try again." } }.frame(minHeight: Northstar.Target.minimum)
                        }
                    }
                }
                if let error = error ?? model.nearbyError { Section { NorthstarBanner(tone: .failure, title: "Nearby unavailable", message: error) } }
                Section { Text("This link is for nearby fictional demonstrations. It does not connect to a hospital or provide internet support.").font(Northstar.Fonts.supporting) }
            }
            .navigationTitle("Connect devices").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
