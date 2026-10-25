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
                    Text("Use one Room iPad and one Rep iPad nearby. Peer names identify devices, not verified people.")
                    if model.linkState == .idle || model.linkState == .disconnected {
                        Button("Look for nearby iPad") { model.startNearbyLink() }
                            .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                    }
                    if model.linkState != .idle {
                        Button("Stop nearby link") { model.stopNearbyLink() }.buttonStyle(NorthstarSecondaryButtonStyle())
                    }
                }
                if let invitation = model.nearbyInvitation {
                    Section("Invitation from \(invitation.name)") {
                        Button("Accept this iPad") { model.answerNearbyInvitation(accept: true) }
                            .buttonStyle(NorthstarPrimaryButtonStyle(tone: .standard))
                        Button("Decline") { model.answerNearbyInvitation(accept: false) }.frame(minHeight: Northstar.Target.minimum)
                    }
                }
                if model.linkState == .looking {
                    Section("Choose the other iPad") {
                        if model.nearbyPeers.isEmpty { Text("No opposite-role iPad found yet. Open nearby discovery on the other iPad.") }
                        ForEach(model.nearbyPeers) { peer in
                            Button("Invite \(peer.name)") { do { try model.inviteNearby(peer.id); error = nil } catch { self.error = "Invitation could not be sent. Stop and try again." } }.frame(minHeight: Northstar.Target.minimum)
                        }
                    }
                }
                if let error = error ?? model.nearbyError { Section { NorthstarBanner(tone: .failure, title: "Nearby unavailable", message: error) } }
                Section { Text("This link is for nearby fictional demonstrations. It does not connect to a hospital or provide internet support.").font(Northstar.Fonts.supporting) }
            }
            .navigationTitle("Nearby iPad").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
