import SwiftUI

/// Brand identity stays separate from native tab and destination navigation.
struct NorthstarWorkspaceHeader: View {
    /// The configured workspace name; nil while no workspace exists yet.
    var communicationLabel: String = "On this device"
    var workspaceName: String?
    /// Present only when a workspace can be edited.
    var onOpenSettings: (() -> Void)?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Northstar.Space.s6) {
                identity
                Spacer(minLength: Northstar.Space.s4)
                context
            }
            VStack(alignment: .leading, spacing: Northstar.Space.s2) {
                identity
                context
            }
        }
        .padding(.horizontal, Northstar.Space.s6)
        .padding(.vertical, Northstar.Space.s1)
        .foregroundStyle(Northstar.Palette.Workspace.onHeader)
        .background(Northstar.Palette.Workspace.header, ignoresSafeAreaEdges: [])
    }

    private var identity: some View {
        HStack(spacing: Northstar.Space.s3) {
            Image("BrandMark")
                .resizable().scaledToFit().frame(width: 40, height: 28)
                .accessibilityHidden(true)
            Text("Northstar OR").font(Northstar.Fonts.supporting)
        }
        .accessibilityElement(children: .combine)
    }

    private var context: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Northstar.Space.s4) { contextLabels }
            VStack(alignment: .leading, spacing: Northstar.Space.s2) { contextLabels }
        }
        .font(Northstar.Fonts.supporting)
        .foregroundStyle(Northstar.Palette.Workspace.onHeaderSecondary)
    }

    @ViewBuilder private var contextLabels: some View {
        if let workspaceName {
            Text(workspaceName)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("header-workspace-name")
        }
        Label(communicationLabel, systemImage: "ipad.landscape")
        if let onOpenSettings {
            Button(action: onOpenSettings) {
                Label("Settings", systemImage: "gearshape")
                    .padding(.horizontal, Northstar.Space.s3)
                    .frame(minHeight: Northstar.Target.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Northstar.Palette.Workspace.onHeader)
            .accessibilityIdentifier("header-workspace-settings")
        }
    }
}
