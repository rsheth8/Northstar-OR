import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var showingSettings = false
    @State private var retryError: String?

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
                        workspaceName: model.workspace?.name,
                        onOpenSettings: model.workspace == nil ? nil : { showingSettings = true })
                    if let saveError = model.saveError {
                        SaveFailureBanner(message: retryError ?? saveError) {
                            do { try model.retrySave(); retryError = nil } catch {
                                retryError = WorkspaceForms.message(for: error)
                            }
                        }
                    }
                    TabView(selection: $model.selectedDestination) {
                        CoPilotView()
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
