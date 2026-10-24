import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            CoPilotView()
                .tabItem { Label("Co-pilot", systemImage: "waveform.path.ecg") }
            PlannerView()
                .tabItem { Label("Planner", systemImage: "map") }
            RemoteSupportView()
                .tabItem { Label("Remote Support", systemImage: "person.wave.2") }
        }
    }
}

#Preview {
    RootView().environment(AppModel()).preferredColorScheme(.dark)
}
