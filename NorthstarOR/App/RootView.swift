import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            NorthstarWorkspaceHeader()
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
        .background(Northstar.Palette.bgBase)
    }
}

#Preview {
    RootView().environment(AppModel.launching(arguments: ["-NorthstarSampleWorkspace"])).preferredColorScheme(.light)
}
