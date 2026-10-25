import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingSettings = false
    @State private var retryError: String?
    @State private var showNearby = false
    @State private var showCall = false
    @State private var pendingRole: DemoPost?
    @State private var showingRoles = false

    var body: some View {
        @Bindable var model = model
        Group {
            switch model.loadState {
            case .loading:
                WorkspaceLoadingView()
            case .needsSetup:
                WorkspaceSetupView(
                    onCreate: { try model.createWorkspace($0) },
                    onLoadSample: { try model.loadSampleWorkspace() })
            case .blocked(let message):
                WorkspaceBlockedView(
                    message: message,
                    canRetry: model.canRetryLoad,
                    canSetAside: model.canSetAsideStoredData,
                    onRetry: { model.load() },
                    onSetAside: { try model.setAsideUnreadableData() })
            case .ready:
                VStack(spacing: 0) {
                    NorthstarWorkspaceHeader(
                        communicationLabel: model.linkState.label,
                        workspaceName: model.workspace?.name,
                        onOpenSettings: model.workspace == nil ? nil : { showingSettings = true })
                    deviceLayout { deviceControls }
                    .font(Northstar.Fonts.supporting)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Northstar.Space.s4)
                    if let saveError = model.saveError {
                        SaveFailureBanner(message: retryError ?? saveError) {
                            do { try model.retrySave(); retryError = nil } catch {
                                retryError = WorkspaceForms.message(for: error)
                            }
                        }
                    }
                    CallWorkspace {
                    TabView(selection: $model.selectedDestination) {
                        Group {
                            if model.demoPost == .room { CoPilotView() }
                            else { ContentUnavailableView("Co-pilot records on the room device", systemImage: "ipad.landscape", description: Text("Open Remote Support to review the room record and reply to questions. Change this device’s role explicitly to record here.")) }
                        }
                            .tabItem { Label("Co-pilot", systemImage: "list.bullet.rectangle") }
                            .tag(AppModel.Destination.coPilot)
                        PlannerView()
                            .tabItem { Label("Planner", systemImage: "calendar") }
                            .tag(AppModel.Destination.planner)
                        RemoteSupportView()
                            .tabItem { Label("Remote Support", systemImage: "headphones") }
                            .tag(AppModel.Destination.remoteSupport)
                    }
                    }
                }
                .onChange(of: model.callInvitation?.state) { _, state in
                    if state == .accepted { showCall = false }
                }
                .onChange(of: model.demoPost) { _, role in
                    model.selectedDestination = role == .rep ? .remoteSupport : .coPilot
                }
                .alert("Change this device’s role?", isPresented: Binding(get: { pendingRole != nil }, set: { if !$0 { pendingRole = nil } })) {
                    Button("Change role and disconnect", role: .destructive) {
                        if let role = pendingRole { model.demoPost = role }
                        pendingRole = nil
                    }
                    Button("Cancel", role: .cancel) { pendingRole = nil }
                } message: {
                    Text("Nearby support will disconnect. Saved records stay on this device. Reconnect using the new role.")
                }
                .sheet(isPresented: $showCall) { NearbyCallView() }
                .sheet(isPresented: $showNearby) { NearbyLinkSheet() }
                .sheet(isPresented: $showingSettings) {
                    if let workspace = model.workspace {
                        WorkspaceSettingsView(workspace: workspace, onSave: { try model.updateWorkspace($0) })
                    }
                }
            }
        }
        .background(Northstar.Palette.bgBase)
    }
    private var deviceLayout: AnyLayout {
        typeSize.isAccessibilitySize || sizeClass == .compact
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(spacing: Northstar.Space.s2))
    }

    @ViewBuilder private var deviceControls: some View {
        Button { showingRoles = true } label: {
            Label(model.demoPost == .room ? "This device: Room" : "This device: Rep", systemImage: "ipad.landscape")
                .frame(minHeight: Northstar.Target.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("nearby-role")
        .accessibilityHint("Choose this device's role")
        .confirmationDialog("This device's role", isPresented: $showingRoles, titleVisibility: .visible) {
            Button("Room device") { requestRole(.room) }
            Button("Rep device") { requestRole(.rep) }
            Button("Cancel", role: .cancel) { }
        }
        if model.demoPost == .room || model.remoteSession != nil {
            Button(model.nearbyCall?.status == "In call" ? "Call controls" : "Session and call") { showCall = true }
                .frame(minHeight: Northstar.Target.minimum).accessibilityIdentifier("open-call")
        }
        Button("Connect devices") { showNearby = true }.frame(minHeight: Northstar.Target.minimum)
    }

    private func requestRole(_ role: DemoPost) {
        guard role != model.demoPost else { return }
        if model.linkState != .idle || model.activeSession != nil || model.remoteSession != nil {
            pendingRole = role
        } else { model.demoPost = role }
    }

}

#Preview {
    RootView().environment(AppModel.launching(arguments: ["-NorthstarSampleWorkspace"])).preferredColorScheme(.light)
}

#Preview("Setup") {
    RootView().environment(AppModel.launching(arguments: ["-NorthstarResetStore"])).preferredColorScheme(.light)
}
