import SwiftUI

/// Brand identity stays separate from native tab and destination navigation.
struct NorthstarWorkspaceHeader: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    /// The configured workspace name; nil while no workspace exists yet.
    var communicationLabel: String = "On this device"
    var workspaceName: String?
    /// Present only when a workspace can be edited.
    var onOpenSettings: (() -> Void)?

    var body: some View {
        let stacked = typeSize.isAccessibilitySize || sizeClass == .compact
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Northstar.Space.s2))
            : AnyLayout(HStackLayout(spacing: Northstar.Space.s6))
        layout {
            identity
            if !stacked { Spacer(minLength: Northstar.Space.s4) }
            context
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        let layout = sizeClass == .compact
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Northstar.Space.s2))
            : AnyLayout(HStackLayout(spacing: Northstar.Space.s4))
        layout { contextLabels }
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
            .fixedSize(horizontal: false, vertical: true)
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
