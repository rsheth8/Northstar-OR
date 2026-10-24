import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 0) {
            NorthstarWorkspaceHeader()
            TabView {
                CoPilotView()
                    .tabItem { Label("Co-pilot", systemImage: "list.bullet.rectangle") }
                PlannerView()
                    .tabItem { Label("Planner", systemImage: "calendar") }
                RemoteSupportView()
                    .tabItem { Label("Remote Support", systemImage: "headphones") }
            }
        }
        .background(Northstar.Palette.bgBase)
    }
}

#Preview {
    RootView().environment(AppModel()).preferredColorScheme(.light)
}
