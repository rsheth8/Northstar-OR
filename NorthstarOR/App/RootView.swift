import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var showingSettings = false
    @State private var retryError: String?
    @State private var showNearby = false
    @State private var showCall = false

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
                    HStack {
                        Picker("This device", selection: $model.demoPost) {
                            Text("Room").tag(DemoPost.room); Text("Rep").tag(DemoPost.rep)
                        }.pickerStyle(.segmented).frame(maxWidth: 240).accessibilityIdentifier("nearby-role")
                        Spacer()
                        if model.demoPost == .room || model.remoteSession != nil {
                            Button(model.nearbyCall?.status == "In call" ? "Call controls" : "Session and call") { showCall = true }
                                .frame(minHeight: Northstar.Target.minimum).accessibilityIdentifier("open-call")
                        }
                        Button("Connect devices") { showNearby = true }.frame(minHeight: Northstar.Target.minimum)
                    }.padding(.horizontal, Northstar.Space.s6)
                    Text("Fictional coordination record. Support links nearby demo devices. This app does not decide whether a procedure proceeds.")
                        .font(Northstar.Fonts.supporting).padding(.horizontal, Northstar.Space.s6)
                    if let saveError = model.saveError {
                        SaveFailureBanner(message: retryError ?? saveError) {
                            do { try model.retrySave(); retryError = nil } catch {
                                retryError = WorkspaceForms.message(for: error)
                            }
                        }
                    }
                    TabView(selection: $model.selectedDestination) {
                        Group { if model.demoPost == .room { CoPilotView() } else { RemoteSupportView() } }
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
                .onChange(of: model.callInvitation?.id) { _, _ in
                    if model.callInvitation?.state == .requested, model.callInvitation?.from.rawValue != model.demoPost.rawValue { showCall = true }
                }
                .onChange(of: model.demoPost) { _, role in
                    model.selectedDestination = role == .rep ? .remoteSupport : .coPilot
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
}

#Preview {
    RootView().environment(AppModel.launching(arguments: ["-NorthstarSampleWorkspace"])).preferredColorScheme(.light)
}

#Preview("Setup") {
    RootView().environment(AppModel.launching(arguments: ["-NorthstarResetStore"])).preferredColorScheme(.light)
}
